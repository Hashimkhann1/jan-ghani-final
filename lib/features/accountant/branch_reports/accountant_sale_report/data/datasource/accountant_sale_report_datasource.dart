import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../model/accountant_sale_report_model.dart';

class AccountantSaleReportDatasource {
  final _client = Supabase.instance.client;
  final String  branchId;

  AccountantSaleReportDatasource({required this.branchId});

  // ── Get Customers for dropdown ────────────────────────────
  Future<List<CustomerOption>> getCustomers() async {
    final result = await _client
        .from('customer')
        .select('id, name, code')
        .eq('is_active', true)
        .order('name');

    return (result as List)
        .map((r) => CustomerOption(
      id:   r['id'].toString(),
      name: r['name']?.toString() ?? '',
      code: r['code']?.toString(),
    ))
        .toList();
  }

  // ── Get one page of the report (20 rows) ───────────────────
  Future<PagedSaleReport> getReportPage({
    required DateTime fromDate,
    required DateTime toDate,
    required int      page,
    String?           customerId,
    String?           paymentType,
  }) async {
    var query = _client
        .from('sale_invoices')
        .select('''
          id, invoice_no, invoice_date,
          total_amount, total_discount, grand_total,
          status, customer_id, deleted_at,
          previous_amount, new_amount, pay_amount, paid_amount,
          customer (name),
          sale_invoice_payments (payment_method, amount),
          sale_invoice_items (
            product_name, sku, sale_price,
            purchase_price, quantity, discount, total_amount
          )
        ''')
        .eq('store_id', branchId)
        .eq('status', 'completed')
        .gte('invoice_date', fromDate.toIso8601String())
        .lte('invoice_date', toDate.toIso8601String());

    if (customerId != null && customerId.isNotEmpty) {
      query = query.eq('customer_id', customerId);
    }

    // Payment type is stored per-payment, so filtering it server-side
    // alongside range-based pagination isn't reliable — until that
    // column exists on sale_invoices, payment type stays a client-side
    // filter applied to the fetched page below.
    final (start, end) = BranchReportPagination.range(page);
    final result = await query
        .order('invoice_date', ascending: false)
        .range(start, end);

    var invoices = (result as List)
        .where((r) => r['deleted_at'] == null)
        .map(_mapInvoice)
        .toList();

    final hasNextPage = BranchReportPagination.hasNextPage(
        (result).length);

    if (paymentType != null) {
      invoices = invoices
          .where((inv) => inv.paymentMethods.contains(paymentType))
          .toList();
    }

    return PagedSaleReport(invoices: invoices, hasNextPage: hasNextPage);
  }

  // ── Get aggregate totals across every matching invoice ─────
  // Kept separate from getReportPage so the summary cards still reflect
  // the whole filtered date range, not just the 20 rows on screen.
  Future<SaleReportSummary> getReportSummary({
    required DateTime fromDate,
    required DateTime toDate,
    String?           customerId,
    String?           paymentType,
  }) async {
    int    totalInvoices = 0;
    double totalSale     = 0;
    double totalQuantity = 0;
    double totalDiscount = 0;

    int   rangeStart = 0;
    const int pageSize = 1000;
    bool  hasMore = true;

    while (hasMore) {
      var query = _client
          .from('sale_invoices')
          .select('''
          grand_total, total_discount, deleted_at,
          sale_invoice_payments (payment_method),
          sale_invoice_items (quantity)
        ''')
          .eq('store_id', branchId)
          .eq('status', 'completed')
          .gte('invoice_date', fromDate.toIso8601String())
          .lte('invoice_date', toDate.toIso8601String());

      if (customerId != null && customerId.isNotEmpty) {
        query = query.eq('customer_id', customerId);
      }

      final result = await query
          .order('invoice_date', ascending: false)
          .range(rangeStart, rangeStart + pageSize - 1);

      final rows = (result as List)
          .where((r) => r['deleted_at'] == null)
          .where((r) {
        if (paymentType == null) return true;
        final methods = (r['sale_invoice_payments'] as List? ?? [])
            .map((p) => p['payment_method']?.toString() ?? '');
        return methods.contains(paymentType);
      });

      for (final r in rows) {
        totalInvoices++;
        totalSale     += _dbl(r['grand_total'])   ?? 0;
        totalDiscount += _dbl(r['total_discount']) ?? 0;
        totalQuantity += (r['sale_invoice_items'] as List? ?? [])
            .fold<double>(0, (s, i) => s + (_dbl(i['quantity']) ?? 0));
      }

      if ((result).length < pageSize) {
        hasMore = false;
      } else {
        rangeStart += pageSize;
      }
    }

    return SaleReportSummary(
      totalInvoices: totalInvoices,
      totalSale:     totalSale,
      totalQuantity: totalQuantity,
      totalDiscount: totalDiscount,
    );
  }

  SaleReportInvoice _mapInvoice(dynamic r) {
    final payments = (r['sale_invoice_payments'] as List? ?? []);
    final methods  = payments
        .map((p) => p['payment_method']?.toString() ?? '')
        .toSet()
        .toList();

    final items = (r['sale_invoice_items'] as List? ?? [])
        .map((i) => SaleReportItem(
      productName:   i['product_name']?.toString() ?? '',
      sku:           i['sku']?.toString(),
      salePrice:     _dbl(i['sale_price'])          ?? 0,
      purchasePrice: _dbl(i['purchase_price'])      ?? 0,
      quantity:      _dbl(i['quantity'])            ?? 0,
      discount:      _dbl(i['discount'])             ?? 0,
      totalAmount:   _dbl(i['total_amount'])        ?? 0,
    ))
        .toList();

    final customerName = r['customer'] != null
        ? r['customer']['name']?.toString()
        : null;

    return SaleReportInvoice(
      id:             r['id'].toString(),
      invoiceNo:      r['invoice_no']?.toString()  ?? '',
      invoiceDate:    DateTime.parse(
          r['invoice_date'].toString())
          .toLocal(),
      customerName:   customerName,
      customerId:     r['customer_id']?.toString(),
      totalAmount:    _dbl(r['total_amount'])       ?? 0,
      totalDiscount:  _dbl(r['total_discount'])     ?? 0,
      grandTotal:     _dbl(r['grand_total'])        ?? 0,
      status:         r['status']?.toString()       ?? '',
      paymentMethods: methods,
      items:          items,
      previousAmount: _dbl(r['previous_amount'])    ?? 0,
      newAmount:      _dbl(r['new_amount'])          ?? 0,
      payAmount:      _dbl(r['pay_amount'])          ?? 0,
      paidAmount:     _dbl(r['paid_amount'])         ?? 0,
    );
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}