import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_warehouse_dashboard_model.dart';

abstract class WarehouseDashboardRemoteDatasource {
  Future<WarehouseDashboardModel> getStats(String warehouseId);
}

class WarehouseDashboardRemoteDatasourceImpl
    implements WarehouseDashboardRemoteDatasource {
  final SupabaseClient _client;
  const WarehouseDashboardRemoteDatasourceImpl(this._client);

  @override
  Future<WarehouseDashboardModel> getStats(String warehouseId) async {
    try {
      // Read-only Supabase RPC — selected warehouse ke aggregated stats
      final res = await _client.rpc(
        'accountant_warehouse_dashboard_stats',
        params: {'p_warehouse_id': warehouseId},
      );

      print('✅ Warehouse stats: $res');

      final map = res is Map
          ? Map<String, dynamic>.from(res)
          : <String, dynamic>{};
      return WarehouseDashboardModel.fromMap(map);
    } catch (e) {
      print('❌ Warehouse stats error: $e');
      rethrow;
    }
  }
}
