import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/service/session/accountant_session.dart';
import '../../data/datasource/dashboard_remote_datasource.dart';
import '../../data/model/dashboard_model.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/dashboard_repository.dart';

// ── Session ──────────────────────────────────────────────────────────────────
final accountantSessionDataProvider =
FutureProvider<Map<String, dynamic>?>((ref) {
  return AccountantSession.getAll();
});

// ── Datasource ───────────────────────────────────────────────────────────────
final dashboardDatasourceProvider =
Provider<DashboardRemoteDatasource>((ref) {
  return DashboardRemoteDatasourceImpl(Supabase.instance.client);
});

// ── Repository ───────────────────────────────────────────────────────────────
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardDatasourceProvider));
});

// ── Janghani Amount ───────────────────────────────────────────────────────────
final janghaniAmountProvider =
FutureProvider<JanghaniAmountModel?>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getJanghaniAmount();
});

// ── Recent Transactions ───────────────────────────────────────────────────────
final recentTransactionsProvider =
FutureProvider<List<RecentTransactionModel>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getRecentTransactions();
});