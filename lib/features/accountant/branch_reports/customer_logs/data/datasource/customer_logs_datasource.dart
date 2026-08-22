import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../model/customer_logs_model.dart';

class CustomerLogsDatasource {
  final SupabaseClient _client;

  CustomerLogsDatasource({required SupabaseClient client})
      : _client = client;

  // ── One page of entries (20 rows) ───────────────────────
  Future<PagedCustomerLogs> fetchLogsPage({
    required String  branchId,
    required int     page,
    DateTime?        startDate,
    DateTime?        endDate,
  }) async {
    var query = _client
        .from('customer_logs')
        .select(
      'id, customer_id, customer_name, old_balance, new_balance, '
          'change_amount, created_by, created_at',
    )
        .eq('store_id', branchId);

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
        .map((r) => CustomerLogEntry.fromMap(r as Map<String, dynamic>))
        .toList();

    return PagedCustomerLogs(
      entries:     entries,
      hasNextPage: BranchReportPagination.hasNextPage(rows.length),
    );
  }

  // ── Totals across every matching entry ──────────────────
  // Kept separate from the page fetch so the summary cards still reflect
  // the whole filtered date range, not just the 20 rows on screen.
  Future<CustomerLogsTotals> fetchTotals({
    required String  branchId,
    DateTime?        startDate,
    DateTime?        endDate,
  }) async {
    int    totalCount    = 0;
    double totalIncrease = 0;
    double totalDecrease = 0;
    int    rangeStart    = 0;
    const  int pageSize  = 1000;
    bool   hasMore = true;

    while (hasMore) {
      var query = _client
          .from('customer_logs')
          .select('change_amount')
          .eq('store_id', branchId);

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

      for (final r in list) {
        totalCount++;
        final change =
            double.tryParse(r['change_amount']?.toString() ?? '0') ?? 0;
        if (change >= 0) {
          totalIncrease += change;
        } else {
          totalDecrease += -change;
        }
      }

      if (list.length < pageSize) {
        hasMore = false;
      } else {
        rangeStart += pageSize;
      }
    }

    return CustomerLogsTotals(
      totalCount:    totalCount,
      totalIncrease: totalIncrease,
      totalDecrease: totalDecrease,
    );
  }
}
