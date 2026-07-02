import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_discount_wise_sale_report_model.dart';

class DiscountWiseSaleReportDatasource {
  final _client = Supabase.instance.client;
  final String  branchId;

  DiscountWiseSaleReportDatasource({required this.branchId});

  // ── Customers dropdown ────────────────────────────────────────────
  Future<List<DiscountReportCustomerOption>> getCustomers() async {
    final result = await _client
        .from('customer')
        .select('id, name, code')
        .eq('is_active', true)
        .order('name');

    return (result as List)
        .map((r) => DiscountReportCustomerOption(
      id:   r['id'].toString(),
      name: r['name']?.toString() ?? '',
      code: r['code']?.toString(),
    ))
        .toList();
  }

  // ── Discount wise report ────────────────────────────────────────────
  Future<List<DiscountReportProduct>> getReport({
    required DateTime fromDate,
    required DateTime toDate,
    String?           customerId,
  }) async {
    List<Map<String, dynamic>> allRows = [];
    int    rangeStart = 0;
    const  int pageSize = 1000;
    bool   hasMore = true;

    while (hasMore) {
      var query = _client
          .from('sale_invoices')
          .select('''
          id, invoice_no, invoice_date, customer_id, deleted_at,
          customer (name),
          sale_invoice_items (
            product_name, sku, sale_price, quantity, discount, total_amount
          )
        ''')
          .eq('store_id', branchId)
          .eq('status', 'completed')
          .gte('invoice_date', fromDate.toIso8601String())
          .lte('invoice_date',
          DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59)
              .toIso8601String());

      if (customerId != null && customerId.isNotEmpty) {
        query = query.eq('customer_id', customerId);
      }

      final result = await query
          .order('invoice_date', ascending: false)
          .range(rangeStart, rangeStart + pageSize - 1);

      final page = (result as List)
          .where((r) => r['deleted_at'] == null)
          .cast<Map<String, dynamic>>()
          .toList();

      allRows.addAll(page);

      if (page.length < pageSize) {
        hasMore = false;
      } else {
        rangeStart += pageSize;
      }
    }

    // ── Sirf wo items jin per discount laga hua hai unko nikalo ────────
    final Map<String, List<DiscountReportDetail>> grouped = {};

    for (final r in allRows) {
      final invoiceId   = r['id'].toString();
      final invoiceNo   = r['invoice_no']?.toString() ?? '';
      final invoiceDate = DateTime.parse(r['invoice_date'].toString()).toLocal();
      final customerName = r['customer'] != null
          ? r['customer']['name']?.toString()
          : null;

      final items = (r['sale_invoice_items'] as List? ?? []);

      for (final i in items) {
        final discount = _dbl(i['discount']) ?? 0;
        if (discount <= 0) continue; // discount nahi laga to skip

        final productName = i['product_name']?.toString() ?? '';
        final sku          = i['sku']?.toString();
        final key          = '$productName|${sku ?? ''}';

        grouped.putIfAbsent(key, () => []).add(DiscountReportDetail(
          invoiceId:    invoiceId,
          invoiceNo:    invoiceNo,
          invoiceDate:  invoiceDate,
          customerName: customerName,
          quantity:     _dbl(i['quantity'])     ?? 0,
          salePrice:    _dbl(i['sale_price'])   ?? 0,
          discount:     discount,
          totalAmount:  _dbl(i['total_amount']) ?? 0,
        ));
      }
    }

    final products = grouped.entries.map((e) {
      final parts = e.key.split('|');
      return DiscountReportProduct(
        productName: parts[0],
        sku:         parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
        details:     e.value,
      );
    }).toList();

    // Zyada discount wala product upar
    products.sort((a, b) => b.totalDiscount.compareTo(a.totalDiscount));

    return products;
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}