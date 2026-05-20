import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_sale_report_model.dart';

class AccountantSaleReportDatasource {
  final _client = Supabase.instance.client;

  // ── Get Customers for dropdown ────────────────────────────
  Future<List<CustomerOption>> getCustomers() async {
    final result = await _client
        .from('customer')        // ← 'customers' → 'customer'
        .select('id, name, code')
        .eq('is_active', true)
        .order('name');

    return (result as List)
        .map((r) => CustomerOption(
      id:   r['id'].toString(),
      name: r['name']?.toString() ?? '',
      code: r['code']?.toString(),
    ))
        .toList();
  }
  // ── Get Report ────────────────────────────────────────────
  Future<List<SaleReportInvoice>> getReport({
    required DateTime fromDate,
    required DateTime toDate,
    String?           customerId,
    String?           paymentType,
  }) async {

    var baseQuery = _client
        .from('sale_invoices')
        .select('''
        id, invoice_no, invoice_date,
        total_amount, total_discount, grand_total,
        status, customer_id, deleted_at,
        customer (name),
        sale_invoice_payments (payment_method, amount),
        sale_invoice_items (
          product_name, sku, price,
          quantity, discount, total_amount
        )
      ''')
        .eq('status', 'completed')       // ← store_id filter hata diya
        .gte('invoice_date', fromDate.toIso8601String())
        .lte('invoice_date',
        DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59)
            .toIso8601String());

    if (customerId != null && customerId.isNotEmpty) {
      baseQuery = baseQuery.eq('customer_id', customerId);
    }

    final result = await baseQuery
        .order('invoice_date', ascending: false);

    // Client side — deleted_at null check
    List<SaleReportInvoice> invoices = (result as List)
        .where((r) => r['deleted_at'] == null) // ← client side filter
        .map((r) {
      final payments = (r['sale_invoice_payments'] as List? ?? []);
      final methods  = payments
          .map((p) => p['payment_method']?.toString() ?? '')
          .toSet()
          .toList();

      final items = (r['sale_invoice_items'] as List? ?? [])
          .map((i) => SaleReportItem(
        productName: i['product_name']?.toString() ?? '',
        sku:         i['sku']?.toString(),
        price:       _dbl(i['price'])       ?? 0,
        quantity:    _dbl(i['quantity'])     ?? 0,
        discount:    _dbl(i['discount'])     ?? 0,
        totalAmount: _dbl(i['total_amount']) ?? 0,
      ))
          .toList();

      final customerName = r['customer'] != null
          ? r['customer']['name']?.toString()
          : null;

      return SaleReportInvoice(
        id:             r['id'].toString(),
        invoiceNo:      r['invoice_no']?.toString()   ?? '',
        invoiceDate:    DateTime.parse(
            r['invoice_date'].toString())
            .toLocal(),
        customerName:   customerName,
        customerId:     r['customer_id']?.toString(),
        totalAmount:    _dbl(r['total_amount'])        ?? 0,
        totalDiscount:  _dbl(r['total_discount'])      ?? 0,
        grandTotal:     _dbl(r['grand_total'])         ?? 0,
        status:         r['status']?.toString()        ?? '',
        paymentMethods: methods,
        items:          items,
      );
    }).toList();

    if (paymentType != null) {
      invoices = invoices
          .where((inv) => inv.paymentMethods.contains(paymentType))
          .toList();
    }

    return invoices;
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}