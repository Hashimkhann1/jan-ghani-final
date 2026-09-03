import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_branch_stock_inventory_model.dart';

class AccountantBranchInventoryDatasource {
  final _client = Supabase.instance.client;
  final String branchId;

  AccountantBranchInventoryDatasource({required this.branchId});

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final result = await _client
          .from('warehouse_categories')
          .select('id, warehouse_id, name, color_code, is_active')
          .eq('is_active', true)
          .order('name', ascending: true);

      final rows = result as List;
      print('🟣 warehouse_categories fetched: ${rows.length} rows');
      if (rows.isEmpty) {
        print('🟣 ⚠️ No categories returned — check RLS policy or is_active column type on warehouse_categories');
      }

      return rows
          .map((r) => CategoryModel.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('🔴 fetchCategories error: $e');
      rethrow;
    }
  }

  Future<List<AccountantBranchInventoryModel>> fetchInventory(
      Map<String, String> categoryNameById,
      ) async {
    List<AccountantBranchInventoryModel> allItems = [];
    int rangeStart = 0;
    const int pageSize = 1000;
    bool hasMore = true;

    while (hasMore) {
      final result = await _client
          .from('branch_stock_inventory')
          .select('''
            id, store_id, product_id,
            barcode, sku, product_name,
            purchase_price, sale_price, wholesale_price,
            stock, min_stock, max_stock,
            unit, created_at, updated_at, category_id
          ''')
          .eq('store_id', branchId)
          .isFilter('deleted_at', null)
          .order('product_name', ascending: true)
          .range(rangeStart, rangeStart + pageSize - 1);

      final rows = result as List;

      if (rows.isEmpty) {
        hasMore = false;
        break;
      }

      final page = rows.map((r) {
        final map = r as Map<String, dynamic>;
        final catId = map['category_id']?.toString();
        final catName = categoryNameById[catId] ?? 'Uncategorized';
        return AccountantBranchInventoryModel.fromMap(map, categoryName: catName);
      }).toList();

      allItems.addAll(page);
      print('🔵 Range: $rangeStart-${rangeStart + pageSize - 1} → Got ${rows.length} rows');
      rangeStart += rows.length;
    }

    return allItems;
  }
}