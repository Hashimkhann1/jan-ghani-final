// Updated on 2026-11-16 09:59 AM
// =============================================================
// branch_return_model.dart — Branch → Warehouse stock return
//
// Data Supabase ke `stock_returns` + `stock_return_items` se aata hai
// (branch ne banaya). Warehouse sirf padhta hai aur RPC se accept /
// reject karta hai — in tables ko kabhi seedha edit nahi karta.
// =============================================================

double _d(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

DateTime? _dt(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

/// Return ki ek line (branch inventory ka snapshot).
class BranchReturnItem {
  final String  id;
  final String  productId;
  final String  productName;
  final String? sku;
  final String  unit;
  final double  purchasePrice;
  final double  salePrice;
  final double  quantityReturned;
  final double  totalCost;

  const BranchReturnItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.sku,
    this.unit = 'pcs',
    this.purchasePrice = 0,
    this.salePrice = 0,
    required this.quantityReturned,
    this.totalCost = 0,
  });

  factory BranchReturnItem.fromJson(Map<String, dynamic> j) => BranchReturnItem(
        id:               j['id'].toString(),
        productId:        j['product_id'].toString(),
        productName:      (j['product_name'] ?? '').toString(),
        sku:              j['sku']?.toString(),
        unit:             (j['unit'] ?? 'pcs').toString(),
        purchasePrice:    _d(j['purchase_price']),
        salePrice:        _d(j['sale_price']),
        quantityReturned: _d(j['quantity_returned']),
        totalCost:        _d(j['total_cost']),
      );
}

class BranchReturn {
  final String    id;
  final String    returnNumber;
  final String    fromStoreId;
  final String    fromStoreName;
  final String    warehouseId;
  final String    status;          // pending | accepted | rejected
  final String?   returnedByName;
  final DateTime  returnedAt;
  final String?   notes;
  final double    totalItems;      // header ki total qty (branch ne likhi)
  final double    totalCost;
  final double    totalSalePrice;
  final String?   respondedById;
  final String?   respondedByName;
  final DateTime? respondedAt;
  final String?   rejectReason;
  final List<BranchReturnItem> items;

  const BranchReturn({
    required this.id,
    required this.returnNumber,
    required this.fromStoreId,
    required this.fromStoreName,
    required this.warehouseId,
    required this.status,
    this.returnedByName,
    required this.returnedAt,
    this.notes,
    this.totalItems = 0,
    this.totalCost = 0,
    this.totalSalePrice = 0,
    this.respondedById,
    this.respondedByName,
    this.respondedAt,
    this.rejectReason,
    this.items = const [],
  });

  bool get isPending  => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  /// Items ka asal jod (display isi se — header `total_items` integer hai).
  double get itemsQty =>
      items.fold(0.0, (s, it) => s + it.quantityReturned);

  double get itemsCost => items.fold(0.0, (s, it) => s + it.totalCost);

  /// Items poore aa gaye? Branch pehle header phir items insert karti hai —
  /// beech ke lamhe mein items khaali ho sakte hain. Header ki qty se match
  /// na ho to Accept band (adhoora return accept na ho).
  bool get itemsComplete =>
      items.isNotEmpty && (itemsQty - totalItems).abs() < 1;

  factory BranchReturn.fromJson(Map<String, dynamic> j) => BranchReturn(
        id:              j['id'].toString(),
        returnNumber:    (j['return_number'] ?? '').toString(),
        fromStoreId:     j['from_store_id'].toString(),
        fromStoreName:   (j['from_store_name'] ?? '').toString(),
        warehouseId:     j['warehouse_id'].toString(),
        status:          (j['status'] ?? 'pending').toString(),
        returnedByName:  j['returned_by_name']?.toString(),
        returnedAt:      _dt(j['returned_at']) ?? DateTime.now(),
        notes:           j['notes']?.toString(),
        totalItems:      _d(j['total_items']),
        totalCost:       _d(j['total_cost']),
        totalSalePrice:  _d(j['total_sale_price']),
        respondedById:   j['responded_by_id']?.toString(),
        respondedByName: j['responded_by_name']?.toString(),
        respondedAt:     _dt(j['responded_at']),
        rejectReason:    j['reject_reason']?.toString(),
        items: (j['stock_return_items'] as List? ?? const [])
            .map((e) => BranchReturnItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Warehouse ke local `warehouse_products` mein product ki halat.
enum ReturnProductStatus { ok, deleted, missing }

extension ReturnProductStatusX on ReturnProductStatus {
  String? get message => switch (this) {
        ReturnProductStatus.ok      => null,
        ReturnProductStatus.deleted => 'Ye product delete hua hai',
        ReturnProductStatus.missing => 'Ye product warehouse mein nahi hai',
      };
}

/// Accept / Reject ka nateeja (UI message ke liye).
class ReturnActionResult {
  final bool    ok;
  final String  message;
  const ReturnActionResult(this.ok, this.message);
}
