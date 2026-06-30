import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/inventory_countting_model.dart';

class InventoryCountingRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  static const int _pageSize = 50;

  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Aaj ke counted product_ids fetch karo (date filter ke saath)
  Future<List<String>> fetchCountedProductIds() async {
    final response = await _client
        .from('inventory_counting')
        .select('product_id')
        .eq('counted_date', _todayDate);

    return (response as List)
        .map((e) => e['product_id'] as String)
        .toList();
  }

  /// Aaj kitne products count ho chuke — DB se actual count
  Future<int> fetchTodayCountedCount() async {
    final response = await _client
        .from('inventory_counting')
        .select('product_id')
        .eq('counted_date', _todayDate);

    return (response as List).length;
  }

  /// 50 products fetch karo — already counted ko exclude karo
  Future<List<InventoryProductModel>> fetchProducts({
    required String storeId,
    required List<String> excludeProductIds,
  }) async {
    var query = _client
        .from('branch_stock_inventory')
        .select('id, product_id, product_name, stock, updated_at')
        .eq('store_id', storeId);

    if (excludeProductIds.isNotEmpty) {
      query = query.not(
        'product_id',
        'in',
        '(${excludeProductIds.join(',')})',
      );
    }

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