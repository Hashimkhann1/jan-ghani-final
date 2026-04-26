import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart' as bc;
import 'package:barcode_widget/barcode_widget.dart';
import '../../data/model/product_model.dart';

/// PrintBarcodeWidget — Xprinter XP-420B
/// Label size: 40mm x 30mm
/// Fixes:
///   1. Label size 40x30mm (was 50x30 → cut off + blank sticker)
///   2. SVG barcode — no RepaintBoundary, no blank PNG ever
///   3. drawText: false → barcode number sirf 1 baar print hoga
///   4. Margins sahi → kuch bhi clip nahi hoga
class PrintBarcodeWidget extends StatefulWidget {
  final ProductModel product;

  const PrintBarcodeWidget({super.key, required this.product});

  static void show(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PrintBarcodeWidget(product: product),
    );
  }

  @override
  State<PrintBarcodeWidget> createState() => _PrintBarcodeWidgetState();
}

class _PrintBarcodeWidgetState extends State<PrintBarcodeWidget> {
  final TextEditingController _countController =
  TextEditingController(text: '1');
  bool _isPrinting = false;

  List<String> get _barcodes => widget.product.barcodes.isNotEmpty
      ? widget.product.barcodes
      : [widget.product.sku];

  int get _count {
    final v = int.tryParse(_countController.text.trim()) ?? 1;
    return v.clamp(1, 200);
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  Future<void> _printOne(String barcodeValue) async {
    await _doPrint(barcodes: [barcodeValue], copies: _count); // ← _count use karo, 1 nahi
  }

  Future<void> _printAll() async {
    await _doPrint(barcodes: _barcodes, copies: _count);
  }

  // SVG barcode — drawText:false → duplicate number band
  pw.Widget _buildPdfBarcode(String data) {
    final svgString = bc.Barcode.code128().toSvg(
      data,
      width: 34 * PdfPageFormat.mm,
      height: 11 * PdfPageFormat.mm,
      drawText: false,
    );
    return pw.SvgImage(svg: svgString);
  }

  // PDF — 40mm x 30mm
  Future<Uint8List> _buildPdf({
    required List<String> barcodes,
    required int copies,
  }) async {
    final fontRegular = await PdfGoogleFonts.nunitoRegular();
    final fontBold    = await PdfGoogleFonts.nunitoBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    const double labelW = 40 * PdfPageFormat.mm;
    const double labelH = 30 * PdfPageFormat.mm;
    const double margin =  2 * PdfPageFormat.mm;

    for (final barcode in barcodes) {
      for (int i = 0; i < copies; i++) {
        final barcodeWidget = _buildPdfBarcode(barcode);

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              labelW,
              labelH,
              marginAll: margin,
            ),
            build: (pw.Context ctx) {
              return pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'JAN GHANI',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 5,
                      letterSpacing: 1.2,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    widget.product.name.length > 26
                        ? '${widget.product.name.substring(0, 24)}...'
                        : widget.product.name,
                    style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                  ),
                  pw.SizedBox(height: 2),
                  pw.SizedBox(
                    width:  34 * PdfPageFormat.mm,
                    height: 12 * PdfPageFormat.mm,
                    child: barcodeWidget,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    barcode,
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 6,
                      letterSpacing: 1.2,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Rs. ${widget.product.sellingPrice.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              );
            },
          ),
        );
      }
    }

    return doc.save();
  }

  Future<void> _doPrint({
    required List<String> barcodes,
    required int copies,
  }) async {
    setState(() => _isPrinting = true);

    try {
      final pdfBytes = await _buildPdf(barcodes: barcodes, copies: copies);

      if (!mounted) return;

      final printers = await Printing.listPrinters().timeout(
        const Duration(seconds: 5),
        onTimeout: () => [],
      );

      if (!mounted) return;

      if (printers.isEmpty) {
        _showSnack('Koi printer nahi mila — USB check karo', isError: true);
        return;
      }

      final xprinter = printers.firstWhere(
            (p) =>
        p.name.toLowerCase().contains('xprint') ||
            p.name.toLowerCase().contains('420'),
        orElse: () => printers.firstWhere(
              (p) => p.isDefault,
          orElse: () => printers.first,
        ),
      );

      final result = await Printing.directPrintPdf(
        printer: xprinter,
        onLayout: (_) async => pdfBytes,
        name: '${widget.product.name}_Barcode',
      );

      if (mounted) {
        _showSnack(
          result ? '✅ Print ho gaya — ${xprinter.name}' : '❌ Print fail hua',
          isError: !result,
        );
        if (result) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Print Error: $e', isError: true, duration: 6);
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false, int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: duration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(product: widget.product),
              const SizedBox(height: 18),
              _CopiesRow(
                controller: _countController,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _barcodes.length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      itemBuilder: (_, i) => _BarcodeRow(
                        index: i,
                        barcodeValue: _barcodes[i],
                        productName: widget.product.name,
                        price: widget.product.sellingPrice,
                        isPrinting: _isPrinting,
                        onPrint: () => _printOne(_barcodes[i]),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: Color(0xFF6C7280),
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isPrinting ? null : _printAll,
                    icon: _isPrinting
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.print_rounded, size: 18),
                    label: Text(
                      _isPrinting
                          ? 'Printing...'
                          : 'Sab Print karo (${_count}x)',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// Header
class _Header extends StatelessWidget {
  final ProductModel product;
  const _Header({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.barcode_reader,
            color: Color(0xFF6366F1), size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Print Barcode',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23))),
            Text('${product.name}  •  SKU: ${product.sku}',
                overflow: TextOverflow.ellipsis,
                style:
                const TextStyle(fontSize: 12, color: Color(0xFF6C7280))),
          ],
        ),
      ),
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
        style:
        IconButton.styleFrom(backgroundColor: const Color(0xFFF3F4F6)),
      ),
    ]);
  }
}

