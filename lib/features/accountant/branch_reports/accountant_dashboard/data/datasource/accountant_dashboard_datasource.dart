import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/accountant_dashboard_model.dart';

// ═══════════════════════════════════════════════════════════
//  DATASOURCE
// ═══════════════════════════════════════════════════════════

class AccountantBranchDashboardDatasource {
  final _client = Supabase.instance.client;
  final String  branchId;

  AccountantBranchDashboardDatasource({required this.branchId});

  // ── Date helpers — timezone-safe ─────────────────────────
  static String _fromStr(DateTime d) =>
      DateTime(d.year, d.month, d.day, 0, 0, 0).toUtc().toIso8601String();

  static String _toStr(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59).toUtc().toIso8601String();

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  // ── Main method ──────────────────────────────────────────
  Future<AccountantBranchDashboardModel> getDashboard({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final counter     = await _fetchCashCounter(fromDate, toDate);
    final returnAmt   = await _fetchSaleReturns(fromDate, toDate);
    final profit      = await _fetchGrossProfit(fromDate, toDate);
    final inventory   = await _fetchInventoryValue();
    final outstanding = await _fetchOutstandingReceivable();

    return AccountantBranchDashboardModel(
      totalSale:             counter.totalSale,
      cashSale:              counter.cashSale,
      cardSale:              counter.cardSale,
      creditSale:            counter.creditSale,
      totalAmountReceived:   counter.totalAmount,
      totalSaleReturn:       returnAmt,
      netSale:               counter.totalSale - returnAmt,
      grossProfit:           profit,
      inventoryValue:        inventory,
      outstandingReceivable: outstanding,
    );
  }

  // ── 1. Cash Counter ──────────────────────────────────────
  Future<_CashCounterTotals> _fetchCashCounter(
      DateTime fromDate,
      DateTime toDate,
      ) async {
    final rows = await _client
        .from('branch_cash_counter')
        .select('cash_sale, card_sale, credit_sale, total_sale, total_amount')
        .eq('store_id', branchId)
        .isFilter('deleted_at', null)
        .gte('counter_date', _dateOnly(fromDate))
        .lte('counter_date', _dateOnly(toDate));

    double cashSale = 0, cardSale = 0, creditSale = 0;
    double totalSale = 0, totalAmount = 0;

    for (final r in (rows as List)) {
      cashSale    += _dbl(r['cash_sale'])    ?? 0;
      cardSale    += _dbl(r['card_sale'])    ?? 0;
      creditSale  += _dbl(r['credit_sale'])  ?? 0;
      totalSale   += _dbl(r['total_sale'])   ?? 0;
      totalAmount += _dbl(r['total_amount']) ?? 0;
    }

    return _CashCounterTotals(
      cashSale:    cashSale,
      cardSale:    cardSale,
      creditSale:  creditSale,
      totalSale:   totalSale,
      totalAmount: totalAmount,
    );
  }

  // ── 2. Sale Returns ──────────────────────────────────────
  Future<double> _fetchSaleReturns(
      DateTime fromDate,
      DateTime toDate,
      ) async {
    final rows = await _client
        .from('sale_returns')
        .select('grand_total')
        .eq('store_id', branchId)
        .eq('status', 'completed')
        .isFilter('deleted_at', null)
        .gte('return_date', _fromStr(fromDate))
        .lte('return_date', _toStr(toDate));

    double total = 0;
    for (final r in (rows as List)) {
      total += _dbl(r['grand_total']) ?? 0;
    }
    return total;
  }

  // ── 3. Gross Profit ──────────────────────────────────────
  Future<double> _fetchGrossProfit(
      DateTime fromDate,
      DateTime toDate,
      ) async {
    final invoiceIds = await _fetchInvoiceIds(fromDate, toDate);
    final returnIds  = await _fetchReturnIds(fromDate, toDate);

    final saleProfit = await _calcItemsProfit(
      table:    'sale_invoice_items',
      fkColumn: 'invoice_id',
      ids:      invoiceIds,
    );

    final returnProfit = await _calcItemsProfit(
      table:    'sale_return_items',
      fkColumn: 'return_id',
      ids:      returnIds,
    );

    return saleProfit - returnProfit;
  }

  Future<List<String>> _fetchInvoiceIds(
      DateTime fromDate,
      DateTime toDate,
      ) async {
    final ids      = <String>[];
    int   start    = 0;
    const pageSize = 1000;
    bool  hasMore  = true;

    while (hasMore) {
      final rows = await _client
          .from('sale_invoices')
          .select('id')
          .eq('store_id', branchId)
          .eq('status', 'completed')
          .isFilter('deleted_at', null)
          .gte('invoice_date', _fromStr(fromDate))
          .lte('invoice_date', _toStr(toDate))
          .range(start, start + pageSize - 1);

      final page = (rows as List).map((r) => r['id'].toString()).toList();
      ids.addAll(page);
      if (page.length < pageSize) hasMore = false;
      else start += pageSize;
    }
    return ids;
  }

  Future<List<String>> _fetchReturnIds(
      DateTime fromDate,
      DateTime toDate,
      ) async {
    final ids      = <String>[];
    int   start    = 0;
    const pageSize = 1000;
    bool  hasMore  = true;

    while (hasMore) {
      final rows = await _client
          .from('sale_returns')
          .select('id')
          .eq('store_id', branchId)
          .eq('status', 'completed')
          .isFilter('deleted_at', null)
          .gte('return_date', _fromStr(fromDate))
          .lte('return_date', _toStr(toDate))
          .range(start, start + pageSize - 1);

      final page = (rows as List).map((r) => r['id'].toString()).toList();
      ids.addAll(page);
      if (page.length < pageSize) hasMore = false;
      else start += pageSize;
    }
    return ids;
  }

  Future<double> _calcItemsProfit({
    required String       table,
    required String       fkColumn,
    required List<String> ids,
  }) async {
    if (ids.isEmpty) return 0.0;

    double profit = 0;
    int    start  = 0;
    const  batchSz = 1000;

    while (start < ids.length) {
      final batch = ids.skip(start).take(batchSz).toList();

      final rows = await _client
          .from(table)
          .select('sale_price, purchase_price, quantity, discount')
          .inFilter(fkColumn, batch);

      for (final r in (rows as List)) {
        final sp  = _dbl(r['sale_price'])     ?? 0;
        final pp  = _dbl(r['purchase_price'])  ?? 0;
        final qty = _dbl(r['quantity'])         ?? 0;
        final dis = _dbl(r['discount'])         ?? 0;
        profit += (sp - pp) * qty - dis;
      }

      if (batch.length < batchSz) break;
      start += batchSz;
    }
    return profit;
  }

  // ── 4. Inventory Value ───────────────────────────────────
  Future<double> _fetchInventoryValue() async {
    try {
      double total   = 0;
      int    start   = 0;
      const  pageSize = 1000;
      bool   hasMore = true;

      while (hasMore) {
        final rows = await _client
            .from('branch_stock_inventory')
            .select('stock, purchase_price')
            .eq('store_id', branchId)
            .range(start, start + pageSize - 1);

        final page = rows as List;
        for (final r in page) {
          total += (_dbl(r['stock']) ?? 0) * (_dbl(r['purchase_price']) ?? 0);
        }

        if (page.length < pageSize) hasMore = false;
        else start += pageSize;
      }
      return total;
    } catch (e) {
      print('❌ Inventory error: $e');
      return 0;
    }
  }

// ── 5. Outstanding Receivable ────────────────────────────
  Future<double> _fetchOutstandingReceivable() async {
    try {
      final rows = await _client
          .from('customer')
          .select('balance')
          .eq('store_id', branchId)
          .isFilter('deleted_at', null);

      double total = 0;
      for (final r in (rows as List)) {
        final bal = _dbl(r['balance']) ?? 0;
        if (bal > 0) total += bal;
      }
      return total;
    } catch (e) {
      print('❌ Outstanding error: $e');
      return 0;
    }
  }

  // ── Helper ───────────────────────────────────────────────
  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}

// ── Private helper class ──────────────────────────────────
class _CashCounterTotals {
  final double cashSale;
  final double cardSale;
  final double creditSale;
  final double totalSale;
  final double totalAmount;

  const _CashCounterTotals({
    required this.cashSale,
    required this.cardSale,
    required this.creditSale,
    required this.totalSale,
    required this.totalAmount,
  });
}