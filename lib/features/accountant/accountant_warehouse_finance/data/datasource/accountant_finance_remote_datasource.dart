import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_finance_model.dart';

abstract class AccountantFinanceRemoteDatasource {
  Future<AccFinanceSummary> getSummary(String warehouseId);
  Future<List<AccCashTransactionModel>> getTransactions(String warehouseId);
}

class AccountantFinanceRemoteDatasourceImpl
    implements AccountantFinanceRemoteDatasource {
  final SupabaseClient _client;
  const AccountantFinanceRemoteDatasourceImpl(this._client);

  // ── Summary (cash in hand, expense, etc.) ───────────────────
  @override
  Future<AccFinanceSummary> getSummary(String warehouseId) async {
    try {
      final res = await _client.rpc(
        'accountant_warehouse_finance_summary',
        params: {'p_warehouse_id': warehouseId},
      );
      final map = res is Map
          ? Map<String, dynamic>.from(res)
          : <String, dynamic>{};
      return AccFinanceSummary.fromMap(map);
    } catch (e) {
      print('❌ getSummary error: $e');
      rethrow;
    }
  }

  // ── Selected warehouse ki saari cash transactions ───────────
  // RPC use karte hain taake supplier_payment ke liye supplier ka naam bhi mile
  @override
  Future<List<AccCashTransactionModel>> getTransactions(
      String warehouseId) async {
    try {
      final res = await _client.rpc(
        'accountant_warehouse_cash_transactions',
        params: {'p_warehouse_id': warehouseId},
      );

      return (res as List)
          .map((e) =>
              AccCashTransactionModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getTransactions error: $e');
      rethrow;
    }
  }
}
