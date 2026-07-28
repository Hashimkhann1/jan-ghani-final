// ================================================================
// warehouse_supabase_sync_service.dart
// Path: lib/core/service/warehouse_supabase_sync_service.dart
//
// Warehouse Local DB → Supabase Sync Service
// Sab 19 tables — sirf is_synced strategy
//
// FIX 1: warehouse_finance — cash_in_hand Supabase mein update hota hai
// FIX 2: suppliers — outstanding_balance Supabase mein update hota hai
// ================================================================

// update code

import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WarehouseSupabaseSyncService {
  WarehouseSupabaseSyncService._();
  static final instance = WarehouseSupabaseSyncService._();

  Timer? _timer;
  bool   _isSyncing = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  // ── DB Config ─────────────────────────────────────────────
  static const _dbHost     = 'localhost';
  static const _dbPort     = 5432;
  static const _dbName     = 'warehouse_db';
  static const _dbUser     = 'warehouseuser';
  static const _dbPassword = 'warehouseUser123';

  // ── Sare 20 Tables — Dependency order mein ───────────────
  static const _allTables = [
    // ── Level 1: Koi dependency nahi ──
    'warehouses',

    // ── Level 2: warehouses pe dependent ──
    'locations',
    'warehouse_users',
    'warehouse_categories',
    'warehouse_companies',   // ← products se pehle (company_id FK)
    'warehouse_employees',   // ← salary_payments se pehle (employee_id FK)
    // 'warehouse_finance',
    'linked_stores',

    // ── Level 3: upar wali tables pe dependent ──
    'suppliers',
    'warehouse_products',

    // ── Level 4: products/suppliers pe dependent ──
    'warehouse_inventory',
    'warehouse_stock_movements',
    'warehouse_cash_transactions',

    // ── Level 5: cash_transactions pe dependent ──
    'warehouse_expenses',
    'warehouse_salary_payments',   // ← employee_id + cash_transaction_id FK

    // ── Level 6: suppliers pe dependent ──
    'purchase_orders',
    'supplier_ledger',

    // ── Level 7: purchase_orders pe dependent ──
    // 'purchase_order_items',  ← generic upsert NAHI. Dedicated
    //   "_syncPurchaseOrderItemsReplace" se sync hota hai (duplicate fix).

    // ── Level 8: stock transfers ──
    'stock_transfers',
    'stock_transfer_items',

    // ── Level 9: audit / logs ──
    'product_audit_log',
    'warehouse_sync_log',
    'po_audit_log',         // ← PO edit history (har create/update/delete)
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
      conn  = await _getConnection();
      int total = 0;

      // Step 1: Sab tables standard is_synced strategy se
      for (final table in _allTables) {
        total += await _syncByIsSynced(conn, table);
      }

      // Step 1b: purchase_order_items — "replace per PO" (duplicate fix)
      // Generic upsert delete nahi karti, is liye PO edit par purane items
      // Supabase par orphan reh kar duplicate bante the. Yeh method har
      // affected PO ke remote items pehle delete karke local se replace karta hai.
      total += await _syncPurchaseOrderItemsReplace(conn);

      // Step 2: warehouse_finance dedicated sync
      // Trigger (fn_update_cash_in_hand) is_synced = false set karta hai
      // Yeh method us flag ko pakad ke Supabase update karti hai
      total += await _syncWarehouseFinanceAfterTransactions(conn);

      // Step 3: suppliers dedicated sync
      // Trigger (fn_update_supplier_balance) is_synced = false set karta hai
      // Yeh method us flag ko pakad ke Supabase update karti hai
      total += await _syncSuppliersAfterLedger(conn);

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

  // ── Standard: is_synced = false wale records sync karo ───
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

      await _batchUpsert(table, rows);

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

  // ── DEDICATED: warehouse_finance sync ────────────────────
  Future<int> _syncWarehouseFinanceAfterTransactions(Connection conn) async {
    try {
      final result = await conn.execute(
        Sql.named('''
          SELECT wf.*
          FROM public.warehouse_finance wf
          WHERE wf.is_synced = false
          LIMIT 20
        '''),
      );

      if (result.isEmpty) return 0;

      final rows = result.map((r) => _serialize(r.toColumnMap())).toList();
      final ids  = rows.map((r) => r['id'].toString()).toList();

      await _batchUpsert('warehouse_finance', rows, onConflict: 'warehouse_id');

      if (ids.isNotEmpty) {
        final placeholders = List.generate(ids.length, (i) => '\$${i + 1}')
            .join(', ');
        await conn.execute(
          'UPDATE public.warehouse_finance '
              'SET is_synced = true, synced_at = NOW() '
              'WHERE id IN ($placeholders)',
          parameters: ids,
        );
      }

      print('[WarehouseSync]   💰 warehouse_finance (cash_in_hand): ${rows.length}');
      return rows.length;
    } catch (e) {
      print('[WarehouseSync]   ❌ warehouse_finance dedicated sync: $e');
      return 0;
    }
  }

  // ── DEDICATED: suppliers outstanding_balance sync ────────
  Future<int> _syncSuppliersAfterLedger(Connection conn) async {
    try {
      final result = await conn.execute(
        Sql.named('''
          SELECT s.*
          FROM public.suppliers s
          WHERE s.is_synced = false
            AND s.deleted_at IS NULL
          LIMIT 100
        '''),
      );

      if (result.isEmpty) return 0;

      final rows = result.map((r) => _serialize(r.toColumnMap())).toList();
      final ids  = rows.map((r) => r['id'].toString()).toList();

      await _batchUpsert('suppliers', rows);

      if (ids.isNotEmpty) {
        final placeholders = List.generate(ids.length, (i) => '\$${i + 1}')
            .join(', ');
        await conn.execute(
          'UPDATE public.suppliers '
              'SET is_synced = true, synced_at = NOW() '
              'WHERE id IN ($placeholders)',
          parameters: ids,
        );
      }

      print('[WarehouseSync]   🏪 suppliers (outstanding_balance): ${rows.length}');
      return rows.length;
    } catch (e) {
      print('[WarehouseSync]   ❌ suppliers dedicated sync: $e');
      return 0;
    }
  }

  // ── DEDICATED: purchase_order_items "replace per PO" ─────
  // PO edit par items DELETE + naye id se INSERT hote hain. Generic sync
  // sirf upsert karti hai (Supabase se delete NAHI), is liye purane items
  // orphan reh kar web par DUPLICATE bante the. Yahan har affected PO ke
  // remote items pehle delete karke local ke POORE set se replace karte hain
  // → Supabase = local ka exact mirror.
  //
  // Offline-safe: yeh edit ke waqt nahi, SYNC ke waqt chalta hai (jab internet
  // ho). Offline edit local mein bach jaata hai (is_synced=false); internet
  // aate hi yeh method us PO ko Supabase par khud-ba-khud durust kar deta hai.
  // Per-PO atomic hai (poora set delete+upsert), is liye 500-limit ya partial
  // batch ka koi masla nahi.
  Future<int> _syncPurchaseOrderItemsReplace(Connection conn) async {
    try {
      // 1. Kaunse POs ke items badle (un-synced) hain
      final poRes = await conn.execute(
        Sql.named('''
          SELECT DISTINCT po_id FROM public.purchase_order_items
          WHERE is_synced = false
          LIMIT 100
        '''),
      );
      if (poRes.isEmpty) return 0;

      final poIds = poRes
          .map((r) => r.toColumnMap()['po_id']?.toString())
          .whereType<String>()
          .toList();

      int synced = 0;
      for (final poId in poIds) {
        // 2. Us PO ke SAARE local items (poora set)
        final itemRes = await conn.execute(
          Sql.named(
            'SELECT * FROM public.purchase_order_items WHERE po_id = @poId',
          ),
          parameters: {'poId': poId},
        );
        final rows = itemRes.map((r) => _serialize(r.toColumnMap())).toList();
        final ids  = itemRes
            .map((r) => r.toColumnMap()['id'].toString())
            .toList();

        // 3. Supabase se us PO ke purane items delete (orphan hatao)
        await _supabase
            .from('purchase_order_items')
            .delete()
            .eq('po_id', poId);

        // 4. Local ka poora set upsert (remote = local exact mirror)
        if (rows.isNotEmpty) {
          await _batchUpsert('purchase_order_items', rows);
        }

        // 5. Sirf inhi items ko synced mark karo (id se — concurrent edit safe)
        if (ids.isNotEmpty) {
          final placeholders =
              List.generate(ids.length, (i) => '\$${i + 1}').join(', ');
          await conn.execute(
            'UPDATE public.purchase_order_items '
                'SET is_synced = true, synced_at = NOW() '
                'WHERE id IN ($placeholders)',
            parameters: ids,
          );
        }

        synced += rows.length;
      }

      print('[WarehouseSync]   🧾 purchase_order_items (replace per PO): $synced');
      return synced;
    } catch (e) {
      print('[WarehouseSync]   ❌ purchase_order_items replace sync: $e');
      return 0;
    }
  }

  // ── Batch Upsert ─────────────────────────────────────────
  Future<void> _batchUpsert(
      String table,
      List<Map<String, dynamic>> rows, {
        String onConflict = 'id',  // ← yeh add karo
      }) async {
    const batchSize = 50;
    for (var i = 0; i < rows.length; i += batchSize) {
      final end   = (i + batchSize) > rows.length ? rows.length : (i + batchSize);
      final batch = rows.sublist(i, end);
      await _supabase
          .from(table)
          .upsert(batch, onConflict: onConflict);  // ← parameter use karo
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


// ================================================================================================================================================
/////======/////====== SECOND VERSOIN WITH WAREHOUSE FIANANCE IS BELWO AND THE ABOVE IS FOR WAREHOSUE FINANCE AND SUPPLIER OUTSTANDING /////======/////======
// ================================================================================================================================================





// // ================================================================
// // warehouse_supabase_sync_service.dart
// // Path: lib/core/service/warehouse_supabase_sync_service.dart
// //
// // Warehouse Local DB → Supabase Sync Service
// // Sab 19 tables — sirf is_synced strategy
// //
// // FIX: warehouse_finance cash_in_hand Supabase mein update hota hai
// //      Trigger fix + dedicated sync method dono shamil hain
// // ================================================================
//
// import 'dart:async';
// import 'package:postgres/postgres.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class WarehouseSupabaseSyncService {
//   WarehouseSupabaseSyncService._();
//   static final instance = WarehouseSupabaseSyncService._();
//
//   Timer? _timer;
//   bool   _isSyncing = false;
//
//   final SupabaseClient _supabase = Supabase.instance.client;
//
//   // ── DB Config ─────────────────────────────────────────────
//   static const _dbHost     = 'localhost';
//   static const _dbPort     = 5432;
//   static const _dbName     = 'warehouse_db';
//   static const _dbUser     = 'warehouseuser';
//   static const _dbPassword = 'warehouseUser123';
//
//   // ── Sare 19 Tables — Dependency order mein ───────────────
//   // Parent pehle, child baad mein — FK violation se bachne ke liye
//   // NOTE: warehouse_finance is list mein hai lekin uski DEDICATED method
//   //       bhi hai (_syncWarehouseFinance) jo trigger ke bina bhi kaam kare
//   static const _allTables = [
//     // ── Level 1: Koi dependency nahi ──
//     'warehouses',
//
//     // ── Level 2: warehouses pe dependent ──
//     'locations',
//     'warehouse_users',
//     'warehouse_categories',
//     'warehouse_finance',          // ← yahan bhi hai (is_synced = false wale)
//     'linked_stores',
//
//     // ── Level 3: upar wali tables pe dependent ──
//     'suppliers',
//     'warehouse_products',
//
//     // ── Level 4: products/suppliers pe dependent ──
//     'warehouse_inventory',
//     'warehouse_stock_movements',
//     'warehouse_cash_transactions', // ← jab yeh sync ho, finance bhi update hoga
//
//     // ── Level 5: cash_transactions pe dependent ──
//     'warehouse_expenses',
//
//     // ── Level 6: suppliers pe dependent ──
//     'purchase_orders',
//     'supplier_ledger',
//
//     // ── Level 7: purchase_orders pe dependent ──
//     'purchase_order_items',
//
//     // ── Level 8: stock transfers ──
//     'stock_transfers',
//     'stock_transfer_items',
//
//     // ── Level 9: audit / logs ──
//     'product_audit_log',
//     'warehouse_sync_log',
//   ];
//
//   // ── Start ─────────────────────────────────────────────────
//   void start({Duration interval = const Duration(minutes: 1)}) {
//     print('[WarehouseSync] 🚀 Service starting — interval: ${interval.inSeconds}s');
//     _runSync();
//     _timer = Timer.periodic(interval, (_) => _runSync());
//   }
//
//   // ── Stop ──────────────────────────────────────────────────
//   void stop() {
//     _timer?.cancel();
//     _timer = null;
//     print('[WarehouseSync] 🛑 Service stopped.');
//   }
//
//   // ── DB Connection ─────────────────────────────────────────
//   Future<Connection> _getConnection() async {
//     return await Connection.open(
//       Endpoint(
//         host:     _dbHost,
//         port:     _dbPort,
//         database: _dbName,
//         username: _dbUser,
//         password: _dbPassword,
//       ),
//       settings: const ConnectionSettings(sslMode: SslMode.disable),
//     );
//   }
//
//   // ── Main Sync Loop ────────────────────────────────────────
//   Future<void> _runSync() async {
//     if (_isSyncing) return;
//     _isSyncing = true;
//
//     final sw = Stopwatch()..start();
//     print('[WarehouseSync] 🔄 ${DateTime.now()}');
//
//     Connection? conn;
//     try {
//       conn  = await _getConnection();
//       int total = 0;
//
//       // ── Step 1: Sab tables standard is_synced strategy se ─
//       for (final table in _allTables) {
//         total += await _syncByIsSynced(conn, table);
//       }
//
//       // ── Step 2: warehouse_finance ka dedicated sync ───────
//       // Ye extra safety ke liye hai.
//       // Agar DB trigger (fn_update_cash_in_hand) is_synced = false
//       // set kare, tu Step 1 mein hi mil jata.
//       // Lekin agar trigger ne is_synced reset nahi kiya tu
//       // yeh method cash_transactions ke baad updated finance
//       // force-sync karti hai.
//       total += await _syncWarehouseFinanceAfterTransactions(conn);
//
//       sw.stop();
//       print(total > 0
//           ? '[WarehouseSync] ✅ $total records synced (${sw.elapsedMilliseconds}ms)'
//           : '[WarehouseSync] ✅ Up to date (${sw.elapsedMilliseconds}ms)');
//     } catch (e) {
//       print('[WarehouseSync] ❌ $e');
//     } finally {
//       await conn?.close();
//       _isSyncing = false;
//     }
//   }
//
//   // ── is_synced = false wale records sync karo ──────────────
//   Future<int> _syncByIsSynced(Connection conn, String table) async {
//     try {
//       final result = await conn.execute(
//         Sql.named(
//           'SELECT * FROM public."$table" WHERE is_synced = false LIMIT 500',
//         ),
//       );
//       if (result.isEmpty) return 0;
//
//       final rows = result.map((r) => _serialize(r.toColumnMap())).toList();
//       final ids  = rows.map((r) => r['id'].toString()).toList();
//
//       // Supabase pe upsert
//       await _batchUpsert(table, rows);
//
//       // Local DB mein is_synced = true mark karo
//       if (ids.isNotEmpty) {
//         final placeholders = List.generate(ids.length, (i) => '\$${i + 1}')
//             .join(', ');
//         await conn.execute(
//           'UPDATE public."$table" '
//               'SET is_synced = true, synced_at = NOW() '
//               'WHERE id IN ($placeholders)',
//           parameters: ids,
//         );
//       }
//
//       print('[WarehouseSync]   📤 $table: ${rows.length}');
//       return rows.length;
//     } catch (e) {
//       print('[WarehouseSync]   ❌ $table: $e');
//       return 0;
//     }
//   }
//
//   // ── DEDICATED: warehouse_finance force sync ───────────────
//   //
//   // Masla: DB trigger (fn_update_cash_in_hand) cash_in_hand
//   // update karta hai lekin is_synced = false nahi karta.
//   // Isliye standard _syncByIsSynced miss kar deta hai.
//   //
//   // PERMANENT FIX (ye bhi karo):
//   // PostgreSQL mein trigger update karo:
//   //   UPDATE public.warehouse_finance
//   //   SET cash_in_hand = (...), is_synced = false   ← yeh line add karo
//   //   WHERE warehouse_id = NEW.warehouse_id;
//   //
//   // Jab tak trigger fix nahi hota, yeh method kaam karti hai:
//   // warehouse_cash_transactions ka latest sync time dekhti hai,
//   // aur agar finance updated_at zyada fresh hai tu force upsert karti hai.
//   // ─────────────────────────────────────────────────────────
//   Future<int> _syncWarehouseFinanceAfterTransactions(Connection conn) async {
//     try {
//       // Woh finance rows lo jo:
//       // 1. is_synced = false hain (trigger fix ke baad normal case), YA
//       // 2. updated_at recent transactions ke baad hai (trigger fix se pehle fallback)
//       final result = await conn.execute(
//         Sql.named('''
//           SELECT wf.*
//           FROM public.warehouse_finance wf
//           WHERE
//             wf.is_synced = false
//             OR wf.updated_at > COALESCE(
//               (
//                 SELECT MAX(ct.created_at)
//                 FROM public.warehouse_cash_transactions ct
//                 WHERE ct.warehouse_id = wf.warehouse_id
//                   AND ct.is_synced = true
//                   AND ct.created_at > NOW() - INTERVAL '10 minutes'
//               ),
//               NOW() - INTERVAL '1 year'  -- agar koi recent transaction nahi tu skip
//             )
//           LIMIT 20
//         '''),
//       );
//
//       if (result.isEmpty) return 0;
//
//       final rows = result.map((r) => _serialize(r.toColumnMap())).toList();
//       final ids  = rows.map((r) => r['id'].toString()).toList();
//
//       // Supabase pe upsert (cash_in_hand updated value ke saath)
//       await _batchUpsert('warehouse_finance', rows);
//
//       // Local DB mein is_synced = true mark karo
//       if (ids.isNotEmpty) {
//         final placeholders = List.generate(ids.length, (i) => '\$${i + 1}')
//             .join(', ');
//         await conn.execute(
//           'UPDATE public.warehouse_finance '
//               'SET is_synced = true, synced_at = NOW() '
//               'WHERE id IN ($placeholders)',
//           parameters: ids,
//         );
//       }
//
//       print('[WarehouseSync]   💰 warehouse_finance (cash_in_hand): ${rows.length}');
//       return rows.length;
//     } catch (e) {
//       print('[WarehouseSync]   ❌ warehouse_finance dedicated sync: $e');
//       return 0;
//     }
//   }
//
//   // ── Batch Upsert ─────────────────────────────────────────
//   Future<void> _batchUpsert(
//       String table,
//       List<Map<String, dynamic>> rows,
//       ) async {
//     const batchSize = 50;
//     for (var i = 0; i < rows.length; i += batchSize) {
//       final end   = (i + batchSize) > rows.length ? rows.length : (i + batchSize);
//       final batch = rows.sublist(i, end);
//       await _supabase
//           .from(table)
//           .upsert(batch, onConflict: 'id');
//     }
//   }
//
//   // ── Row Serializer ────────────────────────────────────────
//   Map<String, dynamic> _serialize(Map<String, dynamic> row) {
//     return row.map((key, value) {
//       if (value is DateTime) return MapEntry(key, value.toIso8601String());
//       return MapEntry(key, value);
//     });
//   }
// }




// ================================================================================================
// ================================================================================================
// ================================================================================================
/////// First version is below with no sync of the warehoue finance ////////
// ================================================================================================
// ================================================================================================
// ================================================================================================



// // ================================================================
// // warehouse_supabase_sync_service.dart
// // Path: lib/core/service/warehouse_supabase_sync_service.dart
// //
// // Warehouse Local DB → Supabase Sync Service
// // Sab 19 tables — sirf is_synced strategy
// // ================================================================
//
// import 'dart:async';
// import 'package:postgres/postgres.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class WarehouseSupabaseSyncService {
//   WarehouseSupabaseSyncService._();
//   static final instance = WarehouseSupabaseSyncService._();
//
//   Timer? _timer;
//   bool _isSyncing = false;
//
//   final SupabaseClient _supabase = Supabase.instance.client;
//
//   // ── DB Config ─────────────────────────────────────────────
//   static const _dbHost     = 'localhost';
//   static const _dbPort     = 5432;
//   static const _dbName     = 'warehouse_db';
//   static const _dbUser     = 'warehouseuser';
//   static const _dbPassword = 'warehouseUser123';
//
//   // ── Sare 19 Tables — Dependency order mein ───────────────
//   // Parent pehle, child baad mein — FK violation se bachne ke liye
//   static const _allTables = [
//     // ── Level 1: Koi dependency nahi ──
//     'warehouses',                 // sab ki parent
//
//     // ── Level 2: warehouses pe dependent ──
//     'locations',                  // warehouse_id → warehouses
//     'warehouse_users',            // warehouse_id → warehouses
//     'warehouse_categories',       // warehouse_id → warehouses
//     'warehouse_finance',          // warehouse_id → warehouses
//     'linked_stores',              // warehouse_id → warehouses
//
//     // ── Level 3: upar wali tables pe dependent ──
//     'suppliers',                  // warehouse_id → warehouses
//     'warehouse_products',         // category_id → warehouse_categories
//
//     // ── Level 4: products/suppliers pe dependent ──
//     'warehouse_inventory',        // product_id → warehouse_products
//     'warehouse_stock_movements',  // product_id → warehouse_products
//     'warehouse_cash_transactions',// warehouse_id → warehouses
//
//     // ── Level 5: cash_transactions pe dependent ──
//     'warehouse_expenses',         // cash_transaction_id → warehouse_cash_transactions
//
//     // ── Level 6: suppliers pe dependent ──
//     'purchase_orders',            // supplier_id → suppliers
//     'supplier_ledger',            // supplier_id → suppliers, po_id → purchase_orders
//
//     // ── Level 7: purchase_orders pe dependent ──
//     'purchase_order_items',       // po_id → purchase_orders
//
//     // ── Level 8: stock transfers ──
//     'stock_transfers',            // warehouse_id → warehouses
//     'stock_transfer_items',       // transfer_id → stock_transfers
//
//     // ── Level 9: audit / logs ──
//     'product_audit_log',          // product_id → warehouse_products
//     'warehouse_sync_log',         // warehouse_id → warehouses
//   ];
//
//   // ── Start ─────────────────────────────────────────────────
//   void start({Duration interval = const Duration(minutes: 1)}) {
//     print('[WarehouseSync] 🚀 Service starting — interval: ${interval.inSeconds}s');
//     _runSync();
//     _timer = Timer.periodic(interval, (_) => _runSync());
//   }
//
//   // ── Stop ──────────────────────────────────────────────────
//   void stop() {
//     _timer?.cancel();
//     _timer = null;
//     print('[WarehouseSync] 🛑 Service stopped.');
//   }
//
//   // ── DB Connection ─────────────────────────────────────────
//   Future<Connection> _getConnection() async {
//     return await Connection.open(
//       Endpoint(
//         host:     _dbHost,
//         port:     _dbPort,
//         database: _dbName,
//         username: _dbUser,
//         password: _dbPassword,
//       ),
//       settings: const ConnectionSettings(sslMode: SslMode.disable),
//     );
//   }
//
//   // ── Main Sync Loop ────────────────────────────────────────
//   Future<void> _runSync() async {
//     if (_isSyncing) return;
//     _isSyncing = true;
//
//     final sw = Stopwatch()..start();
//     print('[WarehouseSync] 🔄 ${DateTime.now()}');
//
//     Connection? conn;
//     try {
//       conn = await _getConnection();
//       int total = 0;
//
//       for (final table in _allTables) {
//         total += await _syncByIsSynced(conn, table);
//       }
//
//       sw.stop();
//       print(total > 0
//           ? '[WarehouseSync] ✅ $total records synced (${sw.elapsedMilliseconds}ms)'
//           : '[WarehouseSync] ✅ Up to date (${sw.elapsedMilliseconds}ms)');
//     } catch (e) {
//       print('[WarehouseSync] ❌ $e');
//     } finally {
//       await conn?.close();
//       _isSyncing = false;
//     }
//   }
//
//   // ── is_synced = false wale records sync karo ──────────────
//   Future<int> _syncByIsSynced(Connection conn, String table) async {
//     try {
//       final result = await conn.execute(
//         Sql.named(
//           'SELECT * FROM public."$table" WHERE is_synced = false LIMIT 500',
//         ),
//       );
//       if (result.isEmpty) return 0;
//
//       final rows = result.map((r) => _serialize(r.toColumnMap())).toList();
//       final ids  = rows.map((r) => r['id'].toString()).toList();
//
//       // Supabase pe upsert
//       await _batchUpsert(table, rows);
//
//       // Local DB mein is_synced = true mark karo
//       if (ids.isNotEmpty) {
//         final placeholders = List.generate(ids.length, (i) => '\$${i + 1}')
//             .join(', ');
//         await conn.execute(
//           'UPDATE public."$table" '
//               'SET is_synced = true, synced_at = NOW() '
//               'WHERE id IN ($placeholders)',
//           parameters: ids,
//         );
//       }
//
//       print('[WarehouseSync]   📤 $table: ${rows.length}');
//       return rows.length;
//     } catch (e) {
//       print('[WarehouseSync]   ❌ $table: $e');
//       return 0;
//     }
//   }
//
//   // ── Batch Upsert ─────────────────────────────────────────
//   Future<void> _batchUpsert(
//       String table,
//       List<Map<String, dynamic>> rows,
//       ) async {
//     const batchSize = 50;
//     for (var i = 0; i < rows.length; i += batchSize) {
//       final end   = (i + batchSize) > rows.length ? rows.length : (i + batchSize);
//       final batch = rows.sublist(i, end);
//       await _supabase
//           .from(table)
//           .upsert(batch, onConflict: 'id');
//     }
//   }
//
//   // ── Row Serializer ────────────────────────────────────────
//   Map<String, dynamic> _serialize(Map<String, dynamic> row) {
//     return row.map((key, value) {
//       if (value is DateTime) return MapEntry(key, value.toIso8601String());
//       return MapEntry(key, value);
//     });
//   }
// }