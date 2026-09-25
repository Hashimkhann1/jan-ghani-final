import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/branch_cash_counter_model.dart';

class BranchCashCounterExcelService {
  static final _rangeFmt = DateFormat('dd MMM yyyy');

  static Future<void> exportAndSave({
    required BranchCashCounterSummary summary,
    required String                   branchName,
    required DateTime                 fromDate,
    required DateTime                 toDate,
  }) async {
    await ReportExcelExport.save(
      fileNamePrefix: 'cash_counter_report',
      sheets: exportSheets(
        summary:    summary,
        branchName: branchName,
        fromDate:   fromDate,
        toDate:     toDate,
      ),
    );
  }

  /// Sheets for any export format (Excel / PDF / CSV).
  static List<ExcelSheetData> exportSheets({
    required BranchCashCounterSummary summary,
    required String                   branchName,
    required DateTime                 fromDate,
    required DateTime                 toDate,
  }) =>
      buildSheets(
        summary:    summary,
        branchName: branchName,
        subtitle:
            '${_rangeFmt.format(fromDate)}  →  ${_rangeFmt.format(toDate)}',
      );

  /// Two sheets: "Daily Cash Log" (fact table — one row per branch per day,
  /// no totals row so it can be pivoted / loaded into BI tools) and
  /// "Period Summary" (the same measures totalled over the range).
  static List<ExcelSheetData> buildSheets({
    required BranchCashCounterSummary summary,
    required String                   branchName,
    required String                   subtitle,
  }) {
    // Same newest-first order as the screen.
    final days = summary.days;

    return [
      ExcelSheetData(
        name:     'Daily Cash Log',
        title:    'Cash Counter / Daily Cash Log (one row per branch per day)',
        subtitle: '$subtitle   •   ${days.length} days',
        columns: const [
          ExcelColumn('date',                  width: 14,
              type: ExcelColType.dateTime, format: 'yyyy-mm-dd'),
          ExcelColumn('branch',                width: 22),
          ExcelColumn('cash_sale',             width: 14, type: ExcelColType.amount),
          ExcelColumn('card_sale',             width: 14, type: ExcelColType.amount),
          ExcelColumn('credit_sale',           width: 14, type: ExcelColType.amount),
          ExcelColumn('installment_collected', width: 22, type: ExcelColType.amount),
          ExcelColumn('cash_in',               width: 14, type: ExcelColType.amount),
          ExcelColumn('cash_out',              width: 14, type: ExcelColType.amount),
          ExcelColumn('total_sale',            width: 14, type: ExcelColType.amount),
          ExcelColumn('total_amount',          width: 16, type: ExcelColType.amount),
        ],
        rows: [
          for (final d in days)
            [
              d.date, branchName,
              d.cashSale, d.cardSale, d.creditSale, d.installment,
              d.cashIn, d.cashOut, d.totalSale, d.totalAmount,
            ],
        ],
      ),
      ExcelSheetData(
        name:     'Period Summary',
        title:    'Cash Counter Summary',
        subtitle: '$subtitle   •   Net cash (in − out): '
            '${summary.netCash.toStringAsFixed(2)}',
        columns: const [
          ExcelColumn('branch',                width: 22),
          ExcelColumn('days',                  width: 8,  type: ExcelColType.integer),
          ExcelColumn('cash_sale',             width: 14, type: ExcelColType.amount),
          ExcelColumn('card_sale',             width: 14, type: ExcelColType.amount),
          ExcelColumn('credit_sale',           width: 14, type: ExcelColType.amount),
          ExcelColumn('installment_collected', width: 22, type: ExcelColType.amount),
          ExcelColumn('cash_in',               width: 14, type: ExcelColType.amount),
          ExcelColumn('cash_out',              width: 14, type: ExcelColType.amount),
          ExcelColumn('total_sale',            width: 14, type: ExcelColType.amount),
          ExcelColumn('total_amount',          width: 16, type: ExcelColType.amount),
        ],
        rows: [
          [
            branchName, days.length,
            summary.totalCashSale, summary.totalCardSale,
            summary.totalCreditSale, summary.totalInstallment,
            summary.totalCashIn, summary.totalCashOut,
            summary.totalSale, summary.totalAmount,
          ],
        ],
      ),
    ];
  }
}
