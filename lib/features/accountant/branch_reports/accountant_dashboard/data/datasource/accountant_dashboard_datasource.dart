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
  // fromDate/toDate ab exact time bhi carry karte hain (time filter),
  // is liye yahan din ki shuruaat/aakhir force nahi ki jaati.
  static String _fromStr(DateTime d) => d.toUtc().toIso8601String();

  static String _toStr(DateTime d) => d.toUtc().toIso8601String();

  // ── Main method ──────────────────────────────────────────
  Future<AccountantBranchDashboardModel> getDashboard({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final sales       = await _fetchSalesBreakdown(fromDate, toDate);
    final installment = await _fetchInstallmentSale(fromDate, toDate);
    final returnAmt   = await _fetchSaleReturns(fromDate, toDate);
    final profit      = await _fetchGrossProfit(fromDate, toDate);
    final stock       = await _fetchStockValue();
    final cash        = await _fetchCashInOut(fromDate, toDate);
    final damage      = await _fetchDamage(fromDate, toDate);
    final outstanding = await _fetchOutstandingReceivable();

    return AccountantBranchDashboardModel(
      totalSale:             sales.totalSale,
      cashSale:              sales.cashSale,
      cardSale:              sales.cardSale,
      creditSale:            sales.creditSale,
      installmentSale:       installment,
      // Actual cash/card/ledger collections during the window — excludes
      // credit sale since that's unpaid (added to customer balance).
      totalAmountReceived:   sales.cashSale + sales.cardSale + installment,
      totalSaleReturn:       returnAmt,
      netSale:               sales.totalSale - returnAmt,
      grossProfit:           profit,
      inventoryValue:        stock.purchaseValue,
      stockSaleValue:        stock.saleValue,
      cashIn:                cash.cashIn,
      cashOut:               cash.cashOut,
      totalDamage:           damage,
      outstandingReceivable: outstanding,
    );
  }

  // ── 1. Sales breakdown (cash / card / credit / total) ────
  // sale_invoices.invoice_date ek real timestamp hai, is liye yahan
  // exact date+time range respect hoti hai (branch_cash_counter ke
  // ulat, jo sirf date-level closing row hai).
  Future<_SalesBreakdown> _fetchSalesBreakdown(
      DateTime fromDate,
      DateTime toDate,
      ) async {
    double cashSale = 0, cardSale = 0, creditSale = 0, totalSale = 0;
    int    start    = 0;
    const  pageSize = 1000;
    bool   hasMore  = true;

    while (hasMore) {
      final rows = await _client
          .from('sale_invoices')
          .select('grand_total, sale_invoice_payments (payment_method, amount)')
          .eq('store_id', branchId)
          .eq('status', 'completed')
          .isFilter('deleted_at', null)
          .gte('invoice_date', _fromStr(fromDate))
          .lte('invoice_date', _toStr(toDate))
          .range(start, start + pageSize - 1);

      final page = rows as List;
      for (final r in page) {
        totalSale += _dbl(r['grand_total']) ?? 0;
        final payments = (r['sale_invoice_payments'] as List? ?? []);
        for (final p in payments) {
          final amt = _dbl(p['amount']) ?? 0;
          switch (p['payment_method']?.toString()) {
            case 'cash':
              cashSale += amt;
              break;
            case 'card':
              cardSale += amt;
              break;
            case 'credit':
              creditSale += amt;
              break;
          }
        }
      }

      if (page.length < pageSize) hasMore = false;
      else start += pageSize;
    }

    return _SalesBreakdown(
      cashSale:   cashSale,
      cardSale:   cardSale,
      creditSale: creditSale,
      totalSale:  totalSale,
    );
  }

  // ── 1b. Installment sale (customer ledger collections) ───
  // "Installment" branch_cash_counter mein customer_ledger se trigger
  // ke zariye aata hai (extra/ledger payments). customer_ledger mein
  // real created_at timestamp hai, is liye yahan seedha wahi se sum
  // karte hain — ab yeh time filter ko sahi respect karta hai.
  Future<double> _fetchInstallmentSale(
      DateTime fromDate,
      DateTime toDate,
      ) async {
    double total   = 0;
    int    start   = 0;
    const  pageSize = 1000;
    bool   hasMore = true;

    while (hasMore) {
      final rows = await _client
          .from('customer_ledger')
          .select('pay_amount')
          .eq('store_id', branchId)
          .isFilter('deleted_at', null)
          .gte('created_at', _fromStr(fromDate))
          .lte('created_at', _toStr(toDate))
          .range(start, start + pageSize - 1);

      final page = rows as List;
      for (final r in page) {
        total += _dbl(r['pay_amount']) ?? 0;
      }

      if (page.length < pageSize) hasMore = false;
      else start += pageSize;
    }
    return total;
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
  // Items seedha unke parent invoice/return se JOIN karke date-filter
  // karte hain (PostgREST embedded-resource filter). Pehle invoice ids
  // fetch karke phir inFilter(1000 ids) karte the — us se URL 37,000+
  // characters ka ban jata tha aur Supabase gateway 400 Bad Request
  // deta tha jab date range mein invoices zyada hote (e.g. 9000+).
  Future<double> _fetchGrossProfit(
      DateTime fromDate,
      DateTime toDate,
      ) async {
    final saleProfit = await _sumItemsProfit(
      itemsTable:  'sale_invoice_items',
      parentTable: 'sale_invoices',
      dateColumn:  'invoice_date',
      fromDate:    fromDate,
      toDate:      toDate,
    );

    final returnProfit = await _sumItemsProfit(
      itemsTable:  'sale_return_items',
      parentTable: 'sale_returns',
      dateColumn:  'return_date',
      fromDate:    fromDate,
      toDate:      toDate,
    );

    return saleProfit - returnProfit;
  }

  Future<double> _sumItemsProfit({
    required String   itemsTable,
    required String   parentTable,
    required String   dateColumn,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    double profit   = 0;
    int    start    = 0;
    const  pageSize = 1000;
    bool   hasMore  = true;

    while (hasMore) {
      final rows = await _client
          .from(itemsTable)
          .select('sale_price, purchase_price, quantity, discount, '
              '$parentTable!inner(id)')
          .eq('$parentTable.store_id', branchId)
          .eq('$parentTable.status', 'completed')
          .isFilter('$parentTable.deleted_at', null)
          .gte('$parentTable.$dateColumn', _fromStr(fromDate))
          .lte('$parentTable.$dateColumn', _toStr(toDate))
          .range(start, start + pageSize - 1);

      final page = rows as List;
      for (final r in page) {
        final sp  = _dbl(r['sale_price'])     ?? 0;
        final pp  = _dbl(r['purchase_price']) ?? 0;
        final qty = _dbl(r['quantity'])       ?? 0;
        final dis = _dbl(r['discount'])       ?? 0;
        profit += (sp - pp) * qty - dis;
      }

      if (page.length < pageSize) hasMore = false;
      else start += pageSize;
    }
    return profit;
  }

  // ── 4. Stock Value (purchase + sale) ─────────────────────
  Future<_StockValue> _fetchStockValue() async {
    try {
      double purchaseValue = 0, saleValue = 0;
      int    start   = 0;
      const  pageSize = 1000;
      bool   hasMore = true;

      while (hasMore) {
        final rows = await _client
            .from('branch_stock_inventory')
            .select('stock, purchase_price, sale_price')
            .eq('store_id', branchId)
            .range(start, start + pageSize - 1);

        final page = rows as List;
        for (final r in page) {
          final stock = _dbl(r['stock']) ?? 0;
          purchaseValue += stock * (_dbl(r['purchase_price']) ?? 0);
          saleValue     += stock * (_dbl(r['sale_price'])     ?? 0);
        }

        if (page.length < pageSize) hasMore = false;
        else start += pageSize;
      }
      return _StockValue(purchaseValue: purchaseValue, saleValue: saleValue);
    } catch (e) {
      print('❌ Inventory error: $e');
      return const _StockValue(purchaseValue: 0, saleValue: 0);
    }
  }

  // ── 4b. Cash In / Cash Out ────────────────────────────────
  Future<_CashInOut> _fetchCashInOut(
      DateTime fromDate,
      DateTime toDate,
      ) async {
    try {
      double cashIn = 0, cashOut = 0;
      int    start   = 0;
      const  pageSize = 1000;
      bool   hasMore = true;

      while (hasMore) {
        final rows = await _client
            .from('branch_cash_transaction')
            .select('transaction_type, cash_out_amount')
            .eq('store_id', branchId)
            .isFilter('deleted_at', null)
            .gte('created_at', _fromStr(fromDate))
            .lte('created_at', _toStr(toDate))
            .range(start, start + pageSize - 1);

        final page = rows as List;
        for (final r in page) {
          final amount = _dbl(r['cash_out_amount']) ?? 0;
          if (r['transaction_type'] == 'cash_in') {
            cashIn += amount;
          } else {
            cashOut += amount;
          }
        }

        if (page.length < pageSize) hasMore = false;
        else start += pageSize;
      }
      return _CashInOut(cashIn: cashIn, cashOut: cashOut);
    } catch (e) {
      print('❌ Cash In/Out error: $e');
      return const _CashInOut(cashIn: 0, cashOut: 0);
    }
  }

  // ── 4c. Stock Damage ──────────────────────────────────────
  Future<double> _fetchDamage(DateTime fromDate, DateTime toDate) async {
    try {
      double total   = 0;
      int    start   = 0;
      const  pageSize = 1000;
      bool   hasMore = true;

      while (hasMore) {
        final rows = await _client
            .from('branch_stock_damage')
            .select('stock_damage, purchase_price')
            .eq('store_id', branchId)
            .gte('created_at', _fromStr(fromDate))
            .lte('created_at', _toStr(toDate))
            .range(start, start + pageSize - 1);

        final page = rows as List;
        for (final r in page) {
          total += (_dbl(r['stock_damage']) ?? 0) * (_dbl(r['purchase_price']) ?? 0);
        }

        if (page.length < pageSize) hasMore = false;
        else start += pageSize;
      }
      return total;
    } catch (e) {
      print('❌ Damage error: $e');
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
class _SalesBreakdown {
  final double cashSale;
  final double cardSale;
  final double creditSale;
  final double totalSale;

  const _SalesBreakdown({
    required this.cashSale,
    required this.cardSale,
    required this.creditSale,
    required this.totalSale,
  });
}

class _StockValue {
  final double purchaseValue;
  final double saleValue;

  const _StockValue({required this.purchaseValue, required this.saleValue});
}

class _CashInOut {
  final double cashIn;
  final double cashOut;

  const _CashInOut({required this.cashIn, required this.cashOut});
}