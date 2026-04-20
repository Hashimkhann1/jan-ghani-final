import 'dart:async';
import 'dart:isolate';
import 'package:postgres/postgres.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


class SyncConfig {
  // ── Local PostgreSQL ──────────────────────────────
  static const String dbHost     = 'localhost';
  static const int    dbPort     = 5432;
  static const String dbName     = 'store_db';
  static const String dbUser     = 'storeuser';
  static const String dbPassword = 'branchUser12C3';

  static const String supabaseUrl = 'https://wwngqwvshtgbkfxdqpmt.supabase.co';
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtqanRxZnJ1eGhqY3h3dnh3ZmZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzMTU1NzAsImV4cCI6MjA5MTg5MTU3MH0.qrX7xIQAEVP3Vp6E6aBxL0a18W3VF0p54YL8IHZQpZ0';

  static const int syncIntervalSeconds = 30;

  static const List<String> tables = [
    'branch',
    'branch_users',
    'customer',
    'branch_counter',
    'branch_cash_counter',
    'branch_cash_transaction',
    'customer_ledger',
    'branch_expense',
    'sale_invoices',
    'sale_invoice_items',
    'sale_invoice_payments',
    'sale_returns',
    'sale_return_payments',
    'sale_return_items',
    'branch_summary',
    'branch_stock_inventory',
  ];

  static const Map<String, String> timestampColumns = {
    'sale_invoice_items': 'created_at',
  };

  static String getTimestampColumn(String table) =>
      timestampColumns[table] ?? 'updated_at';
}

// ─────────────────────────────────────────────────
//  SYNC STATUS MODEL
// ─────────────────────────────────────────────────
class SyncStatus {
  final bool isSyncing;
  final bool hasInternet;
  final DateTime? lastSyncTime;
  final int totalSynced;
  final String? lastError;
  final Map<String, String> tableStatus;

  SyncStatus({
    this.isSyncing   = false,
    this.hasInternet = false,
    this.lastSyncTime,
    this.totalSynced = 0,
    this.lastError,
    this.tableStatus = const {},
  });

