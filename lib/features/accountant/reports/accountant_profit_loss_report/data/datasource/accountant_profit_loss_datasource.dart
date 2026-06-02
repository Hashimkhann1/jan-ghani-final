import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_profit_loss_model.dart';

class PnlReportDatasource {
  final _client = Supabase.instance.client;

  Future<PnlSummary> getReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final toEnd = DateTime(
        toDate.year, toDate.month, toDate.day, 23, 59, 59);

    // ── Step 1: Parallel fetch invoices + returns ─────────
    final results = await Future.wait([

      _client
          .from('sale_invoices')
          .select('''
            id, invoice_no, invoice_date, deleted_at,
            customer (name),
            sale_invoice_items (
              product_name, sku,
              sale_price, purchase_price,
              quantity, discount
            )
          ''')
          .eq('status', 'completed')
          .gte('invoice_date', fromDate.toIso8601String())
          .lte('invoice_date', toEnd.toIso8601String()),

      _client
          .from('sale_returns')
          .select('''
            id, return_no, return_date, deleted_at,
            customer (name),
            sale_return_items (
              product_name, sku,
              sale_price, purchase_price,
              quantity, discount
            )
          ''')
          .eq('status', 'completed')
          .gte('return_date', fromDate.toIso8601String())
          .lte('return_date', toEnd.toIso8601String()),
    ]);

    final salesRaw = (results[0] as List)
        .where((r) => r['deleted_at'] == null)
        .toList();
    final returnsRaw = (results[1] as List)
        .where((r) => r['deleted_at'] == null)
        .toList();

    // ── Step 2: Build invoice list ────────────────────────
    final List<PnlInvoice> allInvoices = [];

    for (final r in salesRaw) {
      allInvoices.add(PnlInvoice(
        invoiceNo:    r['invoice_no']?.toString() ?? '',
        date:         DateTime.parse(r['invoice_date'].toString()).toLocal(),
        customerName: r['customer']?['name']?.toString(),
        items:        _parseItems(r['sale_invoice_items']),
        isReturn:     false,
      ));
    }

    for (final r in returnsRaw) {
      allInvoices.add(PnlInvoice(
        invoiceNo:    r['return_no']?.toString() ?? '',
        date:         DateTime.parse(r['return_date'].toString()).toLocal(),
        customerName: r['customer']?['name']?.toString(),
        items:        _parseItems(r['sale_return_items']),
        isReturn:     true,
      ));
    }

    allInvoices.sort((a, b) => b.date.compareTo(a.date));

    // ── Step 3: Aggregate totals ──────────────────────────
    double grossSaleProfit   = 0;
    double grossReturnProfit = 0;
    double totalSaleRevenue  = 0;
    double totalCost         = 0;

    for (final inv in allInvoices) {
      if (inv.isReturn) {
        grossReturnProfit += inv.totalProfit;
      } else {
        grossSaleProfit  += inv.totalProfit;
        totalSaleRevenue += inv.totalRevenue;
        totalCost        += inv.totalCost;
      }
    }

    // ── Step 4: Daily breakdown ───────────────────────────
    final Map<String, PnlDaySummary> dailyMap = {};

    for (final inv in allInvoices) {
      final key  = _dayKey(inv.date);
      final prev = dailyMap[key] ??
          PnlDaySummary(
            date:         DateTime(inv.date.year, inv.date.month, inv.date.day),
            saleProfit:   0,
            returnProfit: 0,
          );
      dailyMap[key] = PnlDaySummary(
        date:         prev.date,
        saleProfit:   prev.saleProfit   + (!inv.isReturn ? inv.totalProfit : 0),
        returnProfit: prev.returnProfit + (inv.isReturn  ? inv.totalProfit : 0),
      );
    }

    final daily = dailyMap.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return PnlSummary(
      grossSaleProfit:   grossSaleProfit,
      grossReturnProfit: grossReturnProfit,
      totalSaleRevenue:  totalSaleRevenue,
      totalCost:         totalCost,
      totalInvoices:     salesRaw.length,
      totalReturns:      returnsRaw.length,
      invoices:          allInvoices,
      daily:             daily,
    );
  }

  // ── Single parser — dono tables ka same columns hain ────
  List<PnlItem> _parseItems(dynamic raw) =>
      (raw as List? ?? []).map((i) => PnlItem(
        productName:   i['product_name']?.toString()  ?? '',
        sku:           i['sku']?.toString(),
        salePrice:     _dbl(i['sale_price'])           ?? 0,
        purchasePrice: _dbl(i['purchase_price'])       ?? 0,
        discount:      _dbl(i['discount'])             ?? 0,
        quantity:      _dbl(i['quantity'])             ?? 0,
      )).toList();

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}