import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../model/inventory_counting_report_model.dart';

class InventoryCountingPdfService {
  static final _fieldFmt = DateFormat('dd MMM yyyy');

  static String _barcodeText(List<String> barcodes) =>
      barcodes.isEmpty ? '-' : barcodes.join(', ');

  /// records: hamesha CURRENT FILTERED list pass karein (search + date range)
  static Future<void> exportAndShare({
    required List<InventoryCountingRecord> records,
    String searchQuery = '',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final bytes = await _buildPdf(
      records: records,
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
    );

    final fileName =
        'inventory_counting_${DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now())}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<Uint8List> _buildPdf({
    required List<InventoryCountingRecord> records,
    String searchQuery = '',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final doc = pw.Document();

    final surplus = records.where((r) => r.difference > 0).length;
    final shortage = records.where((r) => r.difference < 0).length;
    final matched = records.where((r) => r.difference == 0).length;

    final List<String> filterLabels = [];
    if (startDate != null || endDate != null) {
      final s = startDate != null ? _fieldFmt.format(startDate) : '...';
      final e = endDate != null ? _fieldFmt.format(endDate) : '...';
      filterLabels.add('Date: $s  →  $e');
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
                    pw.Text('Inventory Counting Report',
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
                _summaryBox('Total', '${records.length}'),
                pw.SizedBox(width: 8),
                _summaryBox('Surplus', '$surplus'),
                pw.SizedBox(width: 8),
                _summaryBox('Shortage', '$shortage'),
                pw.SizedBox(width: 8),
                _summaryBox('Matched', '$matched'),
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
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
              7: pw.Alignment.centerRight,
              8: pw.Alignment.center,
            },
            headers: const [
              '#', 'Product', 'Barcode', 'Min Stock', 'Max Stock',
              'System Stock', 'Counted Stock', 'Difference', 'Counted On',
            ],
            data: List.generate(records.length, (i) {
              final r = records[i];
              return [
                '${i + 1}',
                r.productName,
                _barcodeText(r.barcodes),
                r.minStock.toStringAsFixed(1),
                r.maxStock.toStringAsFixed(1),
                r.productStock.toStringAsFixed(1),
                r.countingStock.toStringAsFixed(1),
                r.difference > 0
                    ? '+${r.difference.toStringAsFixed(1)}'
                    : r.difference.toStringAsFixed(1),
                _fieldFmt.format(r.countedDate),
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