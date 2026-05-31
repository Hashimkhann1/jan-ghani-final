import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_inventory_model.dart';

abstract class AccountantInventoryRemoteDatasource {
  Future<List<AccountantInventoryModel>> getInventory(String warehouseId);
}

class AccountantInventoryRemoteDatasourceImpl
    implements AccountantInventoryRemoteDatasource {
  final SupabaseClient _client;
  const AccountantInventoryRemoteDatasourceImpl(this._client);

  @override
  Future<List<AccountantInventoryModel>> getInventory(
      String warehouseId) async {
    try {
      // warehouse_products + embedded warehouse_inventory (FK relation)
      final res = await _client
          .from('warehouse_products')
          .select(
            'id, name, sku, unit_of_measure, purchase_price, selling_price, '
            'min_stock_level, max_stock_level, warehouse_inventory(quantity)',
          )
          .eq('warehouse_id', warehouseId)
          .eq('is_active', true)
          .filter('deleted_at', 'is', null)
          .order('name', ascending: true);

      return (res as List)
          .map((e) =>
              AccountantInventoryModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getInventory error: $e');
      rethrow;
    }
  }
}
