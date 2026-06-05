import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/provider/product_provider.dart';

class InventoryCategoryData {
  final String categoryName;
  final double totalValue;
  final int productCount;

  const InventoryCategoryData({
    required this.categoryName,
    required this.totalValue,
    required this.productCount,
  });
}

class InventoryReportData {
  final int totalActive;
  final int lowStockCount;
  final int outOfStockCount;
  final int needsReorderCount;
  final double totalPurchaseValue;
  final double totalSellingValue;
  final List<InventoryCategoryData> categoryBreakdown;
  final List<ProductModel> reorderProducts;
  final List<ProductModel> activeProducts;
  final bool isLoading;

  const InventoryReportData({
    this.totalActive = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.needsReorderCount = 0,
    this.totalPurchaseValue = 0,
    this.totalSellingValue = 0,
    this.categoryBreakdown = const [],
    this.reorderProducts = const [],
    this.activeProducts = const [],
    this.isLoading = false,
  });
}

final inventoryReportProvider = Provider<InventoryReportData>((ref) {
  final productState = ref.watch(productProvider);

  if (productState.isLoading) {
    return const InventoryReportData(isLoading: true);
  }

  final active = productState.allProducts
      .where((p) => p.isActive && p.deletedAt == null)
      .toList();

  final lowStockCount = active.where((p) => p.isLowStock).length;
  final outOfStockCount =
      active.where((p) => p.isTrackStock && p.quantity == 0).length;

  final reorderProducts = active.where((p) => p.needsReorder).toList()
    ..sort((a, b) {
      final aRatio =
          a.reorderPoint > 0 ? a.quantity / a.reorderPoint : 1.0;
      final bRatio =
          b.reorderPoint > 0 ? b.quantity / b.reorderPoint : 1.0;
      return aRatio.compareTo(bRatio);
    });

  final totalPurchaseValue = active.fold<double>(
      0.0, (sum, p) => sum + (p.quantity * p.purchasePrice));
  final totalSellingValue = active.fold<double>(
      0.0, (sum, p) => sum + (p.quantity * p.sellingPrice));

  final catMap = <String, InventoryCategoryData>{};
  for (final p in active) {
    final cat = (p.categoryName?.trim().isNotEmpty == true)
        ? p.categoryName!
        : 'Uncategorized';
    final val = p.quantity * p.purchasePrice;
    final existing = catMap[cat];
    catMap[cat] = InventoryCategoryData(
      categoryName: cat,
      totalValue: (existing?.totalValue ?? 0) + val,
      productCount: (existing?.productCount ?? 0) + 1,
    );
  }

  final categories = catMap.values.toList()
    ..sort((a, b) => b.totalValue.compareTo(a.totalValue));

  return InventoryReportData(
    totalActive: active.length,
    lowStockCount: lowStockCount,
    outOfStockCount: outOfStockCount,
    needsReorderCount: reorderProducts.length,
    totalPurchaseValue: totalPurchaseValue,
    totalSellingValue: totalSellingValue,
    categoryBreakdown: categories,
    reorderProducts: reorderProducts,
    activeProducts: active,
  );
});
