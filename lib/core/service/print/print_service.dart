// lib/features/branch/sale_invoice/presentation/service/thermal_print_service.dart
//
// REQUIRED PACKAGES (pubspec.yaml):
//   pdf: ^3.10.8
//   printing: ^5.12.0

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../features/branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../../../features/branch/sale_invoice/data/model/sale_return_model.dart';

class ThermalPrintService {
  static const double _paperWidth = 72 * PdfPageFormat.mm;

  // ── Thermal Printer dhundo ─────────────────────────────────────────────────
  static Future<Printer> _getThermalPrinter() async {
    final printers = await Printing.listPrinters();

    for (final p in printers) {
      debugPrint('🖨️ Printer found: ${p.name} | Default: ${p.isDefault}');
    }

    // ✅ FORCE BlackCopper select
    return printers.firstWhere(
          (p) => p.name.toLowerCase().contains('blackcopper'),
      orElse: () => printers.first,
    );
  }
  // ── Sale Invoice ───────────────────────────────────────────────────────────
  static Future<void> printSaleInvoice({
    required String storeName,
    required String invoiceNo,
    required DateTime date,
    required String? customerName,
    required List<CartItem> items,
    required double totalAmount,
    required double totalDiscount,
    required double grandTotal,
    required List<PaymentEntry> payments,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd-MM-yyyy  hh:mm a');

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
            pw.Center(
              child: pw.Text(
                storeName,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'MalangAbad Road Jaga Stop',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
              ),
            ),
            pw.Center(
              child: pw.Text(
                '03489729366',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
              ),
            ),
            _divider(),
            _kv('Invoice No', invoiceNo),
            _kv('Date', dateFmt.format(date)),
            _kv('Customer', (customerName != null && customerName.isNotEmpty) ? customerName : 'Walk In'),
            _divider(),
            _itemsHeader(),
            _thinDivider(),
            ...items.map(_invoiceRow),
            _divider(),
            _kv('Sub Total', 'Rs ${totalAmount.toStringAsFixed(0)}'),
            if (totalDiscount > 0)
              _kv('Discount', '-Rs ${totalDiscount.toStringAsFixed(0)}'),
            pw.SizedBox(height: 4),
            _kvBold('Grand Total', 'Rs ${grandTotal.toStringAsFixed(0)}'),
            _divider(),
            ...payments
                .where((p) => p.amount > 0)
                .map((p) => _kv(_label(p.method), 'Rs ${p.amount.toStringAsFixed(0)}')),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                '*** Thank you for your purchase! ***',
                style: const pw.TextStyle(fontSize: 7),
              ),
            ),
            pw.SizedBox(height: 10),
            // ✅ QR Code section
            // pw.Center(
            //   child: pw.BarcodeWidget(
            //     barcode: pw.Barcode.qrCode(),
            //     data: 'https://asnesa.com/invoice/$invoiceNo', // apna search URL ya ID
            //     width: 80,
            //     height: 80,
            //   ),
            // ),
          ],
        ),
      ),
    );

    final printer = await _getThermalPrinter();
    try {
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => doc.save(),
        name: 'Invoice_$invoiceNo',
      );
      debugPrint('✅ Print sent successfully');
    } catch (e) {
      debugPrint('❌ Print failed: $e');
    }
  }
  // ── Sale Return ────────────────────────────────────────────────────────────
  static Future<void> printSaleReturn({
    required String               storeName,
    required String               returnNo,
    required DateTime             date,
    required String?              customerName,
    required List<ReturnCartItem> items,
    required double               totalAmount,
    required double               totalDiscount,
    required double               grandTotal,
    required List<PaymentEntry>   payments,
    required String               refundType,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd-MM-yyyy  hh:mm a');

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat(
          _paperWidth, double.infinity, marginAll: 5 * PdfPageFormat.mm),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(child: pw.Text(storeName,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              'MalangAbad Road Jaga Stop',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
            ),
          ),
          pw.Center(
            child: pw.Text(
              '03489729366',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.normal),
            ),
          ),
          pw.SizedBox(height: 4),
          _divider(),
          _kv('Return No', returnNo),
          _kv('Date', dateFmt.format(date)),
          _kv('Customer',
              (customerName != null && customerName.isNotEmpty)
                  ? customerName
                  : 'Walk In'),
          _divider(),
          _itemsHeader(),
          _thinDivider(),
          ...items.map(_returnRow),
          _divider(),
          _kv('Sub Total', 'Rs ${totalAmount.toStringAsFixed(0)}'),
          if (totalDiscount > 0)
            _kv('Discount', '-Rs ${totalDiscount.toStringAsFixed(0)}'),
          pw.SizedBox(height: 4),
          _kvBold('Refund Amount', 'Rs ${grandTotal.toStringAsFixed(0)}'),
          pw.SizedBox(height: 4),
          _divider(),
          ...payments
              .where((p) => p.amount > 0)
              .map((p) => _kv(_label(p.method),
              'Rs ${p.amount.toStringAsFixed(0)}')),
          pw.SizedBox(height: 8),
          pw.Center(child: pw.Text('*** Return processed successfully ***',
              style: const pw.TextStyle(fontSize: 7))),
          pw.SizedBox(height: 20),
        ],
      ),
    ));

