import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/sale_invoice_list_model.dart';

class CashierModel {
  final String id;
  final String fullName;
  const CashierModel({required this.id, required this.fullName});
}

class SaleInvoiceListDatasource {

  // ── Cashiers list (manager ke liye) ──────────────────────
  Future<List<CashierModel>> getCashiers({required String storeId}) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT id, full_name
        FROM public.branch_users
        WHERE store_id  = @storeId::uuid
          AND role      = 'cashier'
          AND is_active = true
        ORDER BY full_name ASC
      '''),
      parameters: {'storeId': storeId},
    );
    return result.map((r) {
      final m = r.toColumnMap();
      return CashierModel(
        id:       m['id'].toString(),
        fullName: m['full_name']?.toString() ?? 'Unknown',
      );
    }).toList();
  }

  Future<List<SaleInvoiceListModel>> getAll({
    required String   storeId,
    required DateTime fromDate,
    required DateTime toDate,
    String?           counterId,
    String?           userId,      // cashier filter
  }) async {
    final conn = await DataBaseService.getConnection();

    final counterFilter = counterId != null
        ? 'AND si.counter_id = @counterId::uuid'
        : '';

    final userFilter = userId != null
        ? 'AND si.user_id = @userId::uuid'
        : '';

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
        LEFT JOIN public.customer       c   ON c.id   = si.customer_id
        LEFT JOIN public.branch_counter co  ON co.id  = si.counter_id
        LEFT JOIN public.branch_users   u   ON u.id   = si.user_id
        LEFT JOIN public.sale_invoice_payments sip ON sip.invoice_id = si.id
        WHERE si.store_id          = @storeId::uuid
          AND si.deleted_at        IS NULL
          AND si.invoice_date::date >= @fromDate
          AND si.invoice_date::date <= @toDate
          $counterFilter
          $userFilter
        GROUP BY
          si.id, si.invoice_no, si.invoice_date,
          si.status, si.total_amount, si.total_discount,
          si.grand_total, si.customer_id,
          c.name, co.counter_name, u.full_name
        ORDER BY si.invoice_date DESC
      '''),
      parameters: {
        'storeId':  storeId,
        'fromDate': fromDate.toIso8601String().substring(0, 10),
        'toDate':   toDate.toIso8601String().substring(0, 10),
        if (counterId != null) 'counterId': counterId,
        if (userId    != null) 'userId':    userId,
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

    final Map<String, List<SaleInvoiceItemDetail>> itemsMap = {};
    for (final row in itemsResult) {
      final m         = row.toColumnMap();
      final invoiceId = m['invoice_id'].toString();
      itemsMap.putIfAbsent(invoiceId, () => []);
      itemsMap[invoiceId]!.add(SaleInvoiceItemDetail.fromMap({
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
      return SaleInvoiceListModel(
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