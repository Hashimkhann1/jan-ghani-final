import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_customer_model.dart';

class AccountantCustomerReportDatasource {
  final SupabaseClient _client;

  AccountantCustomerReportDatasource({
    required SupabaseClient client,
  }) : _client = client;

  /// Supabase se saare active customers fetch karo
  Future<List<AccountantCustomerReportModel>> fetchCustomers() async {
    final rows = await _client
        .from('customer')
        .select()
        .isFilter('deleted_at', null)
        .order('balance', ascending: false);

    return (rows as List)
        .map((r) => AccountantCustomerReportModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}