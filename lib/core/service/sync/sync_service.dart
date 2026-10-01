// import 'dart:async';
// import 'dart:io';
// import 'dart:isolate';
// import 'package:postgres/postgres.dart';
// import 'package:supabase/supabase.dart';
//
// // ═══════════════════════════════════════════════════════════
// //  CONFIG
// // ═══════════════════════════════════════════════════════════
// class SyncConfig {
//   // ── Local PostgreSQL ──────────────────────────────────────
//   static const String dbHost     = '127.0.0.1';
//   static const int    dbPort     = 5432;
//   static const String dbName     = 'store_db';
//   static const String dbUser     = 'storeuser';
//   static const String dbPassword = 'shahab';
//
//   // ── Supabase ──────────────────────────────────────────────
//   static const String supabaseUrl = "https://kjjtqfruxhjcxwvxwffz.supabase.co";
//   // static const String supabaseUrl = "https://fngvbieiwilypecznwcl.supabase.co";
//   // static const String supabaseKey = "sb_publishable_z-6QD20dfck8hoG9_NzSZw_063NHmS4";
//   static const String supabaseKey = "sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS";
//
//   // ── Sync interval (seconds) ───────────────────────────────
//   static const int syncIntervalSeconds = 120;
//
//   // ── Tables — dependency order mein (parent pehle) ────────
//   static const List<String> tables = [
//     'branch',
//     'branch_counter',
//     'customer',
//     'customer_logs',                    // ← ADD (customer ke baad)
//     'branch_stock_inventory',
//     'branch_stock_inventory_logs',
//     'branch_expense',
//     'branch_users',
//     'branch_cash_counter',
//     'branch_cash_transaction',
//     'branch_stock_damage',
//     'sale_invoices',
//     'sale_invoice_items',
//     'sale_invoice_payments',
//     'sale_returns',
//     'sale_return_items',
//     'sale_return_payments',
//     'customer_ledger',
//     'branch_summary',
//     'branch_transaction_to_janghani',
//   ];
//
// // ── Yeh tables mein store_id column HAI ──────────────────
//   static const List<String> storeIdTables = [
//     'branch_cash_counter',
//     'branch_cash_transaction',
//     'branch_counter',
//     'branch_expense',
//     'branch_stock_damage',
//     'branch_stock_inventory',
//     'branch_stock_inventory_logs',
//     'branch_summary',
//     'branch_users',
//     'customer',
//     'customer_logs',                    // ← ADD
//     'customer_ledger',
//     'sale_invoice_payments',
//     'sale_invoices',
//     'sale_return_payments',
//     'sale_returns',
//   ];
//
//   // ── Yeh tables HAMESHA full sync hongi ───────────────────
//   // branch: alag machines pe updated_at purana ho sakta hai
//   // sale_invoice_items / sale_return_items: koi store_id nahi
//   // branch_transaction_to_janghani: same reason
//   static const List<String> fullSyncTables = [
//     'branch',
//     'sale_invoice_items',
//     'sale_return_items',
//     'branch_transaction_to_janghani',
//     'branch_stock_inventory',
//   ];
//
//   // ── Har table ka timestamp column ────────────────────────
// // ── Har table ka timestamp column ────────────────────────
//   static const Map<String, String> _timestampColumns = {
//     'sale_invoice_items'    : 'created_at',
//     'sale_invoice_payments' : 'created_at',
//     'sale_return_items'     : 'created_at',
//     'sale_return_payments'  : 'created_at',
//     'branch_stock_damage'   : 'created_at',
//     'customer_logs'          : 'created_at',   // ← ADD
//     'branch_stock_inventory_logs' : 'created_at',   // ← ADD
//   };
//
//   // ── Har table ka conflict (primary key) column ────────────
//   //
//   // ⚠️ IMPORTANT FIX (branch_stock_inventory):
//   // Har local branch database alag machine par hai, aur products
//   // insert/seed karte waqt kayi branches mein SAME UUID `id` ban
//   // jaata hai (alag store_id ke sath). Agar conflict column sirf
//   // "id" ho, to Supabase mein upsert karte waqt Branch B ki row,
//   // Branch A ki row ko OVERWRITE kar deti hai (store_id samet) —
//   // is se dusri branch ka stock "gayab" ho jaata hai.
//   //
//   // Fix: conflict ko store_id + product_id par based karo, taake
//   // har branch ki apni alag row Supabase mein rahe.
//   static const Map<String, String> _conflictColumns = {
//     'branch_summary'        : 'store_id,counter_date',
//     'branch_stock_inventory': 'store_id,product_id',
//   };
//
//   // ── Yeh columns Supabase mein nahi hain — upsert se remove honge
//   static const Map<String, List<String>> excludeColumns = {
//     'accountant_transactions': ['is_synced'],
//   };
//
//   static String timestampColumn(String table) =>
//       _timestampColumns[table] ?? 'updated_at';
//
//   static String conflictColumn(String table) =>
//       _conflictColumns[table] ?? 'id';
// }
//
// // ═══════════════════════════════════════════════════════════
// //  ISOLATE MESSAGE TYPES
// // ═══════════════════════════════════════════════════════════
// sealed class _IsolateMsg {}
//
// class _TableSuccess extends _IsolateMsg {
//   final String table;
//   final int    count;
//   _TableSuccess(this.table, this.count);
// }
//
// class _TableError extends _IsolateMsg {
//   final String table;
//   final String error;
//   _TableError(this.table, this.error);
// }
//
// class _SyncComplete extends _IsolateMsg {}
//
// // ═══════════════════════════════════════════════════════════
// //  SYNC STATUS
// // ═══════════════════════════════════════════════════════════
// class SyncStatus {
//   final bool                isSyncing;
//   final bool                hasInternet;
//   final DateTime?           lastSyncTime;
//   final int                 totalSynced;
//   final String?             lastError;
//   final Map<String, String> tableStatus;
//
//   const SyncStatus({
//     this.isSyncing    = false,
//     this.hasInternet  = false,
//     this.lastSyncTime,
//     this.totalSynced  = 0,
//     this.lastError,
//     this.tableStatus  = const {},
//   });
//
//   SyncStatus copyWith({
//     bool?                isSyncing,
//     bool?                hasInternet,
//     DateTime?            lastSyncTime,
//     int?                 totalSynced,
//     String?              lastError,
//     Map<String, String>? tableStatus,
//   }) =>
//       SyncStatus(
//         isSyncing:    isSyncing    ?? this.isSyncing,
//         hasInternet:  hasInternet  ?? this.hasInternet,
//         lastSyncTime: lastSyncTime ?? this.lastSyncTime,
//         totalSynced:  totalSynced  ?? this.totalSynced,
//         lastError:    lastError,
//         tableStatus:  tableStatus  ?? this.tableStatus,
//       );
// }
//
// // ═══════════════════════════════════════════════════════════
// //  ISOLATE ARGS
// // ═══════════════════════════════════════════════════════════
// class _IsolateArgs {
//   final SendPort sendPort;
//   final String   supabaseUrl;
//   final String   supabaseKey;
//
//   const _IsolateArgs({
//     required this.sendPort,
//     required this.supabaseUrl,
//     required this.supabaseKey,
//   });
// }
//
// // ═══════════════════════════════════════════════════════════
// //  SYNC SERVICE  (Singleton)
// // ═══════════════════════════════════════════════════════════
// class SyncService {
//   static final SyncService _instance = SyncService._();
//   factory SyncService() => _instance;
//   SyncService._();
//
//   Isolate?     _isolate;
//   ReceivePort? _receivePort;
//   Timer?       _syncTimer;
//   Timer?       _internetTimer;
//   bool         _running = false;
//
//   SyncStatus _status = const SyncStatus();
//   SyncStatus get currentStatus => _status;
//
//   final _statusCtrl = StreamController<SyncStatus>.broadcast();
//   Stream<SyncStatus> get statusStream => _statusCtrl.stream;
//
//   Future<void> start() async {
//     if (_running) return;
//     _running = true;
//     _log('🏪 Store Sync Service — Start');
//     _startInternetMonitor();
//     await _runSync();
//     _syncTimer = Timer.periodic(
//       Duration(seconds: SyncConfig.syncIntervalSeconds),
//           (_) => _runSync(),
//     );
//   }
//
//   Future<void> syncNow() async {
//     _log('🔁 Manual sync...');
//     await _runSync();
//   }
//
//   void stop() {
//     _syncTimer?.cancel();
//     _internetTimer?.cancel();
//     _killIsolate();
//     _running = false;
//     _log('🛑 Sync service band');
//   }
//
//   void dispose() {
//     stop();
//     _statusCtrl.close();
//   }
//
//   void _startInternetMonitor() {
//     _internetTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
//       final hasNet = await _checkInternet();
//       final wasNet = _status.hasInternet;
//       _emit(_status.copyWith(hasInternet: hasNet));
//       if (hasNet && !wasNet) {
//         _log('🌐 Internet aa gaya — sync shuru');
//         _runSync();
//       } else if (!hasNet && wasNet) {
//         _log('📵 Internet chala gaya');
//       }
//     });
//   }
//
//   Future<void> _runSync() async {
//     if (_status.isSyncing) {
//       _log('⏳ Pehle se chal rahi hai — skip');
//       return;
//     }
//     final hasNet = await _checkInternet();
//     if (!hasNet) {
//       _log('📵 Internet nahi — skip');
//       _emit(_status.copyWith(hasInternet: false));
//       return;
//     }
//     _emit(_status.copyWith(isSyncing: true, hasInternet: true));
//     _killIsolate();
//     _receivePort = ReceivePort();
//     try {
//       _isolate = await Isolate.spawn(
//         _isolateEntry,
//         _IsolateArgs(
//           sendPort:    _receivePort!.sendPort,
//           supabaseUrl: SyncConfig.supabaseUrl,
//           supabaseKey: SyncConfig.supabaseKey,
//         ),
//         errorsAreFatal: false,
//         debugName: 'SyncIsolate',
//       );
//       await for (final msg in _receivePort!) {
//         if (msg is _IsolateMsg) _handleMsg(msg);
//         if (msg == 'DONE') break;
//       }
//     } catch (e) {
//       _log('❌ Isolate error: $e');
//       _emit(_status.copyWith(isSyncing: false, lastError: e.toString()));
//     } finally {
//       _receivePort?.close();
//       _receivePort = null;
//     }
//   }
//
//   void _handleMsg(_IsolateMsg msg) {
//     switch (msg) {
//       case _TableSuccess(:final table, :final count):
//         final map = Map<String, String>.from(_status.tableStatus);
//         map[table] = count > 0 ? '✅ $count synced' : '✅ up-to-date';
//         _emit(_status.copyWith(
//           tableStatus: map,
//           totalSynced: _status.totalSynced + count,
//         ));
//       case _TableError(:final table, :final error):
//         final map = Map<String, String>.from(_status.tableStatus);
//         map[table] = '❌ error';
//         _emit(_status.copyWith(
//           tableStatus: map,
//           lastError:   '[$table] $error',
//         ));
//       case _SyncComplete():
//         _emit(_status.copyWith(
//           isSyncing:    false,
//           lastSyncTime: DateTime.now(),
//           lastError:    null,
//         ));
//     }
//   }
//
//   void _killIsolate() {
//     _isolate?.kill(priority: Isolate.immediate);
//     _isolate = null;
//   }
//
//   void _emit(SyncStatus s) {
//     _status = s;
//     if (!_statusCtrl.isClosed) _statusCtrl.add(s);
//   }
//
//   static Future<bool> _checkInternet() async {
//     try {
//       final res = await InternetAddress.lookup('supabase.co')
//           .timeout(const Duration(seconds: 5));
//       return res.isNotEmpty && res[0].rawAddress.isNotEmpty;
//     } catch (_) {
//       return false;
//     }
//   }
//
//   static void _log(String msg) => print(msg);
//
//   // ══════════════════════════════════════════════
//   //  🏭 ISOLATE — Background Thread
//   // ══════════════════════════════════════════════
//
//   static Future<void> _isolateEntry(_IsolateArgs args) async {
//     final send = args.sendPort;
//
//     _log('═' * 50);
//     _log('  🕐 Sync: ${DateTime.now()}');
//     _log('═' * 50);
//
//     Connection?     db;
//     SupabaseClient? supabase;
//
//     try {
//       db = await Connection.open(
//         Endpoint(
//           host:     SyncConfig.dbHost,
//           port:     SyncConfig.dbPort,
//           database: SyncConfig.dbName,
//           username: SyncConfig.dbUser,
//           password: SyncConfig.dbPassword,
//         ),
//         settings: ConnectionSettings(sslMode: SslMode.disable),
//       );
//       _log('  ✅ Local DB connected');
//
//       supabase = SupabaseClient(
//         args.supabaseUrl,
//         args.supabaseKey,
//         authOptions: const AuthClientOptions(autoRefreshToken: false),
//       );
//       _log('  ✅ Supabase connected');
//
//       // ── Is machine ki store_id lo ─────────────
//       final storeId = await _getLocalStoreId(db);
//       if (storeId == null) {
//         _log('  ❌ store_id nahi mila — sync cancel');
//         send.send(_TableError('branch', 'Local branch/store_id nahi mila'));
//         send.send('DONE');
//         return;
//       }
//       _log('  🏪 Store ID: $storeId');
//
//       // ── Har table sync karo ───────────────────
//       for (final table in SyncConfig.tables) {
//         final count = await _syncTable(db, supabase, table, storeId, send);
//         _log(count > 0
//             ? '  🔄 $table: $count rows synced'
//             : '  ✅ $table: kuch nahi tha');
//       }
//
//       send.send(_SyncComplete());
//       _log('${"─" * 50}');
//       _log('  ✅ Sync complete!');
//
//     } catch (e, st) {
//       _log('  ❌ Sync error: $e\n$st');
//       send.send(_TableError('connection', e.toString()));
//     } finally {
//       await db?.close();
//       supabase?.dispose();
//       send.send('DONE');
//     }
//   }
//
//   // ══════════════════════════════════════════════
//   //  🏪 Local store_id fetch karo
//   // ══════════════════════════════════════════════
//
//   static Future<String?> _getLocalStoreId(Connection db) async {
//     try {
//       final result = await db.execute(
//         Sql('SELECT id FROM branch LIMIT 1'),
//       );
//       if (result.isEmpty) return null;
//       return result.first.toColumnMap()['id']?.toString();
//     } catch (e) {
//       _log('  ❌ store_id fetch error: $e');
//       return null;
//     }
//   }
//
//   // ══════════════════════════════════════════════
//   //  🔄 Single Table Sync
//   //
//   //  3 strategies:
//   //  1. fullSyncTables   → hamesha poora data
//   //  2. storeIdTables    → store_id filter + timestamp
//   //  3. baaki            → sirf timestamp filter
//   // ══════════════════════════════════════════════
//
//   static Future<int> _syncTable(
//       Connection     db,
//       SupabaseClient supabase,
//       String         table,
//       String         storeId,
//       SendPort       send,
//       ) async {
//     try {
//       final tsCol       = SyncConfig.timestampColumn(table);
//       final conflictCol = SyncConfig.conflictColumn(table);
//       final isFullSync  = SyncConfig.fullSyncTables.contains(table);
//       final hasStoreId  = SyncConfig.storeIdTables.contains(table);
//
//       // ── Step 1: Last timestamp lo ───────────────
//       String? lastSyncedAt;
//
//       if (isFullSync) {
//         // Full sync — timestamp check hi nahi
//         _log('  🔁 $table — full sync mode');
//       } else {
//         try {
//           // KEY FIX: store_id wale tables ke liye
//           // SIRF IS BRANCH ka last timestamp lo
//           // Dusri branch ka timestamp ignore hoga
//           final query = hasStoreId
//               ? supabase
//               .from(table)
//               .select(tsCol)
//               .eq('store_id', storeId)        // ← per-branch filter
//               .order(tsCol, ascending: false)
//               .limit(1)
//               : supabase
//               .from(table)
//               .select(tsCol)
//               .order(tsCol, ascending: false)
//               .limit(1);
//
//           final res = await query;
//
//           if (res.isNotEmpty && res[0][tsCol] != null) {
//             lastSyncedAt = res[0][tsCol].toString();
//             _log('  📅 $table — last synced: $lastSyncedAt'
//                 '${hasStoreId ? " (store: $storeId)" : ""}');
//           } else {
//             _log('  📅 $table — Supabase mein kuch nahi, full sync');
//           }
//         } catch (e) {
//           _log('  ⚠️  $table — lastSync fetch fail: $e');
//         }
//       }
//
//       // ── Step 2: Local se rows lo ───────────────
//       final List<Map<String, dynamic>> rows;
//
//       if (isFullSync) {
//         // Full sync — poora table (store_id filter bhi)
//         if (hasStoreId) {
//           final result = await db.execute(
//             Sql.named('SELECT * FROM "$table" WHERE store_id = @sid ORDER BY "$tsCol" ASC'),
//             parameters: {'sid': storeId},
//           );
//           rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
//         } else {
//           final result = await db.execute(
//             Sql('SELECT * FROM "$table" ORDER BY "$tsCol" ASC'),
//           );
//           rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
//         }
//       } else if (lastSyncedAt != null) {
//         // Incremental — timestamp ke baad wale rows
//         if (hasStoreId) {
//           final result = await db.execute(
//             Sql.named(
//               'SELECT * FROM "$table" '
//                   'WHERE store_id = @sid '
//                   '  AND "$tsCol" > @ts::timestamptz '
//                   'ORDER BY "$tsCol" ASC',
//             ),
//             parameters: {'sid': storeId, 'ts': lastSyncedAt},
//           );
//           rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
//         } else {
//           final result = await db.execute(
//             Sql.named(
//               'SELECT * FROM "$table" '
//                   'WHERE "$tsCol" > @ts::timestamptz '
//                   'ORDER BY "$tsCol" ASC',
//             ),
//             parameters: {'ts': lastSyncedAt},
//           );
//           rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
//         }
//       } else {
//         // Supabase empty tha — poora local data bhejo
//         if (hasStoreId) {
//           final result = await db.execute(
//             Sql.named('SELECT * FROM "$table" WHERE store_id = @sid ORDER BY "$tsCol" ASC'),
//             parameters: {'sid': storeId},
//           );
//           rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
//         } else {
//           final result = await db.execute(
//             Sql('SELECT * FROM "$table" ORDER BY "$tsCol" ASC'),
//           );
//           rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
//         }
//       }
//
//       _log('  📦 $table: ${rows.length} rows milein');
//       if (rows.isEmpty) {
//         send.send(_TableSuccess(table, 0));
//         return 0;
//       }
//
//       // ── Step 3: Exclude columns ─────────────────
//       final excludeCols = SyncConfig.excludeColumns[table] ?? [];
//       final supaRows = excludeCols.isEmpty
//           ? rows
//           : rows.map((r) {
//         final m = Map<String, dynamic>.from(r);
//         for (final col in excludeCols) m.remove(col);
//         return m;
//       }).toList();
//
//       // ── Step 4: Upsert Supabase mein ────────────
//       const batchSize = 50;
//       int totalSynced = 0;
//       final List<String> syncedIds = [];
//
//       for (int i = 0; i < supaRows.length; i += batchSize) {
//         final batch = supaRows.sublist(
//           i,
//           (i + batchSize).clamp(0, supaRows.length),
//         );
//         try {
//           await supabase.from(table).upsert(batch, onConflict: conflictCol);
//           totalSynced += batch.length;
//           if (table == 'accountant_transactions') {
//             syncedIds.addAll(batch.map((r) => r['id'].toString()));
//           }
//         } catch (batchErr) {
//           _log('  ⚠️  $table batch fail — row-by-row: $batchErr');
//           for (final row in batch) {
//             try {
//               await supabase.from(table).upsert(row, onConflict: conflictCol);
//               totalSynced++;
//               if (table == 'accountant_transactions') {
//                 syncedIds.add(row['id'].toString());
//               }
//             } catch (rowErr) {
//               _log('  ❌ $table row skip: $rowErr\n     Row: $row');
//             }
//           }
//         }
//       }
//
//       // ── Step 5: accountant_transactions is_synced ─
//       if (table == 'accountant_transactions' && syncedIds.isNotEmpty) {
//         final idList = syncedIds.map((id) => "'$id'").join(',');
//         await db.execute(
//           Sql('UPDATE accountant_transactions '
//               'SET is_synced = true WHERE id IN ($idList)'),
//         );
//         _log('  ✅ accountant_transactions: ${syncedIds.length} is_synced=true');
//       }
//
//       send.send(_TableSuccess(table, totalSynced));
//       return totalSynced;
//
//     } catch (e, st) {
//       _log('  ❌ $table sync error: $e\n$st');
//       send.send(_TableError(table, e.toString()));
//       return 0;
//     }
//   }
//
//   // ══════════════════════════════════════════════
//   //  Row Convert — Dart types → JSON safe
//   // ══════════════════════════════════════════════
//
//   static Map<String, dynamic> _toJsonRow(Map<String, dynamic> row) {
//     return row.map((key, value) {
//       if (value == null)     return MapEntry(key, null);
//       if (value is DateTime) return MapEntry(key, value.toUtc().toIso8601String());
//       if (value is int)      return MapEntry(key, value);
//       if (value is double)   return MapEntry(key, value);
//       if (value is bool)     return MapEntry(key, value);
//       if (value is String)   return MapEntry(key, value);
//       if (value is List)     return MapEntry(key, value);
//       if (value is Map)      return MapEntry(key, value);
//       return MapEntry(key, value.toString());
//     });
//   }
// }



