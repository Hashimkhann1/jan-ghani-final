import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/pareto_report_datasource.dart';
import '../../data/model/pareto_report_model.dart';

// ── State ─────────────────────────────────────────────────
class ParetoReportState {
  final ParetoReportData data;
  final DateTime         startDate;
  final DateTime         endDate;
  final bool             isLoading;
  final String?          errorMessage;

  ParetoReportState({
    ParetoReportData? data,
    DateTime?         startDate,
    DateTime?         endDate,
    this.isLoading    = false,
    this.errorMessage,
  })  : data      = data ?? ParetoReportData.empty(),
        startDate = startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
        endDate   = endDate   ?? DateTime.now();

  ParetoReportState copyWith({
    ParetoReportData? data,
    DateTime?         startDate,
    DateTime?         endDate,
    bool?             isLoading,
    Object?           errorMessage = _sentinel,
  }) =>
      ParetoReportState(
        data:         data         ?? this.data,
        startDate:    startDate    ?? this.startDate,
        endDate:      endDate      ?? this.endDate,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
      );
}

const _sentinel = Object();

// ── Notifier ──────────────────────────────────────────────
class ParetoReportNotifier extends StateNotifier<ParetoReportState> {
  final ParetoReportDatasource _datasource;

  ParetoReportNotifier(this._datasource) : super(ParetoReportState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _datasource.fetchParetoData(
        startDate: state.startDate,
        endDate:   state.endDate,
      );
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ── Provider ──────────────────────────────────────────────
final paretoReportProvider = StateNotifierProvider.autoDispose
    .family<ParetoReportNotifier, ParetoReportState, String>(
      (ref, branchId) {
    final datasource = ParetoReportDatasource(
      client:   Supabase.instance.client,
      branchId: branchId,
    );
    return ParetoReportNotifier(datasource);
  },
);