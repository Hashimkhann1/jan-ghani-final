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

  // ── Supabase ──────────────────────────────────────────────
  static const String supabaseUrl = 'https://kjjtqfruxhjcxwvxwffz.supabase.co';
  static const String supabaseKey = 'sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS';

  // ── Sync interval (seconds) ───────────────────────────────
  static const int syncIntervalSeconds = 120;

  // ── Tables — dependency order mein (parent pehle) ────────
  static const List<String> tables = [
    'branch',
    'branch_counter',
    'customer',
    'branch_stock_inventory',
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
    "branch_transaction_to_janghani",
  ];

  // ── Har table ka timestamp column ────────────────────────
  static const Map<String, String> _timestampColumns = {
    'sale_invoice_items'    : 'created_at',
    'sale_invoice_payments' : 'created_at',
    'sale_return_items'     : 'created_at',
    'sale_return_payments'  : 'created_at',
  };

  // ── Har table ka conflict (primary key) column ────────────
  static const Map<String, String> _conflictColumns = {
    'branch_summary': 'store_id,counter_date',
  };

  // ── Yeh columns Supabase mein nahi hain — upsert se remove honge
  static const Map<String, List<String>> excludeColumns = {
    'accountant_transactions': ['is_synced'],
  };

  static String timestampColumn(String table) =>
      _timestampColumns[table] ?? 'updated_at';

  static String conflictColumn(String table) =>
      _conflictColumns[table] ?? 'id';
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

  const _IsolateArgs({
    required this.sendPort,
    required this.supabaseUrl,
    required this.supabaseKey,
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

  SyncStatus _status = const SyncStatus();
  SyncStatus get currentStatus => _status;

  final _statusCtrl = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusCtrl.stream;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _log('🏪 Store Sync Service — Start');
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
    _internetTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
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
        ),
        errorsAreFatal: false,
        debugName: 'SyncIsolate',
      );
      await for (final msg in _receivePort!) {
        if (msg is _IsolateMsg) _handleMsg(msg);
        if (msg == 'DONE') break;
      }
    } catch (e) {
      _log('❌ Isolate error: $e');
      _emit(_status.copyWith(isSyncing: false, lastError: e.toString()));
    } finally {
      _receivePort?.close();
      _receivePort = null;
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

      // ── Har table sync karo ───────────────────
      for (final table in SyncConfig.tables) {
        final count = await _syncTable(db, supabase, table, send);
        _log(count > 0
            ? '  🔄 $table: $count rows synced'
            : '  ✅ $table: kuch nahi tha');
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
  //  🔄 Single Table Sync — Seedha upsert
  //  Koi RPC nahi, koi special case nahi
  //  Sare triggers delete ho chuke hain
  // ══════════════════════════════════════════════

  static Future<int> _syncTable(
      Connection     db,
      SupabaseClient supabase,
      String         table,
      SendPort       send,
      ) async {
    try {
      final tsCol       = SyncConfig.timestampColumn(table);
      final conflictCol = SyncConfig.conflictColumn(table);

      // ── Step 1: Supabase mein last timestamp lo ─
      String? lastSyncedAt;
      try {
        final res = await supabase
            .from(table)
            .select(tsCol)
            .order(tsCol, ascending: false)
            .limit(1);

        if (res.isNotEmpty && res[0][tsCol] != null) {
          lastSyncedAt = res[0][tsCol].toString();
          _log('  📅 $table — last synced: $lastSyncedAt');
        } else {
          _log('  📅 $table — Supabase empty, full sync');
        }
      } catch (e) {
        _log('  ⚠️  $table — lastSync fetch fail: $e');
      }

      // ── Step 2: Local se naye rows lo ──────────
      final List<Map<String, dynamic>> rows;

      if (lastSyncedAt != null) {
        final result = await db.execute(
          Sql.named(
            'SELECT * FROM "$table" '
                'WHERE "$tsCol" > @ts::timestamptz '
                'ORDER BY "$tsCol" ASC',
          ),
          parameters: {'ts': lastSyncedAt},
        );
        rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
      } else {
        final result = await db.execute(
          Sql('SELECT * FROM "$table" ORDER BY "$tsCol" ASC'),
        );
        rows = result.map((r) => _toJsonRow(r.toColumnMap())).toList();
      }

      _log('  📦 $table: ${rows.length} rows milein');
      if (rows.isEmpty) {
        send.send(_TableSuccess(table, 0));
        return 0;
      }

      // ── Step 3: Exclude columns ─────────────────
      final excludeCols = SyncConfig.excludeColumns[table] ?? [];
      final supaRows = excludeCols.isEmpty
          ? rows
          : rows.map((r) {
        final m = Map<String, dynamic>.from(r);
        for (final col in excludeCols) m.remove(col);
        return m;
      }).toList();

      // ── Step 4: Seedha upsert — koi trigger nahi ─
      const batchSize = 50;
      int totalSynced = 0;
      final List<String> syncedIds = [];

      for (int i = 0; i < supaRows.length; i += batchSize) {
        final batch = supaRows.sublist(
          i,
          (i + batchSize).clamp(0, supaRows.length),
        );
        try {
          await supabase.from(table).upsert(batch, onConflict: conflictCol);
          totalSynced += batch.length;
          if (table == 'accountant_transactions') {
            syncedIds.addAll(batch.map((r) => r['id'].toString()));
          }
        } catch (batchErr) {
          _log('  ⚠️  $table batch fail — row-by-row: $batchErr');
          for (final row in batch) {
            try {
              await supabase.from(table).upsert(row, onConflict: conflictCol);
              totalSynced++;
              if (table == 'accountant_transactions') {
                syncedIds.add(row['id'].toString());
              }
            } catch (rowErr) {
              _log('  ❌ $table row skip: $rowErr\n     Row: $row');
            }
          }
        }
      }

      // ── Step 5: accountant_transactions is_synced ─
      if (table == 'accountant_transactions' && syncedIds.isNotEmpty) {
        final idList = syncedIds.map((id) => "'$id'").join(',');
        await db.execute(
          Sql('UPDATE accountant_transactions '
              'SET is_synced = true WHERE id IN ($idList)'),
        );
        _log('  ✅ accountant_transactions: ${syncedIds.length} is_synced=true');
      }

      send.send(_TableSuccess(table, totalSynced));
      return totalSynced;

    } catch (e, st) {
      _log('  ❌ $table sync error: $e\n$st');
      send.send(_TableError(table, e.toString()));
      return 0;
    }
  }

  // ══════════════════════════════════════════════
  //  Row Convert — Dart types → JSON safe
  // ══════════════════════════════════════════════

  static Map<String, dynamic> _toJsonRow(Map<String, dynamic> row) {
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
}