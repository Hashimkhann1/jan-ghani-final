import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/top_product_model.dart';

/// Top products — sab hisab database RPC (get_branch_top_products) mein hota hai
/// (indexes use karta hai), app ko sirf chand rows milti hain.
/// 2026_11_10_branch_top_products.sql run karna zaroori hai.
class TopProductsDatasource {
  final _client = Supabase.instance.client;
  final String branchId;
  TopProductsDatasource({required this.branchId});

  Future<TopProductsResult> load(DateTime from, DateTime to,
      {int limit = 8}) async {
    final res = await _client.rpc('get_branch_top_products', params: {
      'p_store_id': branchId,
      'p_from': from.toUtc().toIso8601String(),
      'p_to': to.toUtc().toIso8601String(),
      'p_limit': limit,
    }) as List;

    final selling = <TopProductStat>[], profit = <TopProductStat>[], low = <TopProductStat>[];
    for (final r in res) {
      final s = TopProductStat(
        productId: r['product_id'].toString(),
        name: (r['name'] ?? '').toString(),
        qtySold: _d(r['qty_sold']),
        revenue: _d(r['revenue']),
        profit: _d(r['profit']),
        stock: _d(r['stock']),
      );
      switch (r['kind']) {
        case 'selling':
          selling.add(s);
        case 'profit':
          profit.add(s);
        default:
          low.add(s);
      }
    }
    return TopProductsResult(selling, profit, low);
  }

  static double _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
}
