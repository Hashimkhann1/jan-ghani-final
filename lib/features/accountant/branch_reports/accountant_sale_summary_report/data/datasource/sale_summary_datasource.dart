import 'package:intl/intl.dart';
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
    final invoices = await _fetchInvoices(
      fromDate: fromDate, toDate: toDate, start: start, end: end,
      customerId: customerId,
    );
    return PagedSummaryInvoices(
      invoices:    invoices,
      hasNextPage: BranchReportPagination.hasNextPage(invoices.length),
    );
  }

  /// Every invoice in the range, for export. Fetched in chunks of 500 because
  /// each row carries its items.
  Future<List<SummaryInvoice>> getAllInvoices({
    required DateTime fromDate,
    required DateTime toDate,
    String?           customerId,
  }) async {
    const chunk = 500;
    final all = <SummaryInvoice>[];
    var from = 0;
    while (true) {
      final rows = await _fetchInvoices(
        fromDate: fromDate, toDate: toDate, start: from,
        end: from + chunk - 1, customerId: customerId,
      );
      all.addAll(rows);
      if (rows.length < chunk) break;
      from += chunk;
    }
    return all;
  }

  Future<List<SummaryInvoice>> _fetchInvoices({
    required DateTime fromDate,
    required DateTime toDate,
    required int      start,
    required int      end,
    String?           customerId,
  }) async {
    var query = _client
        .from('sale_invoices')
        .select('''
          id, invoice_no, invoice_date, total_discount, grand_total,
          previous_amount, new_amount, pay_amount, deleted_at,
          customer (name),
          sale_invoice_payments (payment_method),
          sale_invoice_items (product_name, sale_price, purchase_price, quantity, total_amount)
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
                productName:   i['product_name']?.toString() ?? '',
                quantity:      _dbl(i['quantity']),
                salePrice:     _dbl(i['sale_price']),
                purchasePrice: _dbl(i['purchase_price']),
                totalAmount:   _dbl(i['total_amount']),
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

    return invoices;
  }

  /// Every return in the range, for export. Fetched in chunks of 500 because
  /// each row carries its items.
  Future<List<SummaryReturn>> getAllReturns({
    required DateTime fromDate,
    required DateTime toDate,
    String?           customerId,
  }) async {
    const chunk = 500;
    final all = <SummaryReturn>[];
    var from = 0;
    while (true) {
      final rows = await _fetchReturns(
        fromDate: fromDate, toDate: toDate, start: from,
        end: from + chunk - 1, customerId: customerId,
      );
      all.addAll(rows);
      if (rows.length < chunk) break;
      from += chunk;
    }
    return all;
  }

  Future<List<SummaryReturn>> _fetchReturns({
    required DateTime fromDate,
    required DateTime toDate,
    required int      start,
    required int      end,
    String?           customerId,
  }) async {
    var query = _client
        .from('sale_returns')
        .select('''
          id, return_no, return_date, total_discount, grand_total,
          refund_type, deleted_at,
          customer (name),
          sale_return_items (product_name, sale_price, purchase_price, quantity, total_amount)
        ''')
        .eq('store_id', branchId)
        .eq('status', 'completed')
        .isFilter('deleted_at', null)
        .gte('return_date', fromDate.toIso8601String())
        .lte('return_date', toDate.toIso8601String());

    if (customerId != null && customerId.isNotEmpty) {
      query = query.eq('customer_id', customerId);
    }

    final rows = await query
        .order('return_date', ascending: false)
        .range(start, end) as List;

    return rows.map((r) {
      final items = (r['sale_return_items'] as List? ?? [])
          .map((i) => SummaryInvoiceItem(
                productName:   i['product_name']?.toString() ?? '',
                quantity:      _dbl(i['quantity']),
                salePrice:     _dbl(i['sale_price']),
                purchasePrice: _dbl(i['purchase_price']),
                totalAmount:   _dbl(i['total_amount']),
              ))
          .toList();
      return SummaryReturn(
        id:            r['id'].toString(),
        returnNo:      r['return_no']?.toString() ?? '',
        returnDate:    DateTime.parse(r['return_date'].toString()).toLocal(),
        customerName:  (r['customer'] as Map?)?['name']?.toString(),
        totalDiscount: _dbl(r['total_discount']),
        grandTotal:    _dbl(r['grand_total']),
        refundType:    r['refund_type']?.toString(),
        items:         items,
      );
    }).toList();
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

  // ── Graph (Sale / Return / Customer Collection) ──────────
  /// Range ke hisaab se bucket: ≤ 36 ghante → har ghanta,
  /// ≤ 62 din → har din, warna har mahina.
  Future<List<SaleTrendPoint>> getTrend({
    required DateTime fromDate,
    required DateTime toDate,
    String?           customerId,
  }) async {
    final cid = (customerId != null && customerId.isNotEmpty) ? customerId : null;
    final rows = await Future.wait([
      _amountRows('sale_invoices', 'invoice_date', 'grand_total',
          fromDate, toDate, cid, completedOnly: true),
      _amountRows('sale_returns', 'return_date', 'grand_total',
          fromDate, toDate, cid, completedOnly: true),
      _amountRows('customer_ledger', 'created_at', 'pay_amount',
          fromDate, toDate, cid),
    ]);

    final span = toDate.difference(fromDate);
    final unit = span.inHours <= 36
        ? _TrendUnit.hour
        : span.inDays <= 62 ? _TrendUnit.day : _TrendUnit.month;

    DateTime floor(DateTime d) => switch (unit) {
          _TrendUnit.hour  => DateTime(d.year, d.month, d.day, d.hour),
          _TrendUnit.day   => DateTime(d.year, d.month, d.day),
          _TrendUnit.month => DateTime(d.year, d.month),
        };
    DateTime next(DateTime d) => switch (unit) {
          _TrendUnit.hour  => DateTime(d.year, d.month, d.day, d.hour + 1),
          _TrendUnit.day   => DateTime(d.year, d.month, d.day + 1),
          _TrendUnit.month => DateTime(d.year, d.month + 1),
        };
    final labelFmt = switch (unit) {
      _TrendUnit.hour  => DateFormat('h a'),
      _TrendUnit.day   => DateFormat('dd MMM'),
      _TrendUnit.month => DateFormat('MMM yy'),
    };

    final keys = <DateTime>[
      for (var k = floor(fromDate); !k.isAfter(toDate); k = next(k)) k,
    ];
    final index = {for (var i = 0; i < keys.length; i++) keys[i]: i};

    List<double> bucket(List<(DateTime, double)> list) {
      final out = List<double>.filled(keys.length, 0);
      for (final (d, v) in list) {
        final i = index[floor(d)];
        if (i != null) out[i] += v;
      }
      return out;
    }

    final sale = bucket(rows[0]);
    final ret  = bucket(rows[1]);
    final col  = bucket(rows[2]);
    return [
      for (var i = 0; i < keys.length; i++)
        SaleTrendPoint(
          label:      labelFmt.format(keys[i]),
          sale:       sale[i],
          saleReturn: ret[i],
          collection: col[i],
        ),
    ];
  }

  /// Sirf (date, amount) — 1000-row chunks mein (Supabase select cap).
  Future<List<(DateTime, double)>> _amountRows(
    String   table,
    String   dateCol,
    String   amountCol,
    DateTime from,
    DateTime to,
    String?  cid, {
    bool completedOnly = false,
  }) async {
    final out = <(DateTime, double)>[];
    var start = 0;
    while (true) {
      var query = _client
          .from(table)
          .select('$dateCol, $amountCol')
          .eq('store_id', branchId)
          .isFilter('deleted_at', null)
          .gte(dateCol, from.toIso8601String())
          .lte(dateCol, to.toIso8601String());
      if (completedOnly) query = query.eq('status', 'completed');
      if (cid != null)   query = query.eq('customer_id', cid);

      final rows = await query
          .order(dateCol)
          .order('id')
          .range(start, start + _chunk - 1) as List;

      for (final r in rows) {
        final raw = r[dateCol];
        if (raw == null) continue;
        out.add((DateTime.parse(raw.toString()).toLocal(), _dbl(r[amountCol])));
      }
      if (rows.length < _chunk) break;
      start += _chunk;
    }
    return out;
  }

  static double _dbl(dynamic v) {
    if (v == null) return 0;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

enum _TrendUnit { hour, day, month }
