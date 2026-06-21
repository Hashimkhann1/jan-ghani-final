import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';
import '../model/sale_invoice_report_model.dart';

class CashierModel {
  final String id;
  final String fullName;
  const CashierModel({required this.id, required this.fullName});
}

class _BalanceInfo {
  final double previousBalance;
  final double currentBalance;
  const _BalanceInfo(this.previousBalance, this.currentBalance);
}

class SaleInvoiceListDatasource {

  // ── Cashiers list ─────────────────────────────────────────
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

  // ── Get All Invoices ──────────────────────────────────────
  Future<List<SaleInvoiceListModel>> getAll({
    required String   storeId,
    required DateTime fromDate,
    required DateTime toDate,
    String?           counterId,
    String?           userId,
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
        WHERE si.store_id   = @storeId::uuid
          AND si.deleted_at IS NULL
          AND si.invoice_date >= @fromDate::timestamptz
          AND si.invoice_date <= @toDate::timestamptz
          $counterFilter
          $userFilter
        GROUP BY
          si.id, si.invoice_no, si.invoice_date,
          si.status, si.total_amount, si.total_discount,
          si.grand_total, si.notes, si.customer_id,
          c.name, co.counter_name, u.full_name
        ORDER BY si.invoice_date DESC
      '''),
      parameters: {
        'storeId':  storeId,
        'fromDate': fromDate.toIso8601String(),
        'toDate':   toDate.toIso8601String(),
        if (counterId != null) 'counterId': counterId,
        if (userId    != null) 'userId':    userId,
      },
    );

    if (invoiceResult.isEmpty) return [];

    final invoiceIds = invoiceResult
        .map((r) => r.toColumnMap()['id'].toString())
        .toList();

    // ── Items ───────────────────────────────────────────────
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

    final Map<String, List<SaleInvoiceItemDetail>> itemsMap = {};
    for (final row in itemsResult) {
      final m         = row.toColumnMap();
      final invoiceId = m['invoice_id'].toString();
      itemsMap.putIfAbsent(invoiceId, () => []);
      itemsMap[invoiceId]!.add(SaleInvoiceItemDetail.fromMap({
        'product_name':   m['product_name'],
        'sku':            m['sku'],
        'sale_price':     m['sale_price'],
        'purchase_price': m['purchase_price'],
        'quantity':       m['quantity'],
        'discount':       m['discount'],
        'total_amount':   m['total_amount'],
      }));
    }

    // ── Payments (method + amount, for print breakdown) ─────
    final paymentsResult = await conn.execute(
      Sql.named('''
        SELECT
          invoice_id,
          payment_method,
          amount
        FROM public.sale_invoice_payments
        WHERE invoice_id = ANY(@ids::uuid[])
        ORDER BY created_at ASC
      '''),
      parameters: {'ids': invoiceIds},
    );

    final Map<String, List<SaleInvoicePaymentDetail>> paymentsMap = {};
    for (final row in paymentsResult) {
      final m         = row.toColumnMap();
      final invoiceId = m['invoice_id'].toString();
      paymentsMap.putIfAbsent(invoiceId, () => []);
      paymentsMap[invoiceId]!.add(SaleInvoicePaymentDetail.fromMap({
        'payment_method': m['payment_method'],
        'amount':         m['amount'],
      }));
    }

    // ── Previous / Current Balance (customer credit ledger) ─
    // Running balance = cumulative sum of 'credit' payment entries
    // for that customer, ordered by invoice date — across ALL of
    // that customer's invoices (not just the selected date range),
    // so the balance is accurate at the point of this invoice.
    //
    // NOTE: this only accounts for sale_invoices credit amounts.
    // If balance also changes via a separate customer ledger
    // payments table or sale returns, share that schema so it can
    // be folded into this calculation.
    final customerIds = invoiceResult
        .map((r) => r.toColumnMap()['customer_id'])
        .where((id) => id != null)
        .map((id) => id.toString())
        .toSet()
        .toList();

    final Map<String, _BalanceInfo> balanceMap = {};

    if (customerIds.isNotEmpty) {
      final balanceResult = await conn.execute(
        Sql.named('''
          SELECT
            si.id AS invoice_id,
            COALESCE(credit.amount, 0) AS credit_amount,
            SUM(COALESCE(credit.amount, 0)) OVER (
              PARTITION BY si.customer_id
              ORDER BY si.invoice_date, si.created_at
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS running_balance
          FROM public.sale_invoices si
          LEFT JOIN (
            SELECT invoice_id, SUM(amount) AS amount
            FROM public.sale_invoice_payments
            WHERE payment_method = 'credit'
            GROUP BY invoice_id
          ) credit ON credit.invoice_id = si.id
          WHERE si.store_id     = @storeId::uuid
            AND si.customer_id  = ANY(@customerIds::uuid[])
            AND si.deleted_at IS NULL
          ORDER BY si.customer_id, si.invoice_date, si.created_at
        '''),
        parameters: {
          'storeId':     storeId,
          'customerIds': customerIds,
        },
      );

      for (final row in balanceResult) {
        final m              = row.toColumnMap();
        final invId          = m['invoice_id'].toString();
        final creditAmount   = _dbl(m['credit_amount'])   ?? 0;
        final runningBalance = _dbl(m['running_balance']) ?? 0;
        balanceMap[invId] = _BalanceInfo(
          runningBalance - creditAmount, // previousBalance
          runningBalance,                // currentBalance
        );
      }
    }

    return invoiceResult.map((row) {
      final m  = row.toColumnMap();
      final id = m['id'].toString();
      final balance = balanceMap[id];
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
        notes:         m['notes']?.toString(),
        items:           itemsMap[id]    ?? [],
        payments:        paymentsMap[id] ?? [],
        previousBalance: balance?.previousBalance,
        currentBalance:  balance?.currentBalance,
      );
    }).toList();
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}