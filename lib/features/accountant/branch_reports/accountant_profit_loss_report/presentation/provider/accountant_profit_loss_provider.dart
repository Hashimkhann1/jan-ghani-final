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
  final String storeId;

  PnlReportState({
    this.summary,
    required this.storeId,
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
    String? storeId,
  }) =>
      PnlReportState(
        summary:      summary      ?? this.summary,
        fromDate:     fromDate     ?? this.fromDate,
        toDate:       toDate       ?? this.toDate,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage,
        storeId: storeId ?? this.storeId,
      );
}

// ═══════════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════════

class PnlReportNotifier extends StateNotifier<PnlReportState> {
  final PnlReportDatasource _ds;

  PnlReportNotifier(String storeId)
      : _ds = PnlReportDatasource(),
        super(PnlReportState(storeId: storeId)) {
    print('🚀 PnlReportNotifier created with storeId: $storeId');
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      print('📦 Loading for storeId: ${state.storeId}, from: ${state.fromDate}, to: ${state.toDate}');
      final summary = await _ds.getReport(
        fromDate: state.fromDate,
        toDate:   state.toDate,
        storeId:  state.storeId,
      );
      print('📊 Done: invoices=${summary.totalInvoices}, returns=${summary.totalReturns}');
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (e, stack) {
      print('❌ Error: $e');
      print('❌ Stack: $stack');
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
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
StateNotifierProvider.family<PnlReportNotifier, PnlReportState, String>(
      (ref, branchId) => PnlReportNotifier(branchId),
);