import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/sale_summary_model.dart';

class SaleSummaryExportSheets {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  /// "Summary" (sale / return / net / collected), "Invoices" (one row per
  /// invoice), "Invoice Items" (fact table — one row per invoice line),
  /// "Returns" (one row per return) and "Return Items" (one row per
  /// returned line).
  static List<ExcelSheetData> build({
    required SaleSummary summary,
    required List<SummaryInvoice> invoices,
    required List<SummaryReturn> returns,
    required DateTime fromDate,
    required DateTime toDate,
    String? customerName,
  }) {
    final subtitle =
        '${_dateFmt.format(fromDate)}  →  ${_dateFmt.format(toDate)}'
        '   •   Customer: ${customerName ?? 'All'}';

    var discount = 0.0, grand = 0.0, paid = 0.0;
    final invoiceRows = <List<Object?>>[];
    final itemRows    = <List<Object?>>[];
    for (final i in invoices) {
      discount += i.totalDiscount;
      grand    += i.grandTotal;
      paid     += i.payAmount;
      invoiceRows.add([
        i.invoiceDate,
        i.invoiceNo,
        i.customerLabel,
        i.paymentLabel,
        i.totalDiscount,
        i.grandTotal,
        i.previousAmount,
        i.payAmount,
        i.newAmount,
      ]);
      for (final it in i.items) {
        itemRows.add([
          i.invoiceDate,
          i.invoiceNo,
          i.customerLabel,
          it.productName,
          it.quantity,
          it.salePrice,
          it.purchasePrice,
          it.totalAmount,
        ]);
      }
    }

    var returnDiscount = 0.0, returnGrand = 0.0;
    final returnRows     = <List<Object?>>[];
    final returnItemRows = <List<Object?>>[];
    for (final r in returns) {
      returnDiscount += r.totalDiscount;
      returnGrand    += r.grandTotal;
      returnRows.add([
        r.returnDate,
        r.returnNo,
        r.customerLabel,
        r.refundType ?? '—',
        r.totalDiscount,
        r.grandTotal,
      ]);
      for (final it in r.items) {
        returnItemRows.add([
          r.returnDate,
          r.returnNo,
          r.customerLabel,
          it.productName,
          it.quantity,
          it.salePrice,
          it.purchasePrice,
          it.totalAmount,
        ]);
      }
    }

    return [
      ExcelSheetData(
        name:     'Summary',
        title:    'Sale Summary',
        subtitle: subtitle,
        columns: const [
          ExcelColumn('Measure', width: 28),
          ExcelColumn('Amount',  width: 18, type: ExcelColType.amount),
        ],
        rows: [
          ['Total Sale',          summary.totalSale],
          ['Total Return',        summary.totalReturn],
          ['Net Sale',            summary.netSale],
          ['Customer Collection', summary.totalCollected],
        ],
      ),
      ExcelSheetData(
        name:     'Invoices',
        title:    'Sale Summary — Invoices',
        subtitle: '$subtitle   •   ${invoices.length} invoices',
        columns: const [
          ExcelColumn('Date',            width: 18, type: ExcelColType.dateTime),
          ExcelColumn('Invoice No',      width: 18),
          ExcelColumn('Customer',        width: 26),
          ExcelColumn('Payment',         width: 16),
          ExcelColumn('Discount',        width: 14, type: ExcelColType.amount),
          ExcelColumn('Grand Total',     width: 16, type: ExcelColType.amount),
          ExcelColumn('Previous Balance',width: 18, type: ExcelColType.amount),
          ExcelColumn('Paid',            width: 14, type: ExcelColType.amount),
          ExcelColumn('New Balance',     width: 16, type: ExcelColType.amount),
        ],
        rows: invoiceRows,
        totals: ['TOTAL', '', '', '', discount, grand, null, paid, null],
      ),
      ExcelSheetData(
        name:     'Invoice Items',
        title:    'Sale Summary — Invoice Items',
        subtitle: '$subtitle   •   ${itemRows.length} lines',
        columns: const [
          ExcelColumn('Date',        width: 18, type: ExcelColType.dateTime),
          ExcelColumn('Invoice No',  width: 18),
          ExcelColumn('Customer',    width: 26),
          ExcelColumn('Product',     width: 34),
          ExcelColumn('Quantity',    width: 12, type: ExcelColType.quantity),
          ExcelColumn('Sale Price',  width: 14, type: ExcelColType.amount),
          ExcelColumn('Purchase Price', width: 16, type: ExcelColType.amount),
          ExcelColumn('Line Total',  width: 16, type: ExcelColType.amount),
        ],
        rows: itemRows,
      ),
      ExcelSheetData(
        name:     'Returns',
        title:    'Sale Summary — Returns',
        subtitle: '$subtitle   •   ${returns.length} returns',
        columns: const [
          ExcelColumn('Date',        width: 18, type: ExcelColType.dateTime),
          ExcelColumn('Return No',   width: 18),
          ExcelColumn('Customer',    width: 26),
          ExcelColumn('Refund Type', width: 16),
          ExcelColumn('Discount',    width: 14, type: ExcelColType.amount),
          ExcelColumn('Grand Total', width: 16, type: ExcelColType.amount),
        ],
        rows: returnRows,
        totals: ['TOTAL', '', '', '', returnDiscount, returnGrand],
      ),
      ExcelSheetData(
        name:     'Return Items',
        title:    'Sale Summary — Return Items',
        subtitle: '$subtitle   •   ${returnItemRows.length} lines',
        columns: const [
          ExcelColumn('Date',        width: 18, type: ExcelColType.dateTime),
          ExcelColumn('Return No',   width: 18),
          ExcelColumn('Customer',    width: 26),
          ExcelColumn('Product',     width: 34),
          ExcelColumn('Quantity',    width: 12, type: ExcelColType.quantity),
          ExcelColumn('Sale Price',  width: 14, type: ExcelColType.amount),
          ExcelColumn('Purchase Price', width: 16, type: ExcelColType.amount),
          ExcelColumn('Line Total',  width: 16, type: ExcelColType.amount),
        ],
        rows: returnItemRows,
      ),
    ];
  }
}
