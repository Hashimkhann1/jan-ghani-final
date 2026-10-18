import 'package:jan_ghani_final/features/installment/domain/installment_calculator.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';
import 'package:jan_ghani_final/features/installment/register_installment_customer/domain/new_installment_customer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'installment_mapper.dart';

/// Installment ka Supabase datasource (tables + RPCs:
/// supabase/migrations/2026_10_18_installment_system.sql).
class InstallmentRemoteDatasource {
  final SupabaseClient _client;
  const InstallmentRemoteDatasource(this._client);

  static const _select =
      '*, installment_plan(*, installment_schedule(*), installment_payment(*))';

  String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Never _fail(PostgrestException e) => throw Exception(e.message);

  Future<List<InstallmentCustomer>> fetchCustomers() async {
    try {
      final rows = await _client
          .from('installment_customer')
          .select(_select)
          .order('created_at', ascending: false);
      return [
        for (final r in rows as List)
          installmentCustomerFromRow(Map<String, dynamic>.from(r as Map)),
      ];
    } on PostgrestException catch (e) {
      _fail(e);
    }
  }

  Future<InstallmentCustomer?> fetchCustomer(String id) async {
    try {
      final row = await _client
          .from('installment_customer')
          .select(_select)
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : installmentCustomerFromRow(row);
    } on PostgrestException catch (e) {
      _fail(e);
    }
  }

  /// Naya customer — amount default 0. Naye customer ki id wapas.
  Future<String> registerCustomer(NewInstallmentCustomer c) async {
    try {
      final row = await _client
          .from('installment_customer')
          .insert({
            'name': c.name,
            'phone': c.phone,
            'cnic': c.cnic,
            'address': c.address,
          })
          .select('id')
          .single();
      return row['id'] as String;
    } on PostgrestException catch (e) {
      _fail(e);
    }
  }

  /// Calculator ke baad plan + schedule + advance payment (ek transaction).
  Future<String> createPlan({
    required String customerId,
    required String product,
    required InstallmentQuote quote,
    required DateTime startDate,
  }) async {
    try {
      final id = await _client.rpc('create_installment_plan', params: {
        'p_customer_id': customerId,
        'p_product': product,
        'p_price': quote.price,
        'p_advance': quote.advance,
        'p_months': quote.months,
        'p_start_date': _day(startDate),
        'p_schedule': [
          for (final d in quote.schedule(startDate))
            {
              'number': d.number,
              'due_date': _day(d.dueDate),
              'amount': d.amount,
            },
        ],
      });
      return id as String;
    } on PostgrestException catch (e) {
      _fail(e);
    }
  }

  Future<void> recordPayment({
    required String scheduleId,
    required double amount,
    String? note,
  }) async {
    try {
      await _client.rpc('record_installment_payment', params: {
        'p_schedule_id': scheduleId,
        'p_amount': amount,
        'p_note': note,
      });
    } on PostgrestException catch (e) {
      _fail(e);
    }
  }
}
