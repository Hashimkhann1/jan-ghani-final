import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../model/accountant_customer_model.dart';

class AccountantCustomerReportPdfService {
  static final _amtFmt = NumberFormat('#,##,###', 'en_IN');

  static String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  /// items: hamesha CURRENT FILTERED list pass karein (search + filterType)
  static Future<void> exportAndShare({
    required List<AccountantCustomerReportModel> items,
    String? filterType,
    String searchQuery = '',
    required int totalCustomers,
    required int activeCustomers,
    required double totalOutstanding,
    required int limitExceededCount,
  }) async {
    final bytes = await _buildPdf(
      items: items,
      filterType: filterType,
      searchQuery: searchQuery,
      totalCustomers: totalCustomers,
      activeCustomers: activeCustomers,
      totalOutstanding: totalOutstanding,
      limitExceededCount: limitExceededCount,
    );

    final fileName =
        'customer_report_${DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now())}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<Uint8List> _buildPdf({
    required List<AccountantCustomerReportModel> items,
    String? filterType,
    String searchQuery = '',
    required int totalCustomers,
    required int activeCustomers,
    required double totalOutstanding,
    required int limitExceededCount,
  }) async {
    final doc = pw.Document();

    final List<String> filterLabels = [];
    if (filterType != null) {
      filterLabels.add('Type: ${filterType == 'exceeded' ? 'Limit Cross' : filterType.toUpperCase()}');
    }
    if (searchQuery.isNotEmpty) filterLabels.add('Search: "$searchQuery"');
    final filterText = filterLabels.isEmpty ? 'All Customers' : filterLabels.join('   •   ');

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
                    pw.Text('Customer Report',
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
                _summaryBox('Total', '$totalCustomers'),
                pw.SizedBox(width: 8),
                _summaryBox('Active', '$activeCustomers'),
                pw.SizedBox(width: 8),
                _summaryBox('Outstanding', _fmt(totalOutstanding)),
                pw.SizedBox(width: 8),
                _summaryBox('Limit Cross', '$limitExceededCount'),
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
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.center,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
              7: pw.Alignment.centerLeft,
            },
            headers: const ['#', 'Name', 'Code', 'Phone', 'Type', 'Balance', 'Credit Limit', 'Address'],
            data: List.generate(items.length, (i) {
              final c = items[i];
              return [
                '${i + 1}',
                c.name,
                c.code,
                c.phone.isEmpty ? '-' : c.phone,
                c.customerType.toUpperCase(),
                _fmt(c.balance),
                c.creditLimit > 0 ? _fmt(c.creditLimit) : '-',
                c.address.isEmpty ? '-' : c.address,
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