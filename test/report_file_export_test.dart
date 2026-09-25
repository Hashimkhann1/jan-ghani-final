import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/common/export/report_excel_export.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/common/export/report_file_export.dart';

void main() {
  final sheets = [
    ExcelSheetData(
      name: 'A',
      title: 'Title A',
      columns: const [
        ExcelColumn('Name'),
        ExcelColumn('Qty', type: ExcelColType.quantity),
        ExcelColumn('Date', type: ExcelColType.dateTime),
      ],
      rows: [
        ['Widget, "big"', 1234.5, DateTime(2026, 1, 2, 3, 4)],
        ['=cmd', 2, null],
      ],
      totals: ['TOTAL', 1236.5, null],
    ),
    const ExcelSheetData(
        name: 'B', title: 'Title B', columns: [ExcelColumn('X')], rows: []),
  ];

  test('csv: BOM, quoting, formula guard, multi-sheet', () {
    final bytes = ReportFileExport.buildCsv(sheets);
    expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    final text = utf8.decode(bytes.sublist(3));
    expect(text, contains('"Widget, ""big""",1234.5,2026-01-02 03:04'));
    expect(text, contains("'=cmd,2,"));
    expect(text, contains('TOTAL,1236.5,'));
    expect(text, contains('Title B'));
  });

  test('pdf: builds, including empty sheet', () async {
    final pdf = await ReportFileExport.buildPdf(sheets);
    expect(utf8.decode(pdf.sublist(0, 5)), '%PDF-');
  });
}
