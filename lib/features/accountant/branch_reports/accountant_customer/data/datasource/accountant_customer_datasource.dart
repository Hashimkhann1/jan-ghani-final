import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_customer_model.dart';

class AccountantCustomerReportDatasource {
  final SupabaseClient _client;
  final String         branchId; // store_id ke barabar

  AccountantCustomerReportDatasource({
    required SupabaseClient client,
    required this.branchId,
  }) : _client = client;

  /// Supabase se saare active customers fetch karo jinka store_id = branchId
  ///
  /// Fetches every column `AccountantCustomerReportModel.fromMap` reads, no
  /// more — the full list (not a single page) is needed here because the
  /// screen does instant client-side search/filter and sums outstanding
  /// balances across the whole filtered set, both of which require every
  /// customer to already be in memory.
  Future<List<AccountantCustomerReportModel>> fetchCustomers() async {
    final rows = await _client
        .from('customer')
        .select(
          'id, code, name, phone, address, customer_type, '
          'credit_limit, balance, is_active, created_at',
        )
        .eq('store_id', branchId)          // ← branchId filter
        .isFilter('deleted_at', null)
        .order('balance', ascending: false);

    return (rows as List)
        .map((r) => AccountantCustomerReportModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}