import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:postgres/postgres.dart';
import 'package:supabase/supabase.dart';

// ═══════════════════════════════════════════════════════════
//  CONFIG
// ═══════════════════════════════════════════════════════════
class SyncConfig {
  // ── Local PostgreSQL ──────────────────────────────────────
  static const String dbHost     = '127.0.0.1';
  static const int    dbPort     = 5432;
  static const String dbName     = 'store_db';
  static const String dbUser     = 'storeuser';
  static const String dbPassword = 'shahab';

//  ── Supabase production ──────────────────────────────────────────────
  static const String supabaseUrl = "https://kjjtqfruxhjcxwvxwffz.supabase.co";
  static const String supabaseKey = "sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS";

  // // ── Supabase dev ──────────────────────────────────────────────
  // static const String supabaseUrl = "https://fngvbieiwilypecznwcl.supabase.co";
  // static const String supabaseKey = "sb_publishable_z-6QD20dfck8hoG9_NzSZw_063NHmS4";

  // ── Sync interval — 10 minutes ────────────────────────────
  static const int syncIntervalSeconds = 500;

  // ── Watermark lookback: slow/no internet ke waqt kuch rows fail ho
  // sakti hain jabke naye rows pass ho jayen — watermark unse aage nikal
  // jata hai aur woh rows kabhi dobara nahi bhejti thin. Har cycle mein
  // itne din peeche se dobara bhejo (upsert idempotent hai).
  static const int lookbackDays = 7;

