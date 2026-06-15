import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:jan_ghani_final/features/branch/reports/data/model/sale_invoice_report_model.dart';

class SaleInvoicePrintService {
  static const double _paperWidth = 72 * PdfPageFormat.mm;

  static Future<Printer> _getThermalPrinter() async {
    final printers = await Printing.listPrinters();
    return printers.firstWhere(
          (p) => p.name.toLowerCase().contains('blackcopper'),
      orElse: () => printers.first,
    );
  }

  static Future<void> printInvoice({
    required String storeName,
    required SaleInvoiceListModel invoice,
  }) async {
    final doc     = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('hh:mm a');

    final double subtotal =
    invoice.items.fold(0.0, (s, i) => s + (i.totalAmount as double? ?? 0.0));

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat(
        _paperWidth,
        double.infinity,
        marginTop:    3 * PdfPageFormat.mm,
        marginBottom: 3 * PdfPageFormat.mm,
        marginLeft:   3 * PdfPageFormat.mm,
        marginRight:  3 * PdfPageFormat.mm,
      ),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── Store Header ───────────────────────────────────
          pw.Center(
            child: pw.Text(
              storeName.toUpperCase(),
              style: pw.TextStyle(
                fontSize:      13,
                fontWeight:    pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              'SALE INVOICE',
              style: pw.TextStyle(
                fontSize:   8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 3),
          _dashedLine(),

          // ── Invoice Info ───────────────────────────────────
          _infoRow('INVOICE NO:', invoice.invoiceNo),
          _infoRow('DATE:', dateFmt.format(invoice.invoiceDate)),
          _infoRow('TIME:', timeFmt.format(invoice.invoiceDate)),
          _infoRow('CUSTOMER:', invoice.customerName ?? 'WALK IN'),
          if (invoice.counterName != null)
            _infoRow('COUNTER:', invoice.counterName!),
          if (invoice.cashierName != null)
            _infoRow('CASHIER:', invoice.cashierName!.toUpperCase()),
          if (invoice.notes != null &&
              invoice.notes.toString().trim().isNotEmpty)
            _infoRow('NOTE:', invoice.notes.toString()),
          pw.SizedBox(height: 3),
          _dashedLine(),

          // ── Items Header ───────────────────────────────────
          _itemsHeader(),
          _thinDashedLine(),

          // ── Items ──────────────────────────────────────────
          ...invoice.items.map(
                (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(
                      item.productName,
                      style: const pw.TextStyle(fontSize: 7.5),
                      maxLines: 2,
                    ),
                  ),
                  pw.SizedBox(width: 2),
                  pw.SizedBox(
                    width: 22,
                    child: pw.Text(
                      item.qtyLabel,
                      style: const pw.TextStyle(fontSize: 7.5),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(
                    width: 28,
                    child: pw.Text(
                      item.priceLabel,
                      style: const pw.TextStyle(fontSize: 7.5),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(
                    width: 20,
                    child: pw.Text(
                      item.discount.toStringAsFixed(0),
                      style: const pw.TextStyle(fontSize: 7.5),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(
                    width: 32,
                    child: pw.Text(
                      item.totalLabel,
                      style: const pw.TextStyle(fontSize: 7.5),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 2),
          _dashedLine(),

          // ── Totals ─────────────────────────────────────────
          _infoRow('SUB TOTAL:', _fmt(subtotal)),
          if (invoice.totalDiscount > 0)
            _infoRow('DISCOUNT:', '-${_fmt(invoice.totalDiscount)}'),
          pw.SizedBox(height: 1),
          _infoRowBold('NET TOTAL:', invoice.grandTotalLabel),
          pw.SizedBox(height: 2),
          _infoRow('PAYMENT:', invoice.paymentType.toUpperCase()),
          pw.SizedBox(height: 3),
          _dashedLine(),

          // ── Footer ─────────────────────────────────────────
          pw.SizedBox(height: 2),
          pw.Text('1) NO WARRANTY WITHOUT ORIGINAL INVOICE.',
              style: const pw.TextStyle(fontSize: 6.5)),
          pw.Text('2) DAMAGED OR BURNT ITEMS HAVE NO WARRANTY.',
              style: const pw.TextStyle(fontSize: 6.5)),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              'SOFTWARE BY',
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Center(
            child: pw.Text(
              'www.janghani.com',
              style: const pw.TextStyle(fontSize: 7),
            ),
          ),
          pw.SizedBox(height: 8),
        ],
      ),
    ));

    final printer = await _getThermalPrinter();
    try {
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => doc.save(),
        name: 'Invoice_${invoice.invoiceNo}',
      );
      debugPrint('✅ Invoice Print OK: ${invoice.invoiceNo}');
    } catch (e) {
      debugPrint('❌ Invoice Print failed: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────
  static pw.Widget _dashedLine() => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.SizedBox(
      width: double.infinity,
      child: pw.Text(
        '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
        style: const pw.TextStyle(fontSize: 7),
        softWrap: false,
        overflow: pw.TextOverflow.clip,
      ),
    ),
  );

  static pw.Widget _thinDashedLine() => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.SizedBox(
      width: double.infinity,
      child: pw.Text(
        '  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -',
        style: const pw.TextStyle(fontSize: 6),
        softWrap: false,
        overflow: pw.TextOverflow.clip,
      ),
    ),
  );

  static pw.Widget _infoRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 1.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.Flexible(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    ),
  );

  static pw.Widget _infoRowBold(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 1.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style:
            pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.Text(value,
            style:
            pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );

  static pw.Widget _itemsHeader() => pw.Row(
    children: [
      pw.Expanded(
        flex: 5,
        child: pw.Text('ITEM',
            style: pw.TextStyle(
                fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
      ),
      pw.SizedBox(width: 2),
      pw.SizedBox(
        width: 22,
        child: pw.Text('QTY',
            style: pw.TextStyle(
                fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center),
      ),
      pw.SizedBox(
        width: 28,
        child: pw.Text('RATE',
            style: pw.TextStyle(
                fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center),
      ),
      pw.SizedBox(
        width: 20,
        child: pw.Text('DIS',
            style: pw.TextStyle(
                fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center),
      ),
      pw.SizedBox(
        width: 32,
        child: pw.Text('AMT',
            style: pw.TextStyle(
                fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right),
      ),
    ],
  );

  static String _fmt(double v) =>
      v % 1 == 0 ? '${v.toInt()}.00' : v.toStringAsFixed(2);
}