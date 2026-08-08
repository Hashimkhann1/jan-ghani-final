import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../features/branch/reports/data/model/csr_model.dart';

class CsrPrintService {
  static const double _paperWidth = 72 * PdfPageFormat.mm;

  static Future<Printer> _getThermalPrinter() async {
    final printers = await Printing.listPrinters();
    return printers.firstWhere(
          (p) => p.name.toLowerCase().contains('blackcopper'),
      orElse: () => printers.first,
    );
  }

  // ── Print All Filtered Entries ─────────────────────────────
  static Future<void> printCsrReport({
    required String storeName,
    required String branchAddress,
    required String branchPhone,
    required String customerName,
    required String customerId,
    required DateTime fromDate,
    required DateTime toDate,
    required List<CsrEntry> entries,
    required double totalSaleAmount,
    required double totalReturnAmount,
    required double netAmount,
    required double totalDiscount,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('hh:mm a');
    final rangeFmt = DateFormat('dd MMM yyyy');

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
          // ── Store Header ─────────────────────────────────
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
          if (branchAddress.isNotEmpty)
            pw.Center(
              child: pw.Text(
                branchAddress,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
            ),
          if (branchPhone.isNotEmpty)
            pw.Center(
              child: pw.Text(
                branchPhone,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
            ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              'CUSTOMER SALE & RETURN REPORT',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 3),
          _dashedLine(),

          // ── Customer Info ────────────────────────────────
          _infoRow('CUSTOMER:', customerName.toUpperCase()),
          _infoRow('ID:', customerId),
          _infoRow(
            'PERIOD:',
            '${rangeFmt.format(fromDate)} - ${rangeFmt.format(toDate)}',
          ),
          pw.SizedBox(height: 3),
          _dashedLine(),

          // ── Summary ──────────────────────────────────────
          pw.Center(
            child: pw.Text(
              'SUMMARY',
              style: pw.TextStyle(
                  fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 3),
          _infoRow(
            'TOTAL SALES (${entries.where((e) => e.type == CsrType.sale).length}):',
            _fmt(totalSaleAmount),
          ),
          _infoRow(
            'TOTAL RETURNS (${entries.where((e) => e.type == CsrType.saleReturn).length}):',
            '-${_fmt(totalReturnAmount)}',
          ),
          _infoRow('TOTAL DISCOUNT:', _fmt(totalDiscount)),
          pw.SizedBox(height: 1),
          _infoRowBold('NET AMOUNT:', _fmt(netAmount)),
          pw.SizedBox(height: 3),
          _dashedLine(),

          // ── Entries ──────────────────────────────────────
          ...entries.map((entry) {
            // ── Ledger Payment Entry ──────────────────────
            if (entry.type == CsrType.ledgerPayment) {
              final prev = entry.previousAmount ?? 0;
              final paid = entry.payAmount ?? 0;
              final remaining = entry.newAmount ?? 0;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue100,
                          borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(3)),
                        ),
                        child: pw.Text(
                          'PAYMENT',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Expanded(
                        child: pw.Text(
                          entry.entryNo,
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Text(
                        dateFmt.format(entry.entryDate),
                        style: const pw.TextStyle(fontSize: 7.5),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  _infoRow('TIME:', timeFmt.format(entry.entryDate)),
                  if (entry.cashierName != null)
                    _infoRow('CASHIER:', entry.cashierName!.toUpperCase()),
                  if (entry.counterName != null)
                    _infoRow('COUNTER:', entry.counterName!),
                  if (entry.notes != null && entry.notes!.isNotEmpty)
                    _infoRow('NOTE:', entry.notes!),
                  pw.SizedBox(height: 3),
                  _thinDashedLine(),
                  _infoRow('PREV BALANCE:', _fmt(prev)),
                  _infoRow('AMOUNT PAID:', _fmt(paid)),
                  _infoRowBold(
                    remaining > 0 ? 'REMAINING:' : 'CLEARED:',
                    _fmt(remaining),
                  ),
                  _thinDashedLine(),
                ],
              );
            }

            // ── Sale / Return Entry ───────────────────────
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: entry.type == CsrType.sale
                            ? PdfColors.green100
                            : PdfColors.red100,
                        borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        entry.type == CsrType.sale ? 'SALE' : 'RETURN',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: entry.type == CsrType.sale
                              ? PdfColors.green800
                              : PdfColors.red800,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                      child: pw.Text(
                        entry.entryNo,
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Text(
                      dateFmt.format(entry.entryDate),
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                _infoRow('TIME:', timeFmt.format(entry.entryDate)),
                if (entry.cashierName != null)
                  _infoRow('CASHIER:', entry.cashierName!.toUpperCase()),
                if (entry.counterName != null)
                  _infoRow('COUNTER:', entry.counterName!),
                if (entry.type == CsrType.saleReturn &&
                    entry.returnReason != null &&
                    entry.returnReason!.isNotEmpty)
                  _infoRow('REASON:', entry.returnReason!),
                pw.SizedBox(height: 2),
                _thinDashedLine(),
                _itemsHeader(),
                _thinDashedLine(),
                ...entry.items.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(item.productName,
                            style: const pw.TextStyle(fontSize: 7.5),
                            maxLines: 2),
                      ),
                      pw.SizedBox(width: 2),
                      pw.SizedBox(
                        width: 22,
                        child: pw.Text(item.qtyLabel,
                            style: const pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.SizedBox(
                        width: 28,
                        child: pw.Text(
                            item.salePrice.toStringAsFixed(0),
                            style: const pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.SizedBox(
                        width: 20,
                        child: pw.Text(
                            item.discount.toStringAsFixed(0),
                            style: const pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.SizedBox(
                        width: 32,
                        child: pw.Text(
                            item.totalAmount.toStringAsFixed(0),
                            style: const pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                )),
                pw.SizedBox(height: 2),
                _infoRow('DISCOUNT:', '-${_fmt(entry.totalDiscount)}'),
                _infoRowBold(
                  entry.type == CsrType.sale ? 'TOTAL:' : 'REFUND:',
                  _fmt(entry.grandTotal),
                ),
                _thinDashedLine(),
              ],
            );
          }),

          pw.SizedBox(height: 4),
          _dashedLine(),

          // ── Footer Summary ───────────────────────────────
          _infoRowBold('NET AMOUNT:', _fmt(netAmount)),
          pw.SizedBox(height: 3),
          _dashedLine(),
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
        name: 'CSR_${customerName}_${DateFormat('ddMMyyyy').format(fromDate)}',
      );
      debugPrint('✅ CSR Print OK');
    } catch (e) {
      debugPrint('❌ CSR Print failed: $e');
    }
  }

  // ── Print Single Entry ─────────────────────────────────────
  static Future<void> printSingleEntry({
    required String storeName,
    required String branchAddress,
    required String branchPhone,
    required CsrEntry entry,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('hh:mm a');
    final isSale = entry.type == CsrType.sale;

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
          if (branchAddress.isNotEmpty)
            pw.Center(
              child: pw.Text(
                branchAddress,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
            ),
          if (branchPhone.isNotEmpty)
            pw.Center(
              child: pw.Text(
                branchPhone,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
            ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              isSale ? 'SALE INVOICE' : 'RETURN INVOICE',
              style: pw.TextStyle(
                  fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 3),
          _dashedLine(),

          // Info
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CUSTOMER:', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(width: 4),
              pw.Expanded(
                child: pw.Text(
                  entry.customerName?.toUpperCase() ?? 'WALK IN',
                  style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 1.5),
          if (entry.cashierName != null)
            _infoRow('CASHIER:', entry.cashierName!.toUpperCase()),
          _infoRow('DATE:', dateFmt.format(entry.entryDate)),
          _infoRow('TIME:', timeFmt.format(entry.entryDate)),
          _infoRow(isSale ? 'INVOICE:' : 'RETURN NO:', entry.entryNo),
          if (!isSale &&
              entry.returnReason != null &&
              entry.returnReason!.isNotEmpty)
            _infoRow('REASON:', entry.returnReason!),
          pw.SizedBox(height: 3),
          _dashedLine(),
          _itemsHeader(),
          _thinDashedLine(),

          // Items
          ...entry.items.map((item) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Text(item.productName,
                      style: const pw.TextStyle(fontSize: 7.5),
                      maxLines: 2),
                ),
                pw.SizedBox(width: 2),
                pw.SizedBox(
                  width: 22,
                  child: pw.Text(item.qtyLabel,
                      style: const pw.TextStyle(fontSize: 7.5),
                      textAlign: pw.TextAlign.center),
                ),
                pw.SizedBox(
                  width: 28,
                  child: pw.Text(item.salePrice.toStringAsFixed(0),
                      style: const pw.TextStyle(fontSize: 7.5),
                      textAlign: pw.TextAlign.center),
                ),
                pw.SizedBox(
                  width: 20,
                  child: pw.Text(item.discount.toStringAsFixed(0),
                      style: const pw.TextStyle(fontSize: 7.5),
                      textAlign: pw.TextAlign.center),
                ),
                pw.SizedBox(
                  width: 32,
                  child: pw.Text(item.totalAmount.toStringAsFixed(0),
                      style: const pw.TextStyle(fontSize: 7.5),
                      textAlign: pw.TextAlign.right),
                ),
              ],
            ),
          )),

          pw.SizedBox(height: 2),
          _dashedLine(),
          _infoRow(
              'SUB TOTAL:',
              _fmt(entry.items
                  .fold(0.0, (s, i) => s + i.totalAmount))),
          if (entry.totalDiscount > 0)
            _infoRow('DISCOUNT:', '-${_fmt(entry.totalDiscount)}'),
          pw.SizedBox(height: 1),
          _infoRowBold(
            isSale ? 'NET TOTAL:' : 'REFUND AMT:',
            _fmt(entry.grandTotal),
          ),
          pw.SizedBox(height: 3),
          _dashedLine(),

          // QR Code for customer
          if (entry.customerId != null && entry.customerId!.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'https://janghani.netlify.app/${entry.customerId}',
                width: 60,
                height: 60,
              ),
            ),
            pw.SizedBox(height: 4),
            _dashedLine(),
          ],

          pw.SizedBox(height: 2),
          pw.Text('1) NO WARRANTY WITHOUT ORIGINAL INVOICE.',
              style: const pw.TextStyle(fontSize: 6.5)),
          pw.Text('2) DAMAGED OR BURNT ITEMS HAVE NO WARRANTY.',
              style: const pw.TextStyle(fontSize: 6.5)),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text('SOFTWARE BY',
                style: pw.TextStyle(
                    fontSize: 7, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Center(
            child: pw.Text('www.janghani.com',
                style: const pw.TextStyle(fontSize: 7)),
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
        name: '${isSale ? 'Invoice' : 'Return'}_${entry.entryNo}',
      );
      debugPrint('✅ Single Entry Print OK');
    } catch (e) {
      debugPrint('❌ Single Entry Print failed: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────
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
          child: pw.Text(value,
              style: const pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.right),
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
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );

  static pw.Widget _itemsHeader() => pw.Row(children: [
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
  ]);

  static String _fmt(double v) =>
      v % 1 == 0 ? '${v.toInt()}.00' : v.toStringAsFixed(2);
}