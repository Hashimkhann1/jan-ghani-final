import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/branch_cash_counter_report/data/model/branch_cash_counter_model.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/branch_cash_counter_report/data/service/branch_cash_counter_excel_service.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/common/export/report_excel_export.dart';

void main() {
  test('daily cash log sheet: one row per day with the requested columns', () {
    final day = BranchCashCounterDay(
      date: DateTime(2026, 9, 20),
      cashSale: 88463, cardSale: 0, creditSale: 35190, installment: 44460,
      cashIn: 0, cashOut: 0, totalSale: 123563, totalAmount: 168023,
    );
    final summary = BranchCashCounterSummary(
      totalCashSale: 88463, totalCardSale: 0, totalCreditSale: 35190,
      totalInstallment: 44460, totalCashIn: 0, totalCashOut: 0,
      totalSale: 123563, totalAmount: 168023, days: [day],
    );

    final sheets = BranchCashCounterExcelService.buildSheets(
      summary: summary, branchName: 'Main Branch', subtitle: 'x',
    );

    expect(sheets.first.columns.map((c) => c.header), [
      'date', 'branch', 'cash_sale', 'card_sale', 'credit_sale',
      'installment_collected', 'cash_in', 'cash_out', 'total_sale',
      'total_amount',
    ]);
    expect(sheets.first.rows, hasLength(1));
    expect(sheets.first.rows.first.sublist(1),
        ['Main Branch', 88463, 0, 35190, 44460, 0, 0, 123563, 168023]);
    expect(sheets.last.rows.single[1], 1); // days
    expect(ReportExcelExport.build(sheets), isNotEmpty);
  });
}