  // ── Ek sync cycle ki max muddat — slow internet par hang na ho
  static const int syncTimeoutMinutes = 5;

  // ── App open hone par full check (har table ki har row Supabase
  // se match) — zyada data hai, is liye iski muddat alag aur lambi
  static const int fullCheckTimeoutMinutes = 15;

  // ── Tables — dependency order mein (parent pehle) ────────
  static const List<String> tables = [
    'branch',
    'branch_counter',
    'customer',
    'customer_logs',
    'branch_stock_inventory',
    'branch_stock_inventory_logs',
    'branch_expense',
    'branch_users',
    'branch_cash_counter',
    'branch_cash_transaction',
    'branch_stock_damage',
    'sale_invoices',
    'sale_invoice_items',
    'sale_invoice_payments',
    'sale_returns',
    'sale_return_items',
    'sale_return_payments',
    'customer_ledger',
    'branch_summary',
    'branch_transaction_to_janghani',
  ];

  // ── Yeh tables mein store_id column HAI ──────────────────
  static const List<String> storeIdTables = [
    'branch_cash_counter',
    'branch_cash_transaction',
    'branch_counter',
    'branch_expense',
    'branch_stock_damage',
    'branch_stock_inventory',
    'branch_stock_inventory_logs',
    'branch_summary',
    'branch_users',
    'customer',
    'customer_logs',
    'customer_ledger',
    'sale_invoice_payments',
    'sale_invoices',
    'sale_return_payments',
    'sale_returns',
  ];

