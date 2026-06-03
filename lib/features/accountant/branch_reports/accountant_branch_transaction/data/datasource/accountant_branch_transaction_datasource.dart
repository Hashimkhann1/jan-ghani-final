// lib/features/accountant/branch_reports/accountant_branch_transaction/data/datasource/accountant_branch_transaction_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<List<BranchTransactionModel>> fetchTransactions({
    required String  branchId,
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

    final rows = await query.order('created_at', ascending: false);

    return (rows as List)
        .map((r) => BranchTransactionModel.fromMap(
        r as Map<String, dynamic>))
        .toList();
  }
}