import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/inventory_counting_report_model.dart';

class InventoryCountingReportRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<InventoryCountingRecord>> fetchAllRecords({
    required String storeId,
  }) async {
    final countingResponse = await _client
        .from('inventory_counting')
        .select('id, product_id, product_stock, counting_stock, updated_at, created_at, counted_date')
        .order('created_at', ascending: true);

    final countingList = countingResponse as List;
    if (countingList.isEmpty) return [];

    final productIds = countingList
        .map((e) => e['product_id'] as String)
        .toSet()
        .toList();

    // Pehle isi store mein dhoondo
    final inventoryResponse = await _client
        .from('branch_stock_inventory')
        .select('product_id, product_name, purchase_price, sale_price, store_id')
        .eq('store_id', storeId)
        .inFilter('product_id', productIds);

    final inventoryMap = <String, Map<String, dynamic>>{};
    for (final item in inventoryResponse as List) {
      inventoryMap[item['product_id'] as String] = item as Map<String, dynamic>;
    }

    // Jo product_ids is store mein nahi milay, unko without store_id filter dhoondo
    final missingIds = productIds.where((id) => !inventoryMap.containsKey(id)).toList();
    if (missingIds.isNotEmpty) {
      final fallbackResponse = await _client
          .from('branch_stock_inventory')
          .select('product_id, product_name, purchase_price, sale_price, store_id')
          .inFilter('product_id', missingIds);

      for (final item in fallbackResponse as List) {
        final map = item as Map<String, dynamic>;
        inventoryMap.putIfAbsent(map['product_id'] as String, () => map);
      }
    }

    return countingList.map((e) {
      final map = e as Map<String, dynamic>;
      final productId = map['product_id'] as String;
      final inv = inventoryMap[productId] ?? {};
      return InventoryCountingRecord.fromMerged(counting: map, inventory: inv);
    }).toList();
  }
}