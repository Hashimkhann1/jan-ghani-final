// lib/core/service/print/print_service.dart

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../features/branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../../../features/branch/sale_invoice/data/model/sale_return_model.dart';

class ThermalPrintService {
  static const double _paperWidth = 72 * PdfPageFormat.mm;

  static Future<Printer> _getThermalPrinter() async {
    final printers = await Printing.listPrinters();
    for (final p in printers) {
      debugPrint('🖨️ Printer: ${p.name} | Default: ${p.isDefault}');
    }
    return printers.firstWhere(
          (p) => p.name.toLowerCase().contains('blackcopper'),
      orElse: () => printers.first,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SALE INVOICE
  // ═══════════════════════════════════════════════════════════
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
    required String cashierName,
    double? returnAmount,
    double? previousBalance,
    double? paidAmount,
    double? currentBalance,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('hh:mm a');

    final hasCustomer = customerName != null && customerName.isNotEmpty;
    final isCreditSale = payments.any(
          (p) => p.method.toLowerCase() == 'credit' && p.amount > 0.01,
    );

    // ── Scenario detection ──────────────────────────────────
    // Scenario 1: Walk-in — no customer selected
    // Scenario 2: Full credit — customer + credit only (no cash/card)
    // Scenario 3: Partial — customer + some cash/card + some credit

    final cashPaid = payments
        .where((p) => p.method.toLowerCase() == 'cash' && p.amount > 0.01)
        .fold(0.0, (sum, p) => sum + p.amount);
    final cardPaid = payments
        .where((p) => p.method.toLowerCase() == 'card' && p.amount > 0.01)
        .fold(0.0, (sum, p) => sum + p.amount);
    final totalCashCard = cashPaid + cardPaid;

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat(
        _paperWidth,
        double.infinity,
        marginTop: 3 * PdfPageFormat.mm,
        marginBottom: 3 * PdfPageFormat.mm,
        marginLeft: 3 * PdfPageFormat.mm,
        marginRight: 3 * PdfPageFormat.mm,
      ),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── Store Header ───────────────────────────────────
          pw.Center(
            child: pw.Text(
              storeName.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              'MalangAbad Road Jaga Stop',
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ),
          pw.Center(
            child: pw.Text(
              '03489729366',
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ),
          pw.SizedBox(height: 3),
          _dashedLine(),

          // ── Invoice Info ───────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CUSTOMER:', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(width: 4),
              pw.Expanded(
                child: pw.Text(
                  hasCustomer
                      ? customerName!.toUpperCase()
                      : 'WALK IN CUSTOMER',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 1.5),
          _infoRow('CASHIER:', cashierName.toUpperCase()),
          _infoRow('DATE:', dateFmt.format(date)),
          _infoRow('TIME:', timeFmt.format(date)),
          _infoRow('INVOICE:', invoiceNo),
          pw.SizedBox(height: 3),
          _dashedLine(),

          // ── Items Header ───────────────────────────────────
          _itemsHeader(),
          _thinDashedLine(),

          // ── Items ──────────────────────────────────────────
          ...items.map(_itemRow),
          pw.SizedBox(height: 2),
          _dashedLine(),

          // ══════════════════════════════════════════════════
          // SCENARIO 1: Walk-in customer (no customer account)
          // SUB TOTAL → DISCOUNT → NET TOTAL → payments → return
          // ══════════════════════════════════════════════════
          if (!hasCustomer) ...[
            _infoRow('SUB TOTAL:', _fmt(totalAmount)),
            if (totalDiscount > 0)
              _infoRow('TOTAL DISCOUNT:', '-${_fmt(totalDiscount)}'),
            pw.SizedBox(height: 1),
            _infoRowBold('NET TOTAL:', _fmt(grandTotal)),
            pw.SizedBox(height: 3),
            _dashedLine(),
            ...payments
                .where((p) => p.amount > 0)
                .map((p) => _infoRow(_payLabel(p.method), _fmt(p.amount))),
            if (returnAmount != null && returnAmount > 0.01)
              _infoRow('RETURN:', _fmt(returnAmount)),
          ],

          // ══════════════════════════════════════════════════
          // SCENARIO 2: Full Credit (customer + zero cash/card)
          // SUB TOTAL → DISCOUNT → PREVIOUS BAL → NET AMOUNT
          // → payment rows → CURRENT BAL → credit note
          // ══════════════════════════════════════════════════
          if (hasCustomer && isCreditSale && totalCashCard < 0.01) ...[
            _infoRow('SUB TOTAL:', _fmt(totalAmount)),
            if (totalDiscount > 0)
              _infoRow('TOTAL DISCOUNT:', '-${_fmt(totalDiscount)}'),
            if (previousBalance != null && previousBalance > 0.01)
              _infoRowColored(
                  'PREVIOUS BAL:', _fmt(previousBalance), PdfColors.black),
            pw.SizedBox(height: 1),
            _infoRowBold('NET AMOUNT:', _fmt(grandTotal)),
            pw.SizedBox(height: 3),
            _dashedLine(),
            ...payments
                .where((p) => p.amount > 0)
                .map((p) => _infoRow(_payLabel(p.method), _fmt(p.amount))),
            pw.SizedBox(height: 3),
            _dashedLine(),
            if (currentBalance != null)
              _infoRowColoredBold(
                  'CURRENT BAL:', _fmt(currentBalance), PdfColors.black),
          ],

          // ══════════════════════════════════════════════════
          // SCENARIO 3: Partial Payment (customer + cash/card + credit)
          // SUB TOTAL → DISCOUNT → PREVIOUS BAL → NET AMOUNT
          // → payment rows → PAY AMOUNT → CURRENT BAL → credit note
          // ══════════════════════════════════════════════════
          if (hasCustomer && isCreditSale && totalCashCard > 0.01) ...[
            _infoRow('SUB TOTAL:', _fmt(totalAmount)),
            if (totalDiscount > 0)
              _infoRow('TOTAL DISCOUNT:', '-${_fmt(totalDiscount)}'),
            if (previousBalance != null && previousBalance > 0.01)
              _infoRowColored(
                  'PREVIOUS BAL:', _fmt(previousBalance), PdfColors.black),
            pw.SizedBox(height: 1),
            _infoRowBold('NET AMOUNT:', _fmt(grandTotal)),
            pw.SizedBox(height: 3),
            _dashedLine(),
            ...payments
                .where((p) => p.amount > 0)
                .map((p) => _infoRow(_payLabel(p.method), _fmt(p.amount))),
            pw.SizedBox(height: 3),
            _dashedLine(),
            if (paidAmount != null && paidAmount > 0.01)
              _infoRowColored(
                  'PAY AMOUNT:', _fmt(paidAmount), PdfColors.green800),
            if (currentBalance != null)
              _infoRowColoredBold(
                  'CURRENT BAL:', _fmt(currentBalance), PdfColors.black),
          ],

          // ══════════════════════════════════════════════════
          // SCENARIO 2 + 3: Customer with ZERO credit but cash paid
          // (pure cash/card sale for a customer account)
          // SUB TOTAL → DISCOUNT → PREVIOUS BAL → NET AMOUNT
          // → payments → PAY AMOUNT → CURRENT BAL
          // ══════════════════════════════════════════════════
          if (hasCustomer && !isCreditSale) ...[
            _infoRow('SUB TOTAL:', _fmt(totalAmount)),
            if (totalDiscount > 0)
              _infoRow('TOTAL DISCOUNT:', '-${_fmt(totalDiscount)}'),
            if (previousBalance != null && previousBalance > 0.01)
              _infoRowColored(
                  'PREVIOUS BAL:', _fmt(previousBalance), PdfColors.black),
            pw.SizedBox(height: 1),
            _infoRowBold('NET AMOUNT:', _fmt(grandTotal)),
            pw.SizedBox(height: 3),
            _dashedLine(),
            ...payments
                .where((p) => p.amount > 0)
                .map((p) => _infoRow(_payLabel(p.method), _fmt(p.amount))),
            if (returnAmount != null && returnAmount > 0.01)
              _infoRow('RETURN:', _fmt(returnAmount)),
            pw.SizedBox(height: 3),
            _dashedLine(),
            if (paidAmount != null && paidAmount > 0.01)
              _infoRowColored(
                  'PAY AMOUNT:', _fmt(paidAmount), PdfColors.green800),
            if (currentBalance != null && currentBalance > 0.01)
              _infoRowColoredBold(
                  'CURRENT BAL:', _fmt(currentBalance), PdfColors.black),
          ],

          pw.SizedBox(height: 3),
          _dashedLine(),

          // ── Credit Note (jab bhi credit ho) ───────────────
          if (isCreditSale) ...[
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                '*** CREDIT / UDHAR SALE ***',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 2),
            _dashedLine(),
          ],

          // ── Footer ─────────────────────────────────────────
          pw.SizedBox(height: 2),
          pw.Text(
            '1) NO WARRANTY WITHOUT ORIGINAL INVOICE.',
            style: const pw.TextStyle(fontSize: 6.5),
          ),
          pw.Text(
            '2) DAMAGED OR BURNT ITEMS HAVE NO WARRANTY.',
            style: const pw.TextStyle(fontSize: 6.5),
          ),
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
        name: 'Invoice_$invoiceNo',
      );
      debugPrint('✅ Print OK');
    } catch (e) {
      debugPrint('❌ Print failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SALE RETURN
  // ═══════════════════════════════════════════════════════════
  static Future<void> printSaleReturn({
    required String storeName,
    required String returnNo,
    required DateTime date,
    required String? customerName,
    required List<ReturnCartItem> items,
    required double totalAmount,
    required double totalDiscount,
    required double grandTotal,
    required List<PaymentEntry> payments,
    required String refundType,
    double? previousBalance,
    double? paidAmount,
    double? currentBalance,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('hh:mm a');
    final hasCustomer = customerName != null && customerName.isNotEmpty;

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat(
        _paperWidth,
        double.infinity,
        marginTop: 3 * PdfPageFormat.mm,
        marginBottom: 3 * PdfPageFormat.mm,
        marginLeft: 3 * PdfPageFormat.mm,
        marginRight: 3 * PdfPageFormat.mm,
      ),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(
              storeName.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              'MalangAbad Road Jaga Stop',
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ),
          pw.Center(
            child: pw.Text(
              '03489729366',
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ),
          pw.SizedBox(height: 3),
          _dashedLine(),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CUSTOMER:', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(width: 4),
              pw.Expanded(
                child: pw.Text(
                  hasCustomer ? customerName!.toUpperCase() : 'WALK IN',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 1.5),
          _infoRow('DATE:', dateFmt.format(date)),
          _infoRow('TIME:', timeFmt.format(date)),
          _infoRow('RETURN NO:', returnNo),
          pw.SizedBox(height: 3),
          _dashedLine(),
          _itemsHeader(),
          _thinDashedLine(),
          ...items.map(_returnItemRow),
          pw.SizedBox(height: 2),
          _dashedLine(),
          _infoRow('SUB TOTAL:', _fmt(totalAmount)),
          if (totalDiscount > 0)
            _infoRow('TOTAL DISCOUNT:', '-${_fmt(totalDiscount)}'),
          if (hasCustomer && previousBalance != null && previousBalance > 0.01)
            _infoRowColored(
                'PREVIOUS BAL:', _fmt(previousBalance), PdfColors.black),
          pw.SizedBox(height: 1),
          _infoRowBold('REFUND AMT:', _fmt(grandTotal)),
          pw.SizedBox(height: 3),
          _dashedLine(),
          ...payments
              .where((p) => p.amount > 0)
              .map((p) => _infoRow(_payLabel(p.method), _fmt(p.amount))),
          if (hasCustomer) ...[
            pw.SizedBox(height: 3),
            _dashedLine(),
            if (paidAmount != null && paidAmount > 0.01)
              _infoRowColored(
                  'PAY AMOUNT:', _fmt(paidAmount), PdfColors.green800),
            if (currentBalance != null)
              _infoRowColoredBold(
                  'CURRENT BAL:', _fmt(currentBalance), PdfColors.black),
          ],
          pw.SizedBox(height: 3),
          _dashedLine(),
          pw.SizedBox(height: 2),
          pw.Text(
            '1) NO WARRANTY WITHOUT ORIGINAL INVOICE.',
            style: const pw.TextStyle(fontSize: 6.5),
          ),
          pw.Text(
            '2) DAMAGED OR BURNT ITEMS HAVE NO WARRANTY.',
            style: const pw.TextStyle(fontSize: 6.5),
          ),
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
    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (_) async => doc.save(),
      name: 'Return_$returnNo',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════

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
        pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
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

  static pw.Widget _infoRowColored(
      String label, String value, PdfColor color) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 8,
                    color: color,
                    fontWeight: pw.FontWeight.normal)),
          ],
        ),
      );

  static pw.Widget _infoRowColoredBold(
      String label, String value, PdfColor color) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style:
                pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
          ],
        ),
      );

