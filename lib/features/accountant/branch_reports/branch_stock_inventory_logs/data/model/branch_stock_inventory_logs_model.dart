/// One changed field within a log entry (whichever old_/new_ pair is
/// non-null for that row — a row may touch stock, prices, shelf, and
/// min/max stock all at once, or just one of them).
class StockLogFieldChange {
  final String label;
  final String oldValue;
  final String newValue;

  const StockLogFieldChange({
    required this.label,
    required this.oldValue,
    required this.newValue,
  });
}

class BranchStockInventoryLogEntry {
  final String id;
  final String productId;
  final String productName;
  final String changeType;
  final double? oldStock;
  final double? newStock;
  final double? oldSalePrice;
  final double? newSalePrice;
  final double? oldPurchasePrice;
  final double? newPurchasePrice;
  final double? oldWholesalePrice;
  final double? newWholesalePrice;
  final String? oldShelfName;
  final String? newShelfName;
  final double? oldMinStock;
  final double? newMinStock;
  final double? oldMaxStock;
  final double? newMaxStock;
  final String userId;
  final DateTime createdAt;

  const BranchStockInventoryLogEntry({
    required this.id,
    required this.productId,
    required this.productName,
    required this.changeType,
    this.oldStock,
    this.newStock,
    this.oldSalePrice,
    this.newSalePrice,
    this.oldPurchasePrice,
    this.newPurchasePrice,
    this.oldWholesalePrice,
    this.newWholesalePrice,
    this.oldShelfName,
    this.newShelfName,
    this.oldMinStock,
    this.newMinStock,
    this.oldMaxStock,
    this.newMaxStock,
    required this.userId,
    required this.createdAt,
  });

  factory BranchStockInventoryLogEntry.fromMap(Map<String, dynamic> m) =>
      BranchStockInventoryLogEntry(
        id:          m['id'] as String,
        productId:   m['product_id'] as String? ?? '',
        productName: m['product_name'] as String? ?? '',
        changeType:  m['change_type'] as String? ?? '',
        oldStock:            _dbl(m['old_stock']),
        newStock:            _dbl(m['new_stock']),
        oldSalePrice:        _dbl(m['old_sale_price']),
        newSalePrice:        _dbl(m['new_sale_price']),
        oldPurchasePrice:    _dbl(m['old_purchase_price']),
        newPurchasePrice:    _dbl(m['new_purchase_price']),
        oldWholesalePrice:   _dbl(m['old_wholesale_price']),
        newWholesalePrice:   _dbl(m['new_wholesale_price']),
        oldShelfName:        m['old_shelf_name'] as String?,
        newShelfName:        m['new_shelf_name'] as String?,
        oldMinStock:         _dbl(m['old_min_stock']),
        newMinStock:         _dbl(m['new_min_stock']),
        oldMaxStock:         _dbl(m['old_max_stock']),
        newMaxStock:         _dbl(m['new_max_stock']),
        userId: m['user_id'] as String? ?? '',
        createdAt: DateTime.tryParse(
            m['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String _fmtNum(double? v) =>
      v == null ? '—' : (v % 1 == 0 ? v.toInt().toString() : v.toString());

  static String _fmtText(String? v) =>
      (v == null || v.isEmpty) ? '—' : v;

  /// Human label for the raw change_type value, e.g. 'price_update' →
  /// 'Price Update'. Works regardless of which exact enum values exist.
  String get changeTypeLabel => changeType.isEmpty
      ? 'Update'
      : changeType
      .split('_')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  /// Every field pair that actually changed on this row (a row may touch
  /// more than one group — stock, prices, shelf, min/max — at once).
  List<StockLogFieldChange> get changes {
    final list = <StockLogFieldChange>[];
    if (oldStock != null || newStock != null) {
      list.add(StockLogFieldChange(
        label: 'Stock', oldValue: _fmtNum(oldStock), newValue: _fmtNum(newStock),
      ));
    }
    if (oldSalePrice != null || newSalePrice != null) {
      list.add(StockLogFieldChange(
        label: 'Sale Price',
        oldValue: _fmtNum(oldSalePrice), newValue: _fmtNum(newSalePrice),
      ));
    }
    if (oldPurchasePrice != null || newPurchasePrice != null) {
      list.add(StockLogFieldChange(
        label: 'Purchase Price',
        oldValue: _fmtNum(oldPurchasePrice), newValue: _fmtNum(newPurchasePrice),
      ));
    }
    if (oldWholesalePrice != null || newWholesalePrice != null) {
      list.add(StockLogFieldChange(
        label: 'Wholesale Price',
        oldValue: _fmtNum(oldWholesalePrice), newValue: _fmtNum(newWholesalePrice),
      ));
    }
    if ((oldShelfName != null && oldShelfName!.isNotEmpty) ||
        (newShelfName != null && newShelfName!.isNotEmpty)) {
      list.add(StockLogFieldChange(
        label: 'Shelf',
        oldValue: _fmtText(oldShelfName), newValue: _fmtText(newShelfName),
      ));
    }
    if (oldMinStock != null || newMinStock != null) {
      list.add(StockLogFieldChange(
        label: 'Min Stock',
        oldValue: _fmtNum(oldMinStock), newValue: _fmtNum(newMinStock),
      ));
    }
    if (oldMaxStock != null || newMaxStock != null) {
      list.add(StockLogFieldChange(
        label: 'Max Stock',
        oldValue: _fmtNum(oldMaxStock), newValue: _fmtNum(newMaxStock),
      ));
    }
    return list;
  }
}

/// One page of entries plus whether another page exists after it.
class PagedBranchStockInventoryLogs {
  final List<BranchStockInventoryLogEntry> entries;
  final bool hasNextPage;

  const PagedBranchStockInventoryLogs({
    required this.entries,
    required this.hasNextPage,
  });
}
