import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';
import '../../../../accountant/branch_reports/accountant_profit_loss_report/data/datasource/accountant_profit_loss_datasource.dart'
    show PnlReportDatasource;
import '../../../../accountant/branch_reports/accountant_profit_loss_report/data/model/accountant_profit_loss_model.dart';

/// Branch-side source for the Sale Summary Profit & Loss report. Reads the
/// branch's local Postgres and does the same aggregation the accountant
/// report gets from Supabase's `get_pnl_summary` RPC / `pnl_transactions_view`
/// — as plain SQL, so nothing has to be created in the local database.
///
/// Profit per line = (sale_price - purchase_price) * qty - discount.
class BranchPnlDatasource implements PnlSource {
  static const _pageSize = PnlReportDatasource.pageSize;

  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  Map<String, Object?> _params(
          String storeId, DateTime fromDate, DateTime toDate) =>
      {
        'storeId': storeId,
        'from':    fromDate.toIso8601String(),
        'to':      _endOfDay(toDate).toIso8601String(),
      };

  /// One row per completed sale invoice and per completed sale return in
  /// range, with revenue / cost / profit already summed.
  static const _txCte = '''
    WITH tx AS (
      SELECT si.id, 'sale'::text AS type, si.invoice_no AS doc_no,
             si.invoice_date AS tx_date, c.name AS customer_name,
             COALESCE(SUM(sii.sale_price * sii.quantity), 0)     AS total_revenue,
             COALESCE(SUM(sii.purchase_price * sii.quantity), 0) AS total_cost,
             COALESCE(SUM((sii.sale_price - sii.purchase_price) * sii.quantity
                          - COALESCE(sii.discount, 0)), 0)       AS total_profit,
             COUNT(sii.invoice_id)                               AS item_count
      FROM public.sale_invoices si
      LEFT JOIN public.sale_invoice_items sii ON sii.invoice_id = si.id
      LEFT JOIN public.customer c             ON c.id = si.customer_id
      WHERE si.store_id = @storeId::uuid
        AND si.status = 'completed'
        AND si.deleted_at IS NULL
        AND si.invoice_date >= @from::timestamptz
        AND si.invoice_date <= @to::timestamptz
      GROUP BY si.id, si.invoice_no, si.invoice_date, c.name

      UNION ALL

      SELECT sr.id, 'return'::text, sr.return_no, sr.return_date, c.name,
             COALESCE(SUM(sri.sale_price * sri.quantity), 0),
             COALESCE(SUM(sri.purchase_price * sri.quantity), 0),
             COALESCE(SUM((sri.sale_price - sri.purchase_price) * sri.quantity
                          - COALESCE(sri.discount, 0)), 0),
             COUNT(sri.return_id)
      FROM public.sale_returns sr
      LEFT JOIN public.sale_return_items sri ON sri.return_id = sr.id
      LEFT JOIN public.customer c            ON c.id = sr.customer_id
      WHERE sr.store_id = @storeId::uuid
        AND sr.status = 'completed'
        AND sr.deleted_at IS NULL
        AND sr.return_date >= @from::timestamptz
        AND sr.return_date <= @to::timestamptz
      GROUP BY sr.id, sr.return_no, sr.return_date, c.name
    )
  ''';

  String _filterSql(PnlInvoiceFilter f) => switch (f) {
        PnlInvoiceFilter.profit => 'WHERE total_profit >= 0',
        PnlInvoiceFilter.loss   => 'WHERE total_profit < 0',
        PnlInvoiceFilter.all    => '',
      };

