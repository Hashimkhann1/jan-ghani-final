// data/datasource/inventory_counting_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/inventory_countting_model.dart';

class InventoryCountingRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  static const int _pageSize = 100;

  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Store ke sab ever-counted product_ids (kisi bhi date ke) — permanent exclude list
  Future<List<String>> fetchCountedProductIds(String storeId) async {
    final response = await _client
        .from('inventory_counting')
        .select('product_id')
        .eq('store_id', storeId);

    return (response as List)
        .map((e) => e['product_id'] as String)
        .toList();
  }

  /// Store ke ab tak total counted products (kisi bhi date) — serial number ke liye
  Future<int> fetchTotalCountedCount(String storeId) async {
    final response = await _client
        .from('inventory_counting')
        .select('product_id')
        .eq('store_id', storeId);

    return (response as List).length;
  }

  /// 100 products fetch karo — jo inventory_counting mein kabhi bhi count nahi huay
  Future<List<InventoryProductModel>> fetchProducts({
    required String storeId,
    required List<String> excludeProductIds,
  }) async {
    final response = await _client
        .from('branch_stock_inventory')
        .select('id, product_id, product_name, stock, updated_at')
        .eq('store_id', storeId)
        .order('product_name', ascending: true);

    final excludeSet = excludeProductIds.toSet();

    final allProducts = (response as List)
        .map((e) => InventoryProductModel.fromMap(e))
        .where((p) => !excludeSet.contains(p.productId))
        .toList();

    return allProducts.take(_pageSize).toList();
  }

  Future<void> saveInventoryCounting(InventoryCountingModel model) async {
    await _client.from('inventory_counting').insert(model.toMap());
  }
}