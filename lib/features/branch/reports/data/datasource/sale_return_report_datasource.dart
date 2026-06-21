import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';
import '../model/sale_return_report_model.dart';

class CashierReturnModel {
  final String id;
  final String fullName;
  const CashierReturnModel({required this.id, required this.fullName});
}

class _BalanceInfo {
  final double previousBalance;
  final double currentBalance;
  const _BalanceInfo(this.previousBalance, this.currentBalance);
}

class SaleReturnDatasource {

  // ── Cashiers ──────────────────────────────────────────────
  Future<List<CashierReturnModel>> getCashiers({
    required String storeId,
  }) async {
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
      return CashierReturnModel(
        id:       m['id'].toString(),
        fullName: m['full_name']?.toString() ?? 'Unknown',
      );
    }).toList();
  }

  // ── Main: Sale Returns ────────────────────────────────────
  Future<List<SaleReturnModel>> getAll({
    required String   storeId,
    required DateTime fromDate,
    required DateTime toDate,
    String?           counterId,
    String?           userId,
  }) async {
    final conn = await DataBaseService.getConnection();

    final counterFilter = counterId != null
        ? 'AND sr.counter_id = @counterId::uuid' : '';
    final userFilter = userId != null
        ? 'AND sr.user_id = @userId::uuid' : '';

    // ── 1. Returns ────────────────────────────────────────
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
          sr.previous_amount,
          sr.new_amount,
          sr.pay_amount,
          c.name           AS customer_name,
          co.counter_name  AS counter_name,
          u.full_name      AS cashier_name,
          STRING_AGG(srp.payment_method, ',') AS refund_type
        FROM public.sale_returns sr
        LEFT JOIN public.customer            c   ON c.id  = sr.customer_id
        LEFT JOIN public.branch_counter      co  ON co.id = sr.counter_id
        LEFT JOIN public.branch_users        u   ON u.id  = sr.user_id
        LEFT JOIN public.sale_return_payments srp ON srp.return_id = sr.id
        WHERE sr.store_id          = @storeId::uuid
          AND sr.deleted_at        IS NULL
          AND sr.return_date::date >= @fromDate
          AND sr.return_date::date <= @toDate
          $counterFilter
          $userFilter
        GROUP BY
          sr.id, sr.return_no, sr.return_date,
          sr.status, sr.total_amount, sr.total_discount,
          sr.grand_total, sr.return_reason, sr.invoice_id,
          sr.customer_id, sr.previous_amount, sr.new_amount,
          sr.pay_amount, c.name, co.counter_name, u.full_name
        ORDER BY sr.return_date DESC
      '''),
      parameters: {
        'storeId':  storeId,
        'fromDate': fromDate.toIso8601String().substring(0, 10),
        'toDate':   toDate.toIso8601String().substring(0, 10),
        if (counterId != null) 'counterId': counterId,
        if (userId    != null) 'userId':    userId,
      },
    );

    if (returnResult.isEmpty) return [];

    final returnIds = returnResult
        .map((r) => r.toColumnMap()['id'].toString())
        .toList();

    // ── 2. Items ──────────────────────────────────────────
    final itemsResult = await conn.execute(
      Sql.named('''
        SELECT
          return_id,
          product_name,
          sku,
          barcode::text AS barcode,
          sale_price,
          purchase_price,
          quantity,
          discount,
          subtotal,
          total_amount
        FROM public.sale_return_items
        WHERE return_id = ANY(@ids::uuid[])
        ORDER BY created_at ASC
      '''),
      parameters: {'ids': returnIds},
    );

    final Map<String, List<SaleReturnItemDetail>> itemsMap = {};
    for (final row in itemsResult) {
      final m        = row.toColumnMap();
      final returnId = m['return_id'].toString();
      itemsMap.putIfAbsent(returnId, () => []);
      itemsMap[returnId]!.add(SaleReturnItemDetail.fromMap({
        'product_name':   m['product_name'],
        'sku':            m['sku'],
        'barcode':        m['barcode'],
        'sale_price':     m['sale_price'],
        'purchase_price': m['purchase_price'],
        'quantity':       m['quantity'],
        'discount':       m['discount'],
        'subtotal':       m['subtotal'],
        'total_amount':   m['total_amount'],
      }));
    }

    // ── 3. Payments ───────────────────────────────────────
    final paymentsResult = await conn.execute(
      Sql.named('''
        SELECT
          return_id,
          payment_method,
          amount
        FROM public.sale_return_payments
        WHERE return_id = ANY(@ids::uuid[])
        ORDER BY created_at ASC
      '''),
      parameters: {'ids': returnIds},
    );

    final Map<String, List<SaleReturnPaymentDetail>> paymentsMap = {};
    for (final row in paymentsResult) {
      final m        = row.toColumnMap();
      final returnId = m['return_id'].toString();
      paymentsMap.putIfAbsent(returnId, () => []);
      paymentsMap[returnId]!.add(SaleReturnPaymentDetail.fromMap({
        'payment_method': m['payment_method'],
        'amount':         m['amount'],
      }));
    }

    // ── 4. Fallback balance (purani returns ke liye) ──────
    final needsFallback = returnResult.any((r) {
      final m = r.toColumnMap();
      return m['customer_id'] != null && m['previous_amount'] == null;
    });

    final customerIds = returnResult
        .map((r) => r.toColumnMap()['customer_id'])
        .where((id) => id != null)
        .map((id) => id.toString())
        .toSet()
        .toList();

    final Map<String, _BalanceInfo> balanceMap = {};

    if (needsFallback && customerIds.isNotEmpty) {
      final balanceResult = await conn.execute(
        Sql.named('''
          WITH invoice_events AS (
            SELECT
              si.id                      AS event_id,
              si.customer_id,
              si.invoice_date            AS event_time,
              si.created_at              AS event_created_at,
              COALESCE(credit.amount, 0) AS delta,
              'invoice'                  AS event_type
            FROM public.sale_invoices si
            LEFT JOIN (
              SELECT invoice_id, SUM(amount) AS amount
              FROM public.sale_invoice_payments
              WHERE payment_method = 'credit'
              GROUP BY invoice_id
            ) credit ON credit.invoice_id = si.id
            WHERE si.store_id    = @storeId::uuid
              AND si.customer_id = ANY(@customerIds::uuid[])
              AND si.deleted_at IS NULL
          ),
          return_events AS (
            SELECT
              sr.id                       AS event_id,
              sr.customer_id,
              sr.return_date              AS event_time,
              sr.created_at              AS event_created_at,
              -COALESCE(cr.amount, 0)    AS delta,
              'return'                   AS event_type
            FROM public.sale_returns sr
            LEFT JOIN (
              SELECT return_id, SUM(amount) AS amount
              FROM public.sale_return_payments
              WHERE payment_method = 'credit'
              GROUP BY return_id
            ) cr ON cr.return_id = sr.id
            WHERE sr.store_id    = @storeId::uuid
              AND sr.customer_id = ANY(@customerIds::uuid[])
              AND sr.deleted_at IS NULL
          ),
          ledger_events AS (
            SELECT
              cl.id            AS event_id,
              cl.customer_id,
              cl.created_at    AS event_time,
              cl.created_at    AS event_created_at,
              -cl.pay_amount   AS delta,
              'ledger'         AS event_type
            FROM public.customer_ledger cl
            WHERE cl.store_id    = @storeId::uuid
              AND cl.customer_id = ANY(@customerIds::uuid[])
              AND cl.deleted_at IS NULL
          ),
          all_events AS (
            SELECT * FROM invoice_events
            UNION ALL
            SELECT * FROM return_events
            UNION ALL
            SELECT * FROM ledger_events
          )
          SELECT
            event_id,
            event_type,
            delta,
            SUM(delta) OVER (
              PARTITION BY customer_id
              ORDER BY event_time, event_created_at
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS running_balance
          FROM all_events
          WHERE event_type = 'return'
        '''),
        parameters: {
          'storeId':     storeId,
          'customerIds': customerIds,
        },
      );

      for (final row in balanceResult) {
        final m              = row.toColumnMap();
        final retId          = m['event_id'].toString();
        final delta          = _dbl(m['delta'])           ?? 0;
        final runningBalance = _dbl(m['running_balance']) ?? 0;
        balanceMap[retId] = _BalanceInfo(
          runningBalance - delta,
          runningBalance,
        );
      }
    }

    // ── 5. Assemble ───────────────────────────────────────
    return returnResult.map((row) {
      final m  = row.toColumnMap();
      final id = m['id'].toString();

      final storedPrevious = _dbl(m['previous_amount']);
      final storedNew      = _dbl(m['new_amount']);
      final fallback       = balanceMap[id];

      return SaleReturnModel(
        id:              id,
        returnNo:        m['return_no']?.toString()    ?? '',
        returnDate:      m['return_date'] is DateTime
            ? m['return_date'] as DateTime
            : DateTime.tryParse(m['return_date'].toString()) ?? DateTime.now(),
        refundType:      m['refund_type']?.toString()  ?? 'cash',
        status:          m['status']?.toString()       ?? 'completed',
        totalAmount:     _dbl(m['total_amount'])       ?? 0,
        totalDiscount:   _dbl(m['total_discount'])     ?? 0,
        grandTotal:      _dbl(m['grand_total'])        ?? 0,
        returnReason:    m['return_reason']?.toString(),
        invoiceId:       m['invoice_id']?.toString(),
        customerId:      m['customer_id']?.toString(),
        customerName:    m['customer_name']?.toString(),
        counterName:     m['counter_name']?.toString(),
        cashierName:     m['cashier_name']?.toString(),
        items:           itemsMap[id]    ?? [],
        payments:        paymentsMap[id] ?? [],
        previousBalance: storedPrevious ?? fallback?.previousBalance,
        currentBalance:  storedNew      ?? fallback?.currentBalance,
        payAmount:       _dbl(m['pay_amount']),
      );
    }).toList();
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}