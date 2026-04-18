// ================================================================
// warehouse_supabase_sync_service.dart
// Path: lib/core/service/warehouse_supabase_sync_service.dart
//
// Warehouse Local DB → Supabase Sync Service
// Sab 19 tables — sirf is_synced strategy
// ================================================================

import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WarehouseSupabaseSyncService {
  WarehouseSupabaseSyncService._();
  static final instance = WarehouseSupabaseSyncService._();

  Timer? _timer;
  bool _isSyncing = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  // ── DB Config ─────────────────────────────────────────────
  static const _dbHost     = 'localhost';
  static const _dbPort     = 5432;
  static const _dbName     = 'warehouse_db';
  static const _dbUser     = 'warehouseuser';
  static const _dbPassword = 'warehouseUser123';

  // ── Sare 19 Tables — Dependency order mein ───────────────
  // Parent pehle, child baad mein — FK violation se bachne ke liye
  static const _allTables = [
    // ── Level 1: Koi dependency nahi ──
    'warehouses',                 // sab ki parent

    // ── Level 2: warehouses pe dependent ──
    'locations',                  // warehouse_id → warehouses
    'warehouse_users',            // warehouse_id → warehouses
    'warehouse_categories',       // warehouse_id → warehouses
    'warehouse_finance',          // warehouse_id → warehouses
    'linked_stores',              // warehouse_id → warehouses

    // ── Level 3: upar wali tables pe dependent ──
    'suppliers',                  // warehouse_id → warehouses
    'warehouse_products',         // category_id → warehouse_categories

    // ── Level 4: products/suppliers pe dependent ──
    'warehouse_inventory',        // product_id → warehouse_products
    'warehouse_stock_movements',  // product_id → warehouse_products
    'warehouse_cash_transactions',// warehouse_id → warehouses

    // ── Level 5: cash_transactions pe dependent ──
    'warehouse_expenses',         // cash_transaction_id → warehouse_cash_transactions

    // ── Level 6: suppliers pe dependent ──
    'purchase_orders',            // supplier_id → suppliers
    'supplier_ledger',            // supplier_id → suppliers, po_id → purchase_orders

    // ── Level 7: purchase_orders pe dependent ──
    'purchase_order_items',       // po_id → purchase_orders

    // ── Level 8: stock transfers ──
    'stock_transfers',            // warehouse_id → warehouses
    'stock_transfer_items',       // transfer_id → stock_transfers

    // ── Level 9: audit / logs ──
    'product_audit_log',          // product_id → warehouse_products
    'warehouse_sync_log',         // warehouse_id → warehouses
  ];

  // ── Start ─────────────────────────────────────────────────
  void start({Duration interval = const Duration(minutes: 1)}) {
    print('[WarehouseSync] 🚀 Service starting — interval: ${interval.inSeconds}s');
    _runSync();
    _timer = Timer.periodic(interval, (_) => _runSync());
  }

  // ── Stop ──────────────────────────────────────────────────
  void stop() {
    _timer?.cancel();
    _timer = null;
    print('[WarehouseSync] 🛑 Service stopped.');
  }

  // ── DB Connection ─────────────────────────────────────────
  Future<Connection> _getConnection() async {
    return await Connection.open(
      Endpoint(
        host:     _dbHost,
        port:     _dbPort,
        database: _dbName,
        username: _dbUser,
        password: _dbPassword,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  // ── Main Sync Loop ────────────────────────────────────────
  Future<void> _runSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    final sw = Stopwatch()..start();
    print('[WarehouseSync] 🔄 ${DateTime.now()}');

    Connection? conn;
    try {
      conn = await _getConnection();
      int total = 0;

      for (final table in _allTables) {
        total += await _syncByIsSynced(conn, table);
      }

      sw.stop();
      print(total > 0
          ? '[WarehouseSync] ✅ $total records synced (${sw.elapsedMilliseconds}ms)'
          : '[WarehouseSync] ✅ Up to date (${sw.elapsedMilliseconds}ms)');
    } catch (e) {
      print('[WarehouseSync] ❌ $e');
    } finally {
      await conn?.close();
      _isSyncing = false;
    }
  }

  // ── is_synced = false wale records sync karo ──────────────
  Future<int> _syncByIsSynced(Connection conn, String table) async {
    try {
      final result = await conn.execute(
        Sql.named(
          'SELECT * FROM public."$table" WHERE is_synced = false LIMIT 500',
        ),
      );
      if (result.isEmpty) return 0;

      final rows = result.map((r) => _serialize(r.toColumnMap())).toList();
      final ids  = rows.map((r) => r['id'].toString()).toList();

      // Supabase pe upsert
      await _batchUpsert(table, rows);

      // Local DB mein is_synced = true mark karo
      if (ids.isNotEmpty) {
        final placeholders = List.generate(ids.length, (i) => '\$${i + 1}')
            .join(', ');
        await conn.execute(
          'UPDATE public."$table" '
              'SET is_synced = true, synced_at = NOW() '
              'WHERE id IN ($placeholders)',
          parameters: ids,
        );
      }

      print('[WarehouseSync]   📤 $table: ${rows.length}');
      return rows.length;
    } catch (e) {
      print('[WarehouseSync]   ❌ $table: $e');
      return 0;
    }
  }

  // ── Batch Upsert ─────────────────────────────────────────
  Future<void> _batchUpsert(
      String table,
      List<Map<String, dynamic>> rows,
      ) async {
    const batchSize = 50;
    for (var i = 0; i < rows.length; i += batchSize) {
      final end   = (i + batchSize) > rows.length ? rows.length : (i + batchSize);
      final batch = rows.sublist(i, end);
      await _supabase
          .from(table)
          .upsert(batch, onConflict: 'id');
    }
  }

  // ── Row Serializer ────────────────────────────────────────
  Map<String, dynamic> _serialize(Map<String, dynamic> row) {
    return row.map((key, value) {
      if (value is DateTime) return MapEntry(key, value.toIso8601String());
      return MapEntry(key, value);
    });
  }
}