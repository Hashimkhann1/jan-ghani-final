import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../accountant_customer/data/model/accountant_customer_model.dart';
import '../model/accountant_customer_ledger_model.dart';

class AccountantCustomerLedgerDatasource {
  final SupabaseClient _client;
  final String         branchId;

  AccountantCustomerLedgerDatasource({
    required SupabaseClient client,
    required this.branchId,
  }) : _client = client;

  /// Dropdown ke liye customers
  Future<List<AccountantCustomerReportModel>> fetchCustomers() async {
    final rows = await _client
        .from('customer')
        .select()
        .eq('store_id', branchId)
        .isFilter('deleted_at', null)
        .order('name', ascending: true);

    return (rows as List)
        .map((r) => AccountantCustomerReportModel
        .fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Ledger fetch — sab filters optional
  Future<List<CustomerLedgerModel>> fetchLedger({
    String?   customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('customer_ledger')
        .select()
        .eq('store_id', branchId)
        .isFilter('deleted_at', null);

    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }
    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query.lte('created_at', end.toIso8601String());
    }

    final rows = await query.order('created_at', ascending: false);

    final customers   = await fetchCustomers();
    final customerMap = { for (var c in customers) c.id: c.name };

    return (rows as List).map((r) {
      final map = Map<String, dynamic>.from(r as Map<String, dynamic>);
      map['customer_name'] = customerMap[map['customer_id']] ?? map['customer_name'] ?? '';
      return CustomerLedgerModel.fromMap(map);
    }).toList();
  }
}