  static pw.Widget _itemsHeader() => pw.Row(children: [
    pw.Expanded(
        flex: 5,
        child: pw.Text('ITEM',
            style: pw.TextStyle(
                fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
    pw.SizedBox(width: 2),
    pw.SizedBox(
        width: 22,
        child: pw.Text('QTY',
            style: pw.TextStyle(
                fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center)),
    pw.SizedBox(
        width: 28,
        child: pw.Text('RATE',
            style: pw.TextStyle(
                fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center)),
    pw.SizedBox(
        width: 20,
        child: pw.Text('DIS',
            style: pw.TextStyle(
                fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center)),
    pw.SizedBox(
        width: 32,
        child: pw.Text('AMT',
            style: pw.TextStyle(
                fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right)),
  ]);

  static pw.Widget _itemRow(CartItem item) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
            flex: 5,
            child: pw.Text(item.product.name,
                style: const pw.TextStyle(fontSize: 7.5), maxLines: 2)),
        pw.SizedBox(width: 2),
        pw.SizedBox(
            width: 22,
            child: pw.Text(_qty(item.quantity),
                style: const pw.TextStyle(fontSize: 7.5),
                textAlign: pw.TextAlign.center)),
        pw.SizedBox(
            width: 28,
            child: pw.Text(item.salePrice.toStringAsFixed(0),
                style: const pw.TextStyle(fontSize: 7.5),
                textAlign: pw.TextAlign.center)),
        pw.SizedBox(
            width: 20,
            child: pw.Text(item.discountAmount.toStringAsFixed(0),
                style: const pw.TextStyle(fontSize: 7.5),
                textAlign: pw.TextAlign.center)),
        pw.SizedBox(
            width: 32,
            child: pw.Text(
                (item.subTotal - item.discountAmount).toStringAsFixed(0),
                style: const pw.TextStyle(fontSize: 7.5),
                textAlign: pw.TextAlign.right)),
      ],
    ),
  );

  static pw.Widget _returnItemRow(ReturnCartItem item) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
            flex: 5,
            child: pw.Text(item.product.name,
                style: const pw.TextStyle(fontSize: 7.5), maxLines: 2)),
        pw.SizedBox(width: 2),
        pw.SizedBox(
            width: 22,
            child: pw.Text(_qty(item.quantity),
                style: const pw.TextStyle(fontSize: 7.5),
                textAlign: pw.TextAlign.center)),
        pw.SizedBox(
            width: 28,
            child: pw.Text(item.returnPrice.toStringAsFixed(0),
                style: const pw.TextStyle(fontSize: 7.5),
                textAlign: pw.TextAlign.center)),
        pw.SizedBox(
            width: 20,
            child: pw.Text(item.discountAmount.toStringAsFixed(0),
                style: const pw.TextStyle(fontSize: 7.5),
                textAlign: pw.TextAlign.center)),
        pw.SizedBox(
            width: 32,
            child: pw.Text(item.subTotal.toStringAsFixed(0),
                style: const pw.TextStyle(fontSize: 7.5),
                textAlign: pw.TextAlign.right)),
      ],
    ),
  );

  static String _qty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  static String _fmt(double v) =>
      v % 1 == 0 ? '${v.toInt()}.00' : v.toStringAsFixed(2);

  static String _payLabel(String m) {
    switch (m.toLowerCase()) {
      case 'cash':
        return 'CASH:';
      case 'card':
        return 'CARD:';
      case 'credit':
        return 'CREDIT:';
      default:
        return '${m.toUpperCase()}:';
    }
  }
}