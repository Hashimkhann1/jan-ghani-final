import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/product_profit_loss_model.dart';

class ProductProfitLossDatasource {
  final _client = Supabase.instance.client;
  final String branchId;

  ProductProfitLossDatasource({required this.branchId});

  static const int _pageSize = 1000;

  Future<List<ProductPnlCategory>> fetchCategories() async {
    final rows = await _client
        .from('warehouse_categories')
        .select('id, name')
        .eq('is_active', true)
        .order('name', ascending: true);

    return (rows as List)
        .map((r) => ProductPnlCategory(
              id:   r['id'].toString(),
              name: r['name']?.toString() ?? '',
            ))
        .toList();
  }

  /// PostgREST caps a response at 1000 rows, so every fetch below loops
  /// with `.range()` until a short page comes back.
  Future<List<Map<String, dynamic>>> _paged(
    Future<List<dynamic>> Function(int from, int to) page,
  ) async {
    final all = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final rows = await page(from, from + _pageSize - 1);
      all.addAll(rows.cast<Map<String, dynamic>>());
      if (rows.length < _pageSize) break;
      from += _pageSize;
    }
    return all;
  }

  Future<List<Map<String, dynamic>>> _fetchInventory() => _paged(
        (from, to) async => await _client
            .from('branch_stock_inventory')
            .select('product_id, product_name, sku, sale_price, purchase_price, '
                'stock, unit, category_id')
            .eq('store_id', branchId)
            .isFilter('deleted_at', null)
            .order('product_name', ascending: true)
            .order('id', ascending: true)
            .range(from, to) as List,
      );

  Future<List<Map<String, dynamic>>> _fetchSaleItems(
      String start, String end) =>
      _paged(
        (from, to) async => await _client
            .from('sale_invoice_items')
            .select('product_id, product_name, sku, sale_price, purchase_price, '
                'quantity, discount, '
                'sale_invoices!inner(store_id, status, deleted_at, invoice_date)')
            .eq('sale_invoices.store_id', branchId)
            .eq('sale_invoices.status', 'completed')
            .isFilter('sale_invoices.deleted_at', null)
            .gte('sale_invoices.invoice_date', start)
            .lte('sale_invoices.invoice_date', end)
            .order('id', ascending: true)
            .range(from, to) as List,
      );

  Future<List<Map<String, dynamic>>> _fetchReturnItems(
      String start, String end) =>
      _paged(
        (from, to) async => await _client
            .from('sale_return_items')
            .select('product_id, product_name, sku, sale_price, purchase_price, '
                'quantity, discount, '
                'sale_returns!inner(store_id, status, deleted_at, return_date)')
            .eq('sale_returns.store_id', branchId)
            .eq('sale_returns.status', 'completed')
            .isFilter('sale_returns.deleted_at', null)
            .gte('sale_returns.return_date', start)
            .lte('sale_returns.return_date', end)
            .order('id', ascending: true)
            .range(from, to) as List,
      );

  Future<List<ProductProfitLossModel>> fetchReport({
    required DateTime fromDate,
    required DateTime toDate,
    required Map<String, String> categoryNameById,
  }) async {
    final start = DateTime(fromDate.year, fromDate.month, fromDate.day)
        .toIso8601String();
    final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59)
        .toIso8601String();

    final results = await Future.wait([
      _fetchInventory(),
      _fetchSaleItems(start, end),
      _fetchReturnItems(start, end),
    ]);

    final inventory   = results[0];
    final saleItems   = results[1];
    final returnItems = results[2];

    // product_id -> running totals
    final acc = <String, _Acc>{};

    _Acc slot(String pid) => acc.putIfAbsent(pid, _Acc.new);

    for (final r in inventory) {
      final pid = r['product_id']?.toString() ?? '';
      if (pid.isEmpty) continue;
      final a = slot(pid);
      a.name          = r['product_name']?.toString() ?? '';
      a.sku           = r['sku']?.toString() ?? '';
      a.unit          = r['unit']?.toString() ?? '';
      a.categoryId    = r['category_id']?.toString();
      a.salePrice     = _dbl(r['sale_price']);
      a.purchasePrice = _dbl(r['purchase_price']);
      a.stock         = _dbl(r['stock']);
    }

    void addLines(List<Map<String, dynamic>> rows, {required bool isReturn}) {
      for (final r in rows) {
        final pid = r['product_id']?.toString() ?? '';
        if (pid.isEmpty) continue;
        final a   = slot(pid);
        final qty = _dbl(r['quantity']);
        final sp  = _dbl(r['sale_price']);
        final pp  = _dbl(r['purchase_price']);
        final profit = (sp - pp) * qty - _dbl(r['discount']);

        // Product no longer in branch inventory (deleted) — fall back to the
        // name/prices recorded on the invoice line so it still shows up.
        if (a.name.isEmpty) {
          a.name          = r['product_name']?.toString() ?? '';
          a.sku           = r['sku']?.toString() ?? '';
          a.salePrice     = sp;
          a.purchasePrice = pp;
        }

        if (isReturn) {
          a.returnQty    += qty;
          a.returnProfit += profit;
        } else {
          a.soldQty    += qty;
          a.saleProfit += profit;
        }
      }
    }

    addLines(saleItems,   isReturn: false);
    addLines(returnItems, isReturn: true);

    final list = acc.entries
        .map((e) => ProductProfitLossModel(
              productId:      e.key,
              productName:    e.value.name,
              sku:            e.value.sku,
              categoryId:     e.value.categoryId,
              categoryName:   categoryNameById[e.value.categoryId] ??
                  'Uncategorized',
              unit:           e.value.unit,
              salePrice:      e.value.salePrice,
              purchasePrice:  e.value.purchasePrice,
              inventoryStock: e.value.stock,
              soldQty:        e.value.soldQty,
              returnQty:      e.value.returnQty,
              saleProfit:     e.value.saleProfit,
              returnProfit:   e.value.returnProfit,
            ))
        .toList()
      ..sort((a, b) =>
          a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));

    return list;
  }

  static double _dbl(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _Acc {
  String  name          = '';
  String  sku           = '';
  String  unit          = '';
  String? categoryId;
  double  salePrice     = 0;
  double  purchasePrice = 0;
  double  stock         = 0;
  double  soldQty       = 0;
  double  returnQty     = 0;
  double  saleProfit    = 0;
  double  returnProfit  = 0;
}
