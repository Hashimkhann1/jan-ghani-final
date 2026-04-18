import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/dashboard_model.dart';

class DashboardDatasource {

  Future<DashboardData> load({
    required String  storeId,
    required String? counterId,
  }) async {
    final conn = await DataBaseService.getConnection();

    final counterFilter = counterId != null
        ? 'AND counter_id = @counterId::uuid'
        : '';

    final params = <String, dynamic>{
      'storeId': storeId,
      if (counterId != null) 'counterId': counterId,
    };

    // ── 1. Today summary ──────────────────────────────────
    final summaryResult = await conn.execute(
      Sql.named('''
        SELECT
          COALESCE(SUM(cash_sale),   0) AS cash_sale,
          COALESCE(SUM(card_sale),   0) AS card_sale,
          COALESCE(SUM(credit_sale), 0) AS credit_sale,
          COALESCE(SUM(installment), 0) AS installment,
          COALESCE(SUM(total_sale),  0) AS total_sale,
          COALESCE(SUM(total_amount),0) AS total_amount
        FROM public.branch_cash_counter
        WHERE store_id    = @storeId::uuid
          AND counter_date = CURRENT_DATE
          $counterFilter
      '''),
      parameters: params,
    );

    final sm = summaryResult.isNotEmpty
        ? summaryResult.first.toColumnMap()
        : <String, dynamic>{};

    // ── 2. Last 7 days sales ──────────────────────────────
    final weekResult = await conn.execute(
      Sql.named('''
        SELECT
          counter_date,
          SUM(total_sale) AS day_sale
        FROM public.branch_cash_counter
        WHERE store_id    = @storeId::uuid
          AND counter_date >= CURRENT_DATE - INTERVAL '6 days'
          AND counter_date <= CURRENT_DATE
          $counterFilter
        GROUP BY counter_date
        ORDER BY counter_date ASC
      '''),
      parameters: params,
    );

    final Map<String, double> dayMap = {};
    for (final row in weekResult) {
      final m    = row.toColumnMap();
      final date = m['counter_date'] is DateTime
          ? m['counter_date'] as DateTime
          : DateTime.tryParse(m['counter_date'].toString()) ?? DateTime.now();
      final key  = _dayLabel(date.weekday);
      dayMap[key] = _dbl(m['day_sale']) ?? 0;
    }

    final days        = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeklySales = days.map((d) => WeeklySale(d, dayMap[d] ?? 0)).toList();

    // ── 3. Top 10 Products ────────────────────────────────
    final productResult = await conn.execute(
      Sql.named('''
        SELECT
          sii.product_name,
          CAST(SUM(sii.quantity) AS INT) AS total_qty,
          SUM(sii.total_amount)          AS total_amount
        FROM public.sale_invoice_items sii
        JOIN public.sale_invoices si ON si.id = sii.invoice_id
        WHERE si.store_id   = @storeId::uuid
          AND si.deleted_at IS NULL
          AND si.status     = 'completed'
          ${counterId != null ? 'AND si.counter_id = @counterId::uuid' : ''}
        GROUP BY sii.product_name
        ORDER BY total_qty DESC
        LIMIT 10
      '''),
      parameters: params,
    );

    final topProducts = productResult.asMap().entries.map((e) {
      final m = e.value.toColumnMap();
      return TopProduct(
        e.key + 1,
        m['product_name']?.toString() ?? '',
        (_dbl(m['total_qty'])?.toInt()) ?? 0,
        _dbl(m['total_amount']) ?? 0,
      );
    }).toList();

    // ── 4. Top 10 Customers ───────────────────────────────
    final customerResult = await conn.execute(
      Sql.named('''
        SELECT
          COALESCE(c.name, 'Walk In') AS customer_name,
          COUNT(si.id)                AS orders,
          SUM(si.grand_total)         AS total_amount
        FROM public.sale_invoices si
        LEFT JOIN public.customer c ON c.id = si.customer_id
        WHERE si.store_id   = @storeId::uuid
          AND si.deleted_at IS NULL
          AND si.status     = 'completed'
          ${counterId != null ? 'AND si.counter_id = @counterId::uuid' : ''}
        GROUP BY c.name, si.customer_id
        ORDER BY total_amount DESC
        LIMIT 10
      '''),
      parameters: params,
    );

    final topCustomers = customerResult.asMap().entries.map((e) {
      final m = e.value.toColumnMap();
      return TopCustomer(
        e.key + 1,
        m['customer_name']?.toString() ?? 'Walk In',
        int.tryParse(m['orders']?.toString() ?? '0') ?? 0,
        _dbl(m['total_amount']) ?? 0,
      );
    }).toList();

    return DashboardData(
      cashSale:     _dbl(sm['cash_sale'])    ?? 0,
      cardSale:     _dbl(sm['card_sale'])    ?? 0,
      creditSale:   _dbl(sm['credit_sale'])  ?? 0,
      installment:  _dbl(sm['installment'])  ?? 0,
      totalSale:    _dbl(sm['total_sale'])   ?? 0,
      totalAmount:  _dbl(sm['total_amount']) ?? 0,
      weeklySales:  weeklySales,
      topProducts:  topProducts,
      topCustomers: topCustomers,
    );
  }

  static String _dayLabel(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}