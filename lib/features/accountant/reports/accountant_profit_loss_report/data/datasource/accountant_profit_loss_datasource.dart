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

      // Sale invoices — cost_price directly in items
      _client
          .from('sale_invoices')
          .select('''
            id, invoice_no, invoice_date, deleted_at,
            customer (name),
            sale_invoice_items (
              product_name, sku,
              price, cost_price,
              quantity, discount
            )
          ''')
          .eq('status', 'completed')
          .gte('invoice_date', fromDate.toIso8601String())
          .lte('invoice_date', toEnd.toIso8601String()),

      // Sale returns — product_id se purchase_price baad mein lenge
      _client
          .from('sale_returns')
          .select('''
            id, return_no, return_date, deleted_at,
            customer (name),
            sale_return_items (
              product_id,
              product_name, sku,
              price, quantity, discount
            )
          ''')
          .eq('status', 'completed')
          .gte('return_date', fromDate.toIso8601String())
          .lte('return_date', toEnd.toIso8601String()),
    ]);

    final salesRaw   = (results[0] as List)
        .where((r) => r['deleted_at'] == null)
        .toList();
    final returnsRaw = (results[1] as List)
        .where((r) => r['deleted_at'] == null)
        .toList();

    // ── Step 2: Collect unique product_ids from returns ───
    final Set<String> productIds = {};
    for (final r in returnsRaw) {
      for (final item in (r['sale_return_items'] as List? ?? [])) {
        final pid = item['product_id']?.toString();
        if (pid != null && pid.isNotEmpty) productIds.add(pid);
      }
    }

    // ── Step 3: Fetch purchase_price from branch_stock_inventory
    // Map: product_id → purchase_price
    final Map<String, double> purchasePriceMap = {};

    if (productIds.isNotEmpty) {
      final inventory = await _client
          .from('branch_stock_inventory')
          .select('product_id, purchase_price')
          .inFilter('product_id', productIds.toList());

      for (final row in (inventory as List)) {
        final pid   = row['product_id']?.toString();
        final price = _dbl(row['purchase_price']) ?? 0;
        if (pid != null) purchasePriceMap[pid] = price;
      }
    }

    // ── Step 4: Build invoice list ────────────────────────
    final List<PnlInvoice> allInvoices = [];

    for (final r in salesRaw) {
      allInvoices.add(PnlInvoice(
        invoiceNo:    r['invoice_no']?.toString() ?? '',
        date:         DateTime.parse(r['invoice_date'].toString()).toLocal(),
        customerName: r['customer']?['name']?.toString(),
        items:        _parseSaleItems(r['sale_invoice_items']),
        isReturn:     false,
      ));
    }

    for (final r in returnsRaw) {
      allInvoices.add(PnlInvoice(
        invoiceNo:    r['return_no']?.toString() ?? '',
        date:         DateTime.parse(r['return_date'].toString()).toLocal(),
        customerName: r['customer']?['name']?.toString(),
        items:        _parseReturnItems(r['sale_return_items'], purchasePriceMap),
        isReturn:     true,
      ));
    }

    allInvoices.sort((a, b) => b.date.compareTo(a.date));

    // ── Step 5: Aggregate totals ──────────────────────────
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

    // ── Step 6: Daily breakdown ───────────────────────────
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

  // sale_invoice_items — cost_price column directly
  List<PnlItem> _parseSaleItems(dynamic raw) =>
      (raw as List? ?? []).map((i) => PnlItem(
        productName: i['product_name']?.toString() ?? '',
        sku:         i['sku']?.toString(),
        salePrice:   _dbl(i['price'])      ?? 0,
        costPrice:   _dbl(i['cost_price']) ?? 0,
        discount:    _dbl(i['discount'])   ?? 0,
        quantity:    _dbl(i['quantity'])   ?? 0,
      )).toList();

  // sale_return_items — purchase_price from branch_stock_inventory map
  List<PnlItem> _parseReturnItems(
      dynamic raw,
      Map<String, double> purchasePriceMap,
      ) =>
      (raw as List? ?? []).map((i) {
        final pid         = i['product_id']?.toString() ?? '';
        final costPrice   = purchasePriceMap[pid] ?? 0;
        return PnlItem(
          productName: i['product_name']?.toString() ?? '',
          sku:         i['sku']?.toString(),
          salePrice:   _dbl(i['price'])    ?? 0,
          costPrice:   costPrice,
          discount:    _dbl(i['discount']) ?? 0,
          quantity:    _dbl(i['quantity']) ?? 0,
        );
      }).toList();

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}