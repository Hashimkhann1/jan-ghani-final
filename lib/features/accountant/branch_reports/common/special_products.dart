import 'package:supabase_flutter/supabase_flutter.dart';

/// Sale report ki 3 qismein: normal (physical), digital services, Pull PMG.
enum SaleKind {
  physical('Physical Sale Report'),
  digital('Digital Sale Report'),
  pmg('PMG Sale Report');

  final String title;
  const SaleKind(this.title);
}

/// Branch ke Digital (product_type != physical) aur Pull PMG (category naam
/// mein "PMG") product ids. Digital ko priority milti hai.
Future<({Set<String> digital, Set<String> pmg})> loadSpecialProductIds(
    SupabaseClient client, String branchId) async {
  final cats =
      await client.from('warehouse_categories').select('id, name') as List;
  final pmgCats = {
    for (final c in cats)
      if ((c['name'] ?? '')
          .toString()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '')
          .contains('pmg'))
        c['id'].toString()
  };

  final digital = <String>{};
  final pmg = <String>{};
  const chunk = 1000;
  var start = 0;
  while (true) {
    final rows = await client
        .from('branch_stock_inventory')
        .select('product_id, product_type, category_id')
        .eq('store_id', branchId)
        .order('product_id')
        .range(start, start + chunk - 1) as List;
    for (final r in rows) {
      final id = r['product_id'].toString();
      if ((r['product_type'] ?? 'physical') != 'physical') {
        digital.add(id);
      } else if (pmgCats.contains(r['category_id']?.toString())) {
        pmg.add(id);
      }
    }
    if (rows.length < chunk) break;
    start += chunk;
  }
  return (digital: digital, pmg: pmg);
}
