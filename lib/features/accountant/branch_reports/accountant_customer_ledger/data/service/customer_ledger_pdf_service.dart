import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../model/accountant_customer_ledger_model.dart';

class CustomerLedgerPdfService {
  static final _amtFmt  = NumberFormat('#,##,###', 'en_IN');
  static final _dateFmt = DateFormat('dd MMM yyyy  hh:mm a');
  static final _fieldFmt = DateFormat('dd MMM yyyy');

  static String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  /// items: hamesha CURRENT FILTERED list pass karein (customer + date + search)
  static Future<void> exportAndShare({
    required List<CustomerLedgerModel> items,
    String? customerName,
    DateTime? startDate,
    DateTime? endDate,
    String searchQuery = '',
    required double totalCollected,
    required double totalPaid,
  }) async {
    final bytes = await _buildPdf(
      items: items,
      customerName: customerName,
      startDate: startDate,
      endDate: endDate,
      searchQuery: searchQuery,
      totalCollected: totalCollected,
      totalPaid: totalPaid,
    );

    final fileName =
        'customer_ledger_${DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now())}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<Uint8List> _buildPdf({
    required List<CustomerLedgerModel> items,
    String? customerName,
    DateTime? startDate,
    DateTime? endDate,
    String searchQuery = '',
    required double totalCollected,
    required double totalPaid,
  }) async {
    final doc = pw.Document();

    final List<String> filterLabels = [];
    if (customerName != null && customerName.isNotEmpty) {
      filterLabels.add('Customer: $customerName');
    }
    if (startDate != null || endDate != null) {
      final s = startDate != null ? _fieldFmt.format(startDate) : '...';
      final e = endDate != null ? _fieldFmt.format(endDate) : '...';
      filterLabels.add('Date: $s  →  $e');
    }
    if (searchQuery.isNotEmpty) filterLabels.add('Search: "$searchQuery"');
    final filterText = filterLabels.isEmpty ? 'All Entries' : filterLabels.join('   •   ');

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
                    pw.Text('Customer Ledger',
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
                _summaryBox('Entries', '${items.length}'),
                pw.SizedBox(width: 8),
                _summaryBox('Total Collected', _fmt(totalCollected)),
                pw.SizedBox(width: 8),
                _summaryBox('Filtered Total', _fmt(totalPaid)),
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
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerLeft,
              6: pw.Alignment.centerLeft,
            },
            headers: const ['#', 'Customer', 'Previous', 'Paid', 'Remaining', 'Notes', 'Date & Time'],
            data: List.generate(items.length, (i) {
              final e = items[i];
              return [
                '${items.length - i}',
                e.customerName.isNotEmpty ? e.customerName : '-',
                _fmt(e.previousAmount),
                _fmt(e.payAmount),
                _fmt(e.newAmount),
                (e.notes != null && e.notes!.isNotEmpty) ? e.notes! : '-',
                _dateFmt.format(e.createdAt.toLocal()),
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