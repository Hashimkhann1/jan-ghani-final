import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/sale_return_report_model.dart';

class SaleReturnReportExcelService {
  static final _rangeFmt = DateFormat('dd MMM yyyy');

  /// [data] must be the full, filtered result — not just the pages
  /// currently loaded on screen.
  ///
  /// Two sheets: "Returns" (a fact table — one row per product returned, no
  /// totals row so it can be pivoted/loaded into BI tools) and "Return
  /// Summary" (one row per return, return-level totals). Return-level amounts
  /// are kept off the fact table so summing a column never double-counts a
  /// return.
  static Future<void> exportAndSave({
    required SaleReturnExportData data,
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
      sheets: buildSheets(data: data, subtitle: subtitle),
    );
  }

  static const _uncategorized = 'Uncategorized';

  static List<ExcelSheetData> buildSheets({
    required SaleReturnExportData data,
    required String subtitle,
  }) {
    final returns = data.returns;
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

    final factRows = <List<Object?>>[];
    for (final r in returns) {
      for (final i in r.items) {
        factRows.add([
          r.returnNo,
          r.returnDate,
          data.branchName,
          r.invoiceNo ?? '',
          i.productName,
          data.categoryNameByProductId[i.productId] ?? _uncategorized,
          i.quantity,
          i.totalAmount,
          r.refundType == null ? '' : _cap(r.refundType!),
          r.returnReason ?? '',
          r.customerLabel,
        ]);
      }
    }

    return [
      ExcelSheetData(
        name:     'Returns',
        title:    'Returns — Fact Table (one row per product returned)',
        subtitle: '$subtitle   •   ${factRows.length} line items',
        columns: const [
          ExcelColumn('return_no',     width: 18),
          ExcelColumn('date_time',     width: 18, type: ExcelColType.dateTime,
              format: 'yyyy-mm-dd hh:mm'),
          ExcelColumn('branch',        width: 20),
          ExcelColumn('invoice_no',    width: 18),
          ExcelColumn('product',       width: 34),
          ExcelColumn('category',      width: 20),
          ExcelColumn('qty',           width: 8,  type: ExcelColType.quantity),
          ExcelColumn('refund_amount', width: 15, type: ExcelColType.amount),
          ExcelColumn('refund_type',   width: 14),
          ExcelColumn('reason',        width: 30),
          ExcelColumn('customer',      width: 26),
        ],
        rows: factRows,
      ),
      ExcelSheetData(
        name:     'Return Summary',
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
    ];
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
