import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../model/customer_invoice_model.dart';
import '../model/customer_return_model.dart';
import '../model/specific_customer_ledger_model.dart';

class CustomerReportPdfService {
  static final _amtFmt  = NumberFormat('#,##,###', 'en_IN');
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _timeFmt = DateFormat('hh:mm a');

  static String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  static Future<void> exportAndShare({
    required String customerName,
    required double customerBalance,
    required DateTime fromDate,
    required DateTime toDate,
    required List<CustomerInvoiceModel> sales,
    required List<CustomerReturnInvoice> returns,
    required List<SpecificCustomerLedgerModel> ledger,
    required double totalSale,
    required double totalReturn,
    required double totalPaid,
  }) async {
    final bytes = await _buildPdf(
      customerName: customerName,
      customerBalance: customerBalance,
      fromDate: fromDate,
      toDate: toDate,
      sales: sales,
      returns: returns,
      ledger: ledger,
      totalSale: totalSale,
      totalReturn: totalReturn,
      totalPaid: totalPaid,
    );

    final safeName = customerName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    final fileName =
        'customer_statement_${safeName}_${DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now())}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<Uint8List> _buildPdf({
    required String customerName,
    required double customerBalance,
    required DateTime fromDate,
    required DateTime toDate,
    required List<CustomerInvoiceModel> sales,
    required List<CustomerReturnInvoice> returns,
    required List<SpecificCustomerLedgerModel> ledger,
    required double totalSale,
    required double totalReturn,
    required double totalPaid,
  }) async {
    final doc = pw.Document();
    final hasBalance = customerBalance > 0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
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
                    pw.Text('Customer Statement',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text(customerName,
                        style: pw.TextStyle(
                            fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                    pw.SizedBox(height: 2),
                    pw.Text('${_dateFmt.format(fromDate)}  →  ${_dateFmt.format(toDate)}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(hasBalance ? 'Outstanding' : 'Balance',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.Text(_fmt(customerBalance.abs()),
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                _summaryBox('Sales', '${sales.length}'),
                pw.SizedBox(width: 8),
                _summaryBox('Total Sale', _fmt(totalSale)),
                pw.SizedBox(width: 8),
                _summaryBox('Total Return', _fmt(totalReturn)),
                pw.SizedBox(width: 8),
                _summaryBox('Paid', _fmt(totalPaid)),
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
          if (sales.isNotEmpty) ...[
            _sectionTitle('Sales'),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headers: const ['#', 'Invoice No', 'Date', 'Payment', 'Items', 'Discount', 'Grand Total'],
              data: List.generate(sales.length, (i) {
                final s = sales[i];
                return [
                  '${i + 1}',
                  s.invoiceNo,
                  '${_dateFmt.format(s.invoiceDate)} ${_timeFmt.format(s.invoiceDate)}',
                  s.paymentType,
                  '${s.items.length}',
                  s.totalDiscount > 0 ? s.discountLabel : '-',
                  s.grandTotalLabel,
                ];
              }),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 14),
          ],
          if (returns.isNotEmpty) ...[
            _sectionTitle('Returns'),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headers: const ['#', 'Return No', 'Date', 'Payment', 'Items', 'Discount', 'Grand Total'],
              data: List.generate(returns.length, (i) {
                final r = returns[i];
                return [
                  '${i + 1}',
                  r.returnNo,
                  '${_dateFmt.format(r.returnDate)} ${_timeFmt.format(r.returnDate)}',
                  r.paymentLabel,
                  '${r.items.length}',
                  r.totalDiscount > 0 ? _fmt(r.totalDiscount) : '-',
                  _fmt(r.grandTotal),
                ];
              }),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 14),
          ],
          if (ledger.isNotEmpty) ...[
            _sectionTitle('Ledger'),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headers: const ['#', 'Date', 'Type', 'Notes', 'Amount', 'Previous', 'New Balance'],
              data: List.generate(ledger.length, (i) {
                final l = ledger[i];
                return [
                  '${i + 1}',
                  '${_dateFmt.format(l.createdAt)} ${_timeFmt.format(l.createdAt)}',
                  l.isPayment ? 'Payment' : 'Credit',
                  l.notes ?? '-',
                  '${l.isPayment ? '- ' : '+ '}${_fmt(l.payAmount)}',
                  _fmt(l.previousAmount),
                  _fmt(l.newAmount),
                ];
              }),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
          ],
          if (sales.isEmpty && returns.isEmpty && ledger.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 40),
              child: pw.Center(
                child: pw.Text('No records found for selected date range',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
              ),
            ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _sectionTitle(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
  );

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