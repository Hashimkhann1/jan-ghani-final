// data/datasource/inventory_counting_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/inventory_countting_model.dart';

class InventoryCountingRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  static const int _pageSize = 100;
  // counted_date > CURRENT_DATE - _cooldownDays  → aaj + last 6 din exclude,
  // 7ve din product dobara list mein aa jata hai.
  static const int _cooldownDays = 7;

  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 100 products jo last 6 din mein count NAHI huay — server-side RPC
  /// (NOT EXISTS + ORDER BY name + LIMIT). Client-side fetch-all nahi.
  Future<List<InventoryProductModel>> fetchUncountedProducts(
      String storeId) async {
    final response = await _client.rpc(
      'get_uncounted_products',
      params: {
        'p_store_id': storeId,
        'p_days': _cooldownDays,
        'p_limit': _pageSize,
      },
    );

    return (response as List)
        .map((e) => InventoryProductModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Aaj kitne products count huay (counter + serial number ke liye)
  Future<int> fetchCountedTodayCount(String storeId) async {
    final response = await _client
        .from('inventory_counting')
        .select('id')
        .eq('store_id', storeId)
        .eq('counted_date', _todayDate);

    return (response as List).length;
  }

  /// Submit ke waqt product ka CURRENT (fresh) stock — us waqt jo qty ho.
  Future<double> fetchCurrentStock(String storeId, String productId) async {
    final response = await _client
        .from('branch_stock_inventory')
        .select('stock')
        .eq('store_id', storeId)
        .eq('product_id', productId)
        .maybeSingle();

    if (response == null) return 0.0;
    return double.tryParse(response['stock'].toString()) ?? 0.0;
  }

  Future<void> saveInventoryCounting(InventoryCountingModel model) async {
    await _client.from('inventory_counting').insert(model.toMap());
  }
}
