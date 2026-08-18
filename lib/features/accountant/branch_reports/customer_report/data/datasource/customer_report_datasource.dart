import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/customer_invoice_model.dart';
import '../model/customer_return_model.dart';
import '../model/specific_customer_ledger_model.dart';

// ─────────────────────────────────────────────────────────────
// Combined Report Model
// ─────────────────────────────────────────────────────────────
class CustomerFullReport {
  final String                            customerId;
  final String                            customerName;
  final String?                           customerPhone;
  final double                            balance;
  final List<CustomerInvoiceModel>        invoices;
  final List<CustomerReturnInvoice>       returns;
  final List<SpecificCustomerLedgerModel> ledger;

  const CustomerFullReport({
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.balance,
    required this.invoices,
    required this.returns,
    required this.ledger,
  });
}

// ─────────────────────────────────────────────────────────────
// Datasource
// ─────────────────────────────────────────────────────────────
class CustomerReportDatasource {
  final _client = Supabase.instance.client;

  // ── Customer Info (no verification needed) ──────────────────
  Future<Map<String, dynamic>?> getCustomerInfo(String customerId) async {
    try {
      final row = await _client
          .from('customer')
          .select('name, phone, balance')
          .eq('id', customerId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (row == null) return null;

      return {
        'name':    row['name']?.toString()    ?? '',
        'phone':   row['phone']?.toString()   ?? '',
        'balance': double.tryParse(row['balance']?.toString() ?? '0') ?? 0.0,
      };
    } catch (e) {
      print('❌ getCustomerInfo error: $e');
      return null;
    }
  }

  // ── Full report ──────────────────────────────────────────────
  Future<CustomerFullReport?> getFullReport({
    required String   customerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final customerRow = await _client
          .from('customer')
          .select('name, phone, balance')
          .eq('id', customerId)
          .maybeSingle();

      if (customerRow == null) return null;

      final results = await Future.wait([
        fetchInvoices(customerId: customerId, fromDate: fromDate, toDate: toDate),
        fetchReturns(customerId: customerId, fromDate: fromDate, toDate: toDate),
        fetchLedger(customerId: customerId, fromDate: fromDate, toDate: toDate),
      ]);

      return CustomerFullReport(
        customerId:    customerId,
        customerName:  customerRow['name']?.toString()  ?? '',
        customerPhone: customerRow['phone']?.toString(),
        balance:       _dbl(customerRow['balance'])     ?? 0,
        invoices:      results[0] as List<CustomerInvoiceModel>,
        returns:       results[1] as List<CustomerReturnInvoice>,
        ledger:        results[2] as List<SpecificCustomerLedgerModel>,
      );
    } catch (e) {
      print('❌ getFullReport error: $e');
      return null;
    }
  }

  // ── Invoices ─────────────────────────────────────────────────
  Future<List<CustomerInvoiceModel>> fetchInvoices({
    required String   customerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final fromStart = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final toEnd = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);

    print('🔍 fetchInvoices: customerId=$customerId from=$fromStart to=$toEnd');

    final invoiceResult = await _client
        .from('sale_invoices')
        .select('''
          id, invoice_no, invoice_date, status,
          total_amount, total_discount, grand_total, customer_id,
          previous_amount, new_amount, pay_amount,
          customer:customer_id ( name ),
          counter:counter_id   ( counter_name ),
          cashier:user_id      ( full_name ),
          sale_invoice_payments ( payment_method )
        ''')
        .eq('customer_id', customerId)
        .isFilter('deleted_at', null)
        .gte('invoice_date', fromStart.toIso8601String())
        .lte('invoice_date', toEnd.toIso8601String())
        .order('invoice_date', ascending: false);

    print('📦 fetchInvoices result count: ${invoiceResult.length}');
    if (invoiceResult.isNotEmpty) {
      print('📄 first invoice: ${invoiceResult.first}');
    }

    if (invoiceResult.isEmpty) return [];

    final invoiceIds = invoiceResult
        .map((r) => r['id'].toString())
        .toList();

    final itemsResult = await _client
        .from('sale_invoice_items')
        .select(
      'invoice_id, product_name, sku, sale_price, purchase_price, '
          'subtotal, quantity, discount, total_amount',
    )
        .inFilter('invoice_id', invoiceIds)
        .order('created_at', ascending: true);

    final Map<String, List<CustomerInvoiceItemDetail>> itemsMap = {};
    for (final row in itemsResult) {
      final invoiceId = row['invoice_id'].toString();
      itemsMap.putIfAbsent(invoiceId, () => []);
      itemsMap[invoiceId]!.add(CustomerInvoiceItemDetail.fromMap(row));
    }

    return invoiceResult.map((m) {
      final id = m['id'].toString();
      final payments = (m['sale_invoice_payments'] as List?)
          ?.map((p) => p['payment_method']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .join(',') ?? 'cash';

      return CustomerInvoiceModel(
        id:             id,
        invoiceNo:      m['invoice_no']?.toString()   ?? '',
        invoiceDate:    DateTime.tryParse(m['invoice_date']?.toString() ?? '')
            ?? DateTime.now(),
        paymentType:    payments,
        status:         m['status']?.toString()        ?? 'completed',
        totalAmount:    _dbl(m['total_amount'])        ?? 0,
        totalDiscount:  _dbl(m['total_discount'])      ?? 0,
        grandTotal:     _dbl(m['grand_total'])          ?? 0,
        previousAmount: _dbl(m['previous_amount'])      ?? 0,
        newAmount:      _dbl(m['new_amount'])           ?? 0,
        payAmount:      _dbl(m['pay_amount'])           ?? 0,
        customerId:     m['customer_id']?.toString(),
        customerName:   (m['customer'] as Map?)?['name']?.toString(),
        counterName:    (m['counter']  as Map?)?['counter_name']?.toString(),
        cashierName:    (m['cashier']  as Map?)?['full_name']?.toString(),
        items:          itemsMap[id] ?? [],
      );
    }).toList();
  }

  // ── Returns ──────────────────────────────────────────────────
  Future<List<CustomerReturnInvoice>> fetchReturns({
    required String   customerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final result = await _client
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
            product_name, sku, sale_price, purchase_price,
            subtotal, quantity, discount, total_amount
          )
        ''')
        .eq('customer_id', customerId)
        .eq('status', 'completed')
        .gte('return_date', fromDate.toIso8601String())
        .lte(
      'return_date',
      DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59)
          .toIso8601String(),
    )
        .order('return_date', ascending: false);

    return (result as List)
        .where((r) => r['deleted_at'] == null)
        .map((r) {
      final payments = (r['sale_return_payments'] as List? ?? []);
      final methods  = payments
          .map((p) => p['payment_method']?.toString() ?? '')
          .toSet()
          .toList();

      final items = (r['sale_return_items'] as List? ?? [])
          .map((i) => CustomerReturnItem(
        productName:   i['product_name']?.toString()  ?? '',
        sku:           i['sku']?.toString(),
        salePrice:     _dbl(i['sale_price'])     ?? 0,
        purchasePrice: _dbl(i['purchase_price']) ?? 0,
        price:         _dbl(i['subtotal'])       ?? 0,
        quantity:      _dbl(i['quantity'])       ?? 0,
        discount:      _dbl(i['discount'])       ?? 0,
        totalAmount:   _dbl(i['total_amount'])   ?? 0,
      ))
          .toList();

      return CustomerReturnInvoice(
        id:             r['id'].toString(),
        returnNo:       r['return_no']?.toString()    ?? '',
        returnDate:     DateTime.parse(r['return_date'].toString()).toLocal(),
        customerName:   r['customer']?['name']?.toString(),
        customerId:     r['customer_id']?.toString(),
        invoiceId:      r['invoice_id']?.toString(),
        totalAmount:    _dbl(r['total_amount'])        ?? 0,
        totalDiscount:  _dbl(r['total_discount'])      ?? 0,
        grandTotal:     _dbl(r['grand_total'])          ?? 0,
        status:         r['status']?.toString()         ?? '',
        returnReason:   r['return_reason']?.toString(),
        refundType:     r['refund_type']?.toString(),
        paymentMethods: methods,
        items:          items,
      );
    }).toList();
  }

  // ── Ledger ───────────────────────────────────────────────────
  Future<List<SpecificCustomerLedgerModel>> fetchLedger({
    required String   customerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final fromStart = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final toEnd = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);

    final result = await _client
        .from('customer_ledger')
        .select()
        .eq('customer_id', customerId)
        .isFilter('deleted_at', null)
        .gte('created_at', fromStart.toIso8601String())
        .lte('created_at', toEnd.toIso8601String())
        .order('created_at', ascending: false);

    return (result as List)
        .map((r) => SpecificCustomerLedgerModel.fromMap(r))
        .toList();
  }

  // ── Public wrappers ──────────────────────────────────────────
  Future<List<CustomerInvoiceModel>> fetchInvoicesPublic({
    required String   customerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) => fetchInvoices(
    customerId: customerId,
    fromDate:   fromDate,
    toDate:     toDate,
  );

  Future<List<CustomerReturnInvoice>> fetchReturnsPublic({
    required String   customerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) => fetchReturns(
    customerId: customerId,
    fromDate:   fromDate,
    toDate:     toDate,
  );

  Future<List<SpecificCustomerLedgerModel>> fetchLedgerPublic({
    required String   customerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) => fetchLedger(customerId: customerId, fromDate: fromDate, toDate: toDate);

  // ── Utility ──────────────────────────────────────────────────
  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}