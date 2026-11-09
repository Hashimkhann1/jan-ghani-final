import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../branch/customer_ledger/data/model/customer_ledger_model.dart';
import '../../../common/pagination/branch_report_pagination.dart';

class LedgerReportTotals {
  final int totalCount;
  final double totalPaid;
  const LedgerReportTotals({this.totalCount = 0, this.totalPaid = 0});
}

class CustomerLedgerReportDatasource {
  final SupabaseClient _client;
  CustomerLedgerReportDatasource({required SupabaseClient client})
      : _client = client;

  static const _cols =
      'id, store_id, customer_id, customer_name, counter_id, user_id, '
      'previous_amount, pay_amount, new_amount, notes, '
      'payment_method, created_at, updated_at, deleted_at';

  PostgrestFilterBuilder<dynamic> _filtered(
    PostgrestFilterBuilder<dynamic> q, {
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
    String search = '',
  }) {
    q = q.eq('store_id', branchId).isFilter('deleted_at', null);
    if (startDate != null) {
      q = q.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      final end =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
      q = q.lte('created_at', end.toIso8601String());
    }
    if (search.trim().isNotEmpty) {
      q = q.ilike('customer_name', '%${search.trim()}%');
    }
    return q;
  }

  Future<(List<CustomerLedgerModel>, bool)> fetchPage({
    required String branchId,
    required int page,
    DateTime? startDate,
    DateTime? endDate,
    String search = '',
  }) async {
    final (start, end) = BranchReportPagination.range(page);
    final rows = await _filtered(
      _client.from('customer_ledger').select(_cols),
      branchId: branchId,
      startDate: startDate,
      endDate: endDate,
      search: search,
    ).order('created_at', ascending: false).range(start, end) as List;

    // user_full_name customer_ledger ka column nahi — branch_users se.
    final userIds = {
      for (final r in rows)
        if (r['user_id'] != null) r['user_id'].toString()
    }.toList();
    final names = <String, String>{};
    if (userIds.isNotEmpty) {
      try {
        final users = await _client
            .from('branch_users')
            .select('id, full_name')
            .inFilter('id', userIds) as List;
        for (final u in users) {
          names[u['id'].toString()] = u['full_name']?.toString() ?? '';
        }
      } catch (_) {/* naam optional hai */}
    }
    return (
      rows.map((r) {
        final m = Map<String, dynamic>.from(r as Map);
        m['user_full_name'] = names[m['user_id']?.toString()];
        return CustomerLedgerModel.fromMap(m);
      }).toList(),
      BranchReportPagination.hasNextPage(rows.length),
    );
  }

  Future<LedgerReportTotals> fetchTotals({
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
    String search = '',
  }) async {
    var count = 0;
    var paid = 0.0;
    var from = 0;
    const size = 1000;
    while (true) {
      final rows = await _filtered(
        _client.from('customer_ledger').select('pay_amount'),
        branchId: branchId,
        startDate: startDate,
        endDate: endDate,
        search: search,
      ).range(from, from + size - 1) as List;
      for (final r in rows) {
        count++;
        paid += double.tryParse('${(r as Map)['pay_amount']}') ?? 0;
      }
      if (rows.length < size) break;
      from += size;
    }
    return LedgerReportTotals(totalCount: count, totalPaid: paid);
  }
}
