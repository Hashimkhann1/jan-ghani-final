import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/dashboard_model.dart';

abstract class DashboardRemoteDatasource {
  Future<AccountantCounterModel?> getCounter({required String accountantId});
  Future<List<RecentTransactionModel>> getRecentTransactions({required String accountantId});
}

class DashboardRemoteDatasourceImpl implements DashboardRemoteDatasource {
  final SupabaseClient _client;
  const DashboardRemoteDatasourceImpl(this._client);

  @override
  Future<AccountantCounterModel?> getCounter({required String accountantId}) async {
    try {
      final res = await _client
          .from('accountant_counter')
          .select('total_amount, total_investment')
          .eq('accountant_id', accountantId)
          .maybeSingle();

      print('✅ Counter: $res');
      if (res == null) return null;
      return AccountantCounterModel.fromMap(res);
    } catch (e) {
      print('❌ Counter error: $e');
      rethrow;
    }
  }

  @override
  Future<List<RecentTransactionModel>> getRecentTransactions({required String accountantId}) async {
    try {
      final res = await _client
          .from('accountant_transactions')
          .select('id, branch_name, transaction_type, amount, created_at')
          .eq('accountant_id', accountantId)
          .order('created_at', ascending: false)
          .limit(10);

      print('✅ Recent: $res');
      return (res as List)
          .map((e) => RecentTransactionModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Recent error: $e');
      rethrow;
    }
  }
}