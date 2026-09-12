import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/branch/cash_counter/presentation/provider/cash_counter_provider.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../customer/presentation/provider/customer_provider.dart';
import '../../data/model/customer_ledger_model.dart';
import '../../data/repository/customer_ledger_repository_impl.dart';
import '../../domain/usecase/add_ledger_usecase.dart';
import '../../domain/usecase/delete_ledger_usecase.dart';
import '../../domain/usecase/get_ledgers_usecase.dart';
import '../../domain/usecase/update_ledger_usecase.dart';

const kLedgerPageSize = 50;

class CustomerLedgerState {
  /// Sirf current page ke rows (server-side pagination).
  final List<CustomerLedgerModel> allLedgers;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? fromDate;
  final DateTime? toDate;

  // ── Pagination (server-side) ──────────────────────────────
  final int    page;        // 0-based
  final int    totalCount;  // poore filtered dataset ka count
  final double totalPaidAll; // poore filtered dataset ka SUM(pay_amount)

  const CustomerLedgerState({
    this.allLedgers = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.fromDate,
    this.toDate,
    this.page = 0,
    this.totalCount = 0,
    this.totalPaidAll = 0,
  });

  /// Search + counter filter ab DB query karti hai, is liye yeh direct
  /// current page hi hai.
  List<CustomerLedgerModel> get filteredLedgers => allLedgers;

  /// Poore filtered dataset ka total paid (sirf current page ka nahi).
  double get totalPaid => totalPaidAll;

  int get pageCount =>
      totalCount == 0 ? 1 : ((totalCount + kLedgerPageSize - 1) ~/ kLedgerPageSize);

  /// Kya date range abhi default (koi filter nahi) par hai — Clear Filter
  /// button sirf tab dikhayein jab user ne from/to mein se koi date chuni ho.
  bool get isDefaultDateRange => fromDate == null && toDate == null;

  CustomerLedgerState copyWith({
    List<CustomerLedgerModel>? allLedgers,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearFromDate = false,
    bool clearToDate = false,
    int? page,
    int? totalCount,
    double? totalPaidAll,
  }) => CustomerLedgerState(
    allLedgers: allLedgers ?? this.allLedgers,
    searchQuery: searchQuery ?? this.searchQuery,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
    toDate: clearToDate ? null : (toDate ?? this.toDate),
    page: page ?? this.page,
    totalCount: totalCount ?? this.totalCount,
    totalPaidAll: totalPaidAll ?? this.totalPaidAll,
  );
}

class CustomerLedgerNotifier extends StateNotifier<CustomerLedgerState> {
  final GetLedgersUseCase _getAll;
  final AddLedgerUseCase _add;
  final DeleteLedgerUseCase _delete;
  final Ref _ref;
  final UpdateLedgerUseCase  _update;

  Timer? _searchDebounce;

  CustomerLedgerNotifier(this._ref):
        _getAll = GetLedgersUseCase(CustomerLedgerRepositoryImpl()),
        _add = AddLedgerUseCase(CustomerLedgerRepositoryImpl()),
        _delete = DeleteLedgerUseCase(CustomerLedgerRepositoryImpl()),
        _update = UpdateLedgerUseCase(CustomerLedgerRepositoryImpl()),
        super(_initialState()) {
    loadLedgers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  // Default: koi date filter nahi (poori history) — list bhari hone se
  // bachne ke liye pagination (kLedgerPageSize) har baar sirf ek page
  // (50 rows) DB se laati hai, is liye poori history load karna bhi halka
  // rehta hai.
  static CustomerLedgerState _initialState() => const CustomerLedgerState();

  /// Server se current page load karo. [resetPage] true ho to page 0 par
  /// wapas jao (filter / search / date change ke baad).
  Future<void> loadLedgers({bool resetPage = false}) async {
    final auth      = _ref.read(authProvider);
    final counterId = auth.counterId;

    // Koi counter assign nahi — kuch load karne ko nahi.
    if (counterId == null) {
      state = state.copyWith(
        allLedgers:   const [],
        totalCount:   0,
        totalPaidAll: 0,
        page:         0,
        isLoading:    false,
      );
      return;
    }

    final page = resetPage ? 0 : state.page;
    state = state.copyWith(isLoading: true, page: page);

    try {
      final result = await _getAll.page(
        auth.storeId,
        counterId: counterId,
        from:      state.fromDate,
        to:        state.toDate,
        search:    state.searchQuery,
        limit:     kLedgerPageSize,
        offset:    page * kLedgerPageSize,
      );

      // Agar current page range se bahar ho (e.g. delete ke baad), pichle
      // valid page par khud chale jao.
      final maxPage = result.total == 0
          ? 0
          : (result.total - 1) ~/ kLedgerPageSize;
      if (page > maxPage) {
        state = state.copyWith(page: maxPage);
        return loadLedgers();
      }

      state = state.copyWith(
        allLedgers:   result.rows,
        totalCount:   result.total,
        totalPaidAll: result.totalPaid,
        isLoading:    false,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void setPage(int page) {
    if (page == state.page) return;
    state = state.copyWith(page: page);
    loadLedgers();
  }

  Future<void> addLedger({
    required String customerId,
    required String customerName,
    required double previousAmount,
    required double payAmount,
    required double newAmount,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final auth = _ref.read(authProvider);
      final counterId = auth.counterId;
      final userId = auth.user?.id;        // ← cashier/manager id
      final storeId = auth.storeId;

      await _add(CustomerLedgerModel(
        id:             '',
        storeId:        storeId,
        customerId:     customerId,
        customerName:   customerName,
        counterId:      counterId,
        userId:         userId,           // ← new
        previousAmount: previousAmount,
        payAmount:      payAmount,
        newAmount:      newAmount,
        notes:          notes,
        createdAt:      DateTime.now(),
        updatedAt:      DateTime.now(),
      ));

      _ref.read(customerProvider.notifier).loadCustomers();
      _ref.read(cashCounterProvider.notifier).loadRecords();

      // Naya record sabse upar aata hai — page 0 par jao aur reload.
      await loadLedgers(resetPage: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Add error: $e');
    }
  }

  Future<void> deleteLedger(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _delete(id);
      _ref.read(customerProvider.notifier).loadCustomers();
      await loadLedgers();
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Delete error: $e');
    }
  }

  Future<void> updateLedger({
    required String id,
    required double payAmount,
    required double newAmount,
    String?         notes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _update(
        id:        id,
        payAmount: payAmount,
        newAmount: newAmount,
        notes:     notes,
      );

      _ref.read(customerProvider.notifier).loadCustomers();
      await loadLedgers();
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Update error: $e');
    }
  }

  void onSearchChanged(String q) {
    state = state.copyWith(searchQuery: q);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      loadLedgers(resetPage: true);
    });
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  void setFromDate(DateTime? date) {
    state = date == null
        ? state.copyWith(clearFromDate: true)
        : state.copyWith(fromDate: date);
    loadLedgers(resetPage: true);
  }

  void setToDate(DateTime? date) {
    state = date == null
        ? state.copyWith(clearToDate: true)
        : state.copyWith(toDate: date);
    loadLedgers(resetPage: true);
  }

  // From/To dono hata kar wapas default (koi filter nahi) par.
  void clearDateFilter() {
    state = _initialState().copyWith(
      allLedgers:  state.allLedgers,
      searchQuery: state.searchQuery,
    );
    loadLedgers(resetPage: true);
  }
}

final customerLedgerProvider =
StateNotifierProvider<CustomerLedgerNotifier, CustomerLedgerState>(
      (ref) => CustomerLedgerNotifier(ref),
);