// Copies Row
class _CopiesRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _CopiesRow({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        const Icon(Icons.content_copy_rounded,
            size: 18, color: Color(0xFF6366F1)),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('Har barcode ki copies',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D23))),
        ),
        _CountBtn(
          icon: Icons.remove,
          onTap: () {
            final v = int.tryParse(controller.text) ?? 1;
            if (v > 1) {
              controller.text = '${v - 1}';
              onChanged();
            }
          },
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6366F1))),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700),
            onChanged: (val) {
              final filtered = val.replaceAll(RegExp(r'[^0-9]'), '');
              if (filtered != val) {
                controller.value = TextEditingValue(
                  text: filtered,
                  selection:
                  TextSelection.collapsed(offset: filtered.length),
                );
              }
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        _CountBtn(
          icon: Icons.add,
          onTap: () {
            final v = int.tryParse(controller.text) ?? 1;
            controller.text = '${v + 1}';
            onChanged();
          },
        ),
      ]),
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CountBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6366F1)),
      ),
    );
  }
}

// Single Barcode Row
class _BarcodeRow extends StatelessWidget {
  final int index;
  final String barcodeValue;
  final String productName;
  final double price;
  final bool isPrinting;
  final VoidCallback onPrint;

  const _BarcodeRow({
    required this.index,
    required this.barcodeValue,
    required this.productName,
    required this.price,
    required this.isPrinting,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${index + 1}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('JAN GHANI',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1D23),
                          letterSpacing: 1.0)),
                  const SizedBox(height: 2),
                  Text(productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563))),
                  const SizedBox(height: 6),
                  BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: barcodeValue,
                    width: 180,
                    height: 44,
                    drawText: false,
                    color: Colors.black,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Text(barcodeValue,
                      style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Color(0xFF6C7280),
                          letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('Rs. ${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: '1 copy print karo',
            child: InkWell(
              onTap: isPrinting ? null : onPrint,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                child: const Icon(Icons.print_rounded,
                    size: 20, color: Color(0xFF6366F1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:barcode/barcode.dart' as bc;
// import 'package:barcode_widget/barcode_widget.dart';
// import '../../data/model/product_model.dart';
//
// /// PrintBarcodeWidget — Xprinter XP-420B
// /// Label size: 40mm x 30mm
// /// Fixes:
// ///   1. Label size 40x30mm (was 50x30 → cut off + blank sticker)
// ///   2. SVG barcode — no RepaintBoundary, no blank PNG ever
// ///   3. drawText: false → barcode number sirf 1 baar print hoga
// ///   4. Margins sahi → kuch bhi clip nahi hoga
// class PrintBarcodeWidget extends StatefulWidget {
//   final ProductModel product;
//
//   const PrintBarcodeWidget({super.key, required this.product});
//
//   static void show(BuildContext context, ProductModel product) {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (_) => PrintBarcodeWidget(product: product),
//     );
//   }
//
//   @override
//   State<PrintBarcodeWidget> createState() => _PrintBarcodeWidgetState();
// }
//
// class _PrintBarcodeWidgetState extends State<PrintBarcodeWidget> {
//   final TextEditingController _countController =
//   TextEditingController(text: '1');
//   bool _isPrinting = false;
//
//   List<String> get _barcodes => widget.product.barcodes.isNotEmpty
//       ? widget.product.barcodes
//       : [widget.product.sku];
//
//   int get _count {
//     final v = int.tryParse(_countController.text.trim()) ?? 1;
//     return v.clamp(1, 200);
//   }
//
//   @override
//   void dispose() {
//     _countController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _printOne(String barcodeValue) async {
//     await _doPrint(barcodes: [barcodeValue], copies: _count); // ← _count use karo, 1 nahi
//   }
//
//   Future<void> _printAll() async {
//     await _doPrint(barcodes: _barcodes, copies: _count);
//   }
//
//   // SVG barcode — drawText:false → duplicate number band
//   pw.Widget _buildPdfBarcode(String data) {
//     final svgString = bc.Barcode.code128().toSvg(
//       data,
//       width: 34 * PdfPageFormat.mm,
//       height: 11 * PdfPageFormat.mm,
//       drawText: false,
//     );
//     return pw.SvgImage(svg: svgString);
//   }
//
//   // PDF — 40mm x 30mm
//   Future<Uint8List> _buildPdf({
//     required List<String> barcodes,
//     required int copies,
//   }) async {
//     final fontRegular = await PdfGoogleFonts.nunitoRegular();
//     final fontBold    = await PdfGoogleFonts.nunitoBold();
//
//     final doc = pw.Document(
//       theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
//     );
//
//     const double labelW = 40 * PdfPageFormat.mm;
//     const double labelH = 30 * PdfPageFormat.mm;
//     const double margin =  2 * PdfPageFormat.mm;
//
//     for (final barcode in barcodes) {
//       for (int i = 0; i < copies; i++) {
//         final barcodeWidget = _buildPdfBarcode(barcode);
//
//         doc.addPage(
//           pw.Page(
//             pageFormat: PdfPageFormat(
//               labelW,
//               labelH,
//               marginAll: margin,
//             ),
//             build: (pw.Context ctx) {
//               return pw.Column(
//                 mainAxisAlignment: pw.MainAxisAlignment.center,
//                 crossAxisAlignment: pw.CrossAxisAlignment.center,
//                 children: [
//                   pw.Text(
//                     'JAN GHANI',
//                     style: pw.TextStyle(
//                       font: fontBold,
//                       fontSize: 8,
//                       letterSpacing: 1.2,
//                     ),
//                     textAlign: pw.TextAlign.center,
//                   ),
//                   pw.SizedBox(height: 1),
//                   pw.Text(
//                     widget.product.name.length > 26
//                         ? '${widget.product.name.substring(0, 24)}...'
//                         : widget.product.name,
//                     style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
//                     textAlign: pw.TextAlign.center,
//                     maxLines: 1,
//                   ),
//                   pw.SizedBox(height: 2),
//                   pw.SizedBox(
//                     width:  34 * PdfPageFormat.mm,
//                     height: 11 * PdfPageFormat.mm,
//                     child: barcodeWidget,
//                   ),
//                   pw.SizedBox(height: 1),
//                   pw.Text(
//                     barcode,
//                     style: pw.TextStyle(
//                       font: fontRegular,
//                       fontSize: 6,
//                       letterSpacing: 1.2,
//                     ),
//                     textAlign: pw.TextAlign.center,
//                   ),
//                   pw.SizedBox(height: 1.5),
//                   pw.Text(
//                     'Rs. ${widget.product.sellingPrice.toStringAsFixed(0)}',
//                     style: pw.TextStyle(
//                       font: fontBold,
//                       fontSize: 8,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                     textAlign: pw.TextAlign.center,
//                   ),
//                 ],
//               );
//             },
//           ),
//         );
//       }
//     }
//
//     return doc.save();
//   }
//
//   Future<void> _doPrint({
//     required List<String> barcodes,
//     required int copies,
//   }) async {
//     setState(() => _isPrinting = true);
//
//     try {
//       final pdfBytes = await _buildPdf(barcodes: barcodes, copies: copies);
//
//       if (!mounted) return;
//
//       final printers = await Printing.listPrinters().timeout(
//         const Duration(seconds: 5),
//         onTimeout: () => [],
//       );
//
//       if (!mounted) return;
//
//       if (printers.isEmpty) {
//         _showSnack('Koi printer nahi mila — USB check karo', isError: true);
//         return;
//       }
//
//       final xprinter = printers.firstWhere(
//             (p) =>
//         p.name.toLowerCase().contains('xprint') ||
//             p.name.toLowerCase().contains('420'),
//         orElse: () => printers.firstWhere(
//               (p) => p.isDefault,
//           orElse: () => printers.first,
//         ),
//       );
//
//       final result = await Printing.directPrintPdf(
//         printer: xprinter,
//         onLayout: (_) async => pdfBytes,
//         name: '${widget.product.name}_Barcode',
//       );
//
//       if (mounted) {
//         _showSnack(
//           result ? '✅ Print ho gaya — ${xprinter.name}' : '❌ Print fail hua',
//           isError: !result,
//         );
//         if (result) Navigator.pop(context);
//       }
//     } catch (e) {
//       if (mounted) {
//         _showSnack('Print Error: $e', isError: true, duration: 6);
//       }
//     } finally {
//       if (mounted) setState(() => _isPrinting = false);
//     }
//   }
//
//   void _showSnack(String msg, {bool isError = false, int duration = 3}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor:
//         isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
//         behavior: SnackBarBehavior.floating,
//         duration: Duration(seconds: duration),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       backgroundColor: Colors.white,
//       insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _Header(product: widget.product),
//               const SizedBox(height: 18),
//               _CopiesRow(
//                 controller: _countController,
//                 onChanged: () => setState(() {}),
//               ),
//               const SizedBox(height: 16),
//               Flexible(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF8F9FF),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: const Color(0xFFE5E7EB)),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: ListView.separated(
//                       shrinkWrap: true,
//                       itemCount: _barcodes.length,
//                       separatorBuilder: (_, __) =>
//                       const Divider(height: 1, color: Color(0xFFE5E7EB)),
//                       itemBuilder: (_, i) => _BarcodeRow(
//                         index: i,
//                         barcodeValue: _barcodes[i],
//                         productName: widget.product.name,
//                         price: widget.product.sellingPrice,
//                         isPrinting: _isPrinting,
//                         onPrint: () => _printOne(_barcodes[i]),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 18),
//               Row(children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       side: const BorderSide(color: Color(0xFFE5E7EB)),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                     ),
//                     child: const Text('Cancel',
//                         style: TextStyle(
//                             color: Color(0xFF6C7280),
//                             fontWeight: FontWeight.w600)),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   flex: 2,
//                   child: FilledButton.icon(
//                     onPressed: _isPrinting ? null : _printAll,
//                     icon: _isPrinting
//                         ? const SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(
//                           strokeWidth: 2, color: Colors.white),
//                     )
//                         : const Icon(Icons.print_rounded, size: 18),
//                     label: Text(
//                       _isPrinting
//                           ? 'Printing...'
//                           : 'Sab Print karo (${_count}x)',
//                       style: const TextStyle(
//                           fontWeight: FontWeight.w700, fontSize: 14),
//                     ),
//                     style: FilledButton.styleFrom(
//                       backgroundColor: const Color(0xFF6366F1),
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                     ),
//                   ),
//                 ),
//               ]),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // Header
// class _Header extends StatelessWidget {
//   final ProductModel product;
//   const _Header({required this.product});
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(children: [
//       Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: const Color(0xFFEEF2FF),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: const Icon(Icons.barcode_reader,
//             color: Color(0xFF6366F1), size: 22),
//       ),
//       const SizedBox(width: 12),
//       Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Print Barcode',
//                 style: TextStyle(
//                     fontSize: 17,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF1A1D23))),
//             Text('${product.name}  •  SKU: ${product.sku}',
//                 overflow: TextOverflow.ellipsis,
//                 style:
//                 const TextStyle(fontSize: 12, color: Color(0xFF6C7280))),
//           ],
//         ),
//       ),
//       IconButton(
//         onPressed: () => Navigator.pop(context),
//         icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
//         style:
//         IconButton.styleFrom(backgroundColor: const Color(0xFFF3F4F6)),
//       ),
//     ]);
//   }
// }
//
// // Copies Row
// class _CopiesRow extends StatelessWidget {
//   final TextEditingController controller;
//   final VoidCallback onChanged;
//   const _CopiesRow({required this.controller, required this.onChanged});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF8F9FF),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: Row(children: [
//         const Icon(Icons.content_copy_rounded,
//             size: 18, color: Color(0xFF6366F1)),
//         const SizedBox(width: 10),
//         const Expanded(
//           child: Text('Har barcode ki copies',
//               style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1A1D23))),
//         ),
//         _CountBtn(
//           icon: Icons.remove,
//           onTap: () {
//             final v = int.tryParse(controller.text) ?? 1;
//             if (v > 1) {
//               controller.text = '${v - 1}';
//               onChanged();
//             }
//           },
//         ),
//         const SizedBox(width: 8),
//         SizedBox(
//           width: 56,
//           child: TextField(
//             controller: controller,
//             keyboardType: TextInputType.number,
//             textAlign: TextAlign.center,
//             decoration: InputDecoration(
//               contentPadding:
//               const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//               border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
//               focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: const BorderSide(color: Color(0xFF6366F1))),
//               filled: true,
//               fillColor: Colors.white,
//             ),
//             style: const TextStyle(
//                 fontSize: 14, fontWeight: FontWeight.w700),
//             onChanged: (val) {
//               final filtered = val.replaceAll(RegExp(r'[^0-9]'), '');
//               if (filtered != val) {
//                 controller.value = TextEditingValue(
//                   text: filtered,
//                   selection:
//                   TextSelection.collapsed(offset: filtered.length),
//                 );
//               }
//               onChanged();
//             },
//           ),
//         ),
//         const SizedBox(width: 8),
//         _CountBtn(
//           icon: Icons.add,
//           onTap: () {
//             final v = int.tryParse(controller.text) ?? 1;
//             controller.text = '${v + 1}';
//             onChanged();
//           },
//         ),
//       ]),
//     );
//   }
// }
//
// class _CountBtn extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;
//   const _CountBtn({required this.icon, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(6),
//       child: Container(
//         padding: const EdgeInsets.all(4),
//         decoration: BoxDecoration(
//           color: const Color(0xFFEEF2FF),
//           borderRadius: BorderRadius.circular(6),
//         ),
//         child: Icon(icon, size: 16, color: const Color(0xFF6366F1)),
//       ),
//     );
//   }
// }
//
// // Single Barcode Row
// class _BarcodeRow extends StatelessWidget {
//   final int index;
//   final String barcodeValue;
//   final String productName;
//   final double price;
//   final bool isPrinting;
//   final VoidCallback onPrint;
//
//   const _BarcodeRow({
//     required this.index,
//     required this.barcodeValue,
//     required this.productName,
//     required this.price,
//     required this.isPrinting,
//     required this.onPrint,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Container(
//             width: 24,
//             height: 24,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: const Color(0xFFEEF2FF),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Text('${index + 1}',
//                 style: const TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF6366F1))),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Container(
//               padding:
//               const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: const Color(0xFFE5E7EB)),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   const Text('JAN GHANI',
//                       style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w800,
//                           color: Color(0xFF1A1D23),
//                           letterSpacing: 1.0)),
//                   const SizedBox(height: 2),
//                   Text(productName,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF4B5563))),
//                   const SizedBox(height: 6),
//                   BarcodeWidget(
//                     barcode: Barcode.code128(),
//                     data: barcodeValue,
//                     width: 180,
//                     height: 44,
//                     drawText: false,
//                     color: Colors.black,
//                     backgroundColor: Colors.white,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(barcodeValue,
//                       style: const TextStyle(
//                           fontSize: 10,
//                           fontFamily: 'monospace',
//                           color: Color(0xFF6C7280),
//                           letterSpacing: 1.2)),
//                   const SizedBox(height: 4),
//                   Text('Rs. ${price.toStringAsFixed(0)}',
//                       style: const TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF10B981))),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Tooltip(
//             message: '1 copy print karo',
//             child: InkWell(
//               onTap: isPrinting ? null : onPrint,
//               borderRadius: BorderRadius.circular(10),
//               child: Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFEEF2FF),
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: const Color(0xFFE0E7FF)),
//                 ),
//                 child: const Icon(Icons.print_rounded,
//                     size: 20, color: Color(0xFF6366F1)),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }