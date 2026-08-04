import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/dashboard_model.dart';

abstract class DashboardRemoteDatasource {
  Future<JanghaniAmountModel?> getJanghaniAmount();
  Future<List<RecentTransactionModel>> getRecentTransactions();
}

class DashboardRemoteDatasourceImpl implements DashboardRemoteDatasource {
  final SupabaseClient _client;
  const DashboardRemoteDatasourceImpl(this._client);

  // Janghani cash in hand
  @override
  Future<JanghaniAmountModel?> getJanghaniAmount() async {
    try {
      final res = await _client
          .from('janghani_net_amount')
          .select('cash_in_hand, cash_reserved')
          .maybeSingle();

      print('✅ Janghani amount: $res');
      if (res == null) return null;
      return JanghaniAmountModel.fromMap(res);
    } catch (e) {
      print('❌ Janghani amount error: $e');
      rethrow;
    }
  }

  // Branch transactions jo janghani ko aye
  @override
  Future<List<RecentTransactionModel>> getRecentTransactions() async {
    try {
      final res = await _client
          .from('branch_transaction_to_janghani')
          .select('id, pay_amount, type, created_at, branch_id, assign_by_name')
          .order('created_at', ascending: false)
          .limit(10);

      print('✅ Transactions: $res');
      return (res as List).map((e) => RecentTransactionModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('❌ Transactions error: $e');
      rethrow;
    }
  }
}