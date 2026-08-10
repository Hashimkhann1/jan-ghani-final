import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/pareto_report_model.dart';

class ParetoReportDatasource {
  final SupabaseClient _client;
  final String branchId;

  ParetoReportDatasource({
    required SupabaseClient client,
    required this.branchId,
  }) : _client = client;

  // ── 1. Product Sales ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchProductSales(
      DateTime startDate, DateTime endDate) async {
    final start = startDate.toIso8601String();
    final end   = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).toIso8601String();

    final rows = await _client
        .from('sale_invoice_items')
        .select(
      'product_id, product_name, sku, sale_price, purchase_price, quantity, total_amount, '
          'sale_invoices!inner(store_id, status, deleted_at, invoice_date)',
    )
        .eq('sale_invoices.store_id', branchId)
        .eq('sale_invoices.status', 'completed')
        .isFilter('sale_invoices.deleted_at', null)
        .gte('sale_invoices.invoice_date', start)
        .lte('sale_invoices.invoice_date', end);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ── 2. Return Items ──────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchReturnItems(
      DateTime startDate, DateTime endDate) async {
    final start = startDate.toIso8601String();
    final end   = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).toIso8601String();

    final rows = await _client
        .from('sale_return_items')
        .select(
      'product_id, sale_price, purchase_price, quantity, total_amount, '
          'sale_returns!inner(store_id, status, deleted_at, return_date)',
    )
        .eq('sale_returns.store_id', branchId)
        .eq('sale_returns.status', 'completed')
        .isFilter('sale_returns.deleted_at', null)
        .gte('sale_returns.return_date', start)
        .lte('sale_returns.return_date', end);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ── 3. Customer Sales ────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchCustomerSales(
      DateTime startDate, DateTime endDate) async {
    final start = startDate.toIso8601String();
    final end   = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).toIso8601String();

    final rows = await _client
        .from('sale_invoices')
        .select('customer_id, grand_total, customer!inner(name, phone)')
        .eq('store_id', branchId)
        .eq('status', 'completed')
        .isFilter('deleted_at', null)
        .not('customer_id', 'is', null)
        .gte('invoice_date', start)
        .lte('invoice_date', end);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ── 4. Customer Balance (date filter nahi — live balance hai) ──
  Future<List<Map<String, dynamic>>> _fetchCustomerBalances() async {
    final rows = await _client
        .from('customer')
        .select('id, name, phone, customer_type, balance, credit_limit')
        .eq('store_id', branchId)
        .isFilter('deleted_at', null)
        .gt('balance', 0)
        .order('balance', ascending: false);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ── Main Fetch ───────────────────────────────────────────
  Future<ParetoReportData> fetchParetoData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = await Future.wait([
      _fetchProductSales(startDate, endDate),
      _fetchReturnItems(startDate, endDate),
      _fetchCustomerSales(startDate, endDate),
      _fetchCustomerBalances(),
    ]);

    final saleItems   = results[0];
    final returnItems = results[1];
    final custSales   = results[2];
    final custBal     = results[3];

    // ── Aggregate Products ───────────────────────────────
    final Map<String, _ProductAgg> productMap = {};

    for (final row in saleItems) {
      final pid    = row['product_id'] as String;
      final name   = row['product_name'] as String? ?? '';
      final sku    = row['sku'] as String? ?? '';
      final saleP  = _d(row['sale_price']);
      final purchP = _d(row['purchase_price']);
      final qty    = _d(row['quantity']);
      final total  = _d(row['total_amount']);
      final profit = (saleP - purchP) * qty;

      productMap.update(
        pid,
            (v) => v.add(revenue: total, profit: profit, qty: qty),
        ifAbsent: () =>
            _ProductAgg(name: name, sku: sku, revenue: total, profit: profit, qty: qty),
      );
    }

    for (final row in returnItems) {
      final pid    = row['product_id'] as String;
      final saleP  = _d(row['sale_price']);
      final purchP = _d(row['purchase_price']);
      final qty    = _d(row['quantity']);
      final total  = _d(row['total_amount']);
      final profit = (saleP - purchP) * qty;

      if (productMap.containsKey(pid)) {
        productMap.update(
          pid,
              (v) => v.add(revenue: -total, profit: -profit, qty: -qty),
        );
      }
    }

    final sortedProducts = productMap.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));

    final totalRevenue = sortedProducts.fold(
        0.0, (s, e) => s + e.value.revenue.clamp(0, double.infinity));
    final totalProfit = sortedProducts.fold(
        0.0, (s, e) => s + e.value.profit.clamp(0, double.infinity));

    final top20ProductCount = (sortedProducts.length * 0.2).ceil();

    double cumRevenue = 0;
    double cumProfit  = 0;
    final allProducts = <ParetoProductModel>[];

    for (int i = 0; i < sortedProducts.length; i++) {
      final e = sortedProducts[i];
      cumRevenue += e.value.revenue.clamp(0, double.infinity);
      cumProfit  += e.value.profit.clamp(0, double.infinity);
      allProducts.add(ParetoProductModel(
        productId:    e.key,
        productName:  e.value.name,
        sku:          e.value.sku,
        totalRevenue: e.value.revenue,
        totalProfit:  e.value.profit,
        totalQty:     e.value.qty,
        revenueShare: totalRevenue > 0 ? cumRevenue / totalRevenue : 0,
        profitShare:  totalProfit  > 0 ? cumProfit  / totalProfit  : 0,
      ));
    }

    // Sirf top 20% return karo
    final paretoProducts = allProducts.take(top20ProductCount).toList();
    final paretoRevenue  = paretoProducts.fold(
        0.0, (s, p) => s + p.totalRevenue.clamp(0, double.infinity));
    final paretoProfit   = paretoProducts.fold(
        0.0, (s, p) => s + p.totalProfit.clamp(0, double.infinity));

    // ── Aggregate Customer Sales ─────────────────────────
    final Map<String, _CustomerSalesAgg> custSalesMap = {};
    for (final row in custSales) {
      final cid   = row['customer_id'] as String;
      final total = _d(row['grand_total']);
      final name  = (row['customer'] as Map<String, dynamic>?)?['name'] as String? ?? '';
      final phone = (row['customer'] as Map<String, dynamic>?)?['phone'] as String? ?? '';

      custSalesMap.update(
        cid,
            (v) => v.addSale(total),
        ifAbsent: () => _CustomerSalesAgg(name: name, phone: phone, total: total),
      );
    }

    final sortedCustSales = custSalesMap.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    final totalSalesAmt       = sortedCustSales.fold(0.0, (s, e) => s + e.value.total);
    final top20CustSalesCount = (sortedCustSales.length * 0.2).ceil();

    double cumSales = 0;
    final allSalesCustomers = <ParetoCustomerSalesModel>[];
    for (final e in sortedCustSales) {
      cumSales += e.value.total;
      allSalesCustomers.add(ParetoCustomerSalesModel(
        customerId:   e.key,
        customerName: e.value.name,
        phone:        e.value.phone,
        totalSales:   e.value.total,
        salesShare:   totalSalesAmt > 0 ? cumSales / totalSalesAmt : 0,
      ));
    }

    // Sirf top 20% return karo
    final paretoSalesCustomers = allSalesCustomers.take(top20CustSalesCount).toList();
    final paretoSalesAmt       = paretoSalesCustomers.fold(0.0, (s, c) => s + c.totalSales);

    // ── Customer Balance ─────────────────────────────────
    final totalBalAmt   = custBal.fold(0.0, (s, r) => s + _d(r['balance']));
    final top20BalCount = (custBal.length * 0.2).ceil();

    double cumBal = 0;
    final allBalCustomers = <ParetoCustomerBalanceModel>[];
    for (final row in custBal) {
      final bal = _d(row['balance']);
      cumBal += bal;
      allBalCustomers.add(ParetoCustomerBalanceModel(
        customerId:   row['id'] as String,
        customerName: row['name'] as String? ?? '',
        phone:        row['phone'] as String? ?? '',
        customerType: row['customer_type'] as String? ?? 'cash',
        balance:      bal,
        creditLimit:  _d(row['credit_limit']),
        balanceShare: totalBalAmt > 0 ? cumBal / totalBalAmt : 0,
      ));
    }

    // Sirf top 20% return karo
    final paretoBalCustomers = allBalCustomers.take(top20BalCount).toList();
    final paretoBalAmt       = paretoBalCustomers.fold(0.0, (s, c) => s + c.balance);

    // ── Summary ──────────────────────────────────────────
    final summary = ParetoReportSummary(
      totalProducts:              allProducts.length,
      paretoProductCount:         paretoProducts.length,
      paretoRevenue:              paretoRevenue,
      paretoProfit:               paretoProfit,
      totalRevenue:               totalRevenue,
      totalProfit:                totalProfit,
      totalSalesCustomers:        allSalesCustomers.length,
      paretoSalesCustomerCount:   paretoSalesCustomers.length,
      paretoSalesAmount:          paretoSalesAmt,
      totalSalesAmount:           totalSalesAmt,
      totalBalanceCustomers:      allBalCustomers.length,
      paretoBalanceCustomerCount: paretoBalCustomers.length,
      paretoBalanceAmount:        paretoBalAmt,
      totalBalanceAmount:         totalBalAmt,
    );

    return ParetoReportData(
      products:         paretoProducts,        // ← sirf TOP 20%
      salesCustomers:   paretoSalesCustomers,  // ← sirf TOP 20%
      balanceCustomers: paretoBalCustomers,    // ← sirf TOP 20%
      summary:          summary,
    );
  }

  double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
}

class _ProductAgg {
  final String name;
  final String sku;
  double revenue;
  double profit;
  double qty;

  _ProductAgg({
    required this.name,
    required this.sku,
    required this.revenue,
    required this.profit,
    required this.qty,
  });

  _ProductAgg add({required double revenue, required double profit, required double qty}) {
    this.revenue += revenue;
    this.profit  += profit;
    this.qty     += qty;
    return this;
  }
}

class _CustomerSalesAgg {
  final String name;
  final String phone;
  double total;

  _CustomerSalesAgg({required this.name, required this.phone, required this.total});

  _CustomerSalesAgg addSale(double amount) {
    total += amount;
    return this;
  }
}