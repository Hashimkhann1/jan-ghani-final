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

  AccountantBranchDashboardState({
    this.data,
    required this.branchId,
    DateTime? fromDate,
    DateTime? toDate,
    this.isLoading    = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _today(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  AccountantBranchDashboardState copyWith({
    AccountantBranchDashboardModel? data,
    String?                         branchId,
    DateTime?                       fromDate,
    DateTime?                       toDate,
    bool?                           isLoading,
    String?                         errorMessage,
  }) =>
      AccountantBranchDashboardState(
        data:         data         ?? this.data,
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

class AccountantBranchDashboardNotifier
    extends StateNotifier<AccountantBranchDashboardState> {
  final AccountantBranchDashboardDatasource _ds;

  AccountantBranchDashboardNotifier(String branchId)
      : _ds = AccountantBranchDashboardDatasource(branchId: branchId),
        super(AccountantBranchDashboardState(branchId: branchId)) {
    // Auto-load today on init — single call
    load();
  }

  Future<void> load() async {
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

  void setToday() {
    final d = AccountantBranchDashboardState._today();
    state = state.copyWith(fromDate: d, toDate: d);
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