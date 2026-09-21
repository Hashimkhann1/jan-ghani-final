import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/accountant_sale_report_model.dart';

class SaleReportExcelService {
  static final _rangeFmt = DateFormat('dd MMM yyyy hh:mm a');

  /// [invoices] must be the full, filtered result — not just the pages
  /// currently loaded on screen.
  ///
  /// Two sheets: "Invoices" (one row per invoice, invoice-level totals) and
  /// "Items" (one row per sold line item). Invoice-level amounts are kept off
  /// the Items sheet so summing a column never double-counts an invoice.
  static Future<void> exportAndSave({
    required List<SaleReportInvoice> invoices,
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
      sheets: buildSheets(invoices: invoices, subtitle: subtitle),
    );
  }

  static List<ExcelSheetData> buildSheets({
    required List<SaleReportInvoice> invoices,
    required String subtitle,
  }) {
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

    var itemQty = 0.0, itemDiscount = 0.0, itemTotal = 0.0;
    final itemRows = <List<Object?>>[];
    for (final inv in invoices) {
      for (final i in inv.items) {
        itemQty      += i.quantity;
        itemDiscount += i.discount;
        itemTotal    += i.totalAmount;
        itemRows.add([
          inv.invoiceNo,
          inv.invoiceDate,
          inv.customerLabel,
          inv.paymentLabel,
          i.productName,
          i.sku ?? '',
          i.quantity,
          i.salePrice,
          i.purchasePrice,
          i.discount,
          i.totalAmount,
        ]);
      }
    }

    return [
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
      ExcelSheetData(
        name:     'Items',
        title:    'Sale Invoice Report — Line Items',
        subtitle: '$subtitle   •   ${itemRows.length} line items',
        columns: const [
          ExcelColumn('Invoice No',     width: 18),
          ExcelColumn('Date & Time',    width: 22, type: ExcelColType.dateTime),
          ExcelColumn('Customer',       width: 26),
          ExcelColumn('Payment',        width: 14),
          ExcelColumn('Product',        width: 34),
          ExcelColumn('SKU',            width: 16),
          ExcelColumn('Qty',            width: 10, type: ExcelColType.quantity),
          ExcelColumn('Sale Price',     width: 13, type: ExcelColType.amount),
          ExcelColumn('Purchase Price', width: 15, type: ExcelColType.amount),
          ExcelColumn('Discount',       width: 12, type: ExcelColType.amount),
          ExcelColumn('Line Total',     width: 14, type: ExcelColType.amount),
        ],
        rows:   itemRows,
        totals: ['TOTAL', null, null, null, null, null, itemQty, null, null,
                 itemDiscount, itemTotal],
      ),
    ];
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