  // ── Yeh columns Supabase mein nahi hain — upsert se remove honge
  static const Map<String, List<String>> excludeColumns = {
    'accountant_transactions': ['is_synced'],
    // ⚠️ IMPORTANT: alag branches mein same product ke liye
    // 'branch_stock_inventory' ka local 'id' identical ban jaata
    // hai (product_id se juda hua). Conflict target 'store_id,
    // product_id' hai (sahi hai), lekin 'id' bhi bhej dein to woh
    // 'branch_stock_inventory_pkey' (PRIMARY KEY id) violate kar
    // deta hai — jo ON CONFLICT resolve nahi karta, aur poori
    // INSERT fail ho jaati hai (dusri branch ka stock kabhi sync
    // nahi hota). Fix: 'id' bhejo hi mat — Supabase apna naya id
    // khud generate kar lega.
    'branch_stock_inventory': ['id'],
    // Local `branch_stock_inventory_logs` mein `changed_by` aur `notes`
    // columns hain (DB-side, app inhe set nahi karta) jo Supabase ke
    // table mein nahi — bina exclude kiye har log row PGRST204 se skip
    // ho jaati thi. Accountant report sirf `user_id` padhti hai, in
    // dono ko nahi — is liye safely drop.
    'branch_stock_inventory_logs': ['changed_by', 'notes'],
  };

  // ── Har table ka timestamp column ────────────────────────
  static const Map<String, String> _timestampColumns = {
    'sale_invoice_items'          : 'created_at',
    'sale_invoice_payments'       : 'created_at',
    'sale_return_items'           : 'created_at',
    'sale_return_payments'        : 'created_at',
    'branch_stock_damage'         : 'created_at',
    'customer_logs'               : 'created_at',
    'branch_stock_inventory_logs' : 'created_at',
  };

  // ── Har table ka conflict (primary key) column ────────────
  static const Map<String, String> _conflictColumns = {
    'branch_summary'        : 'store_id,counter_date',
    'branch_stock_inventory': 'store_id,product_id',
  };

  // ── Yeh tables mein 'store_id' nahi, lekin koi aur column
  // hai jo isi branch ki row(s) ko uniquely scope karta hai —
  // us column se per-branch filter lagao (warna global timestamp
  // ke wajah se dusri branch ka naya sync is branch ke purane
  // rows ko hamesha ke liye skip kar sakta hai).
  static const Map<String, String> _altFilterColumns = {
    'branch'                       : 'id',
    'branch_transaction_to_janghani': 'branch_id',
  };

  // ── Yeh child tables mein store_id nahi, sirf parent FK hai.
  // Per-branch watermark parent ke store_id par inner join se
  // nikalta hai. Pehle yeh full resync hoti thin (~72k rows har
  // cycle, purani pehle) — slow internet par cycle beech mein
  // timeout/kill ho jaata aur naye items kabhi Supabase tak nahi
  // pahunchte thay (invoice sync, items missing). Items sirf
  // insert hote hain, is liye created_at watermark safe hai.
  //   table → (parent table, FK column)
  static const Map<String, (String, String)> _parentScopedTables = {
    'sale_invoice_items': ('sale_invoices', 'invoice_id'),
    'sale_return_items' : ('sale_returns',  'return_id'),
  };

  // ── 'branch_stock_damage': is table mein 'updated_at' column
  // hi nahi hai, aur 'updateDamage()' row edit karte waqt
  // 'created_at' ko touch nahi karta — isliye edit hui row kabhi
  // incremental sync mein pick nahi hoti thi. Har cycle poora.
  static const List<String> fullSyncTables = [
    'branch_stock_damage',
  ];

  static String timestampColumn(String table) =>
      _timestampColumns[table] ?? 'updated_at';

  static String conflictColumn(String table) =>
      _conflictColumns[table] ?? 'id';

  // ── Is table ko per-branch filter karne wala column, ya
  // null agar table globally (sabhi branches mil ke) sync hoti hai.
  static String? filterColumn(String table) {
    if (_altFilterColumns.containsKey(table)) return _altFilterColumns[table];
    if (storeIdTables.contains(table)) return 'store_id';
    return null;
  }

