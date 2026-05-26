import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CustomerLedgerPrintService {
  static const double _paperWidth = 72 * PdfPageFormat.mm;

  // ── Printer ─────────────────────────────────────────────
  static Future<Printer> _getThermalPrinter() async {
    final printers = await Printing.listPrinters();
    return printers.firstWhere(
          (p) => p.name.toLowerCase().contains('blackcopper'),
      orElse: () => printers.first,
    );
  }

  // ── Main Print Method ────────────────────────────────────
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
    final doc = pw.Document();
    final dateFmt = DateFormat('dd-MM-yyyy hh:mm a');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          _paperWidth,
          double.infinity,
          marginAll: 2 * PdfPageFormat.mm,
        ),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Store Name ──────────────────────────────
            pw.Center(
              child: pw.Text(
                storeName,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 1),

            // ── Receipt Title ───────────────────────────
            pw.Center(
              child: pw.Text(
                'Payment Receipt',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            _thinDivider(),

            // ── Counter & Date ──────────────────────────
            _kv('Counter', counterName),
            _kv('Date', dateFmt.format(date)),
            _thinDivider(),

            // ── Customer ────────────────────────────────
            _kv('Customer', customerName),
            _thinDivider(),

            // ── Amounts ─────────────────────────────────
            _kv('Previous Balance', 'Rs ${previousAmount.toStringAsFixed(2)}'),
            _kv('Amount Paid', 'Rs ${payAmount.toStringAsFixed(2)}'),
            _thinDivider(),
            _kvBold(
              'Due Amount',
              'Rs ${dueAmount.toStringAsFixed(2)}',
            ),
            _thinDivider(),

            // ── Notes ───────────────────────────────────
            if (notes != null && notes.isNotEmpty) ...[
              _kv('Notes', notes),
              _thinDivider(),
            ],

            pw.SizedBox(height: 4),

            // ── Footer Message ──────────────────────────
            pw.Center(
              child: pw.Text(
                dueAmount == 0
                    ? '*** Account Clear ***'
                    : dueAmount < 0
                    ? '*** Advance Paid ***'
                    : '*** Thank You ***',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
          ],
        ),
      ),
    );

    // ── Print ────────────────────────────────────────────
    try {
      final printer = await _getThermalPrinter();
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => doc.save(),
        name: 'Ledger_$customerName',
      );
      debugPrint('✅ Ledger receipt printed');
    } catch (e) {
      debugPrint('❌ Print failed: $e');
      rethrow;
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  static pw.Widget _thinDivider() =>
      pw.Divider(thickness: 0.3, color: PdfColors.black);

  // Key-Value row — ab bold hai
  static pw.Widget _kv(String k, String v) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          k,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.Text(
          v,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ],
    ),
  );

  // Key-Value row bold — sirf black color
  static pw.Widget _kvBold(String k, String v) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          k,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.Text(
          v,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ],
    ),
  );
}