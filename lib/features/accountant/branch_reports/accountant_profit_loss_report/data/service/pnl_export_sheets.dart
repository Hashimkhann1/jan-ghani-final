import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/accountant_profit_loss_model.dart';

class PnlExportSheets {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  /// "Summary" (period totals), "Daily" (per-day sale/return/net profit) and
  /// "Transactions" (fact table — one row per invoice or return).
  static List<ExcelSheetData> build({
    required PnlSummary? summary,
    required List<PnlTransactionRow> transactions,
    required DateTime fromDate,
    required DateTime toDate,
    required PnlInvoiceFilter filter,
  }) {
    final range =
        '${_dateFmt.format(fromDate)}  →  ${_dateFmt.format(toDate)}';
    final filterLabel = switch (filter) {
      PnlInvoiceFilter.all    => 'All',
      PnlInvoiceFilter.profit => 'Profit only',
      PnlInvoiceFilter.loss   => 'Loss only',
    };

    return [
      if (summary != null) ...[
        ExcelSheetData(
          name:     'Summary',
          title:    'Profit & Loss — Summary',
          subtitle: range,
          columns: const [
            ExcelColumn('Measure', width: 30),
            ExcelColumn('Value',   width: 18, type: ExcelColType.amount),
          ],
          rows: [
            ['Sale Revenue',    summary.totalSaleRevenue],
            ['Total Cost',      summary.totalCost],
            ['Gross Sale Profit',   summary.grossSaleProfit],
            ['Gross Return Profit', summary.grossReturnProfit],
            ['Net Profit',      summary.netProfit],
            ['Profit Margin %', summary.profitMargin],
            ['Invoices',        summary.totalInvoices.toDouble()],
            ['Returns',         summary.totalReturns.toDouble()],
          ],
        ),
        ExcelSheetData(
          name:     'Daily',
          title:    'Profit & Loss — Daily',
          subtitle: range,
          columns: const [
            ExcelColumn('Date',          width: 16, type: ExcelColType.dateTime,
                format: 'dd-mmm-yyyy'),
            ExcelColumn('Sale Profit',   width: 16, type: ExcelColType.amount),
            ExcelColumn('Return Profit', width: 16, type: ExcelColType.amount),
            ExcelColumn('Net Profit',    width: 16, type: ExcelColType.amount),
          ],
          rows: [
            for (final d in summary.daily)
              [d.date, d.saleProfit, d.returnProfit, d.netProfit],
          ],
          totals: [
            'TOTAL',
            summary.grossSaleProfit,
            summary.grossReturnProfit,
            summary.netProfit,
          ],
        ),
      ],
      ExcelSheetData(
        name:     'Transactions',
        title:    'Profit & Loss — Invoices and Returns',
        subtitle: '$range   •   Filter: $filterLabel   •   ${transactions.length} rows',
        columns: const [
          ExcelColumn('Date',      width: 18, type: ExcelColType.dateTime),
          ExcelColumn('Type',      width: 10),
          ExcelColumn('Doc No',    width: 18),
          ExcelColumn('Customer',  width: 26),
          ExcelColumn('Items',     width: 8,  type: ExcelColType.integer),
          ExcelColumn('Revenue',   width: 16, type: ExcelColType.amount),
          ExcelColumn('Cost',      width: 16, type: ExcelColType.amount),
          ExcelColumn('Profit',    width: 16, type: ExcelColType.amount),
        ],
        rows: [
          for (final t in transactions)
            [
              t.date,
              t.isReturn ? 'Return' : 'Sale',
              t.docNo,
              t.customerName ?? 'Walk In',
              t.itemCount,
              t.totalRevenue,
              t.totalCost,
              t.totalProfit,
            ],
        ],
      ),
    ];
  }
}
