// =============================================================
// inventory_report_remote_datasource.dart
//
// WEBSITE (kIsWeb) ke liye — Inventory Report ka data Supabase se.
// Desktop (Windows/Mac) + mobile local postgres use karte hain, isliye
// ye file sirf web par chalti hai.
//
// ⚠️ READ-ONLY: sirf .select() — koi insert/update/delete nahi.
//    Kisi table/column ko touch nahi karta.
//
// Data shape bilkul local jaisा rakha gaya hai (ProductModel +
// TransferReportItem) taake report ka baaki computation EXACT same chale
// aur UI mein koi farq na aaye.
// =============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_report_provider.dart'
    show TransferReportItem;

class InventoryReportRemoteDatasource {
  final SupabaseClient _client;
  InventoryReportRemoteDatasource(this._client);

  // PostgREST ek request mein max ~1000 rows deta hai. Isliye saara data
  // .range() se PAGES mein laate hain (warna 1000 par ruk jata).
  static const int _pageSize = 1000;

  // ── Summary (aggregate VIEW — server par compute, exact + fast) ──
  // Saari rows fetch karne ke bajaye 1 row aati hai. Cards + stock-health
  // counts isi se bharte hain.
  Future<
      ({
        int totalActive,
        int lowStock,
        int outOfStock,
        int needsReorder,
        double purchaseValue,
        double sellingValue,
      })> getSummary(String warehouseId) async {
    final m = await _client
        .from('warehouse_inventory_summary_v')
        .select()
        .eq('warehouse_id', warehouseId)
        .maybeSingle();

    final r = m ?? const <String, dynamic>{};
    return (
      totalActive: _int(r['total_active']),
      lowStock: _int(r['low_stock']),
      outOfStock: _int(r['out_of_stock']),
      needsReorder: _int(r['needs_reorder']),
      purchaseValue: _dbl(r['total_purchase_value']),
      sellingValue: _dbl(r['total_selling_value']),
    );
  }

  // ── Category breakdown (aggregate VIEW — per category ek row) ──
  Future<List<({String name, double value, int count})>> getCategoryBreakdown(
      String warehouseId) async {
    final res = await _client
        .from('warehouse_inventory_category_v')
        .select()
        .eq('warehouse_id', warehouseId)
        .order('total_value', ascending: false);

    return (res as List).map((row) {
      final m = row as Map<String, dynamic>;
      return (
        name: (m['category_name'] ?? 'Uncategorized').toString(),
        value: _dbl(m['total_value']),
        count: _int(m['product_count']),
      );
    }).toList();
  }

  // ── Products ───────────────────────────────────────────────
  // Local `ProductRemoteDataSource.getAll()` ka mirror:
  //   warehouse_products  +  warehouse_inventory(qty)  +  category name
  // ProductModel return hota hai taake report bilkul same compute ho.
  Future<List<ProductModel>> getProducts(String warehouseId) async {
    // 1) Category id → name map (alag halki query — FK-embed par depend nahi,
    //    isliye robust rehta hai chahe category relation defined ho ya nahi).
    final catRes = await _client
        .from('warehouse_categories')
        .select('id, name')
        .eq('warehouse_id', warehouseId);

    final categoryName = <String, String>{
      for (final c in (catRes as List))
        c['id'].toString(): (c['name'] ?? '').toString(),
    };

    // 2) Products + embedded inventory quantity (FK relation —
    //    accountant feature mein already proven embedding).
    //    Pages mein fetch — 1000-row cap se bachne ke liye.
    final products = <ProductModel>[];
    var from = 0;

    while (true) {
      final res = await _client
          .from('warehouse_products')
          .select(
            'id, warehouse_id, sku, barcode, name, description, category_id, '
            'unit_of_measure, purchase_price, selling_price, wholesale_price, '
            'tax_rate, min_stock_level, max_stock_level, reorder_point, '
            'is_active, is_track_stock, created_at, updated_at, deleted_at, '
            'warehouse_inventory(quantity, reserved_quantity)',
          )
          .eq('warehouse_id', warehouseId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .range(from, from + _pageSize - 1);

      final rows = res as List;
      for (final row in rows) {
        final m = row as Map<String, dynamic>;

        // Embedded inventory ek list hoti hai (warehouse-product ki one row).
        final inv = m['warehouse_inventory'];
        final invRow = (inv is List && inv.isNotEmpty)
            ? inv.first as Map<String, dynamic>
            : null;

        // ProductModel.fromMap flat keys expect karta hai (jaise local query
        // se aate hain) — embedded/joined values ko flatten kar do.
        products.add(ProductModel.fromMap({
          ...m,
          'category_name': categoryName[m['category_id']?.toString()],
          'quantity': invRow?['quantity'] ?? 0,
          'reserved_quantity': invRow?['reserved_quantity'] ?? 0,
        }));
      }

      if (rows.length < _pageSize) break; // aakhri page mil gaya
      from += _pageSize;
    }

    return products;
  }

  // ── Stock transfers ────────────────────────────────────────
  // Local `_loadTransfers()` ka mirror — inventory report ke transfer
  // section ko sirf transfers ki list chahiye. (Pages mein — safe.)
  Future<List<TransferReportItem>> getStockTransfers(String warehouseId) async {
    final transfers = <TransferReportItem>[];
    var from = 0;

    while (true) {
      final res = await _client
          .from('stock_transfers')
          .select(
            'id, transfer_number, to_store_id, to_store_name, status, '
            'assigned_by_id, assigned_by_name, assigned_at, notes, '
            'total_items, total_cost, total_sale_price, created_at',
          )
          .eq('warehouse_id', warehouseId)
          .filter('deleted_at', 'is', null)
          .order('assigned_at', ascending: false)
          .range(from, from + _pageSize - 1);

      final rows = res as List;
      transfers.addAll(
        rows.map((m) => TransferReportItem.fromMap(m as Map<String, dynamic>)),
      );

      if (rows.length < _pageSize) break;
      from += _pageSize;
    }

    return transfers;
  }

  // ── Safe parsers ───────────────────────────────────────────
  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
