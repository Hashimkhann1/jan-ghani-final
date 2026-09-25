import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/accountant_discount_wise_sale_report_model.dart';

class DiscountSaleExportSheets {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  /// Two sheets: "Discount Summary" (one row per product) and
  /// "Discount Detail" (fact table — one row per invoice line).
  static List<ExcelSheetData> build({
    required List<DiscountReportProduct> products,
    required DateTime fromDate,
    required DateTime toDate,
    String? customerName,
  }) {
    final subtitle =
        '${_dateFmt.format(fromDate)}  →  ${_dateFmt.format(toDate)}'
        '   •   Customer: ${customerName ?? 'All'}';

    var qty = 0.0, disc = 0.0, sale = 0.0, invoices = 0;
    final summaryRows = <List<Object?>>[];
    final detailRows  = <List<Object?>>[];
    for (final p in products) {
      qty      += p.totalQuantity;
      disc     += p.totalDiscount;
      sale     += p.totalSaleAmount;
      invoices += p.invoiceCount;
      summaryRows.add([
        p.productName,
        p.sku ?? '',
        p.invoiceCount,
        p.totalQuantity,
        p.totalDiscount,
        p.avgDiscountPercent,
        p.totalSaleAmount,
      ]);
      for (final d in p.details) {
        detailRows.add([
          d.invoiceDate,
          d.invoiceNo,
          d.customerLabel,
          p.productName,
          p.sku ?? '',
          d.quantity,
          d.salePrice,
          d.discount,
          d.discountPercent,
          d.totalAmount,
        ]);
      }
    }

    return [
      ExcelSheetData(
        name:     'Discount Summary',
        title:    'Discount Wise Sale Report — By Product',
        subtitle: '$subtitle   •   ${products.length} products',
        columns: const [
          ExcelColumn('Product',      width: 32),
          ExcelColumn('SKU',          width: 16),
          ExcelColumn('Invoices',     width: 10, type: ExcelColType.integer),
          ExcelColumn('Quantity',     width: 12, type: ExcelColType.quantity),
          ExcelColumn('Discount',     width: 14, type: ExcelColType.amount),
          ExcelColumn('Avg Disc %',   width: 12, type: ExcelColType.amount),
          ExcelColumn('Sale Amount',  width: 16, type: ExcelColType.amount),
        ],
        rows: summaryRows,
        totals: ['TOTAL', '', invoices, qty, disc, null, sale],
      ),
      ExcelSheetData(
        name:     'Discount Detail',
        title:    'Discount Wise Sale Report — Invoice Lines',
        subtitle: '$subtitle   •   ${detailRows.length} lines',
        columns: const [
          ExcelColumn('Date',        width: 18, type: ExcelColType.dateTime),
          ExcelColumn('Invoice No',  width: 18),
          ExcelColumn('Customer',    width: 24),
          ExcelColumn('Product',     width: 32),
          ExcelColumn('SKU',         width: 16),
          ExcelColumn('Quantity',    width: 12, type: ExcelColType.quantity),
          ExcelColumn('Sale Price',  width: 14, type: ExcelColType.amount),
          ExcelColumn('Discount',    width: 14, type: ExcelColType.amount),
          ExcelColumn('Disc %',      width: 10, type: ExcelColType.amount),
          ExcelColumn('Line Total',  width: 16, type: ExcelColType.amount),
        ],
        rows: detailRows,
      ),
    ];
  }
}
