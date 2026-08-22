import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../model/branch_stock_inventory_logs_model.dart';

class BranchStockInventoryLogsDatasource {
  final SupabaseClient _client;

  BranchStockInventoryLogsDatasource({required SupabaseClient client})
      : _client = client;

  // ── One page of entries (20 rows) ───────────────────────
  Future<PagedBranchStockInventoryLogs> fetchLogsPage({
    required String  branchId,
    required int     page,
    DateTime?        startDate,
    DateTime?        endDate,
  }) async {
    var query = _client
        .from('branch_stock_inventory_logs')
        .select(
      'id, product_id, product_name, change_type, '
          'old_stock, new_stock, '
          'old_sale_price, new_sale_price, '
          'old_purchase_price, new_purchase_price, '
          'old_wholesale_price, new_wholesale_price, '
          'old_shelf_name, new_shelf_name, '
          'old_min_stock, new_min_stock, '
          'old_max_stock, new_max_stock, '
          'user_id, created_at',
    )
        .eq('store_id', branchId)
        .isFilter('deleted_at', null);

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      final end = DateTime(
          endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
      query = query.lte('created_at', end.toIso8601String());
    }

    final (start, end) = BranchReportPagination.range(page);
    final rows = await query
        .order('created_at', ascending: false)
        .range(start, end);

    final entries = (rows as List)
        .map((r) => BranchStockInventoryLogEntry.fromMap(
        r as Map<String, dynamic>))
        .toList();

    return PagedBranchStockInventoryLogs(
      entries:     entries,
      hasNextPage: BranchReportPagination.hasNextPage(rows.length),
    );
  }

  // ── Total count across every matching entry ─────────────
  // Kept separate from the page fetch (and only selects `id`) so the
  // summary card reflects the whole filtered date range, not just the
  // 20 rows on screen, without re-fetching the heavy old/new columns.
  Future<int> fetchTotalCount({
    required String  branchId,
    DateTime?        startDate,
    DateTime?        endDate,
  }) async {
    int totalCount  = 0;
    int rangeStart  = 0;
    const int pageSize = 1000;
    bool hasMore = true;

    while (hasMore) {
      var query = _client
          .from('branch_stock_inventory_logs')
          .select('id')
          .eq('store_id', branchId)
          .isFilter('deleted_at', null);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        final end = DateTime(
            endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
        query = query.lte('created_at', end.toIso8601String());
      }

      final rows = await query.range(rangeStart, rangeStart + pageSize - 1);
      final list = rows as List;
      totalCount += list.length;

      if (list.length < pageSize) {
        hasMore = false;
      } else {
        rangeStart += pageSize;
      }
    }

    return totalCount;
  }
}
