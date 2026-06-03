import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/branch_cash_counter_datasource.dart';
import '../../data/model/branch_cash_counter_model.dart';

// ═══════════════════════════════════════════════════════════
//  STATE
// ═══════════════════════════════════════════════════════════

class BranchCashCounterState {
  final BranchCashCounterSummary? summary;
  final String                    branchId;
  final DateTime                  fromDate;
  final DateTime                  toDate;
  final bool                      isLoading;
  final String?                   errorMessage;

  BranchCashCounterState({
    this.summary,
    required this.branchId,
    DateTime? fromDate,
    DateTime? toDate,
    this.isLoading    = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _monthStart(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _monthStart() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, 1);
  }

  BranchCashCounterState copyWith({
    BranchCashCounterSummary? summary,
    String?                   branchId,
    DateTime?                 fromDate,
    DateTime?                 toDate,
    bool?                     isLoading,
    String?                   errorMessage,
  }) =>
      BranchCashCounterState(
        branchId:     branchId     ?? this.branchId,
        summary:      summary      ?? this.summary,
        fromDate:     fromDate     ?? this.fromDate,
        toDate:       toDate       ?? this.toDate,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

// ═══════════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════════

class BranchCashCounterNotifier
    extends StateNotifier<BranchCashCounterState> {
  final BranchCashCounterDatasource _ds;

  BranchCashCounterNotifier(String branchId)
      : _ds = BranchCashCounterDatasource(),
        super(BranchCashCounterState(branchId: branchId)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final summary = await _ds.getReport(
        branchId: state.branchId,    // ← ADD
        fromDate: state.fromDate,
        toDate:   state.toDate,
      );
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void setFromDate(DateTime d) {
    state = state.copyWith(fromDate: d);
    load();
  }

  void setToDate(DateTime d) {
    state = state.copyWith(toDate: d);
    load();
  }

  void setThisMonth() {
    final n = DateTime.now();
    state = state.copyWith(
      fromDate: DateTime(n.year, n.month, 1),
      toDate:   DateTime(n.year, n.month, n.day),
    );
    load();
  }

  void setToday() {
    final d = BranchCashCounterState._today();
    state = state.copyWith(fromDate: d, toDate: d);
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ═══════════════════════════════════════════════════════════
//  PROVIDER
// ═══════════════════════════════════════════════════════════

final branchCashCounterProvider = StateNotifierProvider.family
<BranchCashCounterNotifier,
BranchCashCounterState,
String>(
(ref, branchId) => BranchCashCounterNotifier(branchId),
);