// ✅ Dialog nahi — seedha thermal printer pe print
    final printer = await _getThermalPrinter();
    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (_) async => doc.save(),
      name: 'Return_$returnNo',
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static pw.Widget _divider() => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Divider(thickness: 0.6, color: PdfColors.black),
  );

  static pw.Widget _thinDivider() => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Divider(thickness: 0.3, color: PdfColors.grey600),
  );

  static pw.Widget _kv(String k, String v) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(k, style: const pw.TextStyle(fontSize: 8)),
        pw.Text(v, style: const pw.TextStyle(fontSize: 8)),
      ],
    ),
  );

  static pw.Widget _kvBold(String k, String v) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(k,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      pw.Text(v,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
    ],
  );

  static pw.Widget _itemsHeader() => pw.Row(children: [
    pw.Expanded(flex: 4,
        child: pw.Text('Item',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
    pw.Expanded(flex: 2,
        child: pw.Text('Qty',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center)),
    pw.Expanded(flex: 2,
        child: pw.Text('Price',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center)),
    pw.Expanded(flex: 2,
        child: pw.Text('Dic',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center)),
    pw.Expanded(flex: 2,
        child: pw.Text('Total',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right)),
  ]);

  static pw.Widget _invoiceRow(CartItem item) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      children: [
        pw.Expanded(
          flex: 4,
          child: pw.Text(
            item.product.name,
            style: const pw.TextStyle(fontSize: 8),
            maxLines: 2,
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            _qty(item.quantity),
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            item.salePrice.toStringAsFixed(0),
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            '${item.discountAmount.toStringAsFixed(0)}', // ✅ discount column
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            (item.subTotal - item.discountAmount).toStringAsFixed(1), // ✅ net total after discount
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    ),
  );

  static pw.Widget _returnRow(ReturnCartItem item) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      pw.Row(children: [
        pw.Expanded(flex: 4,
            child: pw.Text(item.product.name,
                style: const pw.TextStyle(fontSize: 8), maxLines: 2)),
        pw.Expanded(flex: 2,
            child: pw.Text(_qty(item.quantity),
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center)),
        pw.Expanded(flex: 2,
            child: pw.Text(item.returnPrice.toStringAsFixed(0),
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center)),
        pw.Expanded(flex: 2,
            child: pw.Text(item.discountAmount.toStringAsFixed(0),
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.right)),
        pw.Expanded(flex: 2,
            child: pw.Text(item.subTotal.toStringAsFixed(0),
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.right)),
      ]),
      if (item.discountAmount > 0)
        pw.Text('  Dis: -Rs ${item.discountAmount.toStringAsFixed(0)}',
            style: const pw.TextStyle(fontSize: 7)),
    ]),
  );

  static String _qty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  static String _label(String m) {
    switch (m) {
      case 'cash':   return 'Cash';
      case 'card':   return 'Card';
      case 'credit': return 'Credit / Udhar';
      default:       return m;
    }
  }
}