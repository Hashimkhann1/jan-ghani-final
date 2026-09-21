import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/sale_return_report_model.dart';

class SaleReturnReportExcelService {
  static final _rangeFmt = DateFormat('dd MMM yyyy');

  /// [returns] must be the full, filtered result — not just the pages
  /// currently loaded on screen.
  ///
  /// Two sheets: "Returns" (one row per return, return-level totals) and
  /// "Items" (one row per returned line item). Return-level amounts are kept
  /// off the Items sheet so summing a column never double-counts a return.
  static Future<void> exportAndSave({
    required List<SaleReturnInvoice> returns,
    required DateTime fromDate,
    required DateTime toDate,
    String? customerName,
    String? refundType,
  }) async {
    final subtitle = [
      '${_rangeFmt.format(fromDate)}  →  ${_rangeFmt.format(toDate)}',
      'Customer: ${customerName ?? 'All'}',
      'Refund: ${refundType == null ? 'All' : _cap(refundType)}',
    ].join('   •   ');

    await ReportExcelExport.save(
      fileNamePrefix: 'sale_return_report',
      sheets: buildSheets(returns: returns, subtitle: subtitle),
    );
  }

  static List<ExcelSheetData> buildSheets({
    required List<SaleReturnInvoice> returns,
    required String subtitle,
  }) {
    var totalQty = 0.0, totalAmount = 0.0, totalDiscount = 0.0, grandTotal = 0.0;
    final returnRows = <List<Object?>>[];
    for (final r in returns) {
      totalQty      += r.totalQuantity;
      totalAmount   += r.totalAmount;
      totalDiscount += r.totalDiscount;
      grandTotal    += r.grandTotal;
      returnRows.add([
        r.returnNo,
        r.returnDate,
        r.customerLabel,
        r.refundType == null ? '' : _cap(r.refundType!),
        r.paymentLabel,
        r.returnReason ?? '',
        r.items.length,
        r.totalQuantity,
        r.totalAmount,
        r.totalDiscount,
        r.grandTotal,
      ]);
    }

    var itemQty = 0.0, itemDiscount = 0.0, itemTotal = 0.0;
    final itemRows = <List<Object?>>[];
    for (final r in returns) {
      for (final i in r.items) {
        itemQty      += i.quantity;
        itemDiscount += i.discount;
        itemTotal    += i.totalAmount;
        itemRows.add([
          r.returnNo,
          r.returnDate,
          r.customerLabel,
          r.refundType == null ? '' : _cap(r.refundType!),
          r.returnReason ?? '',
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
        name:     'Returns',
        title:    'Sale Return Report',
        subtitle: '$subtitle   •   ${returns.length} returns',
        columns: const [
          ExcelColumn('Return No',    width: 18),
          ExcelColumn('Date & Time',  width: 22, type: ExcelColType.dateTime),
          ExcelColumn('Customer',     width: 26),
          ExcelColumn('Refund Type',  width: 14),
          ExcelColumn('Payment',      width: 14),
          ExcelColumn('Reason',       width: 30),
          ExcelColumn('Items',        width: 8,  type: ExcelColType.integer),
          ExcelColumn('Qty',          width: 10, type: ExcelColType.quantity),
          ExcelColumn('Total Amount', width: 15, type: ExcelColType.amount),
          ExcelColumn('Discount',     width: 13, type: ExcelColType.amount),
          ExcelColumn('Grand Total',  width: 15, type: ExcelColType.amount),
        ],
        rows:   returnRows,
        totals: ['TOTAL', null, null, null, null, null, null, totalQty,
                 totalAmount, totalDiscount, grandTotal],
      ),
      ExcelSheetData(
        name:     'Items',
        title:    'Sale Return Report — Line Items',
        subtitle: '$subtitle   •   ${itemRows.length} line items',
        columns: const [
          ExcelColumn('Return No',      width: 18),
          ExcelColumn('Date & Time',    width: 22, type: ExcelColType.dateTime),
          ExcelColumn('Customer',       width: 26),
          ExcelColumn('Refund Type',    width: 14),
          ExcelColumn('Reason',         width: 30),
          ExcelColumn('Product',        width: 34),
          ExcelColumn('SKU',            width: 16),
          ExcelColumn('Qty',            width: 10, type: ExcelColType.quantity),
          ExcelColumn('Sale Price',     width: 13, type: ExcelColType.amount),
          ExcelColumn('Purchase Price', width: 15, type: ExcelColType.amount),
          ExcelColumn('Discount',       width: 12, type: ExcelColType.amount),
          ExcelColumn('Line Total',     width: 14, type: ExcelColType.amount),
        ],
        rows:   itemRows,
        totals: ['TOTAL', null, null, null, null, null, null, itemQty, null,
                 null, itemDiscount, itemTotal],
      ),
    ];
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
