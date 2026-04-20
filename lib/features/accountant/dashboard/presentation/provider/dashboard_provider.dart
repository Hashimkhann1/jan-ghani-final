import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/service/session/accountant_session.dart';
import '../../data/datasource/dashboard_remote_datasource.dart';
import '../../data/model/dashboard_model.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/dashboard_repository.dart';

// ── Session ──────────────────────────────────────────────────────────────────
final accountantSessionDataProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  return AccountantSession.getAll();
});

// ── Datasource ───────────────────────────────────────────────────────────────
final dashboardDatasourceProvider = Provider<DashboardRemoteDatasource>((ref) {
  return DashboardRemoteDatasourceImpl(Supabase.instance.client);
});

// ── Repository ───────────────────────────────────────────────────────────────
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardDatasourceProvider));
});

// ── Counter ──────────────────────────────────────────────────────────────────
final accountantCounterProvider = FutureProvider<AccountantCounterModel?>((ref) async {
  final session = await ref.watch(accountantSessionDataProvider.future);
  final accountantId = session?['id'] as String? ?? '';
  if (accountantId.isEmpty) return null;

  return ref.watch(dashboardRepositoryProvider).getCounter(
    accountantId: accountantId,
  );
});

// ── Recent Transactions ───────────────────────────────────────────────────────
final recentTransactionsProvider = FutureProvider<List<RecentTransactionModel>>((ref) async {
  final session = await ref.watch(accountantSessionDataProvider.future);
  final accountantId = session?['id'] as String? ?? '';
  if (accountantId.isEmpty) return [];

  return ref.watch(dashboardRepositoryProvider).getRecentTransactions(
    accountantId: accountantId,
  );
});