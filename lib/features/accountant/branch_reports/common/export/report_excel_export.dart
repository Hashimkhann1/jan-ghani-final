import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

/// How a column's values are written into the sheet. Numbers and dates are
/// stored as real Excel numbers/dates (not text) so the accountant can sum,
/// sort and filter them.
enum ExcelColType { text, integer, amount, quantity, dateTime }

class ExcelColumn {
  final String       header;
  final double       width;
  final ExcelColType type;

  const ExcelColumn(
    this.header, {
    this.width = 16,
    this.type  = ExcelColType.text,
  });
}

/// One worksheet: a title block, a header row, data rows and an optional
/// totals row. [rows] and [totals] hold one value per [columns] entry —
/// `String` for text, `num` for the numeric types, `DateTime` for dateTime.
class ExcelSheetData {
  final String             name;
  final String             title;
  final String             subtitle;
  final List<ExcelColumn>  columns;
  final List<List<Object?>> rows;
  final List<Object?>?     totals;

  const ExcelSheetData({
    required this.name,
    required this.title,
    this.subtitle = '',
    required this.columns,
    required this.rows,
    this.totals,
  });
}

class ReportExcelExport {
  static final _generatedFmt = DateFormat('dd MMM yyyy, hh:mm a');
  static final _stampFmt     = DateFormat('yyyy_MM_dd_HHmm');

  static final _amountFormat   = NumFormat.custom(formatCode: '#,##0.00');
  static final _quantityFormat = NumFormat.custom(formatCode: '#,##0.##');
  static final _dateTimeFormat = NumFormat.custom(formatCode: 'dd-mmm-yyyy hh:mm AM/PM');

  static final _titleStyle = CellStyle(bold: true, fontSize: 14);
  static final _metaStyle  = CellStyle(italic: true, fontColorHex: ExcelColor.grey700);
  static final _headerStyle = CellStyle(
    bold: true,
    fontColorHex:       ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
    horizontalAlign:    HorizontalAlign.Center,
    verticalAlign:      VerticalAlign.Center,
  );

  /// Builds the workbook and hands it to the platform's save/download flow.
  static Future<void> save({
    required String fileNamePrefix,
    required List<ExcelSheetData> sheets,
  }) async {
    final bytes = build(sheets);
    await FileSaver.instance.saveFile(
      name:          '${fileNamePrefix}_${_stampFmt.format(DateTime.now())}',
      bytes:         bytes,
      fileExtension: 'xlsx',
      mimeType:      MimeType.microsoftExcel,
    );
  }

  /// Pure workbook builder — no I/O, so it can be unit-tested.
  static Uint8List build(List<ExcelSheetData> sheets) {
    assert(sheets.isNotEmpty);
    final excel = Excel.createExcel();

    // createExcel() ships with a default "Sheet1"; reuse it for the first
    // sheet rather than leaving an empty tab behind.
    final defaultName = excel.getDefaultSheet();
    if (defaultName != null) excel.rename(defaultName, _safeName(sheets.first.name));

    for (final data in sheets) {
      _writeSheet(excel[_safeName(data.name)], data);
    }

    // encode(), not save(): on web save() triggers its own browser download,
    // and FileSaver would then download the file a second time.
    final out = excel.encode();
    if (out == null) throw StateError('Could not generate the Excel file');
    return Uint8List.fromList(out);
  }

  static void _writeSheet(Sheet sheet, ExcelSheetData data) {
    void put(int col, int row, CellValue? value, [CellStyle? style]) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      cell.value = value;
      if (style != null) cell.cellStyle = style;
    }

    put(0, 0, TextCellValue(data.title), _titleStyle);
    final meta = [
      if (data.subtitle.isNotEmpty) data.subtitle,
      'Generated: ${_generatedFmt.format(DateTime.now())}',
    ].join('   •   ');
    put(0, 1, TextCellValue(meta), _metaStyle);

    const headerRow = 3;
    for (var c = 0; c < data.columns.length; c++) {
      put(c, headerRow, TextCellValue(data.columns[c].header), _headerStyle);
      sheet.setColumnWidth(c, data.columns[c].width);
    }
    sheet.setRowHeight(headerRow, 22);

    var r = headerRow + 1;
    for (final row in data.rows) {
      for (var c = 0; c < data.columns.length; c++) {
        put(c, r, _cellValue(data.columns[c].type, row[c]),
            _dataStyle(data.columns[c].type, bold: false));
      }
      r++;
    }

    final totals = data.totals;
    if (totals != null) {
      for (var c = 0; c < data.columns.length; c++) {
        put(c, r, _cellValue(data.columns[c].type, totals[c]),
            _totalStyle(data.columns[c].type));
      }
    }
  }

  static CellValue? _cellValue(ExcelColType type, Object? v) {
    if (v == null) return null;
    // A string is always text, whatever the column type — lets a totals row
    // put its "TOTAL" label in a numeric or date column.
    if (v is String) return TextCellValue(v);
    switch (type) {
      case ExcelColType.text:
        return TextCellValue(v.toString());
      case ExcelColType.integer:
        return IntCellValue((v as num).toInt());
      case ExcelColType.amount:
      case ExcelColType.quantity:
        return DoubleCellValue((v as num).toDouble());
      case ExcelColType.dateTime:
        return DateTimeCellValue.fromDateTime(v as DateTime);
    }
  }

  static CellStyle _dataStyle(ExcelColType type, {required bool bold}) {
    switch (type) {
      case ExcelColType.text:
        return CellStyle(bold: bold);
      case ExcelColType.integer:
        return CellStyle(bold: bold, horizontalAlign: HorizontalAlign.Right);
      case ExcelColType.amount:
        return CellStyle(
            bold: bold, numberFormat: _amountFormat,
            horizontalAlign: HorizontalAlign.Right);
      case ExcelColType.quantity:
        return CellStyle(
            bold: bold, numberFormat: _quantityFormat,
            horizontalAlign: HorizontalAlign.Right);
      case ExcelColType.dateTime:
        return CellStyle(
            bold: bold, numberFormat: _dateTimeFormat,
            horizontalAlign: HorizontalAlign.Left);
    }
  }

  static CellStyle _totalStyle(ExcelColType type) {
    final base = _dataStyle(type, bold: true);
    return base.copyWith(
      backgroundColorHexVal: ExcelColor.fromHexString('#E5E7EB'),
    );
  }

  /// Excel rejects sheet names over 31 chars or containing `[]:*?/\`.
  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').trim();
    return cleaned.length > 31 ? cleaned.substring(0, 31) : cleaned;
  }
}
