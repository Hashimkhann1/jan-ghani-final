import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/product_profit_loss_model.dart';

class ProductProfitLossExcelService {
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _amtFmt  = NumberFormat('#,##0.##');

  /// [items] are exactly the rows to export — the caller passes the ticked
  /// products, or the whole filtered list when nothing is ticked (same as
  /// the PDF export).
  static Future<void> exportAndSave({
    required List<ProductProfitLossModel> items,
    required DateTime fromDate,
    required DateTime toDate,
    required bool isSelection,
    String? categoryName,
  }) async {
    await ReportExcelExport.save(
      fileNamePrefix: 'product_profit_loss',
      sheets: [
        buildSheet(
          items: items,
          fromDate: fromDate,
          toDate: toDate,
          isSelection: isSelection,
          categoryName: categoryName,
        ),
      ],
    );
  }

  static ExcelSheetData buildSheet({
    required List<ProductProfitLossModel> items,
    required DateTime fromDate,
    required DateTime toDate,
    required bool isSelection,
    String? categoryName,
  }) {
    final s = ProductProfitLossSummary.from(items);

    // Branch report rows carry no category — leave that column out.
    final showCategory = items.any((i) => i.categoryName.isNotEmpty);

    final subtitle = [
      '${_dateFmt.format(fromDate)}  →  ${_dateFmt.format(toDate)}',
      isSelection ? 'Selected products (${items.length})' : 'All products',
      if (categoryName != null && categoryName.isNotEmpty)
        'Category: $categoryName',
      'Total Profit: ${_amtFmt.format(s.profitTotal)}',
      'Total Loss: ${_amtFmt.format(s.lossTotal)}',
    ].join('   •   ');

    final columns = <ExcelColumn>[
      const ExcelColumn('Product', width: 34),
      const ExcelColumn('SKU', width: 16),
      if (showCategory) const ExcelColumn('Category', width: 20),
      const ExcelColumn('Unit', width: 9),
      const ExcelColumn('Sale Price',      width: 13, type: ExcelColType.amount),
      const ExcelColumn('Purchase Price',  width: 15, type: ExcelColType.amount),
      const ExcelColumn('Inventory Stock', width: 15, type: ExcelColType.quantity),
      const ExcelColumn('Sold Qty',        width: 11, type: ExcelColType.quantity),
      const ExcelColumn('Return Qty',      width: 11, type: ExcelColType.quantity),
      const ExcelColumn('Net Sold',        width: 11, type: ExcelColType.quantity),
      const ExcelColumn('Sale Profit',     width: 14, type: ExcelColType.amount),
      const ExcelColumn('Return Profit',   width: 14, type: ExcelColType.amount),
      const ExcelColumn('Profit / Loss',   width: 15, type: ExcelColType.amount),
      const ExcelColumn('Status',          width: 10),
    ];

    var saleProfit = 0.0, returnProfit = 0.0;
    final rows = <List<Object?>>[];
    for (final it in items) {
      saleProfit   += it.saleProfit;
      returnProfit += it.returnProfit;
      rows.add([
        it.productName,
        it.sku,
        if (showCategory) it.categoryName,
        it.unit,
        it.salePrice,
        it.purchasePrice,
        it.inventoryStock,
        it.soldQty,
        it.returnQty,
        it.netSoldQty,
        it.saleProfit,
        it.returnProfit,
        it.netProfit,
        it.isProfit ? 'Profit' : 'Loss',
      ]);
    }

    final totals = <Object?>[
      'TOTAL',
      null,
      if (showCategory) null,
      null,
      null,
      null,
      s.inventoryStock,
      s.soldQty,
      s.returnQty,
      s.soldQty - s.returnQty,
      saleProfit,
      returnProfit,
      s.netProfit,
      s.netProfit >= 0 ? 'Profit' : 'Loss',
    ];

    return ExcelSheetData(
      name:     'Product Profit and Loss',
      title:    'Product Profit & Loss Report',
      subtitle: subtitle,
      columns:  columns,
      rows:     rows,
      totals:   totals,
    );
  }
}