  @override
  Future<PnlSummary> getSummary({
    required DateTime fromDate,
    required DateTime toDate,
    required String storeId,
  }) async {
    final conn   = await DataBaseService.getConnection();
    final params = _params(storeId, fromDate, toDate);

    final totals = (await conn.execute(
      Sql.named('''
        $_txCte
        SELECT
          COUNT(*) FILTER (WHERE type = 'sale')                           AS total_invoices,
          COUNT(*) FILTER (WHERE type = 'return')                         AS total_returns,
          COALESCE(SUM(total_profit)  FILTER (WHERE type = 'sale'), 0)    AS gross_sale_profit,
          COALESCE(SUM(total_profit)  FILTER (WHERE type = 'return'), 0)  AS gross_return_profit,
          COALESCE(SUM(total_revenue) FILTER (WHERE type = 'sale'), 0)    AS total_sale_revenue,
          COALESCE(SUM(total_cost)    FILTER (WHERE type = 'sale'), 0)    AS total_cost
        FROM tx
      '''),
      parameters: params,
    ))
        .first
        .toColumnMap();

    final dailyRows = await conn.execute(
      Sql.named('''
        $_txCte
        SELECT tx_date::date AS d,
               COALESCE(SUM(total_profit) FILTER (WHERE type = 'sale'), 0)   AS sale_profit,
               COALESCE(SUM(total_profit) FILTER (WHERE type = 'return'), 0) AS return_profit
        FROM tx
        GROUP BY tx_date::date
        ORDER BY d DESC
      '''),
      parameters: params,
    );

    final daily = dailyRows.map((r) {
      final m = r.toColumnMap();
      return PnlDaySummary(
        date:         _calendarDay(_date(m['d'])),
        saleProfit:   _dbl(m['sale_profit']),
        returnProfit: _dbl(m['return_profit']),
      );
    }).toList();

    return PnlSummary(
      grossSaleProfit:   _dbl(totals['gross_sale_profit']),
      grossReturnProfit: _dbl(totals['gross_return_profit']),
      totalSaleRevenue:  _dbl(totals['total_sale_revenue']),
      totalCost:         _dbl(totals['total_cost']),
      totalInvoices:     _int(totals['total_invoices']),
      totalReturns:      _int(totals['total_returns']),
      daily:             daily,
    );
  }

  @override
  Future<PnlTransactionsPage> getTransactionsPage({
    required DateTime fromDate,
    required DateTime toDate,
    required String storeId,
    required PnlInvoiceFilter filter,
    required int page,
  }) async {
    final conn   = await DataBaseService.getConnection();
    final params = _params(storeId, fromDate, toDate);

    final rows = await conn.execute(
      Sql.named('''
        $_txCte
        SELECT * FROM tx
        ${_filterSql(filter)}
        ORDER BY tx_date DESC, id
        LIMIT @limit OFFSET @offset
      '''),
      parameters: {
        ...params,
        'limit':  _pageSize,
        'offset': page * _pageSize,
      },
    );

    final total = await getFilterCount(
      fromDate: fromDate,
      toDate:   toDate,
      storeId:  storeId,
      filter:   filter,
    );

    return PnlTransactionsPage(
      rows:       rows.map((r) => _mapRow(r.toColumnMap())).toList(),
      totalCount: total,
    );
  }

  @override
  Future<int> getFilterCount({
    required DateTime fromDate,
    required DateTime toDate,
    required String storeId,
    required PnlInvoiceFilter filter,
  }) async {
    final conn = await DataBaseService.getConnection();
    final res  = await conn.execute(
      Sql.named('''
        $_txCte
        SELECT COUNT(*) AS n FROM tx ${_filterSql(filter)}
      '''),
      parameters: _params(storeId, fromDate, toDate),
    );
    return _int(res.first.toColumnMap()['n']);
  }

  @override
  Future<List<PnlItem>> getTransactionItems({
    required String type,
    required String id,
  }) async {
    final table  = type == 'return' ? 'sale_return_items' : 'sale_invoice_items';
    final column = type == 'return' ? 'return_id'         : 'invoice_id';

    final conn = await DataBaseService.getConnection();
    final res  = await conn.execute(
      Sql.named('''
        SELECT product_name, sku, sale_price, purchase_price, quantity, discount
        FROM public.$table
        WHERE $column = @id::uuid
      '''),
      parameters: {'id': id},
    );

    return res.map((r) {
      final m = r.toColumnMap();
      return PnlItem(
        productName:   m['product_name']?.toString() ?? '',
        sku:           m['sku']?.toString(),
        salePrice:     _dbl(m['sale_price']),
        purchasePrice: _dbl(m['purchase_price']),
        discount:      _dbl(m['discount']),
        quantity:      _dbl(m['quantity']),
      );
    }).toList();
  }

  PnlTransactionRow _mapRow(Map<String, dynamic> m) => PnlTransactionRow(
        id:           m['id'].toString(),
        type:         m['type']?.toString() ?? 'sale',
        docNo:        m['doc_no']?.toString() ?? '',
        date:         _date(m['tx_date']).toLocal(),
        customerName: m['customer_name']?.toString(),
        totalRevenue: _dbl(m['total_revenue']),
        totalCost:    _dbl(m['total_cost']),
        totalProfit:  _dbl(m['total_profit']),
        itemCount:    _int(m['item_count']),
      );

  static DateTime _date(dynamic v) =>
      v is DateTime ? v : DateTime.parse(v.toString());

  /// Postgres `date` arrives as a UTC midnight — keep just y/m/d as a plain
  /// local calendar day so it can't shift when converted.
  static DateTime _calendarDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _int(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0;

  static double _dbl(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
