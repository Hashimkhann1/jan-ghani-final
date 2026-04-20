import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/branch_transaction_model.dart';

class BranchTransactionDataSource {
  final SupabaseClient _supabase;
  BranchTransactionDataSource(this._supabase);

  Future<List<BranchTransactionModel>> getTransactions({
    required String accountantId,
    DateTime?       startDate,
    DateTime?       endDate,
  }) async {
    try {
      var query = _supabase
          .from('accountant_transactions')
          .select()
          .eq('accountant_id',    accountantId)
          .eq('transaction_type', 'cash_in');

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        final endOfDay = DateTime(
            endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.lte('created_at', endOfDay.toIso8601String());
      }

      final res = await query.order('created_at', ascending: false);

      return (res as List)
          .map((e) => BranchTransactionModel.fromJson(
          e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getTransactions error: $e');
      rethrow;
    }
  }
}