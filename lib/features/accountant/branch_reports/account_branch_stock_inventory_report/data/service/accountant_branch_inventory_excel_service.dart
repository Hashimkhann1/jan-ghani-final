import '../../../common/export/report_excel_export.dart';
import '../model/accountant_branch_stock_inventory_model.dart';

class AccountantBranchInventoryExcelService {
  /// [items] is the CURRENT FILTERED list (search + stock + category +
  /// dead-stock), so the sheet matches what's on screen — same as the PDF.
  ///
  /// One sheet, a snapshot fact table: one row per product, no totals row so
  /// it can be pivoted/loaded into BI tools.
  static Future<void> exportAndSave({
    required List<AccountantBranchInventoryModel> items,
    required String branchName,
    String? categoryName,
    StockStatus? stockFilter,
    bool deadStockOnly = false,
    String searchQuery = '',
  }) async {
    await ReportExcelExport.save(
      fileNamePrefix: 'inventory_report',
      sheets: exportSheets(
        items:         items,
        branchName:    branchName,
        categoryName:  categoryName,
        stockFilter:   stockFilter,
        deadStockOnly: deadStockOnly,
        searchQuery:   searchQuery,
      ),
    );
  }

  /// Sheets for any export format (Excel / PDF / CSV).
  static List<ExcelSheetData> exportSheets({
    required List<AccountantBranchInventoryModel> items,
    required String branchName,
    String? categoryName,
    StockStatus? stockFilter,
    bool deadStockOnly = false,
    String searchQuery = '',
  }) {
    final subtitle = [
      'Category: ${categoryName ?? 'All'}',
      'Status: ${stockFilter == null ? 'All' : _statusLabel(stockFilter)}',
      if (deadStockOnly) 'Dead stock only',
      if (searchQuery.isNotEmpty) 'Search: "$searchQuery"',
    ].join('   •   ');
    return buildSheets(
      items:      items,
      branchName: branchName,
      subtitle:   subtitle,
    );
  }

  static List<ExcelSheetData> buildSheets({
    required List<AccountantBranchInventoryModel> items,
    required String branchName,
    required String subtitle,
    DateTime? snapshotAt,
  }) {
    final now = snapshotAt ?? DateTime.now();
    final snapshotDate = DateTime(now.year, now.month, now.day);

    final rows = <List<Object?>>[
      for (final i in items)
        [
          snapshotDate,
          branchName,
          i.productName,
          i.sku,
          i.categoryName,
          i.unit,
          i.stock,
          i.minStock,
          i.maxStock,
          i.purchasePrice,
          i.salePrice,
          i.wholesalePrice,
          _statusLabel(i.stockStatus),
        ],
    ];

    return [
      ExcelSheetData(
        name:     'Inventory Snapshot',
        title:    'Current Inventory Snapshot (one row per product, refreshed each export)',
        subtitle: '$subtitle   •   ${rows.length} products',
        columns: const [
          ExcelColumn('snapshot_date',   width: 15, type: ExcelColType.dateTime,
              format: 'yyyy-mm-dd'),
          ExcelColumn('branch',          width: 20),
          ExcelColumn('product',         width: 34),
          ExcelColumn('sku',             width: 18),
          ExcelColumn('category',        width: 22),
          ExcelColumn('unit',            width: 8),
          ExcelColumn('stock',           width: 10, type: ExcelColType.quantity),
          ExcelColumn('min_stock',       width: 11, type: ExcelColType.quantity),
          ExcelColumn('max_stock',       width: 11, type: ExcelColType.quantity),
          ExcelColumn('purchase_price',  width: 15, type: ExcelColType.amount),
          ExcelColumn('sale_price',      width: 12, type: ExcelColType.amount),
          ExcelColumn('wholesale_price', width: 16, type: ExcelColType.amount),
          ExcelColumn('status',          width: 14),
        ],
        rows: rows,
      ),
    ];
  }

  static String _statusLabel(StockStatus s) {
    switch (s) {
      case StockStatus.inStock:    return 'In Stock';
      case StockStatus.lowStock:   return 'Low Stock';
      case StockStatus.outOfStock: return 'Out of Stock';
    }
  }
}
