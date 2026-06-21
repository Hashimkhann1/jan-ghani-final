import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/backup_progress_model.dart';
import '../model/branch_backup_model.dart';

class BackupDatasource {
  final SupabaseClient _supabase;

  BackupDatasource(this._supabase);

  // ── Branches fetch (Supabase se) ──────────────────────────────────────────
  Future<List<BackupBranchModel>> fetchBranches() async {
    final res = await _supabase
        .from('branch')
        .select('id, code, name, address, phone, is_active, created_at')
        .eq('is_active', true)
        .isFilter('deleted_at', null)
        .order('name', ascending: true);
    return (res as List)
        .map((e) => BackupBranchModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ── Main Backup Stream ─────────────────────────────────────────────────────
  Stream<BackupProgress> performBackup({required String branchId}) async* {
    final tables = _getTableConfigs(branchId);
    final totalTables = tables.length;
    final results = <TableBackupResult>[];
    var completed = 0;

    yield BackupProgress(
      totalTables: totalTables,
      completedTables: 0,
      currentTable: 'Local database se connect ho raha hai...',
      results: [],
    );

    late Connection localDb;
    try {
      localDb = await DataBaseService.getConnection();
    } catch (e) {
      yield BackupProgress(
        totalTables: totalTables,
        completedTables: 0,
        currentTable: 'Connection fail!',
        results: [
          TableBackupResult(
            tableName: 'PostgreSQL Connection',
            rowsFetched: 0,
            rowsUpserted: 0,
            success: false,
            error: e.toString(),
          ),
        ],
      );
      return;
    }

    // ── Local schema cache karo ──────────────────────────────────────────────
    yield BackupProgress(
      totalTables: totalTables,
      completedTables: 0,
      currentTable: 'Local schema load ho raha hai...',
      results: [],
    );
    for (final config in tables) {
      await _getLocalColumns(localDb, config.tableName);
    }

    // ── Triggers disable karo ────────────────────────────────────────────────
    yield BackupProgress(
      totalTables: totalTables,
      completedTables: 0,
      currentTable: 'Triggers disable ho rahe hain...',
      results: [],
    );
    await _setTriggers(localDb, enable: false);

    try {
      for (final config in tables) {
        yield BackupProgress(
          totalTables: totalTables,
          completedTables: completed,
          currentTable: '${config.displayName} backup ho raha hai...',
          results: List.from(results),
        );

        final result = await _backupTable(
          localDb: localDb,
          config: config,
          branchId: branchId,
        );

        results.add(result);
        completed++;

        yield BackupProgress(
          totalTables: totalTables,
          completedTables: completed,
          currentTable:
          completed == totalTables ? 'Mukammal!' : config.displayName,
          results: List.from(results),
        );
      }
    } finally {
      await _setTriggers(localDb, enable: true);
    }
  }

  // ── Single table backup ────────────────────────────────────────────────────
  Future<TableBackupResult> _backupTable({
    required Connection localDb,
    required _TableConfig config,
    required String branchId,
  }) async {
    try {
      final rows = await config.fetchFn(branchId);

      if (rows.isEmpty) {
        return TableBackupResult(
          tableName: config.tableName,
          rowsFetched: 0,
          rowsUpserted: 0,
          success: true,
        );
      }

      int upserted = 0;
      final rowErrors = <String>[];

      for (final row in rows) {
        try {
          await _upsertRow(
            localDb: localDb,
            tableName: config.tableName,
            row: row,
            conflictColumn: config.conflictColumn,
          );
          upserted++;
        } catch (e) {
          rowErrors.add('Row ${row['id']}: $e');
        }
      }

      if (rowErrors.isNotEmpty && upserted == 0) {
        return TableBackupResult(
          tableName: config.tableName,
          rowsFetched: rows.length,
          rowsUpserted: 0,
          success: false,
          error: rowErrors.first,
        );
      }

      return TableBackupResult(
        tableName: config.tableName,
        rowsFetched: rows.length,
        rowsUpserted: upserted,
        success: true,
        error: rowErrors.isNotEmpty ? '${rowErrors.length} rows skip huin' : null,
      );
    } catch (e) {
      return TableBackupResult(
        tableName: config.tableName,
        rowsFetched: 0,
        rowsUpserted: 0,
        success: false,
        error: e.toString(),
      );
    }
  }

  // ── Triggers enable/disable ────────────────────────────────────────────────
  static const _triggerTables = [
    'branch_stock_inventory',
    'branch_stock_damage',
    'sale_invoices',
    'sale_invoice_payments',
    'customer_ledger',
    'branch_cash_transaction',
    'branch_cash_counter',
    'sale_returns',
    'sale_return_items',
  ];

  Future<void> _setTriggers(Connection db, {required bool enable}) async {
    final action = enable ? 'ENABLE' : 'DISABLE';
    for (final table in _triggerTables) {
      try {
        await db.execute(Sql('ALTER TABLE public.$table $action TRIGGER ALL'));
        print('$action trigger: $table');
      } catch (e) {
        print('trigger $action failed for $table: $e');
      }
    }
  }

  // ── Local columns cache ────────────────────────────────────────────────────
  final Map<String, Set<String>> _tableColumnsCache = {};

  Future<Set<String>> _getLocalColumns(
      Connection localDb, String tableName) async {
    if (_tableColumnsCache.containsKey(tableName)) {
      return _tableColumnsCache[tableName]!;
    }
    try {
      final result = await localDb.execute(
        Sql('''
          SELECT column_name
          FROM information_schema.columns
          WHERE table_schema = 'public'
            AND table_name = '$tableName'
        '''),
      );
      final cols = result.map((r) => r[0] as String).toSet();
      _tableColumnsCache[tableName] = cols;
      return cols;
    } catch (_) {
      return {};
    }
  }

  // ── Generic upsert ─────────────────────────────────────────────────────────
  Future<void> _upsertRow({
    required Connection localDb,
    required String tableName,
    required Map<String, dynamic> row,
    required String conflictColumn,
  }) async {
    final localCols = _tableColumnsCache[tableName] ?? {};
    final cleaned = _cleanRow(row);

    final filteredMap = localCols.isEmpty
        ? cleaned
        : Map.fromEntries(
        cleaned.entries.where((e) => localCols.contains(e.key)));

    if (filteredMap.isEmpty) return;
    if (!filteredMap.containsKey(conflictColumn)) return;

    final columns = filteredMap.keys.toList();
    final values = filteredMap.values.toList();

    final colList = columns.map((c) => '"$c"').join(', ');
    final valPlaceholders =
    List.generate(columns.length, (i) => '\$${i + 1}').join(', ');
    final updateSet = columns
        .where((c) => c != conflictColumn)
        .map((c) => '"$c" = EXCLUDED."$c"')
        .join(', ');

    final sql = '''
      INSERT INTO "$tableName" ($colList)
      VALUES ($valPlaceholders)
      ON CONFLICT ("$conflictColumn") DO UPDATE SET $updateSet
    ''';

    await localDb.execute(Sql(sql), parameters: values);
  }

  // ── Clean row ──────────────────────────────────────────────────────────────
  Map<String, dynamic> _cleanRow(Map<String, dynamic> row) {
    final result = <String, dynamic>{};
    for (final entry in row.entries) {
      var value = entry.value;
      if (value is List) {
        final escaped = value
            .map((e) => e.toString()
            .replaceAll('\\', '\\\\')
            .replaceAll('"', '\\"'))
            .join(',');
        value = '{$escaped}';
      } else if (value is Map) {
        value = jsonEncode(value);
      }
      result[entry.key] = value;
    }
    return result;
  }

  // ── Paginated fetch (Supabase 1000 row limit bypass) ──────────────────────
  Future<List<Map<String, dynamic>>> _fetchAll({
    required String table,
    required String filterCol,
    required String filterVal,
    bool filterDeleted = false,
  }) async {
    const pageSize = 1000;
    final allRows = <Map<String, dynamic>>[];
    int offset = 0;

    while (true) {
      // isFilter pehle — range baad mein (TransformBuilder pe isFilter nahi hota)
      List res;
      if (filterDeleted) {
        res = await _supabase
            .from(table)
            .select()
            .eq(filterCol, filterVal)
            .isFilter('deleted_at', null)
            .range(offset, offset + pageSize - 1);
      } else {
        res = await _supabase
            .from(table)
            .select()
            .eq(filterCol, filterVal)
            .range(offset, offset + pageSize - 1);
      }

      final rows = List<Map<String, dynamic>>.from(res);
      allRows.addAll(rows);

      if (rows.length < pageSize) break;
      offset += pageSize;
    }

    return allRows;
  }

  // ── Fetch by ID list in chunks ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchByIds({
    required String table,
    required String filterCol,
    required List<String> ids,
  }) async {
    const chunkSize = 100;
    final allRows = <Map<String, dynamic>>[];

    for (int i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, (i + chunkSize).clamp(0, ids.length));
      final res = await _supabase
          .from(table)
          .select()
          .inFilter(filterCol, chunk);
      allRows.addAll(List<Map<String, dynamic>>.from(res as List));
    }

