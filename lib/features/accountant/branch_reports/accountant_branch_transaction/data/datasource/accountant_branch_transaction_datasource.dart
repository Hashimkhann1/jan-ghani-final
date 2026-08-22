// lib/features/accountant/branch_reports/accountant_branch_transaction/data/datasource/accountant_branch_transaction_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../model/accountant_branch_transaction_model.dart';

class BranchTransactionDatasource {
  final SupabaseClient _client;

  BranchTransactionDatasource({required SupabaseClient client})
      : _client = client;

  /// Branch ID se sirf naam fetch karo
  Future<String> fetchBranchName(String branchId) async {
    final row = await _client
        .from('branch')
        .select('name')
        .eq('id', branchId)
        .single();
    return (row['name'] as String?) ?? '';
  }

  // ── One page of transactions (20 rows) ──────────────────
  Future<PagedBranchTransactions> fetchTransactionsPage({
    required String  branchId,
    required int     page,
    DateTime?        startDate,
    DateTime?        endDate,
  }) async {
    var query = _client
        .from('branch_transaction_to_janghani')
        .select(
      'id, branch_id, assign_by_id, assign_by_name, assign_to_id, '
          'type, before_amount, pay_amount, after_amount, '
          'is_synced, created_at, updated_at',
    )
        .eq('branch_id', branchId);

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

    final transactions = (rows as List)
        .map((r) => BranchTransactionModel.fromMap(
        r as Map<String, dynamic>))
        .toList();

    return PagedBranchTransactions(
      transactions: transactions,
      hasNextPage:  BranchReportPagination.hasNextPage(rows.length),
    );
  }

  // ── Totals across every matching transaction ────────────
  // Kept separate from the page fetch so the summary cards still reflect
  // the whole filtered date range, not just the 20 rows on screen.
  Future<BranchTransactionTotals> fetchTransactionTotals({
    required String  branchId,
    DateTime?        startDate,
    DateTime?        endDate,
  }) async {
    int    totalCount = 0;
    double totalCashOut = 0;
    int    rangeStart = 0;
    const  int pageSize = 1000;
    bool   hasMore = true;

    while (hasMore) {
      var query = _client
          .from('branch_transaction_to_janghani')
          .select('type, pay_amount')
          .eq('branch_id', branchId);

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
        if (r['type'] == 'cash_out') {
          totalCashOut +=
              double.tryParse(r['pay_amount']?.toString() ?? '0') ?? 0;
        }
      }

      if (list.length < pageSize) {
        hasMore = false;
      } else {
        rangeStart += pageSize;
      }
    }

    return BranchTransactionTotals(
        totalCount: totalCount, totalCashOut: totalCashOut);
  }
}