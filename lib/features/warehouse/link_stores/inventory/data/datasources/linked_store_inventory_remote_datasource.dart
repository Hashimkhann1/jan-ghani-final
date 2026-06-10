// =============================================================
// linked_store_inventory_remote_datasource.dart
// SIRF READ-ONLY — view `linked_store_inventory_v` se fetch.
// Koi insert/update/delete nahi. Server-side filter + pagination.
// =============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/inventory/data/models/linked_store_product_model.dart';

class LinkedStoreInventoryRemoteDatasource {
  final SupabaseClient supabase;
  LinkedStoreInventoryRemoteDatasource({required this.supabase});

  static const String _view = 'linked_store_inventory_v';

  // PostgREST or() comma/parentheses se break ho sakta hai — sanitize
  static String _sanitize(String s) =>
      s.trim().replaceAll(RegExp(r'[,()]'), ' ').trim();

  // ── Ek page fetch — status filter + search + pagination ──
  Future<List<LinkedStoreProduct>> fetchPage({
    required String storeId,
    String status = 'all',        // all | ok | low | out
    String search = '',
    required int offset,
    required int limit,
  }) async {
    var q = supabase.from(_view).select().eq('store_id', storeId);

    if (status != 'all') {
      q = q.eq('stock_status', status);
    }

    final s = _sanitize(search);
    if (s.isNotEmpty) {
      q = q.or('product_name.ilike.%$s%,sku.ilike.%$s%,barcode.ilike.%$s%');
    }

    final rows = await q
        .order('product_name', ascending: true)
        .range(offset, offset + limit - 1);

    return (rows as List)
        .map((m) => LinkedStoreProduct.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  // ── Chip counts — head-only (rows fetch nahi hote) ───────
  Future<({int all, int low, int out})> counts({
    required String storeId,
    String search = '',
  }) async {
    final s = _sanitize(search);

    Future<int> c(String? status) async {
      var q = supabase.from(_view).count(CountOption.exact).eq('store_id', storeId);
      if (status != null) q = q.eq('stock_status', status);
      if (s.isNotEmpty) {
        q = q.or('product_name.ilike.%$s%,sku.ilike.%$s%,barcode.ilike.%$s%');
      }
      return await q;
    }

    final res = await Future.wait([c(null), c('low'), c('out')]);
    return (all: res[0], low: res[1], out: res[2]);
  }
}
