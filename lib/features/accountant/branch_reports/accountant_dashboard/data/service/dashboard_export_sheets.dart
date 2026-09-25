import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/accountant_dashboard_model.dart';

class DashboardExportSheets {
  static final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');

  /// One sheet, one row per dashboard measure (grouped by section).
  static List<ExcelSheetData> build({
    required AccountantBranchDashboardModel data,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    final rows = <List<Object?>>[
      ['Sales', 'Total Sale',               data.totalSale],
      ['Sales', 'Cash Sale',                data.cashSale],
      ['Sales', 'Card Sale',                data.cardSale],
      ['Sales', 'Credit Sale',              data.creditSale],
      ['Sales', 'Installment Received',     data.installmentSale],
      ['Sales', 'Total Amount Received',    data.totalAmountReceived],
      ['Sales', 'Total Sale Return',        data.totalSaleReturn],
      ['Sales', 'Net Sale',                 data.netSale],
      ['Profit', 'Gross Profit',            data.grossProfit],
      ['Stock', 'Stock Purchase Value',     data.inventoryValue],
      ['Stock', 'Stock Sale Value',         data.stockSaleValue],
      ['Stock', 'Total Damage (at cost)',   data.totalDamage],
      ['Cash', 'Cash In',                   data.cashIn],
      ['Cash', 'Cash Out',                  data.cashOut],
      ['Receivable', 'Outstanding Receivable', data.outstandingReceivable],
    ];

    return [
      ExcelSheetData(
        name:     'Dashboard',
        title:    'Branch Dashboard',
        subtitle: '${_dateTimeFmt.format(fromDate)}  →  '
            '${_dateTimeFmt.format(toDate)}',
        columns: const [
          ExcelColumn('Section', width: 16),
          ExcelColumn('Measure', width: 32),
          ExcelColumn('Amount',  width: 18, type: ExcelColType.amount),
        ],
        rows: rows,
      ),
    ];
  }
}
