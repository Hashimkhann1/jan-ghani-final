import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/store_summary_datasource.dart';
import '../../data/model/store_summary_model.dart';

class StoreSummaryState {
  final List<StoreSummaryModel> allRecords;
  final String  searchQuery;
  final bool    isLoading;
  final String? errorMessage;

  const StoreSummaryState({
    this.allRecords   = const [],
    this.searchQuery  = '',
    this.isLoading    = false,
    this.errorMessage,
  });

  List<StoreSummaryModel> get filteredRecords {
    if (searchQuery.isEmpty) return allRecords;
    final q = searchQuery.toLowerCase();
    return allRecords
        .where((r) => r.counterDate.toString().contains(q))
        .toList();
  }

  // ── Grand Totals ──────────────────────────────────────────
  double get grandTotalSale => allRecords.fold(0, (s, r) => s + r.totalSale);
  double get grandTotalCashIn => allRecords.fold(0, (s, r) => s + r.totalCashIn);
  double get grandTotalCashOut => allRecords.fold(0, (s, r) => s + r.totalCashOut);
  double get grandTotalExpense => allRecords.fold(0, (s, r) => s + r.totalExpense);
  double get grandTotalAmount  => allRecords.fold(0, (s, r) => s + r.totalAmount);

  StoreSummaryState copyWith({
    List<StoreSummaryModel>? allRecords,
    String?                  searchQuery,
    bool?                    isLoading,
    String?                  errorMessage,
  }) => StoreSummaryState(
    allRecords:   allRecords   ?? this.allRecords,
    searchQuery:  searchQuery  ?? this.searchQuery,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,
  );
}

class StoreSummaryNotifier extends StateNotifier<StoreSummaryState> {
  final StoreSummaryDataSource _ds;
  final Ref _ref;

  StoreSummaryNotifier(this._ref)
      : _ds = StoreSummaryDataSource(),
        super(const StoreSummaryState()) {
    load();
  }

  String get _storeId => _ref.read(authProvider).storeId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final records = await _ds.getAll(_storeId);
      state = state.copyWith(allRecords: records, isLoading: false);
    } catch (e) {
      print('❌ StoreSummary load error: $e');
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void onSearchChanged(String q) =>
      state = state.copyWith(searchQuery: q);
  void clearError() => state = state.copyWith(errorMessage: null);
}

final storeSummaryProvider = StateNotifierProvider<StoreSummaryNotifier, StoreSummaryState>((ref) => StoreSummaryNotifier(ref),);