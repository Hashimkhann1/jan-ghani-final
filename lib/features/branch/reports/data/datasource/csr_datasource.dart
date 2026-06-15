// lib/features/branch/reports/data/datasource/csr_datasource.dart

import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';
import '../model/csr_model.dart';

class CsrDatasource {
  // ── Sales ─────────────────────────────────────────────────
  Future<List<CsrEntry>> getSales({
    required String storeId,
    required DateTime fromDate,
    required DateTime toDate,
    required String customerId,
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
          si.notes,
          si.customer_id,
          c.name          AS customer_name,
          co.counter_name AS counter_name,
          u.full_name     AS cashier_name,
          STRING_AGG(sip.payment_method, ',') AS payment_type
        FROM public.sale_invoices si
        LEFT JOIN public.customer            c   ON c.id  = si.customer_id
        LEFT JOIN public.branch_counter      co  ON co.id = si.counter_id
        LEFT JOIN public.branch_users        u   ON u.id  = si.user_id
        LEFT JOIN public.sale_invoice_payments sip ON sip.invoice_id = si.id
        WHERE si.store_id          = @storeId::uuid
          AND si.customer_id       = @customerId::uuid
          AND si.deleted_at        IS NULL
          AND si.invoice_date::date >= @fromDate
          AND si.invoice_date::date <= @toDate
        GROUP BY
          si.id, si.invoice_no, si.invoice_date,
          si.status, si.total_amount, si.total_discount,
          si.grand_total, si.notes, si.customer_id,
          c.name, co.counter_name, u.full_name
        ORDER BY si.invoice_date DESC
      '''),
      parameters: {
        'storeId': storeId,
        'customerId': customerId,
        'fromDate': fromDate.toIso8601String().substring(0, 10),
        'toDate': toDate.toIso8601String().substring(0, 10),
      },
    );

    if (invoiceResult.isEmpty) return [];

    final invoiceIds =
    invoiceResult.map((r) => r.toColumnMap()['id'].toString()).toList();

    final itemsResult = await conn.execute(
      Sql.named('''
        SELECT
          invoice_id,
          product_name,
          sku,
          sale_price,
          purchase_price,
          quantity,
          discount,
          total_amount
        FROM public.sale_invoice_items
        WHERE invoice_id = ANY(@ids::uuid[])
        ORDER BY created_at ASC
      '''),
      parameters: {'ids': invoiceIds},
    );

    final Map<String, List<CsrItemDetail>> itemsMap = {};
    for (final row in itemsResult) {
      final m = row.toColumnMap();
      final invId = m['invoice_id'].toString();
      itemsMap.putIfAbsent(invId, () => []);
      itemsMap[invId]!.add(CsrItemDetail.fromMap({
        'product_name': m['product_name'],
        'sku': m['sku'],
        'sale_price': m['sale_price'],
        'purchase_price': m['purchase_price'],
        'quantity': m['quantity'],
        'discount': m['discount'],
        'total_amount': m['total_amount'],
      }));
    }

    return invoiceResult.map((row) {
      final m = row.toColumnMap();
      final id = m['id'].toString();
      return CsrEntry(
        id: id,
        type: CsrType.sale,
        invoiceNo: m['invoice_no']?.toString() ?? '',
        invoiceDate: m['invoice_date'] is DateTime
            ? m['invoice_date'] as DateTime
            : DateTime.tryParse(m['invoice_date'].toString()) ?? DateTime.now(),
        paymentType: m['payment_type']?.toString() ?? 'cash',
        notes: m['notes']?.toString(),
        status: m['status']?.toString() ?? 'completed',
        totalAmount: _dbl(m['total_amount']) ?? 0,
        totalDiscount: _dbl(m['total_discount']) ?? 0,
        grandTotal: _dbl(m['grand_total']) ?? 0,
        customerId: m['customer_id']?.toString(),
        customerName: m['customer_name']?.toString(),
        counterName: m['counter_name']?.toString(),
        cashierName: m['cashier_name']?.toString(),
        items: itemsMap[id] ?? [],
      );
    }).toList();
  }

  // ── Returns ───────────────────────────────────────────────
  Future<List<CsrEntry>> getReturns({
    required String storeId,
    required DateTime fromDate,
    required DateTime toDate,
    required String customerId,
  }) async {
    final conn = await DataBaseService.getConnection();

    final returnResult = await conn.execute(
      Sql.named('''
        SELECT
          sr.id,
          sr.return_no,
          sr.return_date,
          sr.status,
          sr.total_amount,
          sr.total_discount,
          sr.grand_total,
          sr.return_reason,
          sr.invoice_id,
          sr.customer_id,
          c.name           AS customer_name,
          co.counter_name  AS counter_name,
          u.full_name      AS cashier_name,
          STRING_AGG(srp.payment_method, ',') AS refund_type
        FROM public.sale_returns sr
        LEFT JOIN public.customer       c   ON c.id  = sr.customer_id
        LEFT JOIN public.branch_counter co  ON co.id = sr.counter_id
        LEFT JOIN public.branch_users   u   ON u.id  = sr.user_id
        LEFT JOIN public.sale_return_payments srp ON srp.return_id = sr.id
        WHERE sr.store_id          = @storeId::uuid
          AND sr.customer_id       = @customerId::uuid
          AND sr.deleted_at        IS NULL
          AND sr.return_date::date >= @fromDate
          AND sr.return_date::date <= @toDate
        GROUP BY
          sr.id, sr.return_no, sr.return_date,
          sr.status, sr.total_amount, sr.total_discount,
          sr.grand_total, sr.return_reason, sr.invoice_id,
          sr.customer_id, c.name, co.counter_name, u.full_name
        ORDER BY sr.return_date DESC
      '''),
      parameters: {
        'storeId': storeId,
        'customerId': customerId,
        'fromDate': fromDate.toIso8601String().substring(0, 10),
        'toDate': toDate.toIso8601String().substring(0, 10),
      },
    );

    if (returnResult.isEmpty) return [];

    final returnIds =
    returnResult.map((r) => r.toColumnMap()['id'].toString()).toList();

    final itemsResult = await conn.execute(
      Sql.named('''
        SELECT
          return_id,
          product_name,
          sku,
          sale_price,
          purchase_price,
          quantity,
          discount,
          total_amount
        FROM public.sale_return_items
        WHERE return_id = ANY(@ids::uuid[])
        ORDER BY created_at ASC
      '''),
      parameters: {'ids': returnIds},
    );

    final Map<String, List<CsrItemDetail>> itemsMap = {};
    for (final row in itemsResult) {
      final m = row.toColumnMap();
      final retId = m['return_id'].toString();
      itemsMap.putIfAbsent(retId, () => []);
      itemsMap[retId]!.add(CsrItemDetail.fromMap({
        'product_name': m['product_name'],
        'sku': m['sku'],
        'sale_price': m['sale_price'],
        'purchase_price': m['purchase_price'],
        'quantity': m['quantity'],
        'discount': m['discount'],
        'total_amount': m['total_amount'],
      }));
    }

    return returnResult.map((row) {
      final m = row.toColumnMap();
      final id = m['id'].toString();
      return CsrEntry(
        id: id,
        type: CsrType.saleReturn,
        returnNo: m['return_no']?.toString() ?? '',
        returnDate: m['return_date'] is DateTime
            ? m['return_date'] as DateTime
            : DateTime.tryParse(m['return_date'].toString()) ?? DateTime.now(),
        refundType: m['refund_type']?.toString() ?? 'cash',
        returnReason: m['return_reason']?.toString(),
        invoiceId: m['invoice_id']?.toString(),
        status: m['status']?.toString() ?? 'completed',
        totalAmount: _dbl(m['total_amount']) ?? 0,
        totalDiscount: _dbl(m['total_discount']) ?? 0,
        grandTotal: _dbl(m['grand_total']) ?? 0,
        customerId: m['customer_id']?.toString(),
        customerName: m['customer_name']?.toString(),
        counterName: m['counter_name']?.toString(),
        cashierName: m['cashier_name']?.toString(),
        items: itemsMap[id] ?? [],
      );
    }).toList();
  }

  // ── Combined ──────────────────────────────────────────────
  Future<List<CsrEntry>> getAll({
    required String storeId,
    required DateTime fromDate,
    required DateTime toDate,
    required String customerId,
  }) async {
    final results = await Future.wait([
      getSales(
          storeId: storeId,
          fromDate: fromDate,
          toDate: toDate,
          customerId: customerId),
      getReturns(
          storeId: storeId,
          fromDate: fromDate,
          toDate: toDate,
          customerId: customerId),
    ]);

    final all = [...results[0], ...results[1]];
    all.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return all;
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}