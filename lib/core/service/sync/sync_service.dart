import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:postgres/postgres.dart';
import 'package:supabase/supabase.dart';

// ─────────────────────────────────────────────────
//  CONFIG
// ─────────────────────────────────────────────────
class SyncConfig {
  // ── Local PostgreSQL ──────────────────────────────
  static const String dbHost     = '127.0.0.1';
  static const int    dbPort     = 5432;
  static const String dbName     = 'store_db';
  static const String dbUser     = 'storeuser';
  static const String dbPassword = 'shahab';
  // static const String dbPassword = 'branchUser12C3';

  // ── Supabase ──────────────────────────────────────
  // static const String supabaseUrl = '';
  static const String supabaseUrl = 'https://kjjtqfruxhjcxwvxwffz.supabase.co';
  // static const String supabaseKey = '';
  static const String supabaseKey = 'sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS';

  static const int syncIntervalSeconds = 120;

  static const List<String> tables = [
    // ── Layer 1: Root ─────────────────────────────────────────
    'branch',                   // 1. koi dependency nahi

    // ── Layer 2: Sirf branch per depend ──────────────────────
    'branch_counter',           // 2. branch → counter
    'customer',                 // 3. branch → customer
    'branch_stock_inventory',   // 4. branch → stock inventory
    'branch_expense',           // 5. branch → expense

    // ── Layer 3: branch + branch_counter per depend ───────────
    'branch_users',             // 6. branch + branch_counter → users
    'branch_cash_counter',      // 7. branch + branch_counter → cash counter

    // ── Layer 4: Layer 3 per depend ──────────────────────────
    'branch_cash_transaction',  // 8.  branch_cash_counter → transaction
    'branch_stock_damage',      // 9.  branch_stock_inventory → damage
    'sale_invoices',            // 10. branch + branch_counter + branch_users + customer

    // ── Layer 5: sale_invoices per depend ────────────────────
    'sale_invoice_items',       // 11. sale_invoices → items
    'sale_invoice_payments',    // 12. sale_invoices → payments  (trigger: cash/card/credit counter update)
    'sale_returns',             // 13. sale_invoices + branch_users + customer

    // ── Layer 6: Layer 5 per depend ──────────────────────────
    'sale_return_items',        // 14. sale_returns + sale_invoice_items → return items
    'sale_return_payments',     // 15. sale_returns → return payments
    'customer_ledger',          // 16. customer + branch_counter  (trigger: balance update)

    // ── Layer 7: Sab complete hone ke baad ───────────────────
    'accountant_counter',       // 18. ⚠️ missing tha — accountant balance tracker
    'accountant_transactions',  // 19. branch + accountant_counter → transactions
    'branch_summary',           // 20. sabse akhir — sab tables ka summary
  ];

  static const Map<String, String> timestampColumns = {
    'sale_invoice_items'    : 'created_at',
    'sale_invoice_payments' : 'created_at',
    'sale_return_payments'  : 'created_at',
    'sale_return_items'     : 'created_at',
  };

  static String getTimestampColumn(String table) => timestampColumns[table] ?? 'updated_at';

  // ✅ FIX 1: branch_summary ka conflict column (store_id, counter_date) hai
  static const Map<String, String> conflictColumns = {
    'branch_summary': 'store_id,counter_date',
  };

  static String getConflictColumn(String table) => conflictColumns[table] ?? 'id';

  // ✅ FIX 2: Yeh columns Supabase mein nahi hain — upsert se pehle remove honge
  static const Map<String, List<String>> excludeColumns = {
    'accountant_transactions': ['is_synced'],
  };
}

// ─────────────────────────────────────────────────
//  SYNC STATUS MODEL
// ─────────────────────────────────────────────────
class SyncStatus {
  final bool                isSyncing;
  final bool                hasInternet;
  final DateTime?           lastSyncTime;
  final int                 totalSynced;
  final String?             lastError;
  final Map<String, String> tableStatus;

  SyncStatus({
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
        lastError:    lastError    ?? this.lastError,
        tableStatus:  tableStatus  ?? this.tableStatus,
      );
}

// ─────────────────────────────────────────────────
//  ISOLATE ARGS
// ─────────────────────────────────────────────────
class _IsolateArgs {
  final SendPort sendPort;
  final String   supabaseUrl;
  final String   supabaseKey;

