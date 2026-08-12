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
            ...sales.asMap().entries.map((e) => _invoiceBlock(e.key + 1, e.value)),
            pw.SizedBox(height: 8),
          ],
          if (returns.isNotEmpty) ...[
            _sectionTitle('Returns'),
            ...returns.asMap().entries.map((e) => _returnBlock(e.key + 1, e.value)),
            pw.SizedBox(height: 8),
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

  // ── Invoice block: header line + itemized product table ─────
  static pw.Widget _invoiceBlock(int index, CustomerInvoiceModel s) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('$index.  ${s.invoiceNo}',
                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    '${_dateFmt.format(s.invoiceDate)}  ${_timeFmt.format(s.invoiceDate)}   |   ${s.paymentType}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                pw.Text(s.grandTotalLabel,
                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
              headerDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headers: const ['Product', 'Qty', 'Price', 'Disc', 'Sub Total'],
              cellAlignments: const {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
              data: s.items
                  .map((it) => [
                it.productName,
                it.qtyLabel,
                it.salePriceLabel,
                it.discount > 0 ? _fmt(it.discount) : '-',
                it.totalLabel,
              ])
                  .toList(),
              border: null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Return block: header line + itemized product table ──────
  static pw.Widget _returnBlock(int index, CustomerReturnInvoice r) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('$index.  ${r.returnNo}',
                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    '${_dateFmt.format(r.returnDate)}  ${_timeFmt.format(r.returnDate)}   |   ${r.paymentLabel}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                pw.Text(_fmt(r.grandTotal),
                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
              headerDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headers: const ['Product', 'Qty', 'Price', 'Disc', 'Sub Total'],
              cellAlignments: const {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
              data: r.items
                  .map((it) => [
                it.productName,
                it.qtyLabel,
                it.salePriceLabel,
                it.discount > 0 ? _fmt(it.discount) : '-',
                _fmt(it.totalAmount),
              ])
                  .toList(),
              border: null,
            ),
          ),
        ],
      ),
    );
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