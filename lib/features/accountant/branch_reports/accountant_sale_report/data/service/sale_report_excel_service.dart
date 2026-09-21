import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/accountant_sale_report_model.dart';

class SaleReportExcelService {
  static final _rangeFmt = DateFormat('dd MMM yyyy hh:mm a');

  /// [data] must be the full, filtered result — not just the pages
  /// currently loaded on screen.
  ///
  /// Two sheets: "Sales Transactions" (a fact table — one row per product sold
  /// per invoice, no totals row so it can be pivoted/loaded into BI tools) and
  /// "Invoices" (one row per invoice, invoice-level totals). Invoice-level
  /// amounts are kept off the fact table so summing a column never
  /// double-counts an invoice.
  static Future<void> exportAndSave({
    required SaleReportExportData data,
    required DateTime fromDate,
    required DateTime toDate,
    String? customerName,
    String? paymentType,
  }) async {
    final subtitle = [
      '${_rangeFmt.format(fromDate)}  →  ${_rangeFmt.format(toDate)}',
      'Customer: ${customerName ?? 'All'}',
      'Payment: ${paymentType == null ? 'All' : _cap(paymentType)}',
    ].join('   •   ');

    await ReportExcelExport.save(
      fileNamePrefix: 'sale_invoice_report',
      sheets: buildSheets(data: data, subtitle: subtitle),
    );
  }

  static const _uncategorized = 'Uncategorized';

  static List<ExcelSheetData> buildSheets({
    required SaleReportExportData data,
    required String subtitle,
  }) {
    final invoices = data.invoices;
    var totalQty = 0.0, totalAmount = 0.0, totalDiscount = 0.0, grandTotal = 0.0;
    final invoiceRows = <List<Object?>>[];
    for (final inv in invoices) {
      totalQty      += inv.totalQuantity;
      totalAmount   += inv.totalAmount;
      totalDiscount += inv.totalDiscount;
      grandTotal    += inv.grandTotal;
      invoiceRows.add([
        inv.invoiceNo,
        inv.invoiceDate,
        inv.customerLabel,
        inv.paymentLabel,
        inv.items.length,
        inv.totalQuantity,
        inv.totalAmount,
        inv.totalDiscount,
        inv.grandTotal,
        inv.previousAmount,
        inv.payAmount,
        inv.newAmount,
      ]);
    }

    final factRows = <List<Object?>>[];
    for (final inv in invoices) {
      for (final i in inv.items) {
        factRows.add([
          inv.invoiceNo,
          inv.invoiceDate,
          data.branchName,
          inv.cashierName ?? '',
          i.productName,
          data.categoryNameByProductId[i.productId] ?? _uncategorized,
          i.quantity,
          i.salePrice,
          i.purchasePrice,
          i.discount,
          inv.paymentLabel,
          inv.customerLabel,
        ]);
      }
    }

    return [
      ExcelSheetData(
        name:     'Sales Transactions',
        title:    'Sales Transactions — Fact Table (one row per product sold per invoice)',
        subtitle: '$subtitle   •   ${factRows.length} line items',
        columns: const [
          ExcelColumn('invoice_no',    width: 18),
          ExcelColumn('date_time',     width: 18, type: ExcelColType.dateTime,
              format: 'yyyy-mm-dd hh:mm'),
          ExcelColumn('branch',        width: 20),
          ExcelColumn('cashier',       width: 18),
          ExcelColumn('product',       width: 34),
          ExcelColumn('category',      width: 20),
          ExcelColumn('qty',           width: 8,  type: ExcelColType.quantity),
          ExcelColumn('sale_price',    width: 12, type: ExcelColType.amount),
          ExcelColumn('cost_price',    width: 12, type: ExcelColType.amount),
          ExcelColumn('discount',      width: 10, type: ExcelColType.amount),
          ExcelColumn('payment_type',  width: 14),
          ExcelColumn('customer',      width: 26),
        ],
        rows: factRows,
      ),
      ExcelSheetData(
        name:     'Invoices',
        title:    'Sale Invoice Report',
        subtitle: '$subtitle   •   ${invoices.length} invoices',
        columns: const [
          ExcelColumn('Invoice No',      width: 18),
          ExcelColumn('Date & Time',     width: 22, type: ExcelColType.dateTime),
          ExcelColumn('Customer',        width: 26),
          ExcelColumn('Payment',         width: 14),
          ExcelColumn('Items',           width: 8,  type: ExcelColType.integer),
          ExcelColumn('Qty',             width: 10, type: ExcelColType.quantity),
          ExcelColumn('Total Amount',    width: 15, type: ExcelColType.amount),
          ExcelColumn('Discount',        width: 13, type: ExcelColType.amount),
          ExcelColumn('Grand Total',     width: 15, type: ExcelColType.amount),
          ExcelColumn('Previous Amount', width: 16, type: ExcelColType.amount),
          ExcelColumn('Pay Amount',      width: 14, type: ExcelColType.amount),
          ExcelColumn('New Amount',      width: 14, type: ExcelColType.amount),
        ],
        rows:   invoiceRows,
        totals: ['TOTAL', null, null, null, null, totalQty, totalAmount,
                 totalDiscount, grandTotal, null, null, null],
      ),
    ];
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