  SyncStatus copyWith({
    bool? isSyncing,
    bool? hasInternet,
    DateTime? lastSyncTime,
    int? totalSynced,
    String? lastError,
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
//  ISOLATE ARGS — sendPort + config ek saath pass
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

  Isolate?      _isolate;
  ReceivePort?  _receivePort;
  Timer?        _syncTimer;
  bool          _isRunning = false;

  final StreamController<SyncStatus> _statusController =
  StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get statusStream  => _statusController.stream;
  SyncStatus _currentStatus = SyncStatus();
  SyncStatus get currentStatus         => _currentStatus;

  // ── Start ─────────────────────────────────────
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

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
    _isolate?.kill();
    _isRunning = false;
    print('🛑 Sync service band ho gayi');
  }

  // ── Internet Monitor ──────────────────────────
  void _monitorInternet() {
    Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      _updateStatus(_currentStatus.copyWith(hasInternet: hasNet));
      if (hasNet) {
        print('🌐 Internet aa gaya — Sync shuru...');
        _runSync();
      } else {
        print('📵 Internet chala gaya');
      }
    });
  }

  // ── Run Sync ──────────────────────────────────
  Future<void> _runSync() async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasNet = connectivity.any((r) => r != ConnectivityResult.none);

    if (!hasNet) {
      print('📵 Internet nahi — sync skip');
      _updateStatus(_currentStatus.copyWith(hasInternet: false));
      return;
    }

    _updateStatus(_currentStatus.copyWith(isSyncing: true, hasInternet: true));

    _receivePort = ReceivePort();

    try {
      // ✅ URL + Key isolate ko args mein pass karo
      _isolate = await Isolate.spawn(
        _syncIsolate,
        _IsolateArgs(
          sendPort:    _receivePort!.sendPort,
          supabaseUrl: SyncConfig.supabaseUrl,
          supabaseKey: SyncConfig.supabaseKey,
        ),
        debugName: 'StoreSyncIsolate',
      );

      await for (final message in _receivePort!) {
        if (message is Map<String, dynamic>) {
          _handleIsolateMessage(message);
        }
        if (message == 'DONE') {
          _receivePort!.close();
          break;
        }
      }
    } catch (e) {
      print('❌ Isolate error: $e');
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
        newMap[table] = 'ok';
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
          lastError:   error,
        ));
        break;

      case 'sync_complete':
        _updateStatus(_currentStatus.copyWith(
          isSyncing:    false,
          lastSyncTime: DateTime.now(),
        ));
        break;
    }
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  // ═══════════════════════════════════════════════
  //  🏭 ISOLATE — Background Thread
  // ═══════════════════════════════════════════════
  static Future<void> _syncIsolate(_IsolateArgs args) async {
    final sendPort = args.sendPort;
    final now      = DateTime.now();

    print('\n${'═' * 50}');
    print('  🕐 Sync: ${now.hour}:${now.minute}:${now.second}');
    print('${'═' * 50}');

    Connection?     localConn;
    SupabaseClient? supabase;

    try {
      // ── Local PostgreSQL ──────────────────────
      localConn = await Connection.open(
        Endpoint(
          host:     SyncConfig.dbHost,
          port:     SyncConfig.dbPort,
          database: SyncConfig.dbName,
          username: SyncConfig.dbUser,
          password: SyncConfig.dbPassword,
        ),
        settings: ConnectionSettings(sslMode: SslMode.disable),
      );

      // ✅ Direct SupabaseClient — NO initialize(), NO Flutter binding
      supabase = SupabaseClient(args.supabaseUrl, args.supabaseKey);

      // ── Tables Sync ───────────────────────────
      for (final table in SyncConfig.tables) {
        final count = await _syncTable(localConn, supabase, table, sendPort);
        print(count > 0
            ? '   🔄 $table: $count records sync hue!'
            : '   ✅ $table: Sab sync hai');
      }

      sendPort.send({'type': 'sync_complete'});
      print('${'─' * 50}');
      print('  ✅ Sync Complete!');

    } catch (e) {
      print('  ❌ Connection Error: $e');
      sendPort.send({
        'type':  'table_error',
        'table': 'connection',
        'error': e.toString(),
      });
    } finally {
      await localConn?.close();
      supabase?.dispose(); // ✅ cleanup
    }

    sendPort.send('DONE');
  }

  // ─────────────────────────────────────────────
  //  🔄 Single Table Sync
  // ─────────────────────────────────────────────
  static Future<int> _syncTable(
      Connection     localConn,
      SupabaseClient supabase,
      String         tableName,
      SendPort       sendPort,
      ) async {
    try {
      final tsCol = SyncConfig.getTimestampColumn(tableName);

      // Supabase mein last record ka timestamp lo
      String? lastSync;
      try {
        final result = await supabase
            .from(tableName)
            .select(tsCol)
            .order(tsCol, ascending: false)
            .limit(1);

        if (result.isNotEmpty && result[0][tsCol] != null) {
          lastSync = result[0][tsCol].toString();
        }
      } catch (_) {
        lastSync = null;
      }

      // Local se naye records lo
      List<Map<String, dynamic>> rows;

      if (lastSync != null) {
        final result = await localConn.execute(
          Sql.named(
            'SELECT * FROM "$tableName" WHERE "$tsCol" > @lastSync ORDER BY "$tsCol" ASC',
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

      if (rows.isEmpty) return 0;

      // Batch upsert
      const batchSize = 50;
      int total = 0;

      for (int i = 0; i < rows.length; i += batchSize) {
        final batch = rows.sublist(
          i,
          (i + batchSize) > rows.length ? rows.length : i + batchSize,
        );
        await supabase.from(tableName).upsert(batch, onConflict: 'id');
        total += batch.length;
      }

      sendPort.send({'type': 'table_success', 'table': tableName, 'count': total});
      return total;

    } catch (e) {
      sendPort.send({'type': 'table_error', 'table': tableName, 'error': e.toString()});
      return 0;
    }
  }

  // ─────────────────────────────────────────────
  //  🔧 Row Convert
  // ─────────────────────────────────────────────
  static Map<String, dynamic> _convertRow(Map<String, dynamic> row) {
    return row.map((key, value) {
      if (value is DateTime) return MapEntry(key, value.toIso8601String());
      if (value == null)     return MapEntry(key, null);
      return MapEntry(key, value.toString() == value ? value : value.toString());
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