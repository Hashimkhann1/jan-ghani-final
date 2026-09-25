import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/category_sale_report_model.dart';

class CategorySaleExportSheets {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  /// [reports] is the visible list (date range + category dropdown filter).
  static List<ExcelSheetData> build({
    required List<CategorySaleReport> reports,
    required DateTime fromDate,
    required DateTime toDate,
    String? categoryName,
  }) {
    var invoices = 0, qty = 0.0, sales = 0.0, profit = 0.0;
    final rows = <List<Object?>>[];
    for (final r in reports) {
      invoices += r.invoiceCount;
      qty      += r.totalQuantity;
      sales    += r.totalSales;
      profit   += r.totalProfit;
      rows.add([
        r.categoryName,
        r.invoiceCount,
        r.totalQuantity,
        r.totalSales,
        r.totalProfit,
        r.totalSales == 0 ? 0.0 : r.totalProfit / r.totalSales * 100,
      ]);
    }

    return [
      ExcelSheetData(
        name:     'Category Sales',
        title:    'Category Wise Sale Report',
        subtitle: '${_dateFmt.format(fromDate)}  →  ${_dateFmt.format(toDate)}'
            '   •   Category: ${categoryName ?? 'All'}',
        columns: const [
          ExcelColumn('Category',   width: 30),
          ExcelColumn('Invoices',   width: 12, type: ExcelColType.integer),
          ExcelColumn('Quantity',   width: 14, type: ExcelColType.quantity),
          ExcelColumn('Sales',      width: 16, type: ExcelColType.amount),
          ExcelColumn('Profit',     width: 16, type: ExcelColType.amount),
          ExcelColumn('Margin %',   width: 12, type: ExcelColType.amount),
        ],
        rows: rows,
        totals: [
          'TOTAL', invoices, qty, sales, profit,
          sales == 0 ? 0.0 : profit / sales * 100,
        ],
      ),
    ];
  }
}
