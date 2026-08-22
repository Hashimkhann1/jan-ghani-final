import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../model/branch_cash_difference_model.dart';

class BranchCashDifferenceDatasource {
  final SupabaseClient _client;

  BranchCashDifferenceDatasource({required SupabaseClient client})
      : _client = client;

  // ── One page of entries (20 rows) ───────────────────────
  Future<PagedBranchCashDifference> fetchEntriesPage({
    required String  branchId,
    required int     page,
    DateTime?        startDate,
    DateTime?        endDate,
  }) async {
    var query = _client
        .from('branch_cash_transaction')
        .select(
      'id, counter_id, previous_amount, cash_out_amount, '
          'remaining_amount, transaction_type, description, '
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
        .map((r) => BranchCashDifferenceEntry.fromMap(
        r as Map<String, dynamic>))
        .toList();

    return PagedBranchCashDifference(
      entries:     entries,
      hasNextPage: BranchReportPagination.hasNextPage(rows.length),
    );
  }

  // ── Totals across every matching entry ──────────────────
  // Kept separate from the page fetch so the summary cards still reflect
  // the whole filtered date range, not just the 20 rows on screen.
  Future<BranchCashDifferenceTotals> fetchTotals({
    required String  branchId,
    DateTime?        startDate,
    DateTime?        endDate,
  }) async {
    int    totalCount   = 0;
    double totalCashIn  = 0;
    double totalCashOut = 0;
    int    rangeStart   = 0;
    const  int pageSize = 1000;
    bool   hasMore = true;

    while (hasMore) {
      var query = _client
          .from('branch_cash_transaction')
          .select('transaction_type, cash_out_amount')
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

      for (final r in list) {
        totalCount++;
        final amount =
            double.tryParse(r['cash_out_amount']?.toString() ?? '0') ?? 0;
        if (r['transaction_type'] == 'cash_in') {
          totalCashIn += amount;
        } else {
          totalCashOut += amount;
        }
      }

      if (list.length < pageSize) {
        hasMore = false;
      } else {
        rangeStart += pageSize;
      }
    }

    return BranchCashDifferenceTotals(
      totalCount:   totalCount,
      totalCashIn:  totalCashIn,
      totalCashOut: totalCashOut,
    );
  }
}
