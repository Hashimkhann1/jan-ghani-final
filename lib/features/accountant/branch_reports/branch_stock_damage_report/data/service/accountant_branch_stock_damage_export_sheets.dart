import 'package:intl/intl.dart';
import '../../../common/export/report_excel_export.dart';
import '../model/accountant_branch_stock_damage_model.dart';

class AccountantBranchStockDamageExportSheets {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  /// [items] is the CURRENT FILTERED list (search + date range).
  static List<ExcelSheetData> build({
    required List<AccountantBranchStockDamageModel> items,
    String searchQuery = '',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final subtitle = [
      if (startDate != null || endDate != null)
        'Date: ${startDate == null ? 'start' : _dateFmt.format(startDate)}'
            '  →  ${endDate == null ? 'now' : _dateFmt.format(endDate)}'
      else
        'Date: All',
      if (searchQuery.isNotEmpty) 'Search: "$searchQuery"',
    ].join('   •   ');

    var qty = 0.0, purchaseLoss = 0.0, saleLoss = 0.0;
    final rows = <List<Object?>>[];
    for (final i in items) {
      qty          += i.stockDamage;
      purchaseLoss += i.purchaseLoss;
      saleLoss     += i.saleLoss;
      rows.add([
        i.createdAt,
        i.productName,
        i.stockDamage,
        i.purchasePrice,
        i.salePrice,
        i.purchaseLoss,
        i.saleLoss,
      ]);
    }

    return [
      ExcelSheetData(
        name:     'Stock Damage',
        title:    'Stock Damage Report',
        subtitle: '$subtitle   •   ${items.length} records',
        columns: const [
          ExcelColumn('Date',           width: 18, type: ExcelColType.dateTime),
          ExcelColumn('Product',        width: 34),
          ExcelColumn('Damaged Qty',    width: 14, type: ExcelColType.quantity),
          ExcelColumn('Purchase Price', width: 16, type: ExcelColType.amount),
          ExcelColumn('Sale Price',     width: 14, type: ExcelColType.amount),
          ExcelColumn('Purchase Loss',  width: 16, type: ExcelColType.amount),
          ExcelColumn('Sale Loss',      width: 14, type: ExcelColType.amount),
        ],
        rows:   rows,
        totals: ['TOTAL', '', qty, null, null, purchaseLoss, saleLoss],
      ),
    ];
  }
}
