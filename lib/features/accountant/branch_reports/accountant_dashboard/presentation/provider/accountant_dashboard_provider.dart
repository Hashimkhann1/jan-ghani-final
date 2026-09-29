// lib/features/accountant/branch_reports/accountant_branch_dashboard/presentation/provider/accountant_branch_dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/accountant_dashboard_datasource.dart';
import '../../data/model/accountant_dashboard_model.dart';

// ═══════════════════════════════════════════════════════════
//  STATE
// ═══════════════════════════════════════════════════════════

class AccountantBranchDashboardState {
  final AccountantBranchDashboardModel? data;
  final String                          branchId;
  final DateTime                        fromDate;
  final DateTime                        toDate;
  final bool                            isLoading;
  final String?                         errorMessage;
  // Period → points (cache; date badalne par clear hota hai)
  final Map<DashboardTrendPeriod, List<DashboardTrendPoint>> trends;
  final Set<DashboardTrendPeriod>                            trendLoading;
  // Har graph ka apna selected period
  final Map<DashboardChart, DashboardTrendPeriod>            chartPeriods;

  AccountantBranchDashboardState({
    this.data,
    required this.branchId,
    DateTime? fromDate,
    DateTime? toDate,
    this.isLoading    = false,
    this.errorMessage,
    this.trends       = const {},
    this.trendLoading = const {},
    this.chartPeriods = const {},
  })  : fromDate = fromDate ?? _startOfToday(),
        toDate   = toDate   ?? _endOfToday();

  static DateTime _startOfToday() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _endOfToday() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, 23, 59, 59);
  }

  AccountantBranchDashboardState copyWith({
    AccountantBranchDashboardModel? data,
    String?                         branchId,
    DateTime?                       fromDate,
    DateTime?                       toDate,
    bool?                           isLoading,
    String?                         errorMessage,
    Map<DashboardTrendPeriod, List<DashboardTrendPoint>>? trends,
    Set<DashboardTrendPeriod>?                            trendLoading,
    Map<DashboardChart, DashboardTrendPeriod>?            chartPeriods,
  }) =>
      AccountantBranchDashboardState(
        data:         data         ?? this.data,
        branchId:     branchId     ?? this.branchId,
        fromDate:     fromDate     ?? this.fromDate,
        toDate:       toDate       ?? this.toDate,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage,
        trends:       trends       ?? this.trends,
        trendLoading: trendLoading ?? this.trendLoading,
        chartPeriods: chartPeriods ?? this.chartPeriods,
      );

  DashboardTrendPeriod periodOf(DashboardChart c) =>
      chartPeriods[c] ?? DashboardTrendPeriod.weekly;

  List<DashboardTrendPoint> trendOf(DashboardChart c) =>
      trends[periodOf(c)] ?? const [];

  bool isTrendLoading(DashboardChart c) =>
      trendLoading.contains(periodOf(c));
}

// ═══════════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════════

class AccountantBranchDashboardNotifier
    extends StateNotifier<AccountantBranchDashboardState> {
  final AccountantBranchDashboardDatasource _ds;

  AccountantBranchDashboardNotifier(String branchId)
      : _ds = AccountantBranchDashboardDatasource(branchId: branchId),
        super(AccountantBranchDashboardState(branchId: branchId)) {
    // Auto-load today on init — single call
    load();
  }

  // Date badalne par purane trend results discard karne ke liye.
  int _trendGen = 0;

  Future<void> load() async {
    // Cards aur charts saath load hote hain; charts apna alag loader dikhate hain.
    // Date range badli ho sakti hai → trend cache clear, sirf in-use periods load.
    _trendGen++;
    state = state.copyWith(trends: const {}, trendLoading: const {});
    for (final p in DashboardChart.values.map(state.periodOf).toSet()) {
      _loadTrend(p);
    }
    state = state.copyWith(isLoading: true);
    try {
      final data = await _ds.getDashboard(
        fromDate: state.fromDate,
        toDate:   state.toDate,
      );
      state = state.copyWith(data: data, isLoading: false);
    } catch (err) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Load error: $err',
      );
    }
  }

  Future<void> _loadTrend(DashboardTrendPeriod p) async {
    final gen = _trendGen;
    state = state.copyWith(trendLoading: {...state.trendLoading, p});
    try {
      final points = await _ds.getTrend(endDate: state.toDate, period: p);
      if (gen != _trendGen || !mounted) return;
      state = state.copyWith(
        trends:       {...state.trends, p: points},
        trendLoading: {...state.trendLoading}..remove(p),
      );
    } catch (err) {
      if (gen != _trendGen || !mounted) return;
      state = state.copyWith(
        trendLoading: {...state.trendLoading}..remove(p),
        errorMessage: 'Chart load error: $err',
      );
    }
  }

  /// Sirf [chart] ka period badalta hai; data cache mein na ho to load.
  void setChartPeriod(DashboardChart chart, DashboardTrendPeriod p) {
    if (state.periodOf(chart) == p) return;
    state = state.copyWith(chartPeriods: {...state.chartPeriods, chart: p});
    if (!state.trends.containsKey(p) && !state.trendLoading.contains(p)) {
      _loadTrend(p);
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

  void setToday() {
    state = state.copyWith(
      fromDate: AccountantBranchDashboardState._startOfToday(),
      toDate:   AccountantBranchDashboardState._endOfToday(),
    );
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ═══════════════════════════════════════════════════════════
//  PROVIDER
// ═══════════════════════════════════════════════════════════

final accountantBranchDashboardProvider = StateNotifierProvider.autoDispose
    .family<AccountantBranchDashboardNotifier,
    AccountantBranchDashboardState,
    String>(
      (ref, branchId) => AccountantBranchDashboardNotifier(branchId),
);