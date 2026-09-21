import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/stock_movement_log/data/datasource/stock_movement_datasource.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/stock_movement_log/data/model/stock_movement_model.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/stock_movement_log/data/service/stock_movement_excel_service.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/common/export/report_excel_export.dart';

StockMovementEntry _e(
  int day,
  StockMovementType type,
  double qty, {
  String pid = 'p1',
  double? before,
  double? after,
}) =>
    StockMovementEntry(
      dateTime:    DateTime(2026, 9, day, 12),
      productId:   pid,
      productName: 'Product $pid',
      type:        type,
      qtyChange:   qty,
      stockBefore: before,
      stockAfter:  after,
    );

void main() {
  group('StockMovementDatasource.buildRows', () {
    test('walks back from current stock, newest first', () {
      final rows = StockMovementDatasource.buildRows(
        events: [
          _e(1, StockMovementType.purchase, 50),
          _e(2, StockMovementType.sale, -3),
          _e(3, StockMovementType.damage, -2),
        ],
        currentStock:  {'p1': 100},
        categoryNames: {'p1': 'SWEETS'},
      );
      expect(rows.map((r) => r.entry.dateTime.day), [3, 2, 1]);
      expect(rows.map((r) => r.resultingStock), [100, 102, 105]);
      expect(rows.first.categoryName, 'SWEETS');
    });

    test('count correction re-anchors the walk', () {
      final rows = StockMovementDatasource.buildRows(
        events: [
          _e(1, StockMovementType.sale, -1),
          _e(2, StockMovementType.countCorrection, -1433,
              before: 1586, after: 153),
          _e(3, StockMovementType.sale, -3),
        ],
        // Current stock disagrees with the ledger on purpose (an
        // unrecorded movement) — the count's own numbers must win.
        currentStock:  {'p1': 999},
        categoryNames: const {},
      );
      expect(rows[0].resultingStock, 999);   // day 3
      expect(rows[1].resultingStock, 153);   // day 2: anchored
      expect(rows[2].resultingStock, 1586);  // day 1: walked from `before`
    });

    test('products are tracked independently; unknown stock is null', () {
      final rows = StockMovementDatasource.buildRows(
        events: [
          _e(1, StockMovementType.sale, -1, pid: 'a'),
          _e(2, StockMovementType.sale, -1, pid: 'b'),
        ],
        currentStock:  {'a': 10},
        categoryNames: const {},
      );
      final byPid = {for (final r in rows) r.entry.productId: r};
      expect(byPid['a']!.resultingStock, 10);
      expect(byPid['b']!.resultingStock, isNull);
      expect(byPid['b']!.categoryName, StockMovementDatasource.uncategorized);
    });
  });

  test('Excel fact sheet has the requested columns and one row per event', () {
    final rows = StockMovementDatasource.buildRows(
      events: [
        _e(1, StockMovementType.sale, -3),
        _e(2, StockMovementType.saleReturn, 1),
      ],
      currentStock:  {'p1': 5},
      categoryNames: const {},
    );
    final sheets = StockMovementExcelService.buildSheets(
      data: StockMovementReportData(rows: rows, branchName: 'Main Branch'),
      subtitle: 'x',
    );

    expect(sheets.first.columns.map((c) => c.header), [
      'date_time', 'branch', 'product', 'category', 'event_type',
      'qty_change', 'reference_no', 'reason', 'resulting_stock',
    ]);
    expect(sheets.first.rows, hasLength(2));
    expect(sheets.first.rows.first[1], 'Main Branch');
    expect(sheets.first.rows.first[4], 'Return');
    // The workbook actually encodes.
    expect(ReportExcelExport.build(sheets), isNotEmpty);

    final summary = sheets.last;
    expect(summary.totals, ['TOTAL', 2, 1.0, 3.0, -2.0]);
  });
}
