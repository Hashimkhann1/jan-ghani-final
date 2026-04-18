// =============================================================
// po_invoice_screen.dart
// Purchase Order ka print invoice screen
// PurchaseOrderDetailDialog mein "Print Invoice" button se aayega
//
// Dependencies (pubspec.yaml mein add karo):
//   printing: ^5.12.0
//   pdf:      ^3.10.8
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_detail_models.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:jan_ghani_final/core/color/app_color.dart';

class PoInvoiceScreen extends StatelessWidget {
  final SupplierPurchaseOrder order;
  final SupplierModel         supplier;

  const PoInvoiceScreen({
    super.key,
    required this.order,
    required this.supplier,
  });

  // ── Static helper — easily navigate karo ─────────────────
  static void show(BuildContext context, SupplierPurchaseOrder order,
      SupplierModel supplier) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PoInvoiceScreen(order: order, supplier: supplier),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        children: [
          // ── Top action bar ─────────────────────────────
          _InvoiceTopBar(
            poNumber: order.poNumber,
            onBack:   () => Navigator.of(context).pop(),
            onPrint:  () => _printInvoice(context),
            onSavePdf: () => _savePdf(context),
          ),

          // ── Invoice preview ────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
              child: Center(
                child: _InvoiceCard(order: order, supplier: supplier),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PDF generate karo aur print karo ──────────────────────
  Future<void> _printInvoice(BuildContext context) async {
    final pdf = await _buildPdf();
    await Printing.layoutPdf(onLayout: (_) async => pdf);
  }

  // ── PDF save karo ─────────────────────────────────────────
  Future<void> _savePdf(BuildContext context) async {
    final pdf = await _buildPdf();
    await Printing.sharePdf(
      bytes:    pdf,
      filename: '${order.poNumber}.pdf',
    );
  }

  // ── PDF build karo ────────────────────────────────────────
  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin:     const pw.EdgeInsets.all(32),
        build:      (ctx) => _PdfInvoice(order: order, supplier: supplier).build(ctx),
      ),
    );
    return doc.save();
  }
}

// ─────────────────────────────────────────────────────────────
// TOP ACTION BAR
// ─────────────────────────────────────────────────────────────

class _InvoiceTopBar extends StatelessWidget {
  final String       poNumber;
  final VoidCallback onBack;
  final VoidCallback onPrint;
  final VoidCallback onSavePdf;

