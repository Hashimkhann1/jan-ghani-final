import 'package:supabase_flutter/supabase_flutter.dart';

/// Tumhare actual store_db ke mutabiq Supabase Service
/// Tables: sale_invoices, branch_expense, branch_stock_inventory,
///         branch_summary, customer, sale_returns, branch_stock_damage
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── Helper: store_id filter ──────────────────────────────
  // Agar ek hi store hai to yeh null rakho, multi-store mein pass karo
  final String? storeId; // e.g. '43e7ccf1-c6a0-4fcd-ae81-4a5e9387a8a5'
  SupabaseService({this.storeId});

  PostgrestFilterBuilder _storeFilter(
      PostgrestFilterBuilder q, String col) {
    if (storeId != null) return q.eq(col, storeId!);
    return q;
  }

  // ══════════════════════════════════════════════════════════
  //  SALES — sale_invoices + sale_invoice_items
  // ══════════════════════════════════════════════════════════

  /// Total sales amount (grand_total) with optional date range
  Future<Map<String, dynamic>> getSalesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var q = _client
        .from('sale_invoices')
        .select('grand_total, total_discount, invoice_date, status')
        .neq('status', 'cancelled');

    if (storeId != null) q = q.eq('store_id', storeId!);
    if (startDate != null) q = q.gte('invoice_date', startDate.toIso8601String());
    if (endDate != null) q = q.lte('invoice_date', endDate.toIso8601String());

    final rows = List<Map<String, dynamic>>.from(await q);

    double totalRevenue = 0;
    double totalDiscount = 0;
    int invoiceCount = 0;

    for (final r in rows) {
      totalRevenue  += (r['grand_total']     ?? 0).toDouble();
      totalDiscount += (r['total_discount']  ?? 0).toDouble();
      invoiceCount++;
    }

    return {
      'total_revenue'  : totalRevenue,
      'total_discount' : totalDiscount,
      'invoice_count'  : invoiceCount,
      'avg_invoice'    : invoiceCount > 0 ? totalRevenue / invoiceCount : 0,
    };
  }

  /// Top selling products from sale_invoice_items
  Future<List<Map<String, dynamic>>> getTopProducts({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    // Join invoice_items with invoices to get date
    var q = _client
        .from('sale_invoice_items')
        .select('product_name, quantity, total_amount, purchase_price, sale_invoices!inner(invoice_date, store_id, status)')
        .neq('sale_invoices.status', 'cancelled');

    if (storeId != null) q = q.eq('sale_invoices.store_id', storeId!);
    if (startDate != null) q = q.gte('sale_invoices.invoice_date', startDate.toIso8601String());
    if (endDate != null)   q = q.lte('sale_invoices.invoice_date', endDate.toIso8601String());

    final rows = List<Map<String, dynamic>>.from(await q);

    // Group by product name
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final r in rows) {
      final name = r['product_name'] as String? ?? 'Unknown';
      final qty   = (r['quantity']     ?? 0).toDouble();
      final amt   = (r['total_amount'] ?? 0).toDouble();
      final cost  = (r['purchase_price'] ?? 0).toDouble() * qty;

      if (grouped.containsKey(name)) {
        grouped[name]!['total_qty']    = (grouped[name]!['total_qty'] as double) + qty;
        grouped[name]!['total_sales']  = (grouped[name]!['total_sales'] as double) + amt;
        grouped[name]!['total_cost']   = (grouped[name]!['total_cost']  as double) + cost;
        grouped[name]!['count']        = (grouped[name]!['count'] as int) + 1;
      } else {
        grouped[name] = {
          'product_name': name,
          'total_qty'   : qty,
          'total_sales' : amt,
          'total_cost'  : cost,
          'count'       : 1,
        };
      }
    }

    // Add profit per product
    for (final k in grouped.keys) {
      final sales = grouped[k]!['total_sales'] as double;
      final cost  = grouped[k]!['total_cost']  as double;
      grouped[k]!['gross_profit'] = sales - cost;
    }

    final result = grouped.values.toList()
      ..sort((a, b) => (b['total_sales'] as double).compareTo(a['total_sales'] as double));

    return result.take(limit).toList();
  }

  /// Sales by payment method (cash / card / credit)
  Future<Map<String, double>> getSalesByPaymentMethod({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var q = _client
        .from('sale_invoice_payments')
        .select('payment_method, amount, sale_invoices!inner(invoice_date, status)')
        .neq('sale_invoices.status', 'cancelled');

    if (storeId != null) q = q.eq('store_id', storeId!);
    if (startDate != null) q = q.gte('sale_invoices.invoice_date', startDate.toIso8601String());
    if (endDate != null)   q = q.lte('sale_invoices.invoice_date', endDate.toIso8601String());

    final rows = List<Map<String, dynamic>>.from(await q);
    final Map<String, double> result = {'cash': 0, 'card': 0, 'credit': 0};

    for (final r in rows) {
      final method = r['payment_method'] as String? ?? 'cash';
      result[method] = (result[method] ?? 0) + (r['amount'] ?? 0).toDouble();
    }
    return result;
  }

  // ══════════════════════════════════════════════════════════
  //  EXPENSES — branch_expense
  // ══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getExpensesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var q = _client
        .from('branch_expense')
        .select('amount, expense_head, created_at')
        .filter('deleted_at', 'is', null);

    if (storeId != null) q = q.eq('store_id', storeId!);
    if (startDate != null) q = q.gte('created_at', startDate.toIso8601String());
    if (endDate != null)   q = q.lte('created_at', endDate.toIso8601String());

    final rows = List<Map<String, dynamic>>.from(await q);

    double total = 0;
    final Map<String, double> byCategory = {};

    for (final r in rows) {
      final amt  = (r['amount'] ?? 0).toDouble();
      final head = r['expense_head'] as String? ?? 'Other';
      total += amt;
      byCategory[head] = (byCategory[head] ?? 0) + amt;
    }

    final breakdown = byCategory.entries
        .map((e) => {'category': e.key, 'amount': e.value})
        .toList()
      ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    return {
      'total_expenses' : total,
      'count'          : rows.length,
      'breakdown'      : breakdown,
    };
  }

  // ══════════════════════════════════════════════════════════
  //  BRANCH SUMMARY — branch_summary (daily aggregated table)
  // ══════════════════════════════════════════════════════════

  /// Aaj ka summary (already aggregated by DB triggers)
  Future<Map<String, dynamic>> getTodaySummary() async {
    var q = _client
        .from('branch_summary')
        .select('*')
        .eq('counter_date', DateTime.now().toIso8601String().substring(0, 10));

    if (storeId != null) q = q.eq('store_id', storeId!);

    final rows = List<Map<String, dynamic>>.from(await q);
    if (rows.isEmpty) return {};

    // Aggregate across counters if multiple
    double cashSale = 0, cardSale = 0, creditSale = 0,
        totalSale = 0, totalExpense = 0, totalAmount = 0,
        totalInstallment = 0;

    for (final r in rows) {
      cashSale        += (r['total_cash_sale']   ?? 0).toDouble();
      cardSale        += (r['total_card_sale']   ?? 0).toDouble();
      creditSale      += (r['total_credit_sale'] ?? 0).toDouble();
      totalSale       += (r['total_sale']        ?? 0).toDouble();
      totalExpense    += (r['total_expense']     ?? 0).toDouble();
      totalAmount     += (r['total_amount']      ?? 0).toDouble();
      totalInstallment+= (r['total_installment'] ?? 0).toDouble();
    }

    return {
      'date'             : DateTime.now().toIso8601String().substring(0, 10),
      'cash_sale'        : cashSale,
      'card_sale'        : cardSale,
      'credit_sale'      : creditSale,
      'total_sale'       : totalSale,
      'total_expense'    : totalExpense,
      'installment'      : totalInstallment,
      'net_cash_in_hand' : totalAmount,
    };
  }

  /// Date range ke liye branch_summary
  Future<Map<String, dynamic>> getSummaryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    var q = _client
        .from('branch_summary')
        .select('*')
        .gte('counter_date', startDate.toIso8601String().substring(0, 10))
        .lte('counter_date', endDate.toIso8601String().substring(0, 10));

    if (storeId != null) q = q.eq('store_id', storeId!);

    final rows = List<Map<String, dynamic>>.from(await q);

    double cashSale = 0, cardSale = 0, creditSale = 0,
        totalSale = 0, totalExpense = 0, totalInstallment = 0;

    for (final r in rows) {
      cashSale        += (r['total_cash_sale']   ?? 0).toDouble();
      cardSale        += (r['total_card_sale']   ?? 0).toDouble();
      creditSale      += (r['total_credit_sale'] ?? 0).toDouble();
      totalSale       += (r['total_sale']        ?? 0).toDouble();
      totalExpense    += (r['total_expense']     ?? 0).toDouble();
      totalInstallment+= (r['total_installment'] ?? 0).toDouble();
    }

    final netProfit = totalSale - totalExpense;

    return {
      'period'            : '${startDate.toIso8601String().substring(0,10)} → ${endDate.toIso8601String().substring(0,10)}',
      'total_revenue'     : totalSale,
      'cash_sale'         : cashSale,
      'card_sale'         : cardSale,
      'credit_sale'       : creditSale,
      'total_expense'     : totalExpense,
      'total_installment' : totalInstallment,
      'net_profit'        : netProfit,
      'profit_margin_pct' : totalSale > 0 ? (netProfit / totalSale * 100) : 0,
      'is_profitable'     : netProfit >= 0,
      'days_count'        : rows.length,
    };
  }

  // ══════════════════════════════════════════════════════════
  //  STOCK INVENTORY — branch_stock_inventory
  // ══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getStockSummary() async {
    var q = _client
        .from('branch_stock_inventory')
        .select('product_name, stock, min_stock, sale_price, purchase_price, unit')
        .isFilter('deleted_at', null);

    if (storeId != null) q = q.eq('store_id', storeId!);

    final rows = List<Map<String, dynamic>>.from(await q);

    final lowStock = rows.where((r) {
      final stock    = (r['stock']     ?? 0).toDouble();
      final minStock = (r['min_stock'] ?? 0).toDouble();
      return stock <= minStock && minStock > 0;
    }).toList();

    final outOfStock = rows.where((r) => (r['stock'] ?? 0).toDouble() <= 0).toList();

    double totalStockValue = 0;
    for (final r in rows) {
      totalStockValue += (r['stock'] ?? 0).toDouble() *
          (r['purchase_price'] ?? 0).toDouble();
    }

    return {
      'total_products'  : rows.length,
      'low_stock_count' : lowStock.length,
      'out_of_stock'    : outOfStock.length,
      'total_stock_value': totalStockValue,
      'low_stock_items' : lowStock
          .take(10)
          .map((r) => {
        'name'     : r['product_name'],
        'stock'    : r['stock'],
        'min_stock': r['min_stock'],
        'unit'     : r['unit'] ?? '',
      })
          .toList(),
      'out_of_stock_items': outOfStock
          .take(10)
          .map((r) => {'name': r['product_name'], 'unit': r['unit'] ?? ''})
          .toList(),
    };
  }

  // ══════════════════════════════════════════════════════════
  //  CUSTOMERS — customer + customer_ledger
  // ══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getCustomerSummary() async {
    var q = _client
        .from('customer')
        .select('name, balance, customer_type, is_active')
        .filter('deleted_at', 'is', null);

    if (storeId != null) q = q.eq('store_id', storeId!);

    final rows = List<Map<String, dynamic>>.from(await q);

    double totalCredit = 0;
    int creditCustomers = 0;
    final topDebtors = <Map<String, dynamic>>[];

    for (final r in rows) {
      final bal = (r['balance'] ?? 0).toDouble();
      if (bal > 0) {
        totalCredit += bal;
        creditCustomers++;
        topDebtors.add({'name': r['name'], 'balance': bal});
      }
    }

    topDebtors.sort((a, b) =>
        (b['balance'] as double).compareTo(a['balance'] as double));

    return {
      'total_customers'   : rows.length,
      'credit_customers'  : creditCustomers,
      'total_receivable'  : totalCredit,
      'top_debtors'       : topDebtors.take(5).toList(),
    };
  }

  // ══════════════════════════════════════════════════════════
  //  RETURNS — sale_returns + sale_return_items
  // ══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getReturnsSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var q = _client
        .from('sale_returns')
        .select('grand_total, refund_type, created_at');

    if (storeId != null) q = q.eq('store_id', storeId!);
    if (startDate != null) q = q.gte('created_at', startDate.toIso8601String());
    if (endDate != null)   q = q.lte('created_at', endDate.toIso8601String());

    final rows = List<Map<String, dynamic>>.from(await q);
    double totalReturns = 0;
    for (final r in rows) {
      totalReturns += (r['grand_total'] ?? 0).toDouble();
    }

    return {
      'total_returns_amount': totalReturns,
      'returns_count'       : rows.length,
    };
  }

  // ══════════════════════════════════════════════════════════
  //  DAMAGE — branch_stock_damage
  // ══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getDamageSummary() async {
    var q = _client
        .from('branch_stock_damage')
        .select('product_name, stock_damage, sale_price, purchase_price, created_at');

    if (storeId != null) q = q.eq('store_id', storeId!);

    final rows = List<Map<String, dynamic>>.from(await q);
    double totalDamageValue = 0;
    double totalDamageQty   = 0;

    for (final r in rows) {
      final qty  = (r['stock_damage']   ?? 0).toDouble();
      final cost = (r['purchase_price'] ?? 0).toDouble();
      totalDamageValue += qty * cost;
      totalDamageQty   += qty;
    }

    return {
      'total_damage_qty'  : totalDamageQty,
      'total_damage_value': totalDamageValue,
      'damage_records'    : rows.length,
    };
  }

  // ══════════════════════════════════════════════════════════
  //  PROFIT & LOSS — Complete P&L
  // ══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getProfitAndLoss({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end   = endDate   ?? now;

    // Use branch_summary for fast aggregation
    final summary  = await getSummaryByDateRange(startDate: start, endDate: end);
    final returns  = await getReturnsSummary(startDate: start, endDate: end);
    final expenses = await getExpensesSummary(startDate: start, endDate: end);
    final topProds = await getTopProducts(startDate: start, endDate: end, limit: 5);
    final payments = await getSalesByPaymentMethod(startDate: start, endDate: end);

    final grossRevenue  = (summary['total_revenue'] ?? 0).toDouble();
    final returnsAmt    = (returns['total_returns_amount'] ?? 0).toDouble();
    final netRevenue    = grossRevenue - returnsAmt;
    final totalExpenses = (summary['total_expense'] ?? 0).toDouble();
    final netProfit     = netRevenue - totalExpenses;
    final margin        = netRevenue > 0 ? (netProfit / netRevenue * 100) : 0.0;

    return {
      'period'           : summary['period'],
      'gross_revenue'    : grossRevenue,
      'total_returns'    : returnsAmt,
      'net_revenue'      : netRevenue,
      'total_expenses'   : totalExpenses,
      'expense_breakdown': expenses['breakdown'],
      'net_profit'       : netProfit,
      'profit_margin_pct': margin,
      'is_profitable'    : netProfit >= 0,
      'payment_breakdown': payments,
      'top_products'     : topProds,
      'cash_sale'        : summary['cash_sale'],
      'card_sale'        : summary['card_sale'],
      'credit_sale'      : summary['credit_sale'],
      'installments'     : summary['total_installment'],
    };
  }

  // ══════════════════════════════════════════════════════════
  //  COMPLETE BUSINESS SNAPSHOT (for AI context)
  // ══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getBusinessSnapshot({
    String period = 'this_month', // 'today' | 'this_month' | 'this_year'
  }) async {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (period) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'this_year':
        start = DateTime(now.year, 1, 1);
        break;
      default: // this_month
        start = DateTime(now.year, now.month, 1);
    }

    final today    = await getTodaySummary();
    final pl       = await getProfitAndLoss(startDate: start, endDate: end);
    final stock    = await getStockSummary();
    final customers= await getCustomerSummary();
    final damage   = await getDamageSummary();

    return {
      'today_snapshot'    : today,
      'profit_and_loss'   : pl,
      'stock_status'      : stock,
      'customer_summary'  : customers,
      'damage_summary'    : damage,
      'report_period'     : period,
    };
  }
}