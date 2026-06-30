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

class CustomerLedgerState {
  final List<CustomerLedgerModel> allLedgers;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? fromDate;
  final DateTime? toDate;

  const CustomerLedgerState({
    this.allLedgers = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.fromDate,
    this.toDate,
  });

  List<CustomerLedgerModel> get filteredLedgers {
    var list = allLedgers;

    if (fromDate != null) {
      final start = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
      list = list.where((l) => !l.createdAt.isBefore(start)).toList();
    }

    if (toDate != null) {
      final end = DateTime(toDate!.year, toDate!.month, toDate!.day, 23, 59, 59);
      list = list.where((l) => !l.createdAt.isAfter(end)).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((l) => l.customerName.toLowerCase().contains(q) || (l.notes?.toLowerCase().contains(q) ?? false)).toList();
    }

    return list;
  }

  double get totalPaid => filteredLedgers.fold(0, (sum, l) => sum + l.payAmount);

  CustomerLedgerState copyWith({
    List<CustomerLedgerModel>? allLedgers,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) => CustomerLedgerState(
    allLedgers: allLedgers ?? this.allLedgers,
    searchQuery: searchQuery ?? this.searchQuery,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
    toDate: clearToDate ? null : (toDate ?? this.toDate),
  );
}

class CustomerLedgerNotifier extends StateNotifier<CustomerLedgerState> {
  final GetLedgersUseCase _getAll;
  final AddLedgerUseCase _add;
  final DeleteLedgerUseCase _delete;
  final Ref _ref;
  final UpdateLedgerUseCase  _update;
  CustomerLedgerNotifier(this._ref):
        _getAll = GetLedgersUseCase(CustomerLedgerRepositoryImpl()),
        _add = AddLedgerUseCase(CustomerLedgerRepositoryImpl()),
        _delete = DeleteLedgerUseCase(CustomerLedgerRepositoryImpl()),
        _update = UpdateLedgerUseCase(CustomerLedgerRepositoryImpl()),
        super(const CustomerLedgerState()) {
    loadLedgers();
  }



  Future<void> loadLedgers() async {
    state = state.copyWith(isLoading: true);
    try {
      final _storeId = _ref.read(authProvider).storeId;
      final ledgers = await _getAll(_storeId);
      state = state.copyWith(allLedgers: ledgers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  // customer_ledger_provider.dart (sirf addLedger method change)
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
      final _storeId = auth.storeId;

      final saved = await _add(CustomerLedgerModel(
        id:             '',
        storeId:        _storeId,
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

      state = state.copyWith(
        allLedgers: [saved, ...state.allLedgers],
        isLoading:  false,
      );

      _ref.read(customerProvider.notifier).loadCustomers();
      _ref.read(cashCounterProvider.notifier).loadRecords();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Add error: $e');
    }
  }

  Future<void> deleteLedger(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _delete(id);
      final list = state.allLedgers.where((l) => l.id != id).toList();
      state = state.copyWith(allLedgers: list, isLoading: false);
      _ref.read(customerProvider.notifier).loadCustomers();
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
      final updated = await _update(        // ← _repo ki jagah _update
        id:        id,
        payAmount: payAmount,
        newAmount: newAmount,
        notes:     notes,
      );

      final list = state.allLedgers
          .map((l) => l.id == updated.id ? updated : l)
          .toList();

      state = state.copyWith(allLedgers: list, isLoading: false);
      _ref.read(customerProvider.notifier).loadCustomers();
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Update error: $e');
    }
  }

  void onSearchChanged(String q) => state = state.copyWith(searchQuery: q);
  void clearError()              => state = state.copyWith(errorMessage: null);

  void setFromDate(DateTime? date) {
    state = date == null
        ? state.copyWith(clearFromDate: true)
        : state.copyWith(fromDate: date);
  }

  void setToDate(DateTime? date) {
    state = date == null
        ? state.copyWith(clearToDate: true)
        : state.copyWith(toDate: date);
  }

  void clearDateFilter() {
    state = state.copyWith(clearFromDate: true, clearToDate: true);
  }
}

final customerLedgerProvider =
StateNotifierProvider<CustomerLedgerNotifier, CustomerLedgerState>(
      (ref) => CustomerLedgerNotifier(ref),
);