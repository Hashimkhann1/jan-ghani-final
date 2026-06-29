import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/inventory_countting_model.dart';

class InventoryCountingRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  static const int _pageSize = 50;

  /// Already counted product_ids fetch karo
  Future<List<String>> fetchCountedProductIds() async {
    final response = await _client
        .from('inventory_counting')
        .select('product_id');

    return (response as List)
        .map((e) => e['product_id'] as String)
        .toList();
  }

  /// 50 products fetch karo — already counted ko exclude karo
  Future<List<InventoryProductModel>> fetchProducts({
    required String storeId,
    required List<String> excludeProductIds,
  }) async {
    // ─── Pehle filter build karo (PostgrestFilterBuilder pe) ─────────────────
    var query = _client
        .from('branch_stock_inventory')
        .select('id, product_id, product_name, stock, updated_at')
        .eq('store_id', storeId);

    // .not() filter pehle lagao — transform se pehle
    if (excludeProductIds.isNotEmpty) {
      query = query.not(
        'product_id',
        'in',
        '(${excludeProductIds.join(',')})',
      );
    }

    // ─── Ab order + limit lagao ───────────────────────────────────────────────
    final response = await query
        .order('product_name', ascending: true)
        .limit(_pageSize);

    return (response as List)
        .map((e) => InventoryProductModel.fromMap(e))
        .toList();
  }

  /// Ek product ka counting save karo
  Future<void> saveInventoryCounting(InventoryCountingModel model) async {
    await _client.from('inventory_counting').insert(model.toMap());
  }
}