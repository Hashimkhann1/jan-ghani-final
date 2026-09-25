import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/branch_cash_difference_model.dart';

class BranchCashDifferenceExportSheets {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  static List<ExcelSheetData> build({
    required List<BranchCashDifferenceEntry> entries,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final subtitle = (startDate != null || endDate != null)
        ? 'Date: ${startDate == null ? 'start' : _dateFmt.format(startDate)}'
            '  →  ${endDate == null ? 'now' : _dateFmt.format(endDate)}'
        : 'Date: All';

    var cashIn = 0.0, cashOut = 0.0;
    final rows = <List<Object?>>[];
    for (final e in entries) {
      if (e.isCashIn) {
        cashIn += e.amount;
      } else {
        cashOut += e.amount;
      }
      rows.add([
        e.createdAt,
        e.isCashIn ? 'Cash In' : 'Cash Out',
        e.previousAmount,
        e.amount,
        e.remainingAmount,
        e.difference,
        e.description ?? '',
      ]);
    }

    return [
      ExcelSheetData(
        name:     'Cash Difference',
        title:    'Cash Difference Report',
        subtitle: '$subtitle   •   ${entries.length} entries',
        columns: const [
          ExcelColumn('Date',             width: 20, type: ExcelColType.dateTime),
          ExcelColumn('Type',             width: 12),
          ExcelColumn('Previous Amount',  width: 16, type: ExcelColType.amount),
          ExcelColumn('Amount',           width: 16, type: ExcelColType.amount),
          ExcelColumn('Remaining Amount', width: 18, type: ExcelColType.amount),
          ExcelColumn('Difference',       width: 16, type: ExcelColType.amount),
          ExcelColumn('Description',      width: 34),
        ],
        rows: rows,
        totals: ['TOTAL', 'In ${cashIn.toStringAsFixed(2)}', null,
            cashOut, null, cashIn - cashOut, 'Net (In − Out)'],
      ),
    ];
  }
}
