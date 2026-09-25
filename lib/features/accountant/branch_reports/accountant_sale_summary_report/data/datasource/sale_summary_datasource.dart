import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../model/sale_summary_model.dart';

class SaleSummaryDatasource {
  final _client = Supabase.instance.client;
  final String  branchId;

  SaleSummaryDatasource({required this.branchId});

  Future<List<SummaryCustomer>> getCustomers() async {
    final result = await _client
        .from('customer')
        .select('id, name, code')
        .eq('is_active', true)
        .order('name');

    return (result as List)
        .map((r) => SummaryCustomer(
              id:   r['id'].toString(),
              name: r['name']?.toString() ?? '',
              code: r['code']?.toString(),
            ))
        .toList();
  }

  Future<PagedSummaryInvoices> getInvoicesPage({
    required DateTime fromDate,
    required DateTime toDate,
    required int      page,
    String?           customerId,
  }) async {
    final (start, end) = BranchReportPagination.range(page);
    var query = _client
        .from('sale_invoices')
        .select('''
          id, invoice_no, invoice_date, total_discount, grand_total,
          previous_amount, new_amount, pay_amount, deleted_at,
          customer (name),
          sale_invoice_payments (payment_method),
          sale_invoice_items (product_name, sale_price, quantity, total_amount)
        ''')
        .eq('store_id', branchId)
        .eq('status', 'completed')
        .isFilter('deleted_at', null)
        .gte('invoice_date', fromDate.toIso8601String())
        .lte('invoice_date', toDate.toIso8601String());

    if (customerId != null && customerId.isNotEmpty) {
      query = query.eq('customer_id', customerId);
    }

    final rows = await query
        .order('invoice_date', ascending: false)
        .range(start, end) as List;

    final invoices = rows.map((r) {
      final methods = (r['sale_invoice_payments'] as List? ?? [])
          .map((p) => p['payment_method']?.toString() ?? '')
          .toSet()
          .toList();
      final items = (r['sale_invoice_items'] as List? ?? [])
          .map((i) => SummaryInvoiceItem(
                productName: i['product_name']?.toString() ?? '',
                quantity:    _dbl(i['quantity']),
                salePrice:   _dbl(i['sale_price']),
                totalAmount: _dbl(i['total_amount']),
              ))
          .toList();
      return SummaryInvoice(
        id:             r['id'].toString(),
        invoiceNo:      r['invoice_no']?.toString() ?? '',
        invoiceDate:    DateTime.parse(r['invoice_date'].toString()).toLocal(),
        customerName:   (r['customer'] as Map?)?['name']?.toString(),
        totalDiscount:  _dbl(r['total_discount']),
        grandTotal:     _dbl(r['grand_total']),
        previousAmount: _dbl(r['previous_amount']),
        newAmount:      _dbl(r['new_amount']),
        payAmount:      _dbl(r['pay_amount']),
        paymentMethods: methods,
        items:          items,
      );
    }).toList();

    return PagedSummaryInvoices(
      invoices:    invoices,
      hasNextPage: BranchReportPagination.hasNextPage(rows.length),
    );
  }

  Future<SaleSummary> getSummary({
    required DateTime fromDate,
    required DateTime toDate,
    String?           customerId,
  }) async {
    final cid = (customerId != null && customerId.isNotEmpty) ? customerId : null;

    final results = await Future.wait([
      _totalSale(fromDate, toDate, cid),
      _totalReturn(fromDate, toDate, cid),
      _totalCollected(fromDate, toDate, cid),
    ]);

    return SaleSummary(
      totalSale:      results[0],
      totalReturn:    results[1],
      totalCollected: results[2],
    );
  }

  Future<double> _totalSale(DateTime from, DateTime to, String? cid) async {
    final rows = await _client.rpc('get_sale_report_summary', params: {
      'p_store_id':     branchId,
      'p_from':         from.toIso8601String(),
      'p_to':           to.toIso8601String(),
      'p_customer_id':  cid,
      'p_payment_type': null,
    });
    return _dbl((rows as List).first['total_sale']);
  }

  Future<double> _totalReturn(DateTime from, DateTime to, String? cid) async {
    final rows = await _client.rpc('get_sale_return_summary', params: {
      'p_store_id':    branchId,
      'p_from':        from.toIso8601String(),
      'p_to':          to.toIso8601String(),
      'p_customer_id': cid,
      'p_refund_type': null,
    });
    return _dbl((rows as List).first['total_amount']);
  }

  // Sum of customer_ledger.pay_amount, paged in chunks because Supabase
  // caps a single select at 1000 rows.
  static const int _chunk = 1000;

  Future<double> _totalCollected(DateTime from, DateTime to, String? cid) async {
    var total = 0.0;
    var start = 0;
    while (true) {
      var query = _client
          .from('customer_ledger')
          .select('pay_amount')
          .eq('store_id', branchId)
          .isFilter('deleted_at', null)
          .gte('created_at', from.toIso8601String())
          .lte('created_at', to.toIso8601String());

      if (cid != null) query = query.eq('customer_id', cid);

      final rows = await query
          .order('created_at', ascending: false)
          .order('id')
          .range(start, start + _chunk - 1) as List;

      for (final r in rows) {
        total += _dbl(r['pay_amount']);
      }
      if (rows.length < _chunk) break;
      start += _chunk;
    }
    return total;
  }

  static double _dbl(dynamic v) {
    if (v == null) return 0;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
