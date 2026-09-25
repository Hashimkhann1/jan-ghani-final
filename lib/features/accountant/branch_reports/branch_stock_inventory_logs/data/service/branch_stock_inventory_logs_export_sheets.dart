import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/branch_stock_inventory_logs_model.dart';

class BranchStockInventoryLogsExportSheets {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  /// One row per changed field (a log row can touch stock, prices and shelf
  /// at once), so old → new values stay filterable in a spreadsheet.
  static List<ExcelSheetData> build({
    required List<BranchStockInventoryLogEntry> entries,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final subtitle = (startDate != null || endDate != null)
        ? 'Date: ${startDate == null ? 'start' : _dateFmt.format(startDate)}'
            '  →  ${endDate == null ? 'now' : _dateFmt.format(endDate)}'
        : 'Date: All';

    final rows = <List<Object?>>[];
    for (final e in entries) {
      final changes = e.changes;
      if (changes.isEmpty) {
        rows.add([e.createdAt, e.productName, e.changeTypeLabel, '', '', '']);
        continue;
      }
      for (final c in changes) {
        rows.add([
          e.createdAt,
          e.productName,
          e.changeTypeLabel,
          c.label,
          c.oldValue,
          c.newValue,
        ]);
      }
    }

    return [
      ExcelSheetData(
        name:     'Stock Inventory Logs',
        title:    'Stock Inventory Logs — Product Change History',
        subtitle: '$subtitle   •   ${entries.length} log entries',
        columns: const [
          ExcelColumn('Date',        width: 20, type: ExcelColType.dateTime),
          ExcelColumn('Product',     width: 32),
          ExcelColumn('Change Type', width: 18),
          ExcelColumn('Field',       width: 18),
          ExcelColumn('Old Value',   width: 16),
          ExcelColumn('New Value',   width: 16),
        ],
        rows: rows,
      ),
    ];
  }
}