  const _InvoiceTopBar({
    required this.poNumber,
    required this.onBack,
    required this.onPrint,
    required this.onSavePdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color:  AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Back button
          InkWell(
            onTap:        onBack,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border:       Border.all(color: AppColor.grey200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded,
                      size: 13, color: AppColor.textSecondary),
                  const SizedBox(width: 6),
                  Text('Back',
                      style: TextStyle(fontSize: 13,
                          color: AppColor.textSecondary)),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: AppColor.grey200),
          const SizedBox(width: 16),

          // PO icon + number
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color:        AppColor.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.receipt_long_outlined,
                size: 15, color: AppColor.info),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(poNumber,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary)),
              Text('Invoice Preview',
                  style: TextStyle(fontSize: 11,
                      color: AppColor.textSecondary)),
            ],
          ),

          const Spacer(),

          // Save PDF button
          InkWell(
            onTap:        onSavePdf,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                border:       Border.all(color: AppColor.grey300),
                borderRadius: BorderRadius.circular(8),
                color:        AppColor.surface,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_outlined, size: 15,
                      color: AppColor.textSecondary),
                  const SizedBox(width: 6),
                  Text('Save PDF',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColor.textSecondary)),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Print button
          ElevatedButton.icon(
            onPressed:  onPrint,
            icon:       const Icon(Icons.print_rounded, size: 15),
            label:      const Text('Print Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.white,
              padding:         const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 16),
              minimumSize:     Size.zero,
              tapTargetSize:   MaterialTapTargetSize.shrinkWrap,
              shape:           RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INVOICE CARD — Flutter UI preview
// ─────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final SupplierPurchaseOrder order;
  final SupplierModel         supplier;

  const _InvoiceCard({required this.order, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  760,
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Header ─────────────────────────────────
          _InvHeader(order: order),

          // ── 2. Parties (Supplier + Buyer) ─────────────
          _InvParties(order: order, supplier: supplier),

          // ── 3. Dates row ──────────────────────────────
          _InvDates(order: order),

          // ── 4. Products table ─────────────────────────
          _InvProducts(order: order),

          // ── 5. Totals ─────────────────────────────────
          _InvTotals(order: order),

          // ── 6. Notes ──────────────────────────────────
          if (order.notes != null) _InvNotes(notes: order.notes!),

          // ── 7. Footer ─────────────────────────────────
          _InvFooter(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 1. HEADER
// ─────────────────────────────────────────────────────────────

class _InvHeader extends StatelessWidget {
  final SupplierPurchaseOrder order;
  const _InvHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final Color statusBg;
    switch (order.status) {
      case 'received':  statusColor = AppColor.success; statusBg = AppColor.successLight; break;
      case 'ordered':   statusColor = AppColor.info;    statusBg = AppColor.infoLight;    break;
      case 'partial':   statusColor = AppColor.warning; statusBg = AppColor.warningLight; break;
      case 'cancelled': statusColor = AppColor.error;   statusBg = AppColor.errorLight;   break;
      default:          statusColor = AppColor.grey500; statusBg = AppColor.grey200;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store brand
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jan Ghani',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary)),
              const SizedBox(height: 4),
              Text('General Store / Kiryana Shop',
                  style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
              Text('Hall Road, Lahore  •  0300-1234567',
                  style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
            ],
          ),

          const Spacer(),

          // PO number + date + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(order.poNumber,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                      color: AppColor.info)),
              const SizedBox(height: 4),
              Text('Invoice date: ${_fmtDate(order.orderDate)}',
                  style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: statusColor),
                    ),
                    const SizedBox(width: 5),
                    Text(order.statusLabel,
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600, color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year}';
}

// ─────────────────────────────────────────────────────────────
// 2. PARTIES
// ─────────────────────────────────────────────────────────────

class _InvParties extends StatelessWidget {
  final SupplierPurchaseOrder order;
  final SupplierModel         supplier;

  const _InvParties({required this.order, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supplier (From)
          Expanded(
            child: _PartyBox(
              label:    'FROM (SUPPLIER)',
              name:     supplier.name,
              details:  [
                if (supplier.contactPerson != null &&
                    supplier.contactPerson != supplier.name)
                  supplier.contactPerson!,
                if (supplier.address != null) supplier.address!,
                supplier.phone,
                if (supplier.taxId != null) 'NTN: ${supplier.taxId}',
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Buyer (To)
          Expanded(
            child: _PartyBox(
              label:   'TO (BUYER)',
              name:    'Jan Ghani Store',
              details: [
                'Hall Road, Lahore',
                'NTN: NTN-12345',
                'Payment Terms: ${supplier.paymentTerms} days',
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyBox extends StatelessWidget {
  final String       label;
  final String       name;
  final List<String> details;

  const _PartyBox({
    required this.label,
    required this.name,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: AppColor.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(name,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColor.textPrimary)),
        const SizedBox(height: 4),
        ...details.map((d) => Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(d,
              style: TextStyle(fontSize: 12,
                  color: AppColor.textSecondary)),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3. DATES ROW
// ─────────────────────────────────────────────────────────────

class _InvDates extends StatelessWidget {
  final SupplierPurchaseOrder order;
  const _InvDates({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      color:   AppColor.grey100,
      child: Row(
        children: [
          _DateItem(label: 'ORDER DATE',
              value: _fmtDate(order.orderDate)),
          _DateItem(
              label: 'EXPECTED DATE',
              value: order.expectedDate != null
                  ? _fmtDate(order.expectedDate!) : '—'),
          _DateItem(
              label:      'RECEIVED DATE',
              value:      order.receivedDate != null
                  ? _fmtDate(order.receivedDate!) : '—',
              valueColor: order.receivedDate != null
                  ? AppColor.success : null),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year}';
}

class _DateItem extends StatelessWidget {
  final String  label;
  final String  value;
  final Color?  valueColor;

  const _DateItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColor.textSecondary, letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColor.textPrimary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 4. PRODUCTS TABLE
// ─────────────────────────────────────────────────────────────

class _InvProducts extends StatelessWidget {
  final SupplierPurchaseOrder order;
  const _InvProducts({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColor.grey300)),
            ),
            child: Row(
              children: [
                _th('#  PRODUCT',  3),
                _th('ORDERED',     1),
                _th('RECEIVED',    1),
                _th('UNIT COST',   1),
                _th('TOTAL',       1),
                // _th('PROGRESS',    2),
              ],
            ),
          ),

          // Product rows
          ...order.items.asMap().entries.map((e) {
            final item     = e.value;
            final index    = e.key;
            final isLast   = index == order.items.length - 1;
            final pct      = item.receivedPercent;
            final pctColor = pct >= 1.0 ? AppColor.success
                : pct > 0 ? AppColor.warning : AppColor.error;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: isLast ? null
                    : Border(bottom: BorderSide(color: AppColor.grey100)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // # + Product name + SKU
                  Expanded(
                    flex: 3,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text('${index + 1}',
                              style: TextStyle(fontSize: 11,
                                  color: AppColor.textSecondary)),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.textPrimary)),
                            if (item.sku != null)
                              Text(item.sku!,
                                  style: TextStyle(fontSize: 11,
                                      color: AppColor.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Ordered
                  Expanded(
                    flex: 1,
                    child: Text('${item.quantityOrdered.toInt()}',
                        style: TextStyle(fontSize: 13,
                            color: AppColor.textPrimary)),
                  ),

                  // Received — colored
                  Expanded(
                    flex: 1,
                    child: Text('${item.quantityReceived.toInt()}',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w500, color: pctColor)),
                  ),

                  // Unit cost
                  Expanded(
                    flex: 1,
                    child: Text('Rs ${item.unitCost.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13,
                            color: AppColor.textSecondary)),
                  ),

                  // Total
                  Expanded(
                    flex: 1,
                    child: Text('Rs ${item.totalCost.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary)),
                  ),

                  // // Progress bar + %
                  // Expanded(
                  //   flex: 2,
                  //   child: Row(
                  //     children: [
                  //       Expanded(
                  //         child: ClipRRect(
                  //           borderRadius: BorderRadius.circular(3),
                  //           child: LinearProgressIndicator(
                  //             value:           pct,
                  //             minHeight:       4,
                  //             backgroundColor: pctColor.withOpacity(0.12),
                  //             valueColor:      AlwaysStoppedAnimation<Color>(
                  //                 pctColor),
                  //           ),
                  //         ),
                  //       ),
                  //       const SizedBox(width: 8),
                  //       SizedBox(
                  //         width: 34,
                  //         child: Text('${(pct * 100).toInt()}%',
                  //             style: TextStyle(fontSize: 10,
                  //                 fontWeight: FontWeight.w600,
                  //                 color: pctColor)),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _th(String label, int flex) => Expanded(
    flex: flex,
    child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
            color: AppColor.textSecondary, letterSpacing: 0.4)),
  );
}

// ─────────────────────────────────────────────────────────────
// 5. TOTALS
// ─────────────────────────────────────────────────────────────

class _InvTotals extends StatelessWidget {
  final SupplierPurchaseOrder order;
  const _InvTotals({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 280,
            child: Column(
              children: [
                _TotalRow(label: 'Subtotal',
                    value: _fmt(order.subtotal)),
                if (order.discountAmount > 0)
                  _TotalRow(
                    label:      'Discount',
                    value:      '- ${_fmt(order.discountAmount)}',
                    valueColor: AppColor.success,
                  ),
                if (order.taxAmount > 0)
                  _TotalRow(label: 'Tax', value: _fmt(order.taxAmount)),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColor.grey300),
                ),

                // Total bold
                _TotalRow(
                  label:       'Total Amount',
                  value:       _fmt(order.totalAmount),
                  isBold:      true,
                ),
                _TotalRow(
                  label:      'Paid',
                  value:      _fmt(order.paidAmount),
                  valueColor: AppColor.success,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColor.grey300),
                ),

                // Remaining
                _TotalRow(
                  label:      'Remaining',
                  value:      order.isFullyPaid
                      ? 'Clear' : _fmt(order.remainingAmount),
                  labelColor: order.isFullyPaid
                      ? AppColor.success : AppColor.error,
                  valueColor: order.isFullyPaid
                      ? AppColor.success : AppColor.error,
                  isBold:     true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}

class _TotalRow extends StatelessWidget {
  final String  label;
  final String  value;
  final Color?  labelColor;
  final Color?  valueColor;
  final bool    isBold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize:   isBold ? 14 : 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color:      labelColor ?? AppColor.textSecondary,
              )),
          Text(value,
              style: TextStyle(
                fontSize:   isBold ? 14 : 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                color:      valueColor ?? AppColor.textPrimary,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 6. NOTES
// ─────────────────────────────────────────────────────────────

class _InvNotes extends StatelessWidget {
  final String notes;
  const _InvNotes({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOTES',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColor.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        AppColor.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(notes,
                style: TextStyle(fontSize: 12,
                    color: AppColor.textSecondary, height: 1.7)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 7. FOOTER
// ─────────────────────────────────────────────────────────────

class _InvFooter extends StatelessWidget {
  const _InvFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 14, 32, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shukriya — Jan Ghani ke saath kaam karne ka.',
                  style: TextStyle(fontSize: 11,
                      color: AppColor.textSecondary)),
              Text('Koi masla ho to rabta karein: 0300-1234567',
                  style: TextStyle(fontSize: 11,
                      color: AppColor.textSecondary)),
            ],
          ),
          Text('Jan Ghani POS  •  Generated automatically',
              style: TextStyle(fontSize: 11, color: AppColor.grey400)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PDF BUILDER — printing package ke liye
// ─────────────────────────────────────────────────────────────

class _PdfInvoice {
  final SupplierPurchaseOrder order;
  final SupplierModel         supplier;

  const _PdfInvoice({required this.order, required this.supplier});

  pw.Widget build(pw.Context ctx) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Jan Ghani',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text('General Store / Kiryana Shop',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Hall Road, Lahore  •  0300-1234567',
                    style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(order.poNumber,
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${_fmtDate(order.orderDate)}',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Status: ${order.statusLabel}',
                    style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 12),

        // Parties
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('FROM (SUPPLIER)',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(supplier.name,
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  if (supplier.address != null)
                    pw.Text(supplier.address!,
                        style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(supplier.phone,
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('TO (BUYER)',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Jan Ghani Store',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Hall Road, Lahore',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Payment Terms: ${supplier.paymentTerms} days',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 12),

        // Products table header
        pw.Table(
          border:          pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(1.5),
            4: pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: ['Product', 'Ordered', 'Received', 'Unit Cost', 'Total']
                  .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(h,
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ))
                  .toList(),
            ),
            // Product rows
            ...order.items.map((item) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item.productName,
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      if (item.sku != null)
                        pw.Text(item.sku!,
                            style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('${item.quantityOrdered.toInt()}',
                      style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('${item.quantityReceived.toInt()}',
                      style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                      'Rs ${item.unitCost.toStringAsFixed(0)}',
                      style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                      'Rs ${item.totalCost.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            )),
          ],
        ),

        pw.SizedBox(height: 16),

        // Totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.SizedBox(
              width: 220,
              child: pw.Column(
                children: [
                  _pdfTotalRow('Subtotal', _fmt(order.subtotal)),
                  if (order.discountAmount > 0)
                    _pdfTotalRow('Discount', '- ${_fmt(order.discountAmount)}'),
                  _pdfTotalRow('Total Amount', _fmt(order.totalAmount), bold: true),
                  _pdfTotalRow('Paid', _fmt(order.paidAmount)),
                  _pdfTotalRow(
                    'Remaining',
                    order.isFullyPaid ? 'Clear' : _fmt(order.remainingAmount),
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
        ),

        if (order.notes != null) ...[
          pw.SizedBox(height: 16),
          pw.Text('Notes',
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(order.notes!,
              style: const pw.TextStyle(fontSize: 10)),
        ],

        pw.Spacer(),
        pw.Divider(),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Shukriya — Jan Ghani ke saath kaam karne ka.',
                style: const pw.TextStyle(fontSize: 9)),
            pw.Text('Jan Ghani POS  •  Generated automatically',
                style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfTotalRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: bold ? 11 : 10,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: bold ? 11 : 10,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year}';

  String _fmt(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}