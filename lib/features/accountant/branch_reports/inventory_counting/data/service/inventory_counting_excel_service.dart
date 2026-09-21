import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/inventory_counting_report_model.dart';

class InventoryCountingExcelService {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  /// [records] is the CURRENT FILTERED (visible) list — search + date range —
  /// so the sheet matches what's on screen, same as the PDF.
  ///
  /// One sheet, a fact table: one row per counted product per count, no totals
  /// row so it can be pivoted/loaded into BI tools.
  static Future<void> exportAndSave({
    required List<InventoryCountingRecord> records,
    required String branchName,
    String searchQuery = '',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final subtitle = [
      if (startDate != null || endDate != null)
        'Counted: ${startDate == null ? 'start' : _dateFmt.format(startDate)}'
            '  →  ${endDate == null ? 'now' : _dateFmt.format(endDate)}'
      else
        'Counted: All dates',
      if (searchQuery.isNotEmpty) 'Search: "$searchQuery"',
    ].join('   •   ');

    await ReportExcelExport.save(
      fileNamePrefix: 'stock_counting_report',
      sheets: buildSheets(
        records:    records,
        branchName: branchName,
        subtitle:   subtitle,
      ),
    );
  }

  static List<ExcelSheetData> buildSheets({
    required List<InventoryCountingRecord> records,
    required String branchName,
    required String subtitle,
  }) {
    final rows = <List<Object?>>[
      for (final r in records)
        [
          r.productName,
          r.barcodes.join(', '),
          branchName,
          r.minStock,
          r.maxStock,
          r.productStock,
          r.countingStock,
          r.difference,
          // updatedAt is the real timestamp of the count; countedDate is a
          // date-only column (midnight), same choice the screen makes.
          r.updatedAt.toLocal(),
          // The count isn't attributed to a user anywhere in the data yet
          // (inventory_counting has no user column), so this stays blank.
          '',
        ],
    ];

    return [
      ExcelSheetData(
        name:     'Stock Counting',
        title:    'Branch Stock Counting / Variance (one row per counted product per count session)',
        subtitle: '$subtitle   •   ${rows.length} counts',
        columns: const [
          ExcelColumn('product',       width: 34),
          ExcelColumn('barcode',       width: 20),
          ExcelColumn('branch',        width: 20),
          ExcelColumn('min_stock',     width: 11, type: ExcelColType.quantity),
          ExcelColumn('max_stock',     width: 11, type: ExcelColType.quantity),
          ExcelColumn('system_stock',  width: 13, type: ExcelColType.quantity),
          ExcelColumn('counted_stock', width: 14, type: ExcelColType.quantity),
          ExcelColumn('difference',    width: 12, type: ExcelColType.quantity),
          ExcelColumn('counted_on',    width: 18, type: ExcelColType.dateTime,
              format: 'yyyy-mm-dd hh:mm'),
          ExcelColumn('counted_by',    width: 16),
        ],
        rows: rows,
      ),
    ];
  }
}
