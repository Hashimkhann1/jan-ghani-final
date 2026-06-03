import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/accountant_branch_summary_datasource.dart';
import '../../data/model/accountant_branch_summary_model.dart';

// ═══════════════════════════════════════════════════════════
//  STATE
// ═══════════════════════════════════════════════════════════

class BranchSummaryState {
  final BranchSummaryReport? summary;
  final String               branchId;
  final DateTime             fromDate;
  final DateTime             toDate;
  final bool                 isLoading;
  final String?              errorMessage;

  BranchSummaryState({
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

  BranchSummaryState copyWith({
    BranchSummaryReport? summary,
    String?              branchId,
    DateTime?            fromDate,
    DateTime?            toDate,
    bool?                isLoading,
    String?              errorMessage,
  }) =>
      BranchSummaryState(
        summary:      summary      ?? this.summary,
        branchId:     branchId     ?? this.branchId,
        fromDate:     fromDate     ?? this.fromDate,
        toDate:       toDate       ?? this.toDate,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

// ═══════════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════════

class BranchSummaryNotifier extends StateNotifier<BranchSummaryState> {
  final BranchSummaryDatasource _ds;

  BranchSummaryNotifier(String branchId)
      : _ds = BranchSummaryDatasource(),
        super(BranchSummaryState(branchId: branchId)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final summary = await _ds.getReport(
        branchId: state.branchId,
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
    final d = BranchSummaryState._today();
    state = state.copyWith(fromDate: d, toDate: d);
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ═══════════════════════════════════════════════════════════
//  PROVIDER
// ═══════════════════════════════════════════════════════════

final branchSummaryProvider = StateNotifierProvider.family<
    BranchSummaryNotifier,
    BranchSummaryState,
    String>(
      (ref, branchId) => BranchSummaryNotifier(branchId),
);