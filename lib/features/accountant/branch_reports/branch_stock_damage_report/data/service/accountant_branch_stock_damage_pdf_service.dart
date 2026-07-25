import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../model/accountant_branch_stock_damage_model.dart';

class AccountantBranchStockDamagePdfService {
  static final _amtFmt = NumberFormat('#,##,###.##', 'en_IN');
  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
  static final _fieldFmt = DateFormat('dd MMM yyyy');

  static String _fmtAmt(double v) => 'Rs ${_amtFmt.format(v)}';
  static String _fmtQty(double q) => q.toStringAsFixed(2);
  static String _fmtDate(DateTime d) => _dateFmt.format(d);

  /// items: hamesha CURRENT FILTERED list pass karein (search + date range)
  /// taake jo screen par dikh raha ho wahi PDF mein aaye.
  static Future<void> exportAndShare({
    required List<AccountantBranchStockDamageModel> items,
    String searchQuery = '',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final bytes = await _buildPdf(
      items: items,
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
    );

    final fileName =
        'stock_damage_report_${DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now())}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<Uint8List> _buildPdf({
    required List<AccountantBranchStockDamageModel> items,
    String searchQuery = '',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final doc = pw.Document();

    final qty = items.fold<double>(0, (s, i) => s + i.stockDamage);
    final purchaseLoss = items.fold<double>(0, (s, i) => s + i.purchaseLoss);
    final saleLoss = items.fold<double>(0, (s, i) => s + i.saleLoss);

    // Active filters ka summary text
    final List<String> filterLabels = [];
    if (startDate != null || endDate != null) {
      final startText = startDate != null ? _fieldFmt.format(startDate) : '...';
      final endText = endDate != null ? _fieldFmt.format(endDate) : '...';
      filterLabels.add('Date: $startText  →  $endText');
    }
    if (searchQuery.isNotEmpty) filterLabels.add('Search: "$searchQuery"');
    final filterText = filterLabels.isEmpty ? 'All Records' : filterLabels.join('   •   ');

    final generatedAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

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
                    pw.Text('Stock Damage Report',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text(filterText,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(generatedAt, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                _summaryBox('Records', '${items.length}'),
                pw.SizedBox(width: 8),
                _summaryBox('Damaged Qty', _fmtQty(qty)),
                pw.SizedBox(width: 8),
                _summaryBox('Purchase Loss', _fmtAmt(purchaseLoss)),
                pw.SizedBox(width: 8),
                _summaryBox('Sale Loss', _fmtAmt(saleLoss)),
              ],
            ),
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
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
              7: pw.Alignment.center,
            },
            headers: const [
              '#', 'Product', 'Damage Qty', 'Purchase Price', 'Sale Price',
              'Purchase Loss', 'Sale Loss', 'Date',
            ],
            data: List.generate(items.length, (i) {
              final it = items[i];
              return [
                '${i + 1}',
                it.productName,
                _fmtQty(it.stockDamage),
                _fmtAmt(it.purchasePrice),
                _fmtAmt(it.salePrice),
                _fmtAmt(it.purchaseLoss),
                _fmtAmt(it.saleLoss),
                _fmtDate(it.createdAt),
              ];
            }),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _summaryBox(String label, String value) {
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
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }
}