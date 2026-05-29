import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/specific_customer_ledger_model.dart';

class SpecificCustomerLedgerDatasource {
  final _client = Supabase.instance.client;

  Future<List<SpecificCustomerLedgerModel>> getByCustomer({
    required String customerId,
  }) async {
    final result = await _client
        .from('customer_ledger')
        .select()
        .eq('customer_id', customerId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return (result as List)
        .map((r) => SpecificCustomerLedgerModel.fromMap(r))
        .toList();
  }
}