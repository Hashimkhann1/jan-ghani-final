import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/cash_counter_remote_datasource.dart';
import '../../data/model/cash_counter_model.dart';

// ── State ─────────────────────────────────────────────────────
class CashCounterState {
  final List<CashCounterModel> allRecords;
  final String  searchQuery;
  final bool    isLoading;
  final String? errorMessage;

  const CashCounterState({
    this.allRecords   = const [],
    this.searchQuery  = '',
    this.isLoading    = false,
    this.errorMessage,
  });

  List<CashCounterModel> get filteredRecords {
    if (searchQuery.isEmpty) return allRecords;
    final q = searchQuery.toLowerCase();
    return allRecords
        .where((r) => r.counterDate.toString().contains(q))
        .toList();
  }

  // ── Summary Stats ─────────────────────────────────────────
  double get grandTotalSale    =>
      allRecords.fold(0, (s, r) => s + r.totalSale);
  double get grandCashIn       =>
      allRecords.fold(0, (s, r) => s + r.cashIn);
  double get grandCashOut      => allRecords.fold(0, (s, r) => s + r.cashOut);
  double get grandTotalAmount  =>
      allRecords.fold(0, (s, r) => s + r.totalAmount);

  CashCounterState copyWith({
    List<CashCounterModel>? allRecords,
    String?                 searchQuery,
    bool?                   isLoading,
    String?                 errorMessage,
  }) => CashCounterState(
    allRecords:   allRecords   ?? this.allRecords,
    searchQuery:  searchQuery  ?? this.searchQuery,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,
  );
}

// ── Notifier ──────────────────────────────────────────────────
class CashCounterNotifier extends StateNotifier<CashCounterState> {
  final CashCounterRemoteDataSource _ds;
  final Ref _ref;

  CashCounterNotifier(this._ref)
      : _ds = CashCounterRemoteDataSource(),
        super(const CashCounterState()) {
    loadRecords();
  }

  String  get _storeId   => _ref.read(authProvider).storeId;
  String? get _counterId => _ref.read(authProvider).counterId;
  String  get _role      => _ref.read(authProvider).role;

  Future<void> loadRecords() async {
    state = state.copyWith(isLoading: true);
    try {
      final all      = await _ds.getAll(_storeId);
      final filtered = _filterByRole(all);
      state = state.copyWith(allRecords: filtered, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  List<CashCounterModel> _filterByRole(List<CashCounterModel> all) {
    // Owner / Manager — sab records
    if (_role == 'store_owner' || _role == 'store_manager') return all;

    // Counter nahi — empty
    if (_counterId == null) return [];

    // Exact counter_id match
    return all.where((r) => r.counterId == _counterId).toList();
  }

  Future<void> registerOpeningAmount(double amount) async {
    state = state.copyWith(isLoading: true);
    try {
      final counterId = _counterId;

      print('🔄 Registering...');
      print('   storeId:   $_storeId');
      print('   counterId: $counterId');
      print('   amount:    $amount');

      if (counterId == null) {
        state = state.copyWith(
            isLoading:    false,
            errorMessage: 'Counter assign nahi');
        return;
      }

      await _ds.registerOpeningAmount(
        storeId:   _storeId,
        counterId: counterId,
        amount:    amount,
      );

      print('✅ Done — reloading...');
      await loadRecords();

    } catch (e, stack) {
      print('❌ Error: $e');
      print('❌ Stack: $stack');
      state = state.copyWith(
          isLoading:    false,
          errorMessage: 'Error: $e');
    }
  }

  void onSearchChanged(String q) =>
      state = state.copyWith(searchQuery: q);
  void clearError() => state = state.copyWith(errorMessage: null);
}


// ── Provider ──────────────────────────────────────────────────
final cashCounterProvider =
StateNotifierProvider<CashCounterNotifier, CashCounterState>(
      (ref) => CashCounterNotifier(ref),
);