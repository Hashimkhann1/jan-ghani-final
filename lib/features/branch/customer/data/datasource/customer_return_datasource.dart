import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/customer_return_model.dart';

class CustomerReturnDatasource {
  final _client = Supabase.instance.client;

  Future<List<CustomerReturnInvoice>> getByCustomer({
    required String   customerId,
    required DateTime fromDate,
    required DateTime toDate,
    String?           refundType,
  }) async {
    var query = _client
        .from('sale_returns')
        .select('''
          id, return_no, return_date,
          customer_id, invoice_id,
          total_amount, total_discount, grand_total,
          status, return_reason, refund_type,
          deleted_at,
          customer (name),
          sale_return_payments (payment_method, amount),
          sale_return_items (
            product_name, sku, price,
            quantity, discount, total_amount
          )
        ''')
        .eq('customer_id', customerId)
        .eq('status', 'completed')
        .gte('return_date', fromDate.toIso8601String())
        .lte(
      'return_date',
      DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59)
          .toIso8601String(),
    );

    final result = await query.order('return_date', ascending: false);

    List<CustomerReturnInvoice> returns = (result as List)
        .where((r) => r['deleted_at'] == null)
        .map((r) {
      final payments = (r['sale_return_payments'] as List? ?? []);
      final methods  = payments
          .map((p) => p['payment_method']?.toString() ?? '')
          .toSet()
          .toList();

      final items = (r['sale_return_items'] as List? ?? [])
          .map((i) => CustomerReturnItem(
        productName: i['product_name']?.toString() ?? '',
        sku:         i['sku']?.toString(),
        price:       _dbl(i['price'])        ?? 0,
        quantity:    _dbl(i['quantity'])      ?? 0,
        discount:    _dbl(i['discount'])      ?? 0,
        totalAmount: _dbl(i['total_amount'])  ?? 0,
      ))
          .toList();

      final customerName = r['customer'] != null
          ? r['customer']['name']?.toString()
          : null;

      return CustomerReturnInvoice(
        id:             r['id'].toString(),
        returnNo:       r['return_no']?.toString()    ?? '',
        returnDate:     DateTime.parse(r['return_date'].toString()).toLocal(),
        customerName:   customerName,
        customerId:     r['customer_id']?.toString(),
        invoiceId:      r['invoice_id']?.toString(),
        totalAmount:    _dbl(r['total_amount'])        ?? 0,
        totalDiscount:  _dbl(r['total_discount'])      ?? 0,
        grandTotal:     _dbl(r['grand_total'])         ?? 0,
        status:         r['status']?.toString()        ?? '',
        returnReason:   r['return_reason']?.toString(),
        refundType:     r['refund_type']?.toString(),
        paymentMethods: methods,
        items:          items,
      );
    }).toList();

    if (refundType != null) {
      returns = returns.where((r) => r.refundType == refundType).toList();
    }

    return returns;
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}