  const _IsolateArgs({
    required this.sendPort,
    required this.supabaseUrl,
    required this.supabaseKey,
  });
}

// ─────────────────────────────────────────────────
//  MAIN SYNC SERVICE
// ─────────────────────────────────────────────────
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Isolate?     _isolate;
  ReceivePort? _receivePort;
  Timer?       _syncTimer;
  Timer?       _monitorTimer;
  bool         _isRunning = false;

  final StreamController<SyncStatus> _statusController =
  StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus _currentStatus = SyncStatus();
  SyncStatus get currentStatus => _currentStatus;

  // ── Start ─────────────────────────────────────
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    final errorPort = RawReceivePort((pair) {
      final error = (pair as List)[0];
      final stack = (pair as List)[1];
      print('🔴 Isolate uncaught error: $error');
      print('🔴 Stack: $stack');
      _updateStatus(_currentStatus.copyWith(
        isSyncing: false,
        lastError: error.toString(),
      ));
    });
    Isolate.current.addErrorListener(errorPort.sendPort);

    print('╔══════════════════════════════════════╗');
    print('║   🏪 Store DB Sync Service Start      ║');
    print('╚══════════════════════════════════════╝');

    _monitorInternet();
    await _runSync();

    _syncTimer = Timer.periodic(
      Duration(seconds: SyncConfig.syncIntervalSeconds),
          (_) => _runSync(),
    );
  }

  // ── Stop ──────────────────────────────────────
  void stop() {
    _syncTimer?.cancel();
    _monitorTimer?.cancel();
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _isolate     = null;
    _receivePort = null;
    _isRunning   = false;
    print('🛑 Sync service band ho gayi');
  }

  // ── Internet Check ────────────────────────────
  static Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('supabase.co')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Internet Monitor (polling every 15s) ──────
  void _monitorInternet() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      final hasNet = await _hasInternet();
      final wasNet = _currentStatus.hasInternet;

      _updateStatus(_currentStatus.copyWith(hasInternet: hasNet));

      if (hasNet && !wasNet) {
        print('🌐 Internet aa gaya — Sync shuru...');
        _runSync();
      } else if (!hasNet && wasNet) {
        print('📵 Internet chala gaya');
      }
    });
  }

  // ── Run Sync ──────────────────────────────────
  Future<void> _runSync() async {
    if (_currentStatus.isSyncing) {
      print('⏳ Sync pehle se chal rahi hai — skip');
      return;
    }

    final hasNet = await _hasInternet();

    if (!hasNet) {
      print('📵 Internet nahi — sync skip');
      _updateStatus(_currentStatus.copyWith(hasInternet: false));
      return;
    }

    _updateStatus(_currentStatus.copyWith(
      isSyncing:   true,
      hasInternet: true,
    ));

    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _receivePort = ReceivePort();

    try {
      _isolate = await Isolate.spawn(
        _syncIsolate,
        _IsolateArgs(
          sendPort:    _receivePort!.sendPort,
          supabaseUrl: SyncConfig.supabaseUrl,
          supabaseKey: SyncConfig.supabaseKey,
        ),
        errorsAreFatal: false,
        debugName: 'StoreSyncIsolate',
      );

      await for (final message in _receivePort!) {
        if (message is Map<String, dynamic>) {
          _handleIsolateMessage(message);
        }
        if (message == 'DONE') {
          _receivePort!.close();
          _receivePort = null;
          break;
        }
      }
    } catch (e) {
      print('❌ Isolate spawn error: $e');
      _updateStatus(_currentStatus.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      ));
    }
  }

  // ── Handle Messages ───────────────────────────
  void _handleIsolateMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String;
    switch (type) {
      case 'table_success':
        final table  = msg['table'] as String;
        final count  = msg['count'] as int;
        final newMap = Map<String, String>.from(_currentStatus.tableStatus);
        newMap[table] = 'ok ($count)';
        _updateStatus(_currentStatus.copyWith(
          tableStatus: newMap,
          totalSynced: _currentStatus.totalSynced + count,
        ));
        break;

      case 'table_error':
        final table  = msg['table'] as String;
        final error  = msg['error'] as String;
        final newMap = Map<String, String>.from(_currentStatus.tableStatus);
        newMap[table] = 'error';
        _updateStatus(_currentStatus.copyWith(
          tableStatus: newMap,
          lastError:   '[$table] $error',
        ));
        break;

      case 'sync_complete':
        _updateStatus(_currentStatus.copyWith(
          isSyncing:    false,
          lastSyncTime: DateTime.now(),
          lastError:    null,
        ));
        break;
    }
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  static Future<void> _recalculateCustomerBalances(
      SupabaseClient supabase,
      SendPort sendPort,
      ) async {
    try {
      print('  🔄 Customer balances recalculate ho rahe hain...');
      await supabase.rpc('recalculate_all_customer_balances');
      print('  ✅ Customer balances correct ho gaye');
    } catch (e) {
      print('  ⚠️  Balance recalculate failed: $e');
      sendPort.send({
        'type': 'table_error',
        'table': 'balance_recalculate',
        'error': e.toString(),
      });
    }
  }

  // ═══════════════════════════════════════════════
  //  🏭 ISOLATE — Background Thread
  // ═══════════════════════════════════════════════
  static Future<void> _syncIsolate(_IsolateArgs args) async {
    final sendPort = args.sendPort;
    final now      = DateTime.now();

    print('\n${"═" * 50}');
    print('  🕐 Sync shuru: ${now.hour}:${now.minute.toString().padLeft(2, "0")}:${now.second.toString().padLeft(2, "0")}');
    print('${"═" * 50}');

    Connection?     localConn;
    SupabaseClient? supabase;

    try {
      print('  🔌 Local PostgreSQL se connect ho raha hai...');
      localConn = await Connection.open(
        Endpoint(
          host:     '127.0.0.1',
          port:     SyncConfig.dbPort,
          database: SyncConfig.dbName,
          username: SyncConfig.dbUser,
          password: SyncConfig.dbPassword,
        ),
        settings: ConnectionSettings(sslMode: SslMode.disable),
      );
      print('  ✅ Local DB connected');

      print('  🔌 Supabase se connect ho raha hai...');
      supabase = SupabaseClient(
        args.supabaseUrl,
        args.supabaseKey,
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
        ),
      );
      print('  ✅ Supabase client ready');

      for (final table in SyncConfig.tables) {
        final count = await _syncTable(localConn, supabase, table, sendPort);
        print(count > 0
            ? '   🔄 $table: $count records sync hue!'
            : '   ✅ $table: Sab sync hai');
      }

      await _recalculateCustomerBalances(supabase, sendPort);

      sendPort.send({'type': 'sync_complete'});
      print('${"─" * 50}');
      print('  ✅ Sync Complete!');
      print('${"═" * 50}\n');

    } catch (e, stack) {
      print('  ❌ Connection/Sync Error: $e');
      print('  Stack: $stack');
      sendPort.send({
        'type':  'table_error',
        'table': 'connection',
        'error': e.toString(),
      });
    } finally {
      await localConn?.close();
      supabase?.dispose();
      sendPort.send('DONE');
    }
  }



  // ─────────────────────────────────────────────
  //  🔄 Single Table Sync
  // ─────────────────────────────────────────────

  // ─────────────────────────────────────────
