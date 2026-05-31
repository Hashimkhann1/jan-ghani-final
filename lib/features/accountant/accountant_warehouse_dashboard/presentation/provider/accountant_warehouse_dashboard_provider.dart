import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/accountant_warehouse_dashboard_remote_datasource.dart';
import '../../data/model/accountant_warehouse_dashboard_model.dart';
import '../../data/repositories/accountant_warehouse_dashboard_repository_impl.dart';
import '../../domain/repositories/accountant_warehouse_dashboard_repository.dart';

// ── Datasource ───────────────────────────────────────────────────────────────
final warehouseDashboardDatasourceProvider =
    Provider<WarehouseDashboardRemoteDatasource>((ref) {
  return WarehouseDashboardRemoteDatasourceImpl(Supabase.instance.client);
});

// ── Repository ───────────────────────────────────────────────────────────────
final warehouseDashboardRepositoryProvider =
    Provider<WarehouseDashboardRepository>((ref) {
  return WarehouseDashboardRepositoryImpl(
    ref.watch(warehouseDashboardDatasourceProvider),
  );
});

// ── Stats (selected warehouse ke hisaab se) ──────────────────────────────────
final warehouseDashboardStatsProvider = FutureProvider.family<
    WarehouseDashboardModel, String>((ref, warehouseId) async {
  return ref.watch(warehouseDashboardRepositoryProvider).getStats(warehouseId);
});
