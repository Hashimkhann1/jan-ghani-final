import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_inventory_model.dart';

abstract class AccountantInventoryRemoteDatasource {
  Future<List<AccountantInventoryModel>> getInventory(String warehouseId);
}

class AccountantInventoryRemoteDatasourceImpl
    implements AccountantInventoryRemoteDatasource {
  final SupabaseClient _client;
  const AccountantInventoryRemoteDatasourceImpl(this._client);

  // PostgREST ek request mein max ~1000 rows deta hai. Isliye saara data
  // .range() se PAGES mein laate hain — warna 1000 ke baad wale products
  // (e.g. "PMG") fetch hi nahi hote aur search mein nahi milte.
  static const int _pageSize = 1000;

  @override
  Future<List<AccountantInventoryModel>> getInventory(
      String warehouseId) async {
    try {
      final all = <AccountantInventoryModel>[];
      var from = 0;

      while (true) {
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
            .order('name', ascending: true)
            .range(from, from + _pageSize - 1);

        final rows = res as List;
        all.addAll(rows.map(
            (e) => AccountantInventoryModel.fromMap(e as Map<String, dynamic>)));

        if (rows.length < _pageSize) break; // aakhri page mil gaya
        from += _pageSize;
      }

      return all;
    } catch (e) {
      print('❌ getInventory error: $e');
      rethrow;
    }
  }
}