//  🔄 Single Table Sync
// ─────────────────────────────────────────

  static Future<int> _syncTable(
      Connection     localConn,
      SupabaseClient supabase,
      String         tableName,
      SendPort       sendPort,
      ) async {
    try {
      final tsCol       = SyncConfig.getTimestampColumn(tableName);
      final conflictCol = SyncConfig.getConflictColumn(tableName);

      // ── Tables jo hamesha full sync karengi ───
      const forceFullSyncTables = [
        'sale_invoices',
        'sale_invoice_items',
        'sale_invoice_payments',
      ];

      // ── Supabase mein last timestamp lo ───────
      String? lastSync;

      if (forceFullSyncTables.contains(tableName)) {
        print('   🔄 $tableName — forced full sync (trigger-safe mode)');
      } else {
        try {
          final result = await supabase
              .from(tableName)
              .select(tsCol)
              .order(tsCol, ascending: false)
              .limit(1);

          if (result.isNotEmpty && result[0][tsCol] != null) {
            lastSync = result[0][tsCol].toString();
            print('   📅 $tableName — last sync: $lastSync');
          } else {
            print('   📅 $tableName — Supabase empty, full sync karega');
          }
        } catch (e) {
          print('   ⚠️  $tableName lastSync fetch failed: $e');
          lastSync = null;
        }
      }

      // ── Local se rows lo ──────────────────────
      List<Map<String, dynamic>> rows;

      if (lastSync != null) {
        final result = await localConn.execute(
          Sql.named(
            'SELECT * FROM "$tableName" '
                'WHERE "$tsCol" > @lastSync::timestamptz '
                'ORDER BY "$tsCol" ASC',
          ),
          parameters: {'lastSync': lastSync},
        );
        rows = result.map((r) => _convertRow(r.toColumnMap())).toList();
      } else {
        final result = await localConn.execute(
          Sql('SELECT * FROM "$tableName" ORDER BY "$tsCol" ASC'),
        );
        rows = result.map((r) => _convertRow(r.toColumnMap())).toList();
      }

      print('   📦 $tableName: ${rows.length} rows local se mile');

      if (rows.isEmpty) return 0;

      // ── Exclude columns ───────────────────────
      final excludeCols = SyncConfig.excludeColumns[tableName] ?? [];
      List<Map<String, dynamic>> supabaseRows = rows;
      if (excludeCols.isNotEmpty) {
        supabaseRows = rows.map((r) {
          final map = Map<String, dynamic>.from(r);
          for (final col in excludeCols) {
            map.remove(col);
          }
          return map;
        }).toList();
      }

      // ── Batch upsert ──────────────────────────
      const batchSize = 50;
      int total       = 0;
      final List<String> syncedIds = [];

      for (int i = 0; i < supabaseRows.length; i += batchSize) {
        final end   = (i + batchSize) > supabaseRows.length
            ? supabaseRows.length
            : i + batchSize;
        final batch = supabaseRows.sublist(i, end);

        try {
          await supabase
              .from(tableName)
              .upsert(batch, onConflict: conflictCol);
          total += batch.length;

          if (tableName == 'accountant_transactions') {
            syncedIds.addAll(batch.map((r) => r['id'].toString()));
          }

        } catch (batchErr) {
          print('   ⚠️  $tableName batch fail, row-by-row try: $batchErr');
          for (final row in batch) {
            try {
              await supabase
                  .from(tableName)
                  .upsert(row, onConflict: conflictCol);
              total++;

              if (tableName == 'accountant_transactions') {
                syncedIds.add(row['id'].toString());
              }
            } catch (rowErr) {
              print('   ❌ $tableName row skip: $rowErr');
              print('      Row: $row');
            }
          }
        }
      }

      // ── accountant_transactions is_synced update ──
      if (tableName == 'accountant_transactions' && syncedIds.isNotEmpty) {
        final ids = syncedIds.map((id) => "'$id'").join(',');
        await localConn.execute(
          Sql('UPDATE public.accountant_transactions '
              'SET is_synced = true '
              'WHERE id IN ($ids)'),
        );
        print('   ✅ accountant_transactions: ${syncedIds.length} records is_synced = true');
      }

      sendPort.send({
        'type':  'table_success',
        'table': tableName,
        'count': total,
      });
      return total;

    } catch (e, stack) {
      print('   ❌ $tableName sync error: $e');
      print('      Stack: $stack');
      sendPort.send({
        'type':  'table_error',
        'table': tableName,
        'error': e.toString(),
      });
      return 0;
    }
  }

  // ─────────────────────────────────────────────
  //  🔧 Row Convert — Type-safe
  // ─────────────────────────────────────────────
  static Map<String, dynamic> _convertRow(Map<String, dynamic> row) {
    return row.map((key, value) {
      if (value == null)     return MapEntry(key, null);
      if (value is DateTime) return MapEntry(key, value.toUtc().toIso8601String());
      if (value is int)      return MapEntry(key, value);
      if (value is double)   return MapEntry(key, value);
      if (value is bool)     return MapEntry(key, value);
      if (value is String)   return MapEntry(key, value);
      if (value is List)     return MapEntry(key, value);
      if (value is Map)      return MapEntry(key, value);
      return MapEntry(key, value.toString());
    });
  }

  // ─────────────────────────────────────────────
  //  🔁 Manual Sync
  // ─────────────────────────────────────────────
  Future<void> syncNow() async {
    print('🔁 Manual sync shuru...');
    await _runSync();
  }

  void dispose() {
    stop();
    _statusController.close();
  }
}