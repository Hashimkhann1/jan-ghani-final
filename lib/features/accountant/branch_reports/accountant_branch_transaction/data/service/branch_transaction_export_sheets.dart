import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/accountant_branch_transaction_model.dart';

class BranchTransactionExportSheets {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  static List<ExcelSheetData> build({
    required List<BranchTransactionModel> transactions,
    required String branchName,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final subtitle = [
      if (branchName.isNotEmpty) 'Branch: $branchName',
      if (startDate != null || endDate != null)
        'Date: ${startDate == null ? 'start' : _dateFmt.format(startDate)}'
            '  →  ${endDate == null ? 'now' : _dateFmt.format(endDate)}'
      else
        'Date: All',
    ].join('   •   ');

    var cashIn = 0.0, cashOut = 0.0;
    final rows = <List<Object?>>[];
    for (final t in transactions) {
      if (t.isCashIn) cashIn += t.payAmount;
      if (t.isCashOut) cashOut += t.payAmount;
      rows.add([
        t.createdAt,
        t.isCashIn ? 'Cash In' : (t.isCashOut ? 'Cash Out' : t.type),
        t.assignByName,
        t.beforeAmount,
        t.payAmount,
        t.afterAmount,
        t.isSynced ? 'Yes' : 'No',
      ]);
    }

    return [
      ExcelSheetData(
        name:     'Branch Transactions',
        title:    'Branch Transaction Report',
        subtitle: '$subtitle   •   ${transactions.length} transactions'
            '   •   Cash In: ${cashIn.toStringAsFixed(2)}'
            '   •   Cash Out: ${cashOut.toStringAsFixed(2)}',
        columns: const [
          ExcelColumn('Date',           width: 20, type: ExcelColType.dateTime),
          ExcelColumn('Type',           width: 12),
          ExcelColumn('Assigned By',    width: 24),
          ExcelColumn('Before Amount',  width: 16, type: ExcelColType.amount),
          ExcelColumn('Amount',         width: 16, type: ExcelColType.amount),
          ExcelColumn('After Amount',   width: 16, type: ExcelColType.amount),
          ExcelColumn('Synced',         width: 10),
        ],
        rows: rows,
      ),
    ];
  }
}
