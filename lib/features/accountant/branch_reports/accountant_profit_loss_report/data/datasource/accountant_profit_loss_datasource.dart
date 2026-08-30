import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_profit_loss_model.dart';

enum PnlInvoiceFilter { all, profit, loss }

class PnlReportDatasource {
  final _client = Supabase.instance.client;

  static const pageSize = 20;

  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  // ── Aggregate totals + daily breakdown — one RPC round trip,
  //    computed entirely in Postgres (SUM/COUNT/GROUP BY). Never
  //    fetches invoice rows. ─────────────────────────────────────
  Future<PnlSummary> getSummary({
    required DateTime fromDate,
    required DateTime toDate,
    required String storeId,
  }) async {
    final rows = await _client.rpc('get_pnl_summary', params: {
      'p_store_id': storeId,
      'p_from':     fromDate.toIso8601String(),
      'p_to':       _endOfDay(toDate).toIso8601String(),
    });

    final row = (rows as List).first as Map<String, dynamic>;

    final daily = ((row['daily'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map((d) => PnlDaySummary(
      date:         DateTime.parse(d['date'].toString()),
      saleProfit:   _dbl(d['sale_profit'])   ?? 0,
      returnProfit: _dbl(d['return_profit']) ?? 0,
    ))
        .toList();

    return PnlSummary(
      grossSaleProfit:   _dbl(row['gross_sale_profit'])   ?? 0,
      grossReturnProfit: _dbl(row['gross_return_profit']) ?? 0,
      totalSaleRevenue:  _dbl(row['total_sale_revenue'])  ?? 0,
      totalCost:         _dbl(row['total_cost'])          ?? 0,
      totalInvoices:     (row['total_invoices'] as num?)?.toInt() ?? 0,
      totalReturns:      (row['total_returns']  as num?)?.toInt() ?? 0,
      daily:             daily,
    );
  }

  // ── One page of the Invoices tab, with its exact total count for
  //    the current filter — from `pnl_transactions_view`, which has
  //    profit/revenue/cost pre-aggregated per invoice/return. ──────
  Future<PnlTransactionsPage> getTransactionsPage({
    required DateTime fromDate,
    required DateTime toDate,
    required String storeId,
    required PnlInvoiceFilter filter,
    required int page,
  }) async {
    var query = _client
        .from('pnl_transactions_view')
        .select('''
          id, type, doc_no, tx_date, customer_name,
          total_revenue, total_cost, total_profit, item_count
        ''')
        .eq('store_id', storeId)
        .gte('tx_date', fromDate.toIso8601String())
        .lte('tx_date', _endOfDay(toDate).toIso8601String());

    if (filter == PnlInvoiceFilter.profit) {
      query = query.gte('total_profit', 0);
    } else if (filter == PnlInvoiceFilter.loss) {
      query = query.lt('total_profit', 0);
    }

    final start = page * pageSize;
    final end   = start + pageSize - 1;

    final res = await query
        .order('tx_date', ascending: false)
        .range(start, end)
        .count(CountOption.exact);

    final rows = (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(_mapRow)
        .toList();

    return PnlTransactionsPage(rows: rows, totalCount: res.count);
  }

  // ── Lightweight head-only count for one filter tab (no rows
  //    fetched at all — just `Prefer: count=exact`). ───────────────
  Future<int> getFilterCount({
    required DateTime fromDate,
    required DateTime toDate,
    required String storeId,
    required PnlInvoiceFilter filter,
  }) {
    var query = _client
        .from('pnl_transactions_view')
        .count(CountOption.exact)
        .eq('store_id', storeId)
        .gte('tx_date', fromDate.toIso8601String())
        .lte('tx_date', _endOfDay(toDate).toIso8601String());

    if (filter == PnlInvoiceFilter.profit) {
      query = query.gte('total_profit', 0);
    } else if (filter == PnlInvoiceFilter.loss) {
      query = query.lt('total_profit', 0);
    }

    return query;
  }

  // ── Item breakdown for ONE invoice/return — fetched lazily only
  //    when its card is expanded in the UI. ────────────────────────
  Future<List<PnlItem>> getTransactionItems({
    required String type,
    required String id,
  }) async {
    final table  = type == 'return' ? 'sale_return_items' : 'sale_invoice_items';
    final column = type == 'return' ? 'return_id'          : 'invoice_id';

    final result = await _client
        .from(table)
        .select('product_name, sku, sale_price, purchase_price, quantity, discount')
        .eq(column, id);

    return (result as List)
        .cast<Map<String, dynamic>>()
        .map(_parseItem)
        .toList();
  }

  PnlTransactionRow _mapRow(Map<String, dynamic> r) => PnlTransactionRow(
    id:           r['id'].toString(),
    type:         r['type']?.toString() ?? 'sale',
    docNo:        r['doc_no']?.toString() ?? '',
    date:         DateTime.parse(r['tx_date'].toString()).toLocal(),
    customerName: r['customer_name']?.toString(),
    totalRevenue: _dbl(r['total_revenue']) ?? 0,
    totalCost:    _dbl(r['total_cost'])    ?? 0,
    totalProfit:  _dbl(r['total_profit'])  ?? 0,
    itemCount:    (r['item_count'] as num?)?.toInt() ?? 0,
  );

  PnlItem _parseItem(Map<String, dynamic> i) => PnlItem(
    productName:   i['product_name']?.toString()  ?? '',
    sku:           i['sku']?.toString(),
    salePrice:     _dbl(i['sale_price'])           ?? 0,
    purchasePrice: _dbl(i['purchase_price'])       ?? 0,
    discount:      _dbl(i['discount'])             ?? 0,
    quantity:      _dbl(i['quantity'])             ?? 0,
  );

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}