  static (String, String)? parentScope(String table) =>
      _parentScopedTables[table];
}

// ═══════════════════════════════════════════════════════════
//  ISOLATE MESSAGE TYPES
// ═══════════════════════════════════════════════════════════
sealed class _IsolateMsg {}

class _TableSuccess extends _IsolateMsg {
  final String table;
  final int    count;
  _TableSuccess(this.table, this.count);
}

class _TableError extends _IsolateMsg {
  final String table;
  final String error;
  _TableError(this.table, this.error);
}

class _SyncComplete extends _IsolateMsg {}

// ═══════════════════════════════════════════════════════════
//  SYNC STATUS
// ═══════════════════════════════════════════════════════════
class SyncStatus {
  final bool                isSyncing;
  final bool                hasInternet;
  final DateTime?           lastSyncTime;
  final int                 totalSynced;
  final String?             lastError;
  final Map<String, String> tableStatus;

  const SyncStatus({
    this.isSyncing    = false,
    this.hasInternet  = false,
    this.lastSyncTime,
    this.totalSynced  = 0,
    this.lastError,
    this.tableStatus  = const {},
  });

  SyncStatus copyWith({
    bool?                isSyncing,
    bool?                hasInternet,
    DateTime?            lastSyncTime,
    int?                 totalSynced,
    String?              lastError,
    Map<String, String>? tableStatus,
  }) =>
      SyncStatus(
        isSyncing:    isSyncing    ?? this.isSyncing,
        hasInternet:  hasInternet  ?? this.hasInternet,
        lastSyncTime: lastSyncTime ?? this.lastSyncTime,
        totalSynced:  totalSynced  ?? this.totalSynced,
        lastError:    lastError,
        tableStatus:  tableStatus  ?? this.tableStatus,
      );
}

// ═══════════════════════════════════════════════════════════
//  ISOLATE ARGS
// ═══════════════════════════════════════════════════════════
class _IsolateArgs {
  final SendPort sendPort;
  final String   supabaseUrl;
  final String   supabaseKey;
  final bool     fullCheck;

  const _IsolateArgs({
    required this.sendPort,
    required this.supabaseUrl,
    required this.supabaseKey,
    required this.fullCheck,
  });
}

// ═══════════════════════════════════════════════════════════
//  SYNC SERVICE  (Singleton)
// ═══════════════════════════════════════════════════════════
class SyncService {
  static final SyncService _instance = SyncService._();
  factory SyncService() => _instance;
  SyncService._();

  Isolate?     _isolate;
  ReceivePort? _receivePort;
  Timer?       _syncTimer;
  Timer?       _internetTimer;
  bool         _running = false;

  // App open hone ke baad pehli mukammal sync full check hogi. Internet
  // na ho, timeout ho ya connection error aaye to yeh false hi rehta hai
  // aur agli cycle phir se full check karti hai.
  bool _fullCheckDone  = false;
  bool _currentRunFull = false;

  SyncStatus _status = const SyncStatus();
  SyncStatus get currentStatus => _status;

