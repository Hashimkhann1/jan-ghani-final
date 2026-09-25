import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'report_excel_export.dart';

enum ReportExportFormat { excel, pdf, csv }

/// CSV and PDF renderers for the same [ExcelSheetData] the Excel export uses,
/// so every report can offer all three formats from one data definition.
class ReportFileExport {
  static final _stampFmt     = DateFormat('yyyy_MM_dd_HHmm');
  static final _generatedFmt = DateFormat('dd MMM yyyy, hh:mm a');
  static final _csvDateFmt   = DateFormat('yyyy-MM-dd HH:mm');
  static final _pdfDateFmt   = DateFormat('dd MMM yyyy hh:mm a');
  static final _amountFmt    = NumberFormat('#,##0.00');
  static final _qtyFmt       = NumberFormat('#,##0.##');

  static String _name(String prefix) =>
      '${prefix}_${_stampFmt.format(DateTime.now())}';

  static Future<void> saveFormat({
    required ReportExportFormat format,
    required String fileNamePrefix,
    required List<ExcelSheetData> sheets,
  }) {
    switch (format) {
      case ReportExportFormat.excel:
        return ReportExcelExport.save(
            fileNamePrefix: fileNamePrefix, sheets: sheets);
      case ReportExportFormat.pdf:
        return savePdf(fileNamePrefix: fileNamePrefix, sheets: sheets);
      case ReportExportFormat.csv:
        return saveCsv(fileNamePrefix: fileNamePrefix, sheets: sheets);
    }
  }

  // ── CSV ────────────────────────────────────────────────────────────────

  static Future<void> saveCsv({
    required String fileNamePrefix,
    required List<ExcelSheetData> sheets,
  }) async {
    await FileSaver.instance.saveFile(
      name:          _name(fileNamePrefix),
      bytes:         buildCsv(sheets),
      fileExtension: 'csv',
      mimeType:      MimeType.csv,
    );
  }

  /// UTF-8 with BOM so Excel opens non-ASCII text correctly. Numbers are
  /// written raw (no thousands separators) so they stay numeric on import.
  /// With several sheets, each is a titled block separated by a blank line.
  static Uint8List buildCsv(List<ExcelSheetData> sheets) {
    final b = StringBuffer();
    for (var i = 0; i < sheets.length; i++) {
      final s = sheets[i];
      if (sheets.length > 1) {
        if (i > 0) b.write('\r\n');
        b.write('${_csvCell(s.title)}\r\n');
      }
      b.write(s.columns.map((c) => _csvCell(c.header)).join(','));
      b.write('\r\n');
      for (final row in s.rows) {
        b.write(_csvRow(s, row));
      }
      if (s.totals != null) b.write(_csvRow(s, s.totals!));
    }
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(b.toString())]);
  }

  static String _csvRow(ExcelSheetData s, List<Object?> row) {
    final cells = <String>[
      for (var c = 0; c < s.columns.length; c++)
        _csvCell(_csvValue(c < row.length ? row[c] : null)),
    ];
    return '${cells.join(',')}\r\n';
  }

  static String _csvValue(Object? v) {
    if (v == null) return '';
    if (v is DateTime) return _csvDateFmt.format(v);
    return v.toString();
  }

  static String _csvCell(String v) {
    // Neutralise spreadsheet formula injection from user-entered text.
    var t = v;
    if (t.isNotEmpty && '=+@'.contains(t[0])) t = "'$t";
    if (t.contains(',') || t.contains('"') || t.contains('\n') || t.contains('\r')) {
      return '"${t.replaceAll('"', '""')}"';
    }
    return t;
  }

  // ── PDF ────────────────────────────────────────────────────────────────

  static Future<void> savePdf({
    required String fileNamePrefix,
    required List<ExcelSheetData> sheets,
  }) async {
    await FileSaver.instance.saveFile(
      name:          _name(fileNamePrefix),
      bytes:         await buildPdf(sheets),
      fileExtension: 'pdf',
      mimeType:      MimeType.pdf,
    );
  }

  /// The PDF's built-in Helvetica has no glyphs for these; swap them for
  /// plain-ASCII look-alikes so they don't render blank.
  static String _pdfText(String v) => v
      .replaceAll('→', '->')
      .replaceAll('−', '-')
      .replaceAll('—', '-')
      .replaceAll('•', '|');

  static String _pdfValue(ExcelColumn col, Object? v) {
    if (v == null) return '';
    if (v is String) return _pdfText(v);
    if (v is DateTime) return _pdfDateFmt.format(v);
    if (v is num) {
      switch (col.type) {
        case ExcelColType.amount:   return _amountFmt.format(v);
        case ExcelColType.quantity: return _qtyFmt.format(v);
        case ExcelColType.integer:  return v.toInt().toString();
        default:                    return v.toString();
      }
    }
    return v.toString();
  }

  static pw.Alignment _align(ExcelColType t) =>
      t == ExcelColType.text || t == ExcelColType.dateTime
          ? pw.Alignment.centerLeft
          : pw.Alignment.centerRight;

  static Future<Uint8List> buildPdf(List<ExcelSheetData> sheets) async {
    final doc = pw.Document();
    final generated = _generatedFmt.format(DateTime.now());

    for (final s in sheets) {
      final wide = s.columns.length > 6;
      final rows = <List<String>>[
        for (final r in s.rows)
          [
            for (var c = 0; c < s.columns.length; c++)
              _pdfValue(s.columns[c], c < r.length ? r[c] : null),
          ],
      ];
      if (s.totals != null) {
        rows.add([
          for (var c = 0; c < s.columns.length; c++)
            _pdfValue(s.columns[c], c < s.totals!.length ? s.totals![c] : null),
        ]);
      }
      final hasTotals = s.totals != null;

      doc.addPage(
        pw.MultiPage(
          pageFormat: wide ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(_pdfText(s.title),
                            style: pw.TextStyle(
                                fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        if (s.subtitle.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(_pdfText(s.subtitle),
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.grey700)),
                        ],
                      ],
                    ),
                  ),
                  pw.Text(generated,
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
              pw.SizedBox(height: 10),
            ],
          ),
          footer: (ctx) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
          ),
          build: (ctx) => [
            if (rows.isEmpty)
              pw.Text('No data', style: const pw.TextStyle(fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                    fontSize: wide ? 8 : 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellStyle: pw.TextStyle(fontSize: wide ? 7.5 : 8.5),
                oddRowDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey100),
                cellAlignments: {
                  for (var c = 0; c < s.columns.length; c++)
                    c: _align(s.columns[c].type),
                },
                headers: [for (final c in s.columns) _pdfText(c.header)],
                data: rows,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                // Bold the totals row.
                cellDecoration: (index, data, rowNum) =>
                    hasTotals && rowNum == rows.length
                        ? const pw.BoxDecoration(color: PdfColors.grey300)
                        : const pw.BoxDecoration(),
              ),
          ],
        ),
      );
    }
    return doc.save();
  }
}
