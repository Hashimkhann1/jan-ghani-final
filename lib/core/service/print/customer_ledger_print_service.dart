import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CustomerLedgerPrintService {
  static const double _paperWidth = 72 * PdfPageFormat.mm;

  static Future<Printer> _getThermalPrinter() async {
    final printers = await Printing.listPrinters();
    return printers.firstWhere(
          (p) => p.name.toLowerCase().contains('blackcopper'),
      orElse: () => printers.first,
    );
  }

  static Future<void> printReceipt({
    required String storeName,
    required String counterName,
    required String customerName,
    required double previousAmount,
    required double payAmount,
    required double dueAmount,
    required DateTime date,
    String? notes,
  }) async {
    final doc    = pw.Document();
    final dateFmt = DateFormat('dd-MM-yyyy  hh:mm a');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          _paperWidth,
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Store Name ──────────────────────────────
            pw.Center(
              child: pw.Text(
                storeName,
                style: pw.TextStyle(
                    fontSize:   11,
                    fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                'Payment Receipt',
                style: pw.TextStyle(
                    fontSize:   9,
                    fontWeight: pw.FontWeight.bold),
              ),
            ),
            _divider(),

            // ── Info ────────────────────────────────────
            _kv('Counter', counterName),
            _kv('Date',    dateFmt.format(date)),
            _divider(),

            // ── Customer ────────────────────────────────
            _kv('Customer', customerName),
            _divider(),

            // ── Amounts ─────────────────────────────────
            _kv('Previous Balance',
                'Rs ${previousAmount.toStringAsFixed(0)}'),
            _kv('Amount Paid',
                'Rs ${payAmount.toStringAsFixed(0)}'),
            _thinDivider(),
            _kvBold(
              'Due Amount',
              'Rs ${dueAmount.toStringAsFixed(0)}',
              valueColor: dueAmount > 0
                  ? PdfColors.red
                  : dueAmount < 0
                  ? PdfColors.blue
                  : PdfColors.green,
            ),
            _divider(),

            // ── Notes ───────────────────────────────────
            if (notes != null && notes.isNotEmpty) ...[
              _kv('Notes', notes),
              _divider(),
            ],

            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                dueAmount == 0
                    ? '*** Account Clear ***'
                    : dueAmount < 0
                    ? '*** Advance Paid ***'
                    : '*** Shukriya ***',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
      ),
    );

    try {
      final printer = await _getThermalPrinter();
      await Printing.directPrintPdf(
        printer:  printer,
        onLayout: (_) async => doc.save(),
        name:     'Ledger_$customerName',
      );
      debugPrint('✅ Ledger receipt printed');
    } catch (e) {
      debugPrint('❌ Print failed: $e');
      rethrow;
    }
  }

  // ── Helpers ─────────────────────────────────────────────
  static pw.Widget _divider() => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Divider(thickness: 0.6, color: PdfColors.black),
  );

  static pw.Widget _thinDivider() => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Divider(thickness: 0.3, color: PdfColors.grey600),
  );

  static pw.Widget _kv(String k, String v) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(k, style: const pw.TextStyle(fontSize: 8)),
        pw.Text(v, style: const pw.TextStyle(fontSize: 8)),
      ],
    ),
  );

  static pw.Widget _kvBold(
      String k,
      String v, {
        PdfColor valueColor = PdfColors.black,
      }) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(k,
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(v,
              style: pw.TextStyle(
                  fontSize:   10,
                  fontWeight: pw.FontWeight.bold,
                  color:      valueColor)),
        ],
      );
}