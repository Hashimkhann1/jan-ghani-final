import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/accountant_profit_loss_datasource.dart';
import '../../data/model/accountant_profit_loss_model.dart';

// ═══════════════════════════════════════════════════════════
//  STATE
// ═══════════════════════════════════════════════════════════

class PnlReportState {
  final PnlSummary? summary;
  final DateTime    fromDate;
  final DateTime    toDate;
  final bool        isLoading;
  final String?     errorMessage;

  PnlReportState({
    this.summary,
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

  PnlReportState copyWith({
    PnlSummary? summary,
    DateTime?   fromDate,
    DateTime?   toDate,
    bool?       isLoading,
    String?     errorMessage,
  }) =>
      PnlReportState(
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

class PnlReportNotifier extends StateNotifier<PnlReportState> {
  final PnlReportDatasource _ds;

  PnlReportNotifier()
      : _ds = PnlReportDatasource(),
        super(PnlReportState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final summary = await _ds.getReport(
        fromDate: state.fromDate,
        toDate:   state.toDate,
      );
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (e) {
      print('❌ P&L error: $e');
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
    final d = PnlReportState._today();
    state = state.copyWith(fromDate: d, toDate: d);
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ═══════════════════════════════════════════════════════════
//  PROVIDER
// ═══════════════════════════════════════════════════════════

final pnlReportProvider =
StateNotifierProvider<PnlReportNotifier, PnlReportState>(
      (ref) => PnlReportNotifier(),
);