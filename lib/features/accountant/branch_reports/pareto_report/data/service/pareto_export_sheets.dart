import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/pareto_report_model.dart';

class ParetoExportSheets {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  /// Three sheets, one per tab: top products, top customers by sales, and
  /// top customers by outstanding balance (the top 20% of each).
  static List<ExcelSheetData> build({
    required ParetoReportData data,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final range =
        '${_dateFmt.format(startDate)}  →  ${_dateFmt.format(endDate)}';
    final s = data.summary;

    return [
      ExcelSheetData(
        name:     'Top Products',
        title:    'Pareto — Top 20% Products',
        subtitle: '$range   •   ${s.paretoProductCount} of ${s.totalProducts} products',
        columns: const [
          ExcelColumn('#',                width: 6,  type: ExcelColType.integer),
          ExcelColumn('Product',          width: 34),
          ExcelColumn('SKU',              width: 16),
          ExcelColumn('Quantity',         width: 12, type: ExcelColType.quantity),
          ExcelColumn('Revenue',          width: 16, type: ExcelColType.amount),
          ExcelColumn('Profit',           width: 16, type: ExcelColType.amount),
          ExcelColumn('Cum. Revenue %',   width: 16, type: ExcelColType.amount),
          ExcelColumn('Cum. Profit %',    width: 16, type: ExcelColType.amount),
        ],
        rows: [
          for (var i = 0; i < data.products.length; i++)
            [
              i + 1,
              data.products[i].productName,
              data.products[i].sku,
              data.products[i].totalQty,
              data.products[i].totalRevenue,
              data.products[i].totalProfit,
              data.products[i].revenueShare * 100,
              data.products[i].profitShare * 100,
            ],
        ],
      ),
      ExcelSheetData(
        name:     'Top Customers by Sales',
        title:    'Pareto — Top 20% Customers by Sales',
        subtitle: '$range   •   ${s.paretoSalesCustomerCount} of ${s.totalSalesCustomers} customers',
        columns: const [
          ExcelColumn('#',              width: 6,  type: ExcelColType.integer),
          ExcelColumn('Customer',       width: 30),
          ExcelColumn('Phone',          width: 16),
          ExcelColumn('Total Sales',    width: 18, type: ExcelColType.amount),
          ExcelColumn('Cum. Sales %',   width: 16, type: ExcelColType.amount),
        ],
        rows: [
          for (var i = 0; i < data.salesCustomers.length; i++)
            [
              i + 1,
              data.salesCustomers[i].customerName,
              data.salesCustomers[i].phone,
              data.salesCustomers[i].totalSales,
              data.salesCustomers[i].salesShare * 100,
            ],
        ],
      ),
      ExcelSheetData(
        name:     'Top Customers by Balance',
        title:    'Pareto — Top 20% Customers by Outstanding Balance',
        subtitle: '$range   •   ${s.paretoBalanceCustomerCount} of ${s.totalBalanceCustomers} customers',
        columns: const [
          ExcelColumn('#',                width: 6,  type: ExcelColType.integer),
          ExcelColumn('Customer',         width: 30),
          ExcelColumn('Phone',            width: 16),
          ExcelColumn('Type',             width: 14),
          ExcelColumn('Balance',          width: 16, type: ExcelColType.amount),
          ExcelColumn('Credit Limit',     width: 16, type: ExcelColType.amount),
          ExcelColumn('Limit Exceeded',   width: 14),
          ExcelColumn('Cum. Balance %',   width: 16, type: ExcelColType.amount),
        ],
        rows: [
          for (var i = 0; i < data.balanceCustomers.length; i++)
            [
              i + 1,
              data.balanceCustomers[i].customerName,
              data.balanceCustomers[i].phone,
              data.balanceCustomers[i].customerType,
              data.balanceCustomers[i].balance,
              data.balanceCustomers[i].creditLimit,
              data.balanceCustomers[i].isCreditLimitExceeded ? 'Yes' : 'No',
              data.balanceCustomers[i].balanceShare * 100,
            ],
        ],
      ),
    ];
  }
}