  final _statusCtrl = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusCtrl.stream;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _fullCheckDone = false;
    _log('🏪 Store Sync Service — Start (full check, phir har ${SyncConfig.syncIntervalSeconds}s)');
    _startInternetMonitor();
    await _runSync();
    _syncTimer = Timer.periodic(
      Duration(seconds: SyncConfig.syncIntervalSeconds),
          (_) => _runSync(),
    );
  }

  Future<void> syncNow() async {
    _log('🔁 Manual sync...');
    await _runSync();
  }

  void stop() {
    _syncTimer?.cancel();
    _internetTimer?.cancel();
    _killIsolate();
    _running = false;
    _log('🛑 Sync service band');
  }

  void dispose() {
    stop();
    _statusCtrl.close();
  }

  void _startInternetMonitor() {
    _internetTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final hasNet = await _checkInternet();
      final wasNet = _status.hasInternet;
      _emit(_status.copyWith(hasInternet: hasNet));
      if (hasNet && !wasNet) {
        _log('🌐 Internet aa gaya — sync shuru');
        _runSync();
      } else if (!hasNet && wasNet) {
        _log('📵 Internet chala gaya');
      }
    });
  }

  Future<void> _runSync() async {
    if (_status.isSyncing) {
      _log('⏳ Pehle se chal rahi hai — skip');
      return;
    }
    final hasNet = await _checkInternet();
    if (!hasNet) {
      _log('📵 Internet nahi — skip');
      _emit(_status.copyWith(hasInternet: false));
      return;
    }
    _currentRunFull = !_fullCheckDone;
    _emit(_status.copyWith(isSyncing: true, hasInternet: true));
    _killIsolate();
    _receivePort = ReceivePort();
    try {
      _isolate = await Isolate.spawn(
        _isolateEntry,
        _IsolateArgs(
          sendPort:    _receivePort!.sendPort,
          supabaseUrl: SyncConfig.supabaseUrl,
          supabaseKey: SyncConfig.supabaseKey,
          fullCheck:   _currentRunFull,
        ),
        errorsAreFatal: false,
        debugName: 'SyncIsolate',
      );
      await () async {
        await for (final msg in _receivePort!) {
          if (msg is _IsolateMsg) _handleMsg(msg);
          if (msg == 'DONE') break;
        }
      }().timeout(Duration(minutes: _currentRunFull
          ? SyncConfig.fullCheckTimeoutMinutes
          : SyncConfig.syncTimeoutMinutes));
    } catch (e) {
      _log('❌ Isolate error: $e');
      _killIsolate();
      _emit(_status.copyWith(isSyncing: false, lastError: e.toString()));
    } finally {
      _receivePort?.close();
      _receivePort = null;
      // Isolate error path _SyncComplete nahi bhejta — flag reset na ho
      // to har agla _runSync "pehle se chal rahi hai" keh kar skip hota.
      if (_status.isSyncing) {
        _emit(_status.copyWith(isSyncing: false, lastError: _status.lastError));
      }
    }
  }

  void _handleMsg(_IsolateMsg msg) {
    switch (msg) {
      case _TableSuccess(:final table, :final count):
        final map = Map<String, String>.from(_status.tableStatus);
        map[table] = count > 0 ? '✅ $count synced' : '✅ up-to-date';
        _emit(_status.copyWith(
          tableStatus: map,
          totalSynced: _status.totalSynced + count,
        ));
      case _TableError(:final table, :final error):
        final map = Map<String, String>.from(_status.tableStatus);
        map[table] = '❌ error';
        _emit(_status.copyWith(
          tableStatus: map,
          lastError:   '[$table] $error',
        ));
      case _SyncComplete():
        if (_currentRunFull) {
          _fullCheckDone = true;
          _log('✅ Full check mukammal — ab normal sync');
        }
        _emit(_status.copyWith(
          isSyncing:    false,
          lastSyncTime: DateTime.now(),
          lastError:    null,
        ));
    }
  }

  void _killIsolate() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  void _emit(SyncStatus s) {
    _status = s;
    if (!_statusCtrl.isClosed) _statusCtrl.add(s);
  }

  static Future<bool> _checkInternet() async {
    try {
      final res = await InternetAddress.lookup('supabase.co')
          .timeout(const Duration(seconds: 5));
      return res.isNotEmpty && res[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static void _log(String msg) => print(msg);

  // ══════════════════════════════════════════════
  //  🏭 ISOLATE — Background Thread
  // ══════════════════════════════════════════════

  static Future<void> _isolateEntry(_IsolateArgs args) async {
    final send = args.sendPort;

    _log('═' * 50);
    _log('  🕐 Sync: ${DateTime.now()}');
    _log('═' * 50);

    Connection?     db;
    SupabaseClient? supabase;

    try {
      db = await Connection.open(
        Endpoint(
          host:     SyncConfig.dbHost,
          port:     SyncConfig.dbPort,
          database: SyncConfig.dbName,
          username: SyncConfig.dbUser,
          password: SyncConfig.dbPassword,
        ),
        settings: ConnectionSettings(sslMode: SslMode.disable),
      );
      _log('  ✅ Local DB connected');

      supabase = SupabaseClient(
        args.supabaseUrl,
        args.supabaseKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      _log('  ✅ Supabase connected');

      // ── Is machine ki store_id lo ─────────────
      final storeId = await _getLocalStoreId(db);
      if (storeId == null) {
        _log('  ❌ store_id nahi mila — sync cancel');
        send.send(_TableError('branch', 'Local branch/store_id nahi mila'));
        send.send('DONE');
        return;
      }
      _log('  🏪 Store ID: $storeId');

      // ── Pending cash-outs ko janghani_net_amount mein apply karo ──
      // (slow/no internet ke waqt cashOut sirf local hota hai; yahan
      //  reliably retry hota hai jab tak amount janghani na pahunche)
      await _applyPendingJanghani(db, supabase, storeId, send);

      // ── Har table sync karo ───────────────────
      for (final table in SyncConfig.tables) {
        final count = await _syncTable(db, supabase, table, storeId, send);
        _log(count > 0
            ? '  🔄 $table: $count rows synced'
            : '  ✅ $table: kuch nahi tha');
      }

      // ── App open: har table ki har row Supabase se match karo ──
      // Incremental upar ho chuka (naya data pehle pahunche); yahan
      // sirf woh purani rows jo Supabase mein hain hi nahi.
      if (args.fullCheck) {
        _log('  🔎 Full check shuru — har table match ho rahi hai');
        for (final table in SyncConfig.tables) {
          await _reconcileTable(db, supabase, table, storeId, send);
        }
      }

      send.send(_SyncComplete());
      _log('${"─" * 50}');
      _log('  ✅ Sync complete!');

    } catch (e, st) {
      _log('  ❌ Sync error: $e\n$st');
      send.send(_TableError('connection', e.toString()));
    } finally {
      await db?.close();
      supabase?.dispose();
      send.send('DONE');
    }
  }

  // ══════════════════════════════════════════════
  //  🏪 Local store_id fetch karo
  // ══════════════════════════════════════════════

  static Future<String?> _getLocalStoreId(Connection db) async {
    try {
      final result = await db.execute(
        Sql('SELECT id FROM branch LIMIT 1'),
      );
      if (result.isEmpty) return null;
      return result.first.toColumnMap()['id']?.toString();
    } catch (e) {
      _log('  ❌ store_id fetch error: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════
  //  💸 Pending branch cash-outs → janghani_net_amount.cash_in_hand
  //
  //  App ka cashOut ab sirf local hota hai (counter minus +
  //  is_synced=false row). Yahan har sync cycle mein — aur internet
  //  aate hi (internet monitor _runSync trigger karta hai) — pending
  //  rows janghani_net_amount mein add hoti hain.
  //
  //  Idempotency: row ko PEHLE claim kiya jaata hai (is_synced ko
  //  true sirf tab jab woh false ho). Jo caller woh atomic update
  //  jeet-ta hai wahi Supabase ko touch karta hai. Remote update fail
  //  ho to claim wapas false — agle cycle mein retry.
  // ══════════════════════════════════════════════
  static Future<void> _applyPendingJanghani(
      Connection     db,
      SupabaseClient supabase,
      String         storeId,
      SendPort       send,
      ) async {
    try {
      final pending = await db.execute(
        Sql.named('''
          SELECT id, pay_amount FROM branch_transaction_to_janghani
          WHERE branch_id  = @sid
            AND is_synced   = false
            AND type        = 'cash_out'
          ORDER BY created_at ASC
        '''),
        parameters: {'sid': storeId},
      );
      if (pending.isEmpty) return;

      final netList = await supabase
          .from('janghani_net_amount')
          .select('id, cash_in_hand')
          .limit(1);
      if ((netList as List).isEmpty) {
        send.send(_TableError('janghani_net_amount', 'row not found'));
        return;
      }
      final janghaniId = netList.first['id'].toString();

      int applied = 0;
      for (final row in pending) {
        final m     = row.toColumnMap();
        final rowId = m['id'].toString();
        final pay   = m['pay_amount'] is num
            ? (m['pay_amount'] as num).toDouble()
            : double.tryParse(m['pay_amount'].toString()) ?? 0.0;

        // Claim the row atomically.
        final claim = await db.execute(
          Sql.named('''
            UPDATE branch_transaction_to_janghani
            SET is_synced = true, updated_at = NOW()
            WHERE id = @id AND is_synced = false
          '''),
          parameters: {'id': rowId},
        );
        if (claim.affectedRows != 1) continue;

        if (pay <= 0) { applied++; continue; } // nothing to add, already marked

        try {
          final curList = await supabase
              .from('janghani_net_amount')
              .select('cash_in_hand')
              .eq('id', janghaniId)
              .limit(1);
          final currentCash = (curList as List).isNotEmpty
              ? (double.tryParse(
                      curList.first['cash_in_hand']?.toString() ?? '0') ??
                  0.0)
              : 0.0;

          await supabase
              .from('janghani_net_amount')
              .update({'cash_in_hand': currentCash + pay})
              .eq('id', janghaniId);

          await db.execute(
            Sql.named('''
              UPDATE branch_transaction_to_janghani
              SET assign_to_id = @jid, updated_at = NOW()
              WHERE id = @id
            '''),
            parameters: {'jid': janghaniId, 'id': rowId},
          );
          applied++;
        } catch (e) {
          // Release the claim so a later cycle retries this row.
          await db.execute(
            Sql.named('''
              UPDATE branch_transaction_to_janghani
              SET is_synced = false, updated_at = NOW()
              WHERE id = @id
            '''),
            parameters: {'id': rowId},
          );
          _log('  ⚠️  janghani apply fail ($rowId): $e');
          break; // network likely down — stop, retry next cycle
        }
      }

      if (applied > 0) {
        _log('  💸 janghani_net_amount: $applied pending cash-out(s) applied');
        send.send(_TableSuccess('janghani_net_amount', applied));
      }
    } catch (e, st) {
      _log('  ❌ janghani apply error: $e\n$st');
      send.send(_TableError('janghani_net_amount', e.toString()));
    }
  }

  // ══════════════════════════════════════════════
  //  🔄 Single Table Sync
  //
  //  Strategies:
  //  1. fullSyncTables → har cycle poora table (no branch-scoping
  //                      column mumkin nahi, ya edit-timestamp
  //                      track nahi hoti)
  //  2. filterColumn() != null → us column (store_id/id/branch_id)
  //                      se per-branch filter + timestamp
  //  3. baaki          → sirf global timestamp filter
  // ══════════════════════════════════════════════

  static Future<int> _syncTable(
      Connection     db,
      SupabaseClient supabase,
      String         table,
      String         storeId,
      SendPort       send,
      ) async {
    try {
      final tsCol       = SyncConfig.timestampColumn(table);
      final conflictCol = SyncConfig.conflictColumn(table);
      final filterCol   = SyncConfig.filterColumn(table);
      final isFullSync  = SyncConfig.fullSyncTables.contains(table);

      // ── Full sync tables: koi store_id/branch scoping column
      // nahi — timestamp watermark check hi skip, seedha poora
      // local table le lo (Step 1 & 2 dono bypass) ──────────
      if (isFullSync) {
        final result = await db.execute(
          Sql('SELECT * FROM "$table" ORDER BY "$tsCol" ASC'),
        );
        final rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
        _log('  🔁 $table — full resync: ${rows.length} rows');
        return _upsertRows(db, supabase, table, conflictCol, rows, send);
      }

      final parent = SyncConfig.parentScope(table);
      if (parent != null) {
        return _syncChildTable(
            db, supabase, table, parent.$1, parent.$2, tsCol, conflictCol,
            storeId, send);
      }

      // ── Step 1: Sirf timestamp fetch karo (min egress) ──
      String? lastSyncedAt;

      try {
        final query = filterCol != null
            ? supabase
            .from(table)
            .select(tsCol)          // sirf timestamp column
            .eq(filterCol, storeId)
            .order(tsCol, ascending: false)
            .limit(1)
            : supabase
            .from(table)
            .select(tsCol)          // sirf timestamp column
            .order(tsCol, ascending: false)
            .limit(1);

        final res = await query;

        if (res.isNotEmpty && res[0][tsCol] != null) {
          lastSyncedAt = res[0][tsCol].toString();
          _log('  📅 $table — last synced: $lastSyncedAt'
              '${filterCol != null ? " ($filterCol: $storeId)" : ""}');
        } else {
          _log('  📅 $table — Supabase mein kuch nahi, full send');
        }
      } catch (e) {
        _log('  ⚠️  $table — lastSync fetch fail: $e');
      }

      // ── Step 2: Local se sirf naye rows lo ──────────────
      final List<Map<String, dynamic>> rows;

      if (lastSyncedAt != null) {
        // Incremental — sirf timestamp ke baad wale rows
        if (filterCol != null) {
          final result = await db.execute(
            Sql.named(
              'SELECT * FROM "$table" '
                  'WHERE "$filterCol" = @sid '
                  '  AND "$tsCol" > (@ts::timestamptz - interval \'${SyncConfig.lookbackDays} days\') '
                  'ORDER BY "$tsCol" ASC',
            ),
            parameters: {'sid': storeId, 'ts': lastSyncedAt},
          );
          rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
        } else {
          final result = await db.execute(
            Sql.named(
              'SELECT * FROM "$table" '
                  'WHERE "$tsCol" > (@ts::timestamptz - interval \'${SyncConfig.lookbackDays} days\') '
                  'ORDER BY "$tsCol" ASC',
            ),
            parameters: {'ts': lastSyncedAt},
          );
          rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
        }
      } else {
        // Supabase empty tha — poora local data ek baar bhejo
        if (filterCol != null) {
          final result = await db.execute(
            Sql.named(
              'SELECT * FROM "$table" WHERE "$filterCol" = @sid ORDER BY "$tsCol" ASC',
            ),
            parameters: {'sid': storeId},
          );
          rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
        } else {
          final result = await db.execute(
            Sql('SELECT * FROM "$table" ORDER BY "$tsCol" ASC'),
          );
          rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
        }
      }

      _log('  📦 $table: ${rows.length} rows milein');
      return _upsertRows(db, supabase, table, conflictCol, rows, send);

    } catch (e, st) {
      _log('  ❌ $table sync error: $e\n$st');
      send.send(_TableError(table, e.toString()));
      return 0;
    }
  }

  // ══════════════════════════════════════════════
  //  🔗 Child Table Sync (items) — parent.store_id se scoped
  //
  //  Watermark: Supabase mein IS branch ka latest child row
  //  (parent par inner join). Local: sirf is branch ke parents
  //  ke children, watermark - lookbackDays ke baad wale.
  // ══════════════════════════════════════════════

  static Future<int> _syncChildTable(
      Connection     db,
      SupabaseClient supabase,
      String         table,
      String         parentTable,
      String         fkCol,
      String         tsCol,
      String         conflictCol,
      String         storeId,
      SendPort       send,
      ) async {
    String? lastSyncedAt;
    try {
      final res = await supabase
          .from(table)
          .select('$tsCol, $parentTable!inner(store_id)')
          .eq('$parentTable.store_id', storeId)
          .order(tsCol, ascending: false)
          .limit(1);
      if (res.isNotEmpty && res[0][tsCol] != null) {
        lastSyncedAt = res[0][tsCol].toString();
        _log('  📅 $table — last synced: $lastSyncedAt (store: $storeId)');
      } else {
        _log('  📅 $table — Supabase mein kuch nahi, full send');
      }
    } catch (e) {
      // Watermark na mile to full send — upsert idempotent hai
      _log('  ⚠️  $table — lastSync fetch fail: $e');
    }

    final result = await db.execute(
      Sql.named(
        'SELECT c.* FROM "$table" c '
            'JOIN "$parentTable" p ON p.id = c."$fkCol" '
            'WHERE p.store_id = @sid '
            '${lastSyncedAt != null ? 'AND c."$tsCol" > (@ts::timestamptz - interval \'${SyncConfig.lookbackDays} days\') ' : ''}'
            'ORDER BY c."$tsCol" ASC',
      ),
      parameters: {
        'sid': storeId,
        if (lastSyncedAt != null) 'ts': lastSyncedAt,
      },
    );
    final rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
    _log('  📦 $table: ${rows.length} rows milein');
    return _upsertRows(db, supabase, table, conflictCol, rows, send);
  }

  // ══════════════════════════════════════════════
  //  🔎 Full Check (app open par) — local vs Supabase
  //
  //  Local ki is branch ki saari ids, Supabase ki saari ids se
  //  match hoti hain; jo Supabase mein nahi, sirf woh upload.
  //  Composite conflict wali tables (id match nahi hoti) poori
  //  bheji jaati hain; fullSyncTables har cycle poori jaati hi hain.
  // ══════════════════════════════════════════════

  static Future<void> _reconcileTable(
      Connection     db,
      SupabaseClient supabase,
      String         table,
      String         storeId,
      SendPort       send,
      ) async {
    if (SyncConfig.fullSyncTables.contains(table)) return;
    try {
      final parent    = SyncConfig.parentScope(table);
      final filterCol = SyncConfig.filterColumn(table);

      // ── Local scope: sirf is branch ki rows ──────────
      final String fromWhere;
      if (parent != null) {
        fromWhere = 'FROM "$table" c '
            'JOIN "${parent.$1}" p ON p.id = c."${parent.$2}" '
            'WHERE p.store_id = @sid';
      } else if (filterCol != null) {
        fromWhere = 'FROM "$table" c WHERE c."$filterCol" = @sid';
      } else {
        fromWhere = 'FROM "$table" c WHERE @sid::text IS NOT NULL';
      }

      // ── Composite conflict: id se match mumkin nahi — poori bhejo
      if (SyncConfig.conflictColumn(table) != 'id') {
        final result = await db.execute(
          Sql.named('SELECT c.* $fromWhere'),
          parameters: {'sid': storeId},
        );
        final rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
        _log('  🔎 $table — full check: ${rows.length} rows (poori)');
        await _upsertRows(db, supabase, table,
            SyncConfig.conflictColumn(table), rows, send);
        return;
      }

      // ── Local ids ─────────────────────────────────────
      final localRes = await db.execute(
        Sql.named('SELECT c.id::text AS id $fromWhere'),
        parameters: {'sid': storeId},
      );
      final localIds = localRes
          .map((r) => r.toColumnMap()['id'].toString())
          .toSet();
      if (localIds.isEmpty) return;

      // ── Supabase ids (keyset pagination, 1000 per page) ──
      final remoteIds = <String>{};
      String? lastId;
      while (true) {
        var q = supabase.from(table).select(
            parent != null ? 'id, ${parent.$1}!inner(store_id)' : 'id');
        if (parent != null) {
          q = q.eq('${parent.$1}.store_id', storeId);
        } else if (filterCol != null) {
          q = q.eq(filterCol, storeId);
        }
        if (lastId != null) q = q.gt('id', lastId);
        final page = await q
            .order('id', ascending: true)
            .limit(1000)
            .timeout(const Duration(seconds: 60));
        if (page.isEmpty) break;
        for (final r in page) {
          remoteIds.add(r['id'].toString());
        }
        lastId = page.last['id'].toString();
        if (page.length < 1000) break;
      }

      final missing = localIds.difference(remoteIds).toList();
      if (missing.isEmpty) {
        _log('  🔎 $table — full check: sab ${localIds.length} rows maujood');
        return;
      }
      _log('  🔎 $table — full check: ${missing.length} missing rows mili');

      // ── Missing rows upload (chunks mein) ──────────────
      const chunk = 500;
      for (int i = 0; i < missing.length; i += chunk) {
        final ids = missing.sublist(i, (i + chunk).clamp(0, missing.length));
        final result = await db.execute(
          Sql.named('SELECT * FROM "$table" WHERE id = ANY(@ids::uuid[]) '
              'ORDER BY "${SyncConfig.timestampColumn(table)}" ASC'),
          parameters: {'ids': ids},
        );
        final rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
        await _upsertRows(db, supabase, table, 'id', rows, send);
      }
    } catch (e, st) {
      _log('  ❌ $table full check error: $e\n$st');
      send.send(_TableError(table, 'full check: $e'));
    }
  }

  // ══════════════════════════════════════════════
  //  🔼 Rows Upsert — Exclude columns + batch push
  // ══════════════════════════════════════════════

  static Future<int> _upsertRows(
      Connection                  db,
      SupabaseClient              supabase,
      String                      table,
      String                      conflictCol,
      List<Map<String, dynamic>> rows,
      SendPort                    send,
      ) async {
    try {
      if (rows.isEmpty) {
        send.send(_TableSuccess(table, 0));
        return 0;
      }

      // ── Exclude columns ──────────────────────────────────
      final excludeCols = SyncConfig.excludeColumns[table] ?? [];
      final supaRows = excludeCols.isEmpty
          ? rows
          : rows.map((r) {
        final m = Map<String, dynamic>.from(r);
        for (final col in excludeCols) m.remove(col);
        return m;
      }).toList();

      // ── Upsert Supabase mein ─────────────────────────────
      const batchSize = 50;
      int totalSynced = 0;
      int failedRows  = 0;
      String? lastRowErr;
      final List<String> syncedIds = [];

      // Slow internet: har request par timeout + retry (backoff ke sath)
      Future<void> upsertRetry(Object payload) async {
        const maxAttempts = 3;
        for (int attempt = 1; ; attempt++) {
          try {
            await supabase
                .from(table)
                .upsert(payload, onConflict: conflictCol)
                .timeout(const Duration(seconds: 60));
            return;
          } catch (e) {
            // Schema/constraint errors (PostgrestException) retry se theek
            // nahi hote — sirf network/timeout errors retry karo.
            final isNetwork = e is TimeoutException || e is SocketException ||
                e is HttpException || e is IOException;
            if (!isNetwork || attempt >= maxAttempts) rethrow;
            _log('  ⏳ $table retry $attempt/$maxAttempts: $e');
            await Future.delayed(Duration(seconds: 2 * attempt));
          }
        }
      }

      for (int i = 0; i < supaRows.length; i += batchSize) {
        final batch = supaRows.sublist(
          i,
          (i + batchSize).clamp(0, supaRows.length),
        );
        try {
          await upsertRetry(batch);
          totalSynced += batch.length;
          if (table == 'accountant_transactions') {
            syncedIds.addAll(batch.map((r) => r['id'].toString()));
          }
        } catch (batchErr) {
          _log('  ⚠️  $table batch fail — row-by-row: $batchErr');
          for (final row in batch) {
            try {
              await upsertRetry(row);
              totalSynced++;
              if (table == 'accountant_transactions') {
                syncedIds.add(row['id'].toString());
              }
            } catch (rowErr) {
              failedRows++;
              lastRowErr = rowErr.toString();
              _log('  ❌ $table row skip: $rowErr\n     Row: $row');
            }
          }
        }
      }

      if (failedRows > 0) {
        send.send(_TableError(
            table, '$failedRows row(s) sync nahi hui: $lastRowErr'));
      }

      // ── accountant_transactions is_synced ────────────────
      if (table == 'accountant_transactions' && syncedIds.isNotEmpty) {
        final idList = syncedIds.map((id) => "'$id'").join(',');
        await db.execute(
          Sql('UPDATE accountant_transactions '
              'SET is_synced = true WHERE id IN ($idList)'),
        );
        _log('  ✅ accountant_transactions: ${syncedIds.length} is_synced=true');
      }

      if (failedRows == 0) send.send(_TableSuccess(table, totalSynced));
      return totalSynced;

    } catch (e, st) {
      _log('  ❌ $table upsert error: $e\n$st');
      send.send(_TableError(table, e.toString()));
      return 0;
    }
  }

  // ══════════════════════════════════════════════
  //  Row Convert — Dart types → JSON safe
  // ══════════════════════════════════════════════

  static Map<String, dynamic> _toJsonRow(Map<String, dynamic> row) {
    return row.map((key, value) {
      if (value == null)   return MapEntry(key, null);
      if (value is DateTime) return MapEntry(key, value.toUtc().toIso8601String());
      if (value is int)    return MapEntry(key, value);
      if (value is double) return MapEntry(key, value);
      if (value is bool)   return MapEntry(key, value);
      if (value is String) return MapEntry(key, value);
      if (value is List)   return MapEntry(key, value);
      if (value is Map)    return MapEntry(key, value);
      return MapEntry(key, value.toString());
    });
  }
}