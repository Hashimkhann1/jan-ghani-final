import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../model/product_profit_loss_model.dart';

class ProductProfitLossPdfService {
  static final _amtFmt = NumberFormat('#,##,###.##', 'en_IN');
  static final _dateFmt = DateFormat('dd MMM yyyy');

  static String _fmtAmt(double v) =>
      v < 0 ? '-Rs ${_amtFmt.format(-v)}' : 'Rs ${_amtFmt.format(v)}';
  static String _fmtQty(double q) => q.toStringAsFixed(2);

  /// [items] are exactly the rows to print — the caller passes the ticked
  /// products, or the whole filtered list when nothing is ticked.
  static Future<void> exportAndShare({
    required List<ProductProfitLossModel> items,
    required DateTime fromDate,
    required DateTime toDate,
    required bool isSelection,
    String? categoryName,
  }) async {
    final bytes = await _buildPdf(
      items: items,
      fromDate: fromDate,
      toDate: toDate,
      isSelection: isSelection,
      categoryName: categoryName,
    );
    final fileName =
        'product_profit_loss_${DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now())}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<Uint8List> _buildPdf({
    required List<ProductProfitLossModel> items,
    required DateTime fromDate,
    required DateTime toDate,
    required bool isSelection,
    String? categoryName,
  }) async {
    final doc = pw.Document();
    final s = ProductProfitLossSummary.from(items);

    final filters = <String>[
      '${_dateFmt.format(fromDate)} - ${_dateFmt.format(toDate)}',
      isSelection ? 'Selected products (${items.length})' : 'All products',
      if (categoryName != null && categoryName.isNotEmpty)
        'Category: $categoryName',
    ].join('   •   ');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Product Profit & Loss Report',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text(filters,
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(children: [
              _summaryBox('Products', '${s.products}'),
              pw.SizedBox(width: 8),
              _summaryBox('Inventory Stock', _fmtQty(s.inventoryStock)),
              pw.SizedBox(width: 8),
              _summaryBox('Sold Qty', _fmtQty(s.soldQty)),
              pw.SizedBox(width: 8),
              _summaryBox('Return Qty', _fmtQty(s.returnQty)),
              pw.SizedBox(width: 8),
              _summaryBox(
                s.netProfit >= 0 ? 'Net Profit' : 'Net Loss',
                _fmtAmt(s.netProfit),
                color: s.netProfit >= 0 ? PdfColors.green800 : PdfColors.red800,
              ),
            ]),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.center,
              8: pw.Alignment.center,
              9: pw.Alignment.centerRight,
              10: pw.Alignment.center,
            },
            headers: const [
              '#', 'Product', 'Category', 'Sale Price', 'Purchase Price',
              'Inventory Stock', 'Sold Qty', 'Return Qty', 'Net Sold',
              'Profit / Loss', 'Status',
            ],
            data: List.generate(items.length, (i) {
              final it = items[i];
              return [
                '${i + 1}',
                it.productName,
                it.categoryName,
                _fmtAmt(it.salePrice),
                _fmtAmt(it.purchasePrice),
                _fmtQty(it.inventoryStock),
                _fmtQty(it.soldQty),
                _fmtQty(it.returnQty),
                _fmtQty(it.netSoldQty),
                _fmtAmt(it.netProfit),
                it.isProfit ? 'Profit' : 'Loss',
              ];
            }),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total Profit: ${_fmtAmt(s.profitTotal)}    '
              'Total Loss: ${_fmtAmt(s.lossTotal)}    '
              'Net: ${_fmtAmt(s.netProfit)}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _summaryBox(String label, String value, {PdfColor? color}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
            pw.SizedBox(height: 2),
            pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }
}
