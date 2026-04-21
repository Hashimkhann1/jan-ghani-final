import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/investment_model.dart';

abstract class InvestmentRemoteDatasource {
  Future<List<InvestmentModel>> getInvestments({required String accountantId});
  Future<void> addInvestment({
    required String accountantId,
    required String name,
    required double amount,
    String? note,
  });
}

class InvestmentRemoteDatasourceImpl implements InvestmentRemoteDatasource {
  final SupabaseClient _client;
  const InvestmentRemoteDatasourceImpl(this._client);

  @override
  Future<List<InvestmentModel>> getInvestments({
    required String accountantId,
  }) async {
    try {
      final res = await _client
          .from('accountant_investments')
          .select()
          .eq('accountant_id', accountantId)
          .order('created_at', ascending: false);

      print('✅ Investments: $res');
      return (res as List)
          .map((e) => InvestmentModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getInvestments error: $e');
      rethrow;
    }
  }

  @override
  Future<void> addInvestment({
    required String accountantId,
    required String name,
    required double amount,
    String? note,
  }) async {
    try {
      // Sirf insert — trigger khud counter update karega
      await _client.from('accountant_investments').insert({
        'accountant_id': accountantId,
        'name':          name,
        'amount':        amount,
        'note':          note,
      });

      print('✅ Investment inserted');
    } catch (e) {
      print('❌ addInvestment error: $e');
      rethrow;
    }
  }
}