import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/inventory_counting_report_model.dart';

class InventoryCountingReportRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<InventoryCountingRecord>> fetchAllRecords({
    required String storeId,
  }) async {
    // Step 1: inventory_counting se saray records lo (no date filter)
    final countingResponse = await _client
        .from('inventory_counting')
        .select('id, product_id, product_stock, counting_stock, updated_at, created_at, counted_date')
        .order('created_at', ascending: true);

    final countingList = countingResponse as List;
    if (countingList.isEmpty) return [];

    // Step 2: unique product_ids nikaalo
    final productIds = countingList
        .map((e) => e['product_id'] as String)
        .toSet()
        .toList();

    // Step 3: branch_stock_inventory se product details lo
    final inventoryResponse = await _client
        .from('branch_stock_inventory')
        .select('product_id, product_name, purchase_price, sale_price')
        .eq('store_id', storeId)
        .inFilter('product_id', productIds);

    // Step 4: product_id → inventory map banao
    final inventoryMap = <String, Map<String, dynamic>>{};
    for (final item in inventoryResponse as List) {
      inventoryMap[item['product_id'] as String] = item as Map<String, dynamic>;
    }

    // Step 5: merge karke model banao
    return countingList.map((e) {
      final map = e as Map<String, dynamic>;
      final productId = map['product_id'] as String;
      final inv = inventoryMap[productId] ?? {};
      return InventoryCountingRecord.fromMerged(counting: map, inventory: inv);
    }).toList();
  }
}