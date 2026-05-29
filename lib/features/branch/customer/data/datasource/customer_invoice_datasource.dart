// customer_invoice_datasource.dart

import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/customer_invoice_model.dart';

class CustomerInvoiceDatasource {

  Future<List<CustomerInvoiceModel>> getByCustomer({
    required String   storeId,
    required String   customerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final conn = await DataBaseService.getConnection();

    final invoiceResult = await conn.execute(
      Sql.named('''
        SELECT
          si.id,
          si.invoice_no,
          si.invoice_date,
          si.status,
          si.total_amount,
          si.total_discount,
          si.grand_total,
          si.customer_id,
          c.name          AS customer_name,
          co.counter_name AS counter_name,
          u.full_name     AS cashier_name,
          STRING_AGG(sip.payment_method, ',') AS payment_type
        FROM public.sale_invoices si
        LEFT JOIN public.customer             c   ON c.id  = si.customer_id
        LEFT JOIN public.branch_counter       co  ON co.id = si.counter_id
        LEFT JOIN public.branch_users         u   ON u.id  = si.user_id
        LEFT JOIN public.sale_invoice_payments sip ON sip.invoice_id = si.id
        WHERE si.store_id            = @storeId::uuid
          AND si.customer_id         = @customerId::uuid
          AND si.deleted_at          IS NULL
          AND si.invoice_date::date >= @fromDate
          AND si.invoice_date::date <= @toDate
        GROUP BY
          si.id, si.invoice_no, si.invoice_date,
          si.status, si.total_amount, si.total_discount,
          si.grand_total, si.customer_id,
          c.name, co.counter_name, u.full_name
        ORDER BY si.invoice_date DESC
      '''),
      parameters: {
        'storeId':    storeId,
        'customerId': customerId,
        'fromDate':   fromDate.toIso8601String().substring(0, 10),
        'toDate':     toDate.toIso8601String().substring(0, 10),
      },
    );

    if (invoiceResult.isEmpty) return [];

    final invoiceIds = invoiceResult
        .map((r) => r.toColumnMap()['id'].toString())
        .toList();

    final itemsResult = await conn.execute(
      Sql.named('''
        SELECT
          invoice_id, product_name, sku,
          price, quantity, discount, total_amount
        FROM public.sale_invoice_items
        WHERE invoice_id = ANY(@ids::uuid[])
        ORDER BY created_at ASC
      '''),
      parameters: {'ids': invoiceIds},
    );

    final Map<String, List<CustomerInvoiceItemDetail>> itemsMap = {};
    for (final row in itemsResult) {
      final m         = row.toColumnMap();
      final invoiceId = m['invoice_id'].toString();
      itemsMap.putIfAbsent(invoiceId, () => []);
      itemsMap[invoiceId]!.add(CustomerInvoiceItemDetail.fromMap({
        'product_name': m['product_name'],
        'sku':          m['sku'],
        'price':        m['price'],
        'quantity':     m['quantity'],
        'discount':     m['discount'],
        'total_amount': m['total_amount'],
      }));
    }

    return invoiceResult.map((row) {
      final m  = row.toColumnMap();
      final id = m['id'].toString();
      return CustomerInvoiceModel(
        id:            id,
        invoiceNo:     m['invoice_no']?.toString()   ?? '',
        invoiceDate:   m['invoice_date'] is DateTime
            ? m['invoice_date'] as DateTime
            : DateTime.tryParse(m['invoice_date'].toString()) ?? DateTime.now(),
        paymentType:   m['payment_type']?.toString() ?? 'cash',
        status:        m['status']?.toString()       ?? 'completed',
        totalAmount:   _dbl(m['total_amount'])       ?? 0,
        totalDiscount: _dbl(m['total_discount'])     ?? 0,
        grandTotal:    _dbl(m['grand_total'])        ?? 0,
        customerId:    m['customer_id']?.toString(),
        customerName:  m['customer_name']?.toString(),
        counterName:   m['counter_name']?.toString(),
        cashierName:   m['cashier_name']?.toString(),
        items:         itemsMap[id] ?? [],
      );
    }).toList();
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}