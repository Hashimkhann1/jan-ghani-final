import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/customer_logs_model.dart';

class CustomerLogsExportSheets {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  static List<ExcelSheetData> build({
    required List<CustomerLogEntry> entries,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final subtitle = (startDate != null || endDate != null)
        ? 'Date: ${startDate == null ? 'start' : _dateFmt.format(startDate)}'
            '  →  ${endDate == null ? 'now' : _dateFmt.format(endDate)}'
        : 'Date: All';

    var increase = 0.0, decrease = 0.0;
    final rows = <List<Object?>>[];
    for (final e in entries) {
      if (e.isIncrease) {
        increase += e.changeAmount;
      } else {
        decrease += -e.changeAmount;
      }
      rows.add([
        e.createdAt,
        e.customerName,
        e.oldBalance,
        e.newBalance,
        e.changeAmount,
        e.isIncrease ? 'Increase' : 'Decrease',
      ]);
    }

    return [
      ExcelSheetData(
        name:     'Customer Logs',
        title:    'Customer Logs — Balance Change History',
        subtitle: '$subtitle   •   ${entries.length} entries',
        columns: const [
          ExcelColumn('Date',        width: 20, type: ExcelColType.dateTime),
          ExcelColumn('Customer',    width: 28),
          ExcelColumn('Old Balance', width: 16, type: ExcelColType.amount),
          ExcelColumn('New Balance', width: 16, type: ExcelColType.amount),
          ExcelColumn('Change',      width: 16, type: ExcelColType.amount),
          ExcelColumn('Direction',   width: 12),
        ],
        rows: rows,
        totals: ['TOTAL', 'Increase ${increase.toStringAsFixed(2)}', null,
            null, increase - decrease, 'Net'],
      ),
    ];
  }
}
