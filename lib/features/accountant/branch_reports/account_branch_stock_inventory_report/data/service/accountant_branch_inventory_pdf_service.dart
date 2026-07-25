import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../model/accountant_branch_stock_inventory_model.dart';

class AccountantBranchInventoryPdfService {
  static final _amtFmt = NumberFormat('#,##,###.##', 'en_IN');

  static String _fmtAmt(double v) => 'Rs ${_amtFmt.format(v)}';
  static String _fmtQty(double q) => q.toStringAsFixed(2);

  static String _statusLabel(StockStatus s) {
    switch (s) {
      case StockStatus.inStock: return 'In Stock';
      case StockStatus.lowStock: return 'Low Stock';
      case StockStatus.outOfStock: return 'Out of Stock';
    }
  }

  /// items: hamesha CURRENT FILTERED list pass karein (search + stock + category + diet)
  /// taake jo screen par dikh raha ho wahi PDF mein aaye.
  static Future<void> exportAndShare({
    required List<AccountantBranchInventoryModel> items,
    String? categoryName,
    StockStatus? stockFilter,
    bool deadStockOnly = false,
    String searchQuery = '',
  }) async {
    final bytes = await _buildPdf(
      items: items,
      categoryName: categoryName,
      stockFilter: stockFilter,
      deadStockOnly: deadStockOnly,
      searchQuery: searchQuery,
    );

    final fileName =
        'inventory_report_${DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now())}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<Uint8List> _buildPdf({
    required List<AccountantBranchInventoryModel> items,
    String? categoryName,
    StockStatus? stockFilter,
    bool deadStockOnly = false,
    String searchQuery = '',
  }) async {
    final doc = pw.Document();

    final qty = items.fold<double>(0, (s, i) => s + i.stock);
    final saleVal = items.fold<double>(0, (s, i) => s + (i.stock * i.salePrice));
    final purchaseVal = items.fold<double>(0, (s, i) => s + (i.stock * i.purchasePrice));

    // Active filters ka summary text — taake PDF mein pata chale konsa data hai
    final List<String> filterLabels = [];
    if (stockFilter != null) filterLabels.add(_statusLabel(stockFilter));
    if (deadStockOnly) filterLabels.add('Diet Product (No sale today)');
    if (categoryName != null && categoryName.isNotEmpty) {
      filterLabels.add('Category: $categoryName');
    }
    if (searchQuery.isNotEmpty) filterLabels.add('Search: "$searchQuery"');
    final filterText = filterLabels.isEmpty ? 'All Products' : filterLabels.join('   •   ');

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
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
                    pw.Text('Inventory Report',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text(filterText,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(dateStr, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                _summaryBox('Products', '${items.length}'),
                pw.SizedBox(width: 8),
                _summaryBox('Total Qty', _fmtQty(qty)),
                pw.SizedBox(width: 8),
                _summaryBox('Purchase Value', _fmtAmt(purchaseVal)),
                pw.SizedBox(width: 8),
                _summaryBox('Sale Value', _fmtAmt(saleVal)),
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
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.centerRight,
              8: pw.Alignment.centerRight,
              9: pw.Alignment.centerRight,
              10: pw.Alignment.center,
            },
            headers: const [
              '#', 'Product', 'Category', 'SKU', 'Unit', 'Stock', 'Min/Max',
              'Purchase', 'Sale', 'Wholesale', 'Status',
            ],
            data: List.generate(items.length, (i) {
              final it = items[i];
              return [
                '${i + 1}',
                it.productName,
                it.categoryName,
                it.sku,
                it.unit,
                _fmtQty(it.stock),
                '${_fmtQty(it.minStock)}/${_fmtQty(it.maxStock)}',
                _fmtAmt(it.purchasePrice),
                _fmtAmt(it.salePrice),
                _fmtAmt(it.wholesalePrice),
                _statusLabel(it.stockStatus),
              ];
            }),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
        ],
      ),
    );

    return doc.save();
  }

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