import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../features/branch/dashboard/data/model/dashboard_model.dart';

class LowStockPrintService {
  static const double _paperWidth = 72 * PdfPageFormat.mm;

  // ── Printer ─────────────────────────────────────────────────
  static Future<Printer> _getThermalPrinter() async {
    final printers = await Printing.listPrinters();
    return printers.firstWhere(
          (p) => p.name.toLowerCase().contains('blackcopper'),
      orElse: () => printers.first,
    );
  }

  // ── Main Print Method ────────────────────────────────────────
  static Future<void> printReport({
    required String storeName,
    required List<LowStockItem> items,
    required DateTime date,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd-MM-yyyy hh:mm a');

    final outItems = items.where((i) => i.status == StockStatus.outOfStock).toList();
    final lowItems = items.where((i) => i.status == StockStatus.low).toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          _paperWidth,
          double.infinity,
          marginAll: 3 * PdfPageFormat.mm,
        ),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Store Name ──────────────────────────────────
            pw.Center(
              child: pw.Text(
                storeName,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 2),

            // ── Report Title ────────────────────────────────
            pw.Center(
              child: pw.Text(
                'Low Stock Report',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 1),

            // ── Date ────────────────────────────────────────
            pw.Center(
              child: pw.Text(
                dateFmt.format(date),
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
            _divider(),

            // ── Summary ─────────────────────────────────────
            _row('Total Selected', '${items.length}'),
            _row('Out of Stock', '${outItems.length}'),
            _row('Low Stock', '${lowItems.length}'),
            _divider(),

            // ── Table Header ─────────────────────────────────
            _tableHeader(),
            _thinDivider(),

            // ── Out of Stock Section ─────────────────────────
            if (outItems.isNotEmpty) ...[
              _sectionLabel('OUT OF STOCK'),
              ...outItems.map(_tableRow),
              _thinDivider(),
            ],

            // ── Low Stock Section ────────────────────────────
            if (lowItems.isNotEmpty) ...[
              _sectionLabel('LOW STOCK'),
              ...lowItems.map(_tableRow),
              _thinDivider(),
            ],

            pw.SizedBox(height: 4),

            // ── Footer ──────────────────────────────────────
            pw.Center(
              child: pw.Text(
                '*** Please restock the above items ***',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
          ],
        ),
      ),
    );

    // ── Print ──────────────────────────────────────────────────
    try {
      final printer = await _getThermalPrinter();
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => doc.save(),
        name: 'LowStock_${DateFormat('ddMMyyyy').format(date)}',
      );
      debugPrint('✅ Low stock report printed');
    } catch (e) {
      debugPrint('❌ Print failed: $e');
      rethrow;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────

  static pw.Widget _divider() =>
      pw.Divider(thickness: 0.5, color: PdfColors.black);

  static pw.Widget _thinDivider() =>
      pw.Divider(thickness: 0.3, color: PdfColors.black);

  static pw.Widget _sectionLabel(String label) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Text(
      label,
      style: pw.TextStyle(
        fontSize: 7,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      ),
    ),
  );

  // ── Table Header: ITEM | STOCK | MIN ────────────────────────
  static pw.Widget _tableHeader() => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Text(
            'ITEM',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),
        _headerCell('STOCK'),
        _headerCell('MIN'),  // ← sirf MIN, MAX hata diya
      ],
    ),
  );

  static pw.Widget _headerCell(String text) => pw.SizedBox(
    width: 30,
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      ),
    ),
  );

  // ── Table Row: name+sku | stock | minStock ───────────────────
  static pw.Widget _tableRow(LowStockItem item) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.name,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                maxLines: 2,
              ),
              if (item.sku.isNotEmpty)
                pw.Text(
                  item.sku,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
            ],
          ),
        ),
        _dataCell(_fmt(item.quantity)),
        _dataCell(_fmt(item.minStock)),
      ],
    ),
  );

  static pw.Widget _dataCell(String text) => pw.SizedBox(
    width: 30,
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      ),
    ),
  );

  static pw.Widget _row(String k, String v) => pw.Padding(
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

  static String _fmt(num v) =>
      v.truncateToDouble() == v ? v.toInt().toString() : v.toStringAsFixed(1);
}