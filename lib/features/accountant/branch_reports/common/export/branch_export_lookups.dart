import 'package:supabase_flutter/supabase_flutter.dart';

/// Id → name lookups the fact-table Excel exports need, shared by the sale
/// and sale-return reports. Only fetched on export, never on screen load.
class BranchExportLookups {
  final SupabaseClient _client;
  final String         branchId;

  BranchExportLookups({required this.branchId, SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<String> branchName() async {
    final row = await _client
        .from('branch')
        .select('name')
        .eq('id', branchId)
        .maybeSingle();
    return row?['name']?.toString() ?? '';
  }

  /// product_id → category name, via the branch's stock inventory rows.
  /// Products with no category (or no longer in inventory) are simply absent
  /// from the map; the export labels those "Uncategorized".
  Future<Map<String, String>> categoryNameByProductId() async =>
      (await inventorySnapshot()).categoryNames;

  /// One pass over the branch's live inventory: category name and current
  /// stock per product. Products no longer in inventory are absent from both
  /// maps.
  Future<({Map<String, String> categoryNames, Map<String, double> stock})>
      inventorySnapshot() async {
    final categories = await _client
        .from('warehouse_categories')
        .select('id, name');
    final nameById = {
      for (final c in categories as List)
        c['id'].toString(): c['name']?.toString() ?? '',
    };

    final categoryNames = <String, String>{};
    final stock         = <String, double>{};
    var from = 0;
    const page = 1000;
    while (true) {
      final rows = await _client
          .from('branch_stock_inventory')
          .select('product_id, category_id, stock')
          .eq('store_id', branchId)
          .isFilter('deleted_at', null)
          .order('id', ascending: true)
          .range(from, from + page - 1) as List;
      for (final r in rows) {
        final pid = r['product_id']?.toString();
        if (pid == null) continue;
        final name = nameById[r['category_id']?.toString()];
        if (name != null && name.isNotEmpty) categoryNames[pid] = name;
        final qty = r['stock'];
        if (qty is num) stock[pid] = qty.toDouble();
      }
      if (rows.length < page) break;
      from += page;
    }
    return (categoryNames: categoryNames, stock: stock);
  }
}
