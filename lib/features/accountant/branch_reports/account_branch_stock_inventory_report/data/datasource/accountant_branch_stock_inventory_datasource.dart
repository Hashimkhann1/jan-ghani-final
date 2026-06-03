import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_branch_stock_inventory_model.dart';

class AccountantBranchInventoryDatasource {
  final _client = Supabase.instance.client;
  final String  branchId;

  AccountantBranchInventoryDatasource({required this.branchId});

  Future<List<AccountantBranchInventoryModel>> fetchInventory() async {
    List<AccountantBranchInventoryModel> allItems = [];
    int       rangeStart = 0;
    const int pageSize   = 1000;
    bool      hasMore    = true;

    while (hasMore) {
      final result = await _client
          .from('branch_stock_inventory')
          .select('''
            id, store_id, product_id,
            barcode, sku, product_name,
            purchase_price, sale_price, wholesale_price,
            stock, min_stock, max_stock,
            unit, created_at, updated_at
          ''')
          .eq('store_id', branchId)
          .order('product_name', ascending: true)
          .range(rangeStart, rangeStart + pageSize - 1);

      final page = (result as List)
          .map((r) => AccountantBranchInventoryModel.fromMap(
          r as Map<String, dynamic>))
          .toList();

      allItems.addAll(page);

      if (page.length < pageSize) {
        hasMore = false;
      } else {
        rangeStart += pageSize;
      }
    }

    return allItems;
  }
}