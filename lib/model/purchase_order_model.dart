// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

enum PurchaseOrderStatus { draft, ordered, partial, received, cancelled }

extension PurchaseOrderStatusX on PurchaseOrderStatus {
  String get label {
    switch (this) {
      case PurchaseOrderStatus.draft:
        return 'Draft';
      case PurchaseOrderStatus.ordered:
        return 'Ordered';
      case PurchaseOrderStatus.partial:
        return 'Partial';
      case PurchaseOrderStatus.received:
        return 'Received';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static PurchaseOrderStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'ordered':
        return PurchaseOrderStatus.ordered;
      case 'partial':
        return PurchaseOrderStatus.partial;
      case 'received':
        return PurchaseOrderStatus.received;
      case 'cancelled':
        return PurchaseOrderStatus.cancelled;
      default:
        return PurchaseOrderStatus.draft;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCATION MODEL  (maps to `locations` table)
// ─────────────────────────────────────────────────────────────────────────────

enum LocationType { warehouse, store }

class LocationModel {
  final int id;
  final String code;
  final String name;
  final LocationType type;
  final String? address;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;

  const LocationModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.address,
    this.phone,
    this.isActive = true,
    required this.createdAt,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPPLIER MODEL  (maps to `suppliers` table)
// ─────────────────────────────────────────────────────────────────────────────

class PoSupplierModel {
  final int id;
  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? taxId;
  final int paymentTerms;
  final bool isActive;
  final DateTime createdAt;

  const PoSupplierModel({
    required this.id,
    required this.name,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.taxId,
    this.paymentTerms = 30,
    this.isActive = true,
    required this.createdAt,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT SNAPSHOT  (lightweight — used inside PO items)
// ─────────────────────────────────────────────────────────────────────────────

class PoProductSnapshot {
  final int id;
  final String sku;
  final String name;
  final String? barcode;
  final String unitOfMeasure;
  final double costPrice;
  final String? categoryName;

  const PoProductSnapshot({
    required this.id,
    required this.sku,
    required this.name,
    this.barcode,
    this.unitOfMeasure = 'pcs',
    required this.costPrice,
    this.categoryName,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PURCHASE ORDER ITEM  (maps to `purchase_order_items` table)
// ─────────────────────────────────────────────────────────────────────────────

class PurchaseOrderItem {
  final int id;
  final int poId;
  final int? productId;
  final String productName;
  final String? sku;
  final double quantityOrdered;
  final double quantityReceived;
  final double unitCost;
  final double totalCost;

  const PurchaseOrderItem({
    required this.id,
    required this.poId,
    this.productId,
    required this.productName,
    this.sku,
    required this.quantityOrdered,
    this.quantityReceived = 0,
    required this.unitCost,
    required this.totalCost,
  });

  PurchaseOrderItem copyWith({
    double? quantityOrdered,
    double? quantityReceived,
    double? unitCost,
    double? totalCost,
  }) {
    return PurchaseOrderItem(
      id: id,
      poId: poId,
      productId: productId,
      productName: productName,
      sku: sku,
      quantityOrdered: quantityOrdered ?? this.quantityOrdered,
      quantityReceived: quantityReceived ?? this.quantityReceived,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PURCHASE ORDER  (maps to `purchase_orders` table)
// ─────────────────────────────────────────────────────────────────────────────

class PurchaseOrderModel {
  final int id;
  final String poNumber;
  final PoSupplierModel? supplier;
  final LocationModel? destinationLocation;
  final String destinationLocationName;
  final PurchaseOrderStatus status;
  final DateTime orderDate;
  final DateTime? expectedDate;
  final DateTime? receivedDate;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String? notes;
  final List<PurchaseOrderItem> items;

  const PurchaseOrderModel({
    required this.id,
    required this.poNumber,
    this.supplier,
    this.destinationLocation,
    required this.destinationLocationName,
    required this.status,
    required this.orderDate,
    this.expectedDate,
    this.receivedDate,
    required this.subtotal,
    this.taxAmount = 0,
    required this.totalAmount,
    this.notes,
    this.items = const [],
  });

  PurchaseOrderModel copyWith({
    PurchaseOrderStatus? status,
    DateTime? receivedDate,
    List<PurchaseOrderItem>? items,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    String? notes,
  }) {
    return PurchaseOrderModel(
      id: id,
      poNumber: poNumber,
      supplier: supplier,
      destinationLocation: destinationLocation,
      destinationLocationName: destinationLocationName,
      status: status ?? this.status,
      orderDate: orderDate,
      expectedDate: expectedDate,
      receivedDate: receivedDate ?? this.receivedDate,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAFT ORDER ITEM  (mutable — used while building a new PO in PlaceOrderView)
// ─────────────────────────────────────────────────────────────────────────────

class DraftOrderItem {
  final PoProductSnapshot? product;
  final String productName;
  final String? sku;
  final double quantity;
  final double unitCost;

  DraftOrderItem({
    this.product,
    required this.productName,
    this.sku,
    required this.quantity,
    required this.unitCost,
  });

  double get total => quantity * unitCost;

  DraftOrderItem copyWith({
    PoProductSnapshot? product,
    String? productName,
    String? sku,
    double? quantity,
    double? unitCost,
  }) {
    return DraftOrderItem(
      product: product ?? this.product,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
    );
  }
}