// =============================================================
// inventory_report_provider.dart
//
// Inventory Report ka data source PLATFORM ke hisaab se switch hota hai:
//   • Website (kIsWeb)        → Supabase (remote, read-only)
//   • Windows / Mac / mobile  → Local postgres (pehle jaisा, unchanged)
//
// Dono raaste EXACT same `InventoryReportData` banate hain (compute logic
// shared hai), isliye UI/screen mein koi farq nahi padta.
// =============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/provider/product_provider.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_report_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/inventory/data/datasources/inventory_report_remote_datasource.dart';

// ─────────────────────────────────────────────────────────────
// MODELS (unchanged)
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// COMPUTE — product list se report banata hai
// (web aur desktop dono isi function ko use karte hain → ek hi logic)
// ─────────────────────────────────────────────────────────────

InventoryReportData _computeReport(List<ProductModel> allProducts) {
  // Sirf active + non-deleted products report mein aate hain
  final active = allProducts
      .where((p) => p.isActive && p.deletedAt == null)
      .toList();

  final lowStockCount = active.where((p) => p.isLowStock).length;
  final outOfStockCount =
      active.where((p) => p.isTrackStock && p.quantity == 0).length;

  // Reorder wale products — sabse urgent (quantity/reorderPoint ratio kam) upar
  final reorderProducts = active.where((p) => p.needsReorder).toList()
    ..sort((a, b) {
      final aRatio = a.reorderPoint > 0 ? a.quantity / a.reorderPoint : 1.0;
      final bRatio = b.reorderPoint > 0 ? b.quantity / b.reorderPoint : 1.0;
      return aRatio.compareTo(bRatio);
    });

  final totalPurchaseValue = active.fold<double>(
      0.0, (sum, p) => sum + (p.quantity * p.purchasePrice));
  final totalSellingValue = active.fold<double>(
      0.0, (sum, p) => sum + (p.quantity * p.sellingPrice));

  // Category-wise stock value breakdown
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
}

// ─────────────────────────────────────────────────────────────
// REMOTE (WEB) — Supabase datasource + fetch providers
// (cached FutureProviders — har rebuild par dobara fetch nahi)
// ─────────────────────────────────────────────────────────────

// ── Reports kis warehouse ka data dikhayein ───────────────────
// • null  → config warehouse (warehouse app — Windows/Mac, local DB).
// • value → selected warehouse id (accountant/web is se set karta hai,
//           kyunki web par config-id local DB ki hai, Supabase ki nahi).
final reportsWarehouseIdProvider = StateProvider<String?>((ref) => null);

// Web/remote fetch ke liye effective warehouse id
String _effectiveWarehouseId(Ref ref) =>
    ref.watch(reportsWarehouseIdProvider) ?? AppConfig.warehouseId;

final _remoteDsProvider = Provider<InventoryReportRemoteDatasource>(
  (ref) => InventoryReportRemoteDatasource(Supabase.instance.client),
);

// Web: summary + category VIEWS se InventoryReportData banata hai —
// saari product rows fetch nahi hoti, sirf aggregate numbers (fast + exact).
final _remoteReportProvider = FutureProvider<InventoryReportData>((ref) async {
  final ds  = ref.watch(_remoteDsProvider);
  final wid = _effectiveWarehouseId(ref);

  final summaryF = ds.getSummary(wid);          // dono parallel
  final catsF    = ds.getCategoryBreakdown(wid);
  final s    = await summaryF;
  final cats = await catsF;

  return InventoryReportData(
    totalActive:        s.totalActive,
    lowStockCount:      s.lowStock,
    outOfStockCount:    s.outOfStock,
    needsReorderCount:  s.needsReorder,
    totalPurchaseValue: s.purchaseValue,
    totalSellingValue:  s.sellingValue,
    categoryBreakdown: cats
        .map((c) => InventoryCategoryData(
              categoryName: c.name, totalValue: c.value, productCount: c.count))
        .toList(),
    // Product lists (Stock Health drill-down) web par ON-DEMAND aate hain.
  );
});

final _remoteTransfersProvider = FutureProvider<List<TransferReportItem>>((ref) {
  return ref.watch(_remoteDsProvider).getStockTransfers(_effectiveWarehouseId(ref));
});

// Stock Health drill-down ke products — user ke tap par fetch hote hain:
//  • web   → Supabase se (active products, paginated)
//  • warna → report mein already-computed activeProducts (memory mein)
final stockHealthProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  if (kIsWeb) {
    final all = await ref.watch(_remoteDsProvider).getProducts(_effectiveWarehouseId(ref));
    // Desktop ke activeProducts se match — sirf active (deleted query mein already nikle)
    return all.where((p) => p.isActive).toList();
  }
  return ref.watch(inventoryReportProvider).activeProducts;
});

// ─────────────────────────────────────────────────────────────
// MAIN PROVIDER — inventory report data (platform-aware)
// ─────────────────────────────────────────────────────────────

final inventoryReportProvider = Provider<InventoryReportData>((ref) {
  if (kIsWeb) {
    // ── WEBSITE → Supabase aggregate views (exact + fast) ──
    return ref.watch(_remoteReportProvider).when(
      data: (d) => d,
      loading: () => const InventoryReportData(isLoading: true),
      error: (_, __) => const InventoryReportData(), // empty (screen shows empty states)
    );
  }

  // ── WINDOWS / MAC / MOBILE → Local DB (pehle jaisa, unchanged) ──
  final productState = ref.watch(productProvider);
  if (productState.isLoading) {
    return const InventoryReportData(isLoading: true);
  }
  return _computeReport(productState.allProducts);
});

// ─────────────────────────────────────────────────────────────
// TRANSFERS (inventory report ke transfer section ke liye) — platform-aware
//
// Shared `transferReportProvider` ko chheda nahi (dedicated transfer screen
// usi par chalti hai). Yahan sirf {transfers, isLoading} ka halka wrapper hai:
//   • web      → Supabase
//   • warna    → local transferReportProvider proxy
// ─────────────────────────────────────────────────────────────

typedef InventoryTransfers = ({List<TransferReportItem> transfers, bool isLoading});

final inventoryTransfersProvider = Provider<InventoryTransfers>((ref) {
  if (kIsWeb) {
    // ── WEBSITE → Supabase ──
    final async = ref.watch(_remoteTransfersProvider);
    return (
      transfers: async.valueOrNull ?? const <TransferReportItem>[],
      isLoading: async.isLoading,
    );
  }

  // ── Desktop/mobile → mojooda local provider (unchanged) ──
  final st = ref.watch(transferReportProvider);
  return (transfers: st.transfers, isLoading: st.isLoading);
});
