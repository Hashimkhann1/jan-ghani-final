import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/inventory_counting_report_model.dart';

/// Server-side paginated report — `get_inventory_counting_report` RPC
/// (supabase/migrations/2026_10_18_inventory_counting_report.sql).
class InventoryCountingReportRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  static const int pageSize = 50;

  Future<List<Map<String, dynamic>>> _rpc({
    required String    storeId,
    DateTime?          from,
    DateTime?          to,
    String?            search,
    required int       limit,
    required int       offset,
  }) async {
    final res = await _client.rpc('get_inventory_counting_report', params: {
      'p_store_id': storeId,
      'p_from':     from == null ? null : _date(from),
      'p_to':       to   == null ? null : _date(to),
      'p_search':   (search == null || search.isEmpty) ? null : search,
      'p_limit':    limit,
      'p_offset':   offset,
    });
    return (res as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  /// Ek page (0-indexed) + poore filter ke totals.
  Future<InventoryCountingPage> fetchPage({
    required String storeId,
    required int    page,
    DateTime?       from,
    DateTime?       to,
    String?         search,
  }) async {
    final rows = await _rpc(
      storeId: storeId, from: from, to: to, search: search,
      limit: pageSize, offset: page * pageSize,
    );
    if (rows.isEmpty) return const InventoryCountingPage();
    final first = rows.first;
    return InventoryCountingPage(
      records:       rows.map(InventoryCountingRecord.fromRpc).toList(),
      totalCount:    _int(first['total_count']),
      surplusCount:  _int(first['surplus_count']),
      shortageCount: _int(first['shortage_count']),
      matchedCount:  _int(first['matched_count']),
    );
  }

  /// Export ke liye poora filtered data — 1000 ke chunks mein.
  Future<List<InventoryCountingRecord>> fetchAll({
    required String storeId,
    DateTime?       from,
    DateTime?       to,
    String?         search,
  }) async {
    const chunk = 1000;
    final all = <InventoryCountingRecord>[];
    var offset = 0;
    while (true) {
      final rows = await _rpc(
        storeId: storeId, from: from, to: to, search: search,
        limit: chunk, offset: offset,
      );
      all.addAll(rows.map(InventoryCountingRecord.fromRpc));
      if (rows.length < chunk) break;
      offset += chunk;
    }
    return all;
  }
}
