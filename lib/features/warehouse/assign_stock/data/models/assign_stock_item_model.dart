
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';
import 'package:uuid/uuid.dart';

class AssignStockCartItem {
  final String cartId;
  final String productId;
  final String? inventoryId;
  final String productName;
  final String sku;
  final List<String> barcodes;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final String unitOfMeasure;
  final double quantity;
  final double purchasePrice;
  final double salePrice;
  final double wholesalePrice;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final int minStockLevel;
  final int? maxStockLevel;
  final int reorderPoint;
  final bool isActive;
  final double availableStock;
  String? transferNumber; // Non-final field

  // Remove 'const' from constructor
  AssignStockCartItem({  // Changed from 'const AssignStockCartItem'
    required this.cartId,
    required this.productId,
    this.inventoryId,
    required this.productName,
    required this.sku,
    required this.barcodes,
    this.description,
    this.categoryId,
    this.categoryName,
    required this.unitOfMeasure,
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
    required this.wholesalePrice,
    required this.taxRate,
    required this.taxAmount,
    required this.discountAmount,
    required this.minStockLevel,
    this.maxStockLevel,
    required this.reorderPoint,
    required this.isActive,
    required this.availableStock,
    this.transferNumber,
  });

  double get totalCost => (purchasePrice * quantity) + taxAmount - discountAmount;

  double get totalSalePrice => (salePrice * quantity) + taxAmount - discountAmount;

  double? get marginPercent =>
      salePrice > 0 && purchasePrice > 0
          ? ((salePrice - purchasePrice) / purchasePrice) * 100
          : null;

  AssignStockCartItem copyWith({
    double? quantity,
    double? purchasePrice,
    double? salePrice,
    double? wholesalePrice,
    double? taxRate,
    double? taxAmount,
    double? discountAmount,
    String? transferNumber,
  }) {
    return AssignStockCartItem(
      cartId: cartId,
      productId: productId,
      inventoryId: inventoryId,
      productName: productName,
      sku: sku,
      barcodes: barcodes,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      unitOfMeasure: unitOfMeasure,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      minStockLevel: minStockLevel,
      maxStockLevel: maxStockLevel,
      reorderPoint: reorderPoint,
      isActive: isActive,
      availableStock: availableStock,
      transferNumber: transferNumber ?? this.transferNumber,
    );
  }

  static AssignStockCartItem fromProduct(ProductModel p) {
    return AssignStockCartItem(
      cartId: const Uuid().v4(),
      productId: p.id,
      inventoryId: null,
      productName: p.name,
      sku: p.sku,
      barcodes: p.barcodes,
      description: p.description,
      categoryId: p.categoryId,
      categoryName: p.categoryName,
      unitOfMeasure: p.unitOfMeasure,
      quantity: 1,
      purchasePrice: p.purchasePrice,
      salePrice: p.sellingPrice,
      wholesalePrice: p.wholesalePrice ?? 0,
      taxRate: p.taxRate,
      taxAmount: 0,
      discountAmount: 0,
      minStockLevel: p.minStockLevel,
      maxStockLevel: p.maxStockLevel,
      reorderPoint: p.reorderPoint,
      isActive: p.isActive,
      availableStock: p.quantity,
      transferNumber: null,
    );
  }

  Map<String, dynamic> toLocalMap(String transferId, String warehouseId) {
    return {
      'id': cartId,
      'transfer_id': transferId,
      'warehouse_id': warehouseId,
      'product_id': productId,
      'inventory_id': inventoryId,
      'product_name': productName,
      'sku': sku,
      'barcode': barcodes,
      'description': description,
      'category_id': categoryId,
      'unit_of_measure': unitOfMeasure,
      'quantity_requested': quantity,
      'quantity_sent': quantity,
      'transfer_number': transferNumber,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'wholesale_price': wholesalePrice,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'min_stock_level': minStockLevel,
      'max_stock_level': maxStockLevel,
      'reorder_point': reorderPoint,
      'is_active': isActive,
      'total_cost': totalCost,
    };
  }

  Map<String, dynamic> toRemoteMap(String transferId, String warehouseId) {
    return {
      'id': cartId,
      'transfer_id': transferId,
      'warehouse_id': warehouseId,
      'product_id': productId,
      'inventory_id': inventoryId,
      'product_name': productName,
      'sku': sku,
      'barcode': barcodes,
      'description': description,
      'category_id': categoryId,
      'unit_of_measure': unitOfMeasure,
      'quantity_requested': quantity, // ✅ FIX: 'quantity' → 'quantity_requested'
      'quantity_sent': quantity,
      'transfer_number': transferNumber,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'wholesale_price': wholesalePrice,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'min_stock_level': minStockLevel,
      'max_stock_level': maxStockLevel,
      'reorder_point': reorderPoint,
      'is_active': isActive,
      'total_cost': totalCost,
    };
  }
}