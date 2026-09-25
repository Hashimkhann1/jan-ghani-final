import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/stock_movement_model.dart';

class StockMovementExcelService {
  static final _rangeFmt = DateFormat('dd MMM yyyy');

  /// [data] must be the full, filtered result — not just the page currently
  /// on screen.
  static Future<void> exportAndSave({
    required StockMovementReportData data,
    required DateTime fromDate,
    required DateTime toDate,
    StockMovementType? type,
  }) async {
    await ReportExcelExport.save(
      fileNamePrefix: 'stock_movement_log',
      sheets: exportSheets(
          data: data, fromDate: fromDate, toDate: toDate, type: type),
    );
  }

  /// Sheets for any export format (Excel / PDF / CSV).
  static List<ExcelSheetData> exportSheets({
    required StockMovementReportData data,
    required DateTime fromDate,
    required DateTime toDate,
    StockMovementType? type,
  }) {
    final subtitle = [
      '${_rangeFmt.format(fromDate)}  →  ${_rangeFmt.format(toDate)}',
      'Event: ${type?.label ?? 'All'}',
    ].join('   •   ');
    return buildSheets(data: data, subtitle: subtitle);
  }

  /// Two sheets: "Stock Movement" (fact table — one row per stock-changing
  /// event, no totals row so it can be pivoted / loaded into BI tools) and
  /// "Movement Summary" (one row per event type).
  static List<ExcelSheetData> buildSheets({
    required StockMovementReportData data,
    required String subtitle,
  }) {
    final factRows = <List<Object?>>[
      for (final r in data.rows)
        [
          r.entry.dateTime,
          data.branchName,
          r.entry.productName,
          r.categoryName,
          r.entry.type.label,
          r.entry.qtyChange,
          r.entry.referenceNo,
          r.entry.reason,
          r.resultingStock,
        ],
    ];

    final summaryRows = <List<Object?>>[];
    var totalEvents = 0, totalIn = 0.0, totalOut = 0.0;
    for (final type in StockMovementType.values) {
      final rows = data.rows.where((r) => r.entry.type == type).toList();
      if (rows.isEmpty) continue;
      var qtyIn = 0.0, qtyOut = 0.0;
      for (final r in rows) {
        final q = r.entry.qtyChange;
        if (q > 0) {
          qtyIn += q;
        } else {
          qtyOut -= q;
        }
      }
      totalEvents += rows.length;
      totalIn     += qtyIn;
      totalOut    += qtyOut;
      summaryRows.add([type.label, rows.length, qtyIn, qtyOut, qtyIn - qtyOut]);
    }

    return [
      ExcelSheetData(
        name:     'Stock Movement',
        title:    'Stock Movement Log — Fact Table (one row per stock-changing event)',
        subtitle: '$subtitle   •   ${factRows.length} events',
        columns: const [
          ExcelColumn('date_time',       width: 18, type: ExcelColType.dateTime,
              format: 'yyyy-mm-dd hh:mm'),
          ExcelColumn('branch',          width: 20),
          ExcelColumn('product',         width: 34),
          ExcelColumn('category',        width: 20),
          ExcelColumn('event_type',      width: 18),
          ExcelColumn('qty_change',      width: 12, type: ExcelColType.quantity),
          ExcelColumn('reference_no',    width: 20),
          ExcelColumn('reason',          width: 32),
          ExcelColumn('resulting_stock', width: 16, type: ExcelColType.amount),
        ],
        rows: factRows,
      ),
      ExcelSheetData(
        name:     'Movement Summary',
        title:    'Stock Movement Summary',
        subtitle: '$subtitle   •   $totalEvents events',
        columns: const [
          ExcelColumn('Event Type', width: 20),
          ExcelColumn('Events',     width: 10, type: ExcelColType.integer),
          ExcelColumn('Qty In',     width: 14, type: ExcelColType.quantity),
          ExcelColumn('Qty Out',    width: 14, type: ExcelColType.quantity),
          ExcelColumn('Net Change', width: 14, type: ExcelColType.quantity),
        ],
        rows:   summaryRows,
        totals: ['TOTAL', totalEvents, totalIn, totalOut, totalIn - totalOut],
      ),
    ];
  }
}