    return allRows;
  }

  // ── 17 Tables Config ───────────────────────────────────────────────────────
  List<_TableConfig> _getTableConfigs(String branchId) {
    return [
      // 1. branch
      _TableConfig(
        tableName: 'branch',
        displayName: 'Branch',
        conflictColumn: 'id',
        fetchFn: (_) async {
          final res =
          await _supabase.from('branch').select().eq('id', branchId);
          return List<Map<String, dynamic>>.from(res as List);
        },
      ),

      // 2. branch_counter
      _TableConfig(
        tableName: 'branch_counter',
        displayName: 'Branch Counter',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'branch_counter',
          filterCol: 'store_id',
          filterVal: branchId,
          filterDeleted: true,
        ),
      ),

      // 3. branch_users
      _TableConfig(
        tableName: 'branch_users',
        displayName: 'Branch Users',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'branch_users',
          filterCol: 'store_id',
          filterVal: branchId,
          filterDeleted: true,
        ),
      ),

      // 4. branch_cash_counter
      _TableConfig(
        tableName: 'branch_cash_counter',
        displayName: 'Cash Counter',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'branch_cash_counter',
          filterCol: 'store_id',
          filterVal: branchId,
          filterDeleted: true,
        ),
      ),

      // 5. branch_cash_transaction
      _TableConfig(
        tableName: 'branch_cash_transaction',
        displayName: 'Cash Transactions',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'branch_cash_transaction',
          filterCol: 'store_id',
          filterVal: branchId,
        ),
      ),

      // 6. branch_summary
      _TableConfig(
        tableName: 'branch_summary',
        displayName: 'Branch Summary',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'branch_summary',
          filterCol: 'store_id',
          filterVal: branchId,
        ),
      ),

      // 7. branch_stock_inventory
      _TableConfig(
        tableName: 'branch_stock_inventory',
        displayName: 'Stock Inventory',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'branch_stock_inventory',
          filterCol: 'store_id',
          filterVal: branchId,
        ),
      ),

      // 8. branch_stock_damage
      _TableConfig(
        tableName: 'branch_stock_damage',
        displayName: 'Stock Damage',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'branch_stock_damage',
          filterCol: 'store_id',
          filterVal: branchId,
        ),
      ),

      // 9. branch_transaction_to_janghani
      _TableConfig(
        tableName: 'branch_transaction_to_janghani',
        displayName: 'Branch Transactions',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'branch_transaction_to_janghani',
          filterCol: 'branch_id',
          filterVal: branchId,
        ),
      ),

      // 10. customer
      _TableConfig(
        tableName: 'customer',
        displayName: 'Customers',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'customer',
          filterCol: 'store_id',
          filterVal: branchId,
          filterDeleted: true,
        ),
      ),

      // 11. customer_ledger
      _TableConfig(
        tableName: 'customer_ledger',
        displayName: 'Customer Ledger',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'customer_ledger',
          filterCol: 'store_id',
          filterVal: branchId,
          filterDeleted: true,
        ),
      ),

      // 12. sale_invoices
      _TableConfig(
        tableName: 'sale_invoices',
        displayName: 'Sale Invoices',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'sale_invoices',
          filterCol: 'store_id',
          filterVal: branchId,
        ),
      ),

      // 13. sale_invoice_items
      _TableConfig(
        tableName: 'sale_invoice_items',
        displayName: 'Sale Invoice Items',
        conflictColumn: 'id',
        fetchFn: (_) async {
          final invoices = await _fetchAll(
            table: 'sale_invoices',
            filterCol: 'store_id',
            filterVal: branchId,
          );
          final ids = invoices.map((e) => e['id'] as String).toList();
          if (ids.isEmpty) return [];
          return _fetchByIds(
            table: 'sale_invoice_items',
            filterCol: 'invoice_id',
            ids: ids,
          );
        },
      ),

      // 14. sale_invoice_payments
      _TableConfig(
        tableName: 'sale_invoice_payments',
        displayName: 'Sale Invoice Payments',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'sale_invoice_payments',
          filterCol: 'store_id',
          filterVal: branchId,
        ),
      ),

      // 15. sale_returns
      _TableConfig(
        tableName: 'sale_returns',
        displayName: 'Sale Returns',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'sale_returns',
          filterCol: 'store_id',
          filterVal: branchId,
          filterDeleted: true,
        ),
      ),

      // 16. sale_return_items
      _TableConfig(
        tableName: 'sale_return_items',
        displayName: 'Sale Return Items',
        conflictColumn: 'id',
        fetchFn: (_) async {
          final returns = await _fetchAll(
            table: 'sale_returns',
            filterCol: 'store_id',
            filterVal: branchId,
            filterDeleted: true,
          );
          final ids = returns.map((e) => e['id'] as String).toList();
          if (ids.isEmpty) return [];
          return _fetchByIds(
            table: 'sale_return_items',
            filterCol: 'return_id',
            ids: ids,
          );
        },
      ),

      // 17. sale_return_payments
      _TableConfig(
        tableName: 'sale_return_payments',
        displayName: 'Sale Return Payments',
        conflictColumn: 'id',
        fetchFn: (_) => _fetchAll(
          table: 'sale_return_payments',
          filterCol: 'store_id',
          filterVal: branchId,
        ),
      ),
    ];
  }
}

// ── Internal Table Config ──────────────────────────────────────────────────
class _TableConfig {
  final String tableName;
  final String displayName;
  final String conflictColumn;
  final Future<List<Map<String, dynamic>>> Function(String branchId) fetchFn;

  const _TableConfig({
    required this.tableName,
    required this.displayName,
    required this.conflictColumn,
    required this.fetchFn,
  });
}