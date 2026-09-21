/// Why a product's stock moved. [label] is what the screen and the Excel
/// `event_type` column show.
enum StockMovementType {
  sale('Sale'),
  saleReturn('Return'),
  purchase('Purchase'),
  damage('Damage'),
  adjustment('Adjustment'),
  countCorrection('Count Correction');

  final String label;
  const StockMovementType(this.label);
}

/// One stock-changing event for one product.
class StockMovementEntry {
  final DateTime          dateTime;
  final String            productId;
  final String            productName;
  final StockMovementType type;

  /// Signed: negative = stock out, positive = stock in.
  final double            qtyChange;
  final String            referenceNo;
  final String            reason;

  /// Stock immediately before / after this event when the source records it
  /// (count corrections and manual stock edits do). Used to anchor the
  /// running-stock calculation; null for sales, returns, purchases, damage.
  final double?           stockBefore;
  final double?           stockAfter;

  const StockMovementEntry({
    required this.dateTime,
    required this.productId,
    required this.productName,
    required this.type,
    required this.qtyChange,
    this.referenceNo = '',
    this.reason      = '',
    this.stockBefore,
    this.stockAfter,
  });
}

/// A [StockMovementEntry] plus the derived columns of the report.
class StockMovementRow {
  final StockMovementEntry entry;
  final String             categoryName;

  /// Stock level right after this event; null when it can't be derived
  /// (product no longer in inventory).
  final double?            resultingStock;

  const StockMovementRow({
    required this.entry,
    required this.categoryName,
    required this.resultingStock,
  });
}

class StockMovementReportData {
  final List<StockMovementRow> rows;
  final String                 branchName;

  const StockMovementReportData({
    required this.rows,
    required this.branchName,
  });

  double get totalIn =>
      rows.fold(0.0, (s, r) => r.entry.qtyChange > 0 ? s + r.entry.qtyChange : s);

  double get totalOut =>
      rows.fold(0.0, (s, r) => r.entry.qtyChange < 0 ? s - r.entry.qtyChange : s);
}
