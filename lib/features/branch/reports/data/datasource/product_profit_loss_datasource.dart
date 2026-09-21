import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';
import '../../../../accountant/branch_reports/product_profit_loss_report/data/model/product_profit_loss_model.dart';

/// Branch-side source for the product profit/loss report. Reads the
/// branch's local Postgres (same as every other branch report) and
/// aggregates per product in SQL, so a busy month is a few hundred rows
/// instead of tens of thousands of invoice lines.
///
/// Profit per line = (sale_price - purchase_price) * qty - discount, the
/// same formula the accountant report uses.
class BranchProductProfitLossDatasource implements ProductProfitLossSource {
  final String storeId;

  BranchProductProfitLossDatasource({required this.storeId});

  /// Category names live in the warehouse database and are not synced to
  /// the branch, so the branch report has no category filter/column.
  @override
  Future<List<ProductPnlCategory>> fetchCategories() async => const [];

  @override
  Future<List<ProductProfitLossModel>> fetchReport({
    required DateTime fromDate,
    required DateTime toDate,
    required Map<String, String> categoryNameById,
  }) async {
    final conn = await DataBaseService.getConnection();

    final params = {
      'storeId':  storeId,
      'fromDate': DateTime(fromDate.year, fromDate.month, fromDate.day)
          .toIso8601String(),
      'toDate':   DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59)
          .toIso8601String(),
    };

    final inventory = await conn.execute(
      Sql.named('''
        SELECT product_id, product_name, sku, sale_price, purchase_price,
               stock, unit
        FROM public.branch_stock_inventory
        WHERE store_id = @storeId::uuid
          AND deleted_at IS NULL
      '''),
      parameters: {'storeId': storeId},
    );

    final sales = await conn.execute(
      Sql.named('''
        SELECT i.product_id,
               (array_agg(i.product_name ORDER BY h.invoice_date DESC))[1] AS product_name,
               (array_agg(i.sku          ORDER BY h.invoice_date DESC))[1] AS sku,
               (array_agg(i.sale_price   ORDER BY h.invoice_date DESC))[1] AS sale_price,
               (array_agg(i.purchase_price ORDER BY h.invoice_date DESC))[1] AS purchase_price,
               SUM(i.quantity) AS qty,
               SUM((i.sale_price - i.purchase_price) * i.quantity
                   - COALESCE(i.discount, 0)) AS profit
        FROM public.sale_invoice_items i
        JOIN public.sale_invoices h ON h.id = i.invoice_id
        WHERE h.store_id = @storeId::uuid
          AND h.status = 'completed'
          AND h.deleted_at IS NULL
          AND h.invoice_date >= @fromDate::timestamptz
          AND h.invoice_date <= @toDate::timestamptz
        GROUP BY i.product_id
      '''),
      parameters: params,
    );

    final returns = await conn.execute(
      Sql.named('''
        SELECT i.product_id,
               (array_agg(i.product_name ORDER BY h.return_date DESC))[1] AS product_name,
               (array_agg(i.sku          ORDER BY h.return_date DESC))[1] AS sku,
               (array_agg(i.sale_price   ORDER BY h.return_date DESC))[1] AS sale_price,
               (array_agg(i.purchase_price ORDER BY h.return_date DESC))[1] AS purchase_price,
               SUM(i.quantity) AS qty,
               SUM((i.sale_price - i.purchase_price) * i.quantity
                   - COALESCE(i.discount, 0)) AS profit
        FROM public.sale_return_items i
        JOIN public.sale_returns h ON h.id = i.return_id
        WHERE h.store_id = @storeId::uuid
          AND h.status = 'completed'
          AND h.deleted_at IS NULL
          AND h.return_date >= @fromDate::timestamptz
          AND h.return_date <= @toDate::timestamptz
        GROUP BY i.product_id
      '''),
      parameters: params,
    );

    final acc = <String, _Acc>{};
    _Acc slot(String pid) => acc.putIfAbsent(pid, _Acc.new);

    for (final row in inventory) {
      final m   = row.toColumnMap();
      final pid = m['product_id']?.toString() ?? '';
      if (pid.isEmpty) continue;
      final a = slot(pid);
      a.name          = m['product_name']?.toString() ?? '';
      a.sku           = m['sku']?.toString() ?? '';
      a.unit          = m['unit']?.toString() ?? '';
      a.salePrice     = _dbl(m['sale_price']);
      a.purchasePrice = _dbl(m['purchase_price']);
      a.stock         = _dbl(m['stock']);
    }

    void addLines(Iterable<ResultRow> rows, {required bool isReturn}) {
      for (final row in rows) {
        final m   = row.toColumnMap();
        final pid = m['product_id']?.toString() ?? '';
        if (pid.isEmpty) continue;
        final a = slot(pid);

        // Product no longer in branch inventory (deleted) — fall back to
        // the name/prices recorded on the invoice line so it still shows.
        if (a.name.isEmpty) {
          a.name          = m['product_name']?.toString() ?? '';
          a.sku           = m['sku']?.toString() ?? '';
          a.salePrice     = _dbl(m['sale_price']);
          a.purchasePrice = _dbl(m['purchase_price']);
        }

        if (isReturn) {
          a.returnQty    += _dbl(m['qty']);
          a.returnProfit += _dbl(m['profit']);
        } else {
          a.soldQty    += _dbl(m['qty']);
          a.saleProfit += _dbl(m['profit']);
        }
      }
    }

    addLines(sales,   isReturn: false);
    addLines(returns, isReturn: true);

    return acc.entries
        .map((e) => ProductProfitLossModel(
              productId:      e.key,
              productName:    e.value.name,
              sku:            e.value.sku,
              categoryId:     null,
              categoryName:   '',
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
  }

  static double _dbl(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _Acc {
  String name          = '';
  String sku           = '';
  String unit          = '';
  double salePrice     = 0;
  double purchasePrice = 0;
  double stock         = 0;
  double soldQty       = 0;
  double returnQty     = 0;
  double saleProfit    = 0;
  double returnProfit  = 0;
}
