import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../model/sale_return_report_model.dart';

class AccountantSaleReturnDatasource {
  final _client = Supabase.instance.client;
  final String  branchId;

  AccountantSaleReturnDatasource({required this.branchId});

  // ── Customers dropdown ────────────────────────────────────
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

  // ── Get one page of the return report (20 rows) ────────────
  Future<PagedSaleReturnReport> getReportPage({
    required DateTime fromDate,
    required DateTime toDate,
    required int      page,
    String?           customerId,
    String?           refundType,
  }) async {
    var query = _client
        .from('sale_returns')
        .select('''
          id, return_no, return_date,
          customer_id, invoice_id,
          total_amount, total_discount, grand_total,
          status, return_reason, refund_type,
          deleted_at,
          customer (name),
          sale_return_payments (payment_method, amount),
          sale_return_items (
            product_name, sku, sale_price,
            purchase_price, quantity, discount, total_amount
          )
        ''')
        .eq('store_id', branchId)
        .eq('status', 'completed')
        .gte('return_date', fromDate.toIso8601String())
        .lte(
      'return_date',
      DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59)
          .toIso8601String(),
    );

    if (customerId != null && customerId.isNotEmpty) {
      query = query.eq('customer_id', customerId);
    }

    // refund_type isn't filterable server-side against a stable column
    // set here, so — same as before — it's applied client-side to the
    // fetched page below.
    final (start, end) = BranchReportPagination.range(page);
    final result = await query
        .order('return_date', ascending: false)
        .range(start, end);

    var returns = (result as List)
        .where((r) => r['deleted_at'] == null)
        .map(_mapReturn)
        .toList();

    final hasNextPage = BranchReportPagination.hasNextPage(
        (result).length);

    if (refundType != null) {
      returns = returns
          .where((r) => r.refundType == refundType)
          .toList();
    }

    return PagedSaleReturnReport(
        returns: returns, hasNextPage: hasNextPage);
  }

  // ── Aggregate totals across every matching return ──────────
  // Kept separate from getReportPage so the summary cards still reflect
  // the whole filtered date range, not just the 20 rows on screen.
  Future<SaleReturnSummary> getReportSummary({
    required DateTime fromDate,
    required DateTime toDate,
    String?           customerId,
    String?           refundType,
  }) async {
    int    totalReturns  = 0;
    double totalAmount   = 0;
    double totalQuantity = 0;
    double totalDiscount = 0;

    int   rangeStart = 0;
    const int pageSize = 1000;
    bool  hasMore = true;

    while (hasMore) {
      var query = _client
          .from('sale_returns')
          .select('''
          grand_total, total_discount, refund_type, deleted_at,
          sale_return_items (quantity)
        ''')
          .eq('store_id', branchId)
          .eq('status', 'completed')
          .gte('return_date', fromDate.toIso8601String())
          .lte(
        'return_date',
        DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59)
            .toIso8601String(),
      );

      if (customerId != null && customerId.isNotEmpty) {
        query = query.eq('customer_id', customerId);
      }

      final result = await query
          .order('return_date', ascending: false)
          .range(rangeStart, rangeStart + pageSize - 1);

      final rows = (result as List)
          .where((r) => r['deleted_at'] == null)
          .where((r) =>
              refundType == null || r['refund_type']?.toString() == refundType);

      for (final r in rows) {
        totalReturns++;
        totalAmount   += _dbl(r['grand_total'])   ?? 0;
        totalDiscount += _dbl(r['total_discount']) ?? 0;
        totalQuantity += (r['sale_return_items'] as List? ?? [])
            .fold<double>(0, (s, i) => s + (_dbl(i['quantity']) ?? 0));
      }

      if ((result).length < pageSize) {
        hasMore = false;
      } else {
        rangeStart += pageSize;
      }
    }

    return SaleReturnSummary(
      totalReturns:  totalReturns,
      totalAmount:   totalAmount,
      totalQuantity: totalQuantity,
      totalDiscount: totalDiscount,
    );
  }

  SaleReturnInvoice _mapReturn(dynamic r) {
    final payments = (r['sale_return_payments'] as List? ?? []);
    final methods  = payments
        .map((p) => p['payment_method']?.toString() ?? '')
        .toSet()
        .toList();

    final items = (r['sale_return_items'] as List? ?? [])
        .map((i) => SaleReturnItem(
      productName:   i['product_name']?.toString() ?? '',
      sku:           i['sku']?.toString(),
      salePrice:     _dbl(i['sale_price'])          ?? 0,
      purchasePrice: _dbl(i['purchase_price'])      ?? 0,
      quantity:      _dbl(i['quantity'])            ?? 0,
      discount:      _dbl(i['discount'])            ?? 0,
      totalAmount:   _dbl(i['total_amount'])        ?? 0,
    ))
        .toList();

    final customerName = r['customer'] != null
        ? r['customer']['name']?.toString()
        : null;

    return SaleReturnInvoice(
      id:             r['id'].toString(),
      returnNo:       r['return_no']?.toString()     ?? '',
      returnDate:     DateTime.parse(
          r['return_date'].toString())
          .toLocal(),
      customerName:   customerName,
      customerId:     r['customer_id']?.toString(),
      invoiceId:      r['invoice_id']?.toString(),
      totalAmount:    _dbl(r['total_amount'])        ?? 0,
      totalDiscount:  _dbl(r['total_discount'])      ?? 0,
      grandTotal:     _dbl(r['grand_total'])         ?? 0,
      status:         r['status']?.toString()        ?? '',
      returnReason:   r['return_reason']?.toString(),
      refundType:     r['refund_type']?.toString(),
      paymentMethods: methods,
      items:          items,
    );
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}