import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_branch_stock_damage_model.dart';

class AccountantBranchStockDamageDatasource {
  final _client = Supabase.instance.client;
  final String branchId;

  AccountantBranchStockDamageDatasource({required this.branchId});

  Future<List<AccountantBranchStockDamageModel>> fetchDamage() async {
    List<AccountantBranchStockDamageModel> allItems = [];
    int rangeStart = 0;
    const int pageSize = 1000;
    bool hasMore = true;

    while (hasMore) {
      final result = await _client
          .from('branch_stock_damage')
          .select('''
            id, store_id, product_id, product_name,
            sale_price, purchase_price, stock_damage, created_at
          ''')
          .eq('store_id', branchId)
          .order('created_at', ascending: false)
          .range(rangeStart, rangeStart + pageSize - 1);

      final rows = result as List;

      if (rows.isEmpty) {
        hasMore = false;
        break;
      }

      final page = rows
          .map((r) => AccountantBranchStockDamageModel.fromMap(
          r as Map<String, dynamic>))
          .toList();

      allItems.addAll(page);
      print('🔴 Range: $rangeStart-${rangeStart + pageSize - 1} → Got ${rows.length} rows');
      rangeStart += rows.length;
    }

    return allItems;
  }
}
