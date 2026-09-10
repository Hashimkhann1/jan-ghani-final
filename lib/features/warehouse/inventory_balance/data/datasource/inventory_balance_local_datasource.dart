// =============================================================
// inventory_balance_local_datasource.dart
// Warehouse-side LOCAL postgres CRUD for inventory_balance_*
//
// Design: offline-first (jaisa stock_transfer). Warehouse user
// batch create karta hai → yahin local par insert + reserve
// pattern se pehle sab kuch local mein land, phir background sync
// Supabase par push kar deta.
//
// Reviewer (accountant) SEPARATE device par hai — wo Supabase par
// seedha padhta/likhta. Warehouse ki local DB reviewer se
// concerned nahi.
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

import '../../domain/balance_status.dart';
import '../model/balance_batch_model.dart';
import '../model/balance_item_model.dart';

class InventoryBalanceLocalDatasource {
  static final instance = InventoryBalanceLocalDatasource._();
  InventoryBalanceLocalDatasource._();

  Future<Connection> get _db  => DatabaseService.getConnection();
  String             get _wid => AppConfig.warehouseId;

  // ─────────────────────────────────────────────────────────
  // BATCH: create karo (header + items, ek transaction mein)
  // ─────────────────────────────────────────────────────────
  Future<BalanceBatchModel> createBatch({
    required String storeId,
    required String batchNumber,
    String?         notes,
    required List<BalanceItemModel> items,
    String?         createdBy,
    String?         createdByName,
  }) async {
    if (items.isEmpty) {
      throw Exception('Batch mein at least ek item hona chahiye');
    }

    final conn = await _db;
    final batchId = const Uuid().v4();
    final now = DateTime.now();

    return conn.runTx<BalanceBatchModel>((tx) async {
      // 1. Batch header
      final batchRow = await tx.execute(
        Sql.named('''
          INSERT INTO inventory_balance_batches (
            id, warehouse_id, store_id, batch_number,
            notes, total_items,
            created_by, created_by_name, created_at,
            is_synced
          ) VALUES (
            @id, @wid, @storeId, @batchNumber,
            @notes, @totalItems,
            @createdBy, @createdByName, @createdAt,
            false
          )
          RETURNING *
        '''),
        parameters: {
          'id':            batchId,
          'wid':           _wid,
          'storeId':       storeId,
          'batchNumber':   batchNumber,
          'notes':         notes,
          'totalItems':    items.length,
          'createdBy':     createdBy,
          'createdByName': createdByName,
          'createdAt':     now,
        },
      );

      // 2. Items — bulk insert (one execute per row inside same tx)
      for (final it in items) {
        final itemId = it.id.isEmpty ? const Uuid().v4() : it.id;
        await tx.execute(
          Sql.named('''
            INSERT INTO inventory_balance_items (
              id, batch_id, warehouse_id, store_id,
              product_id, product_name, product_sku, counting_id,
              system_stock_at_count, physical_stock, delta,
              unit_price, is_high_variance,
              status, created_at, is_synced
            ) VALUES (
              @id, @batchId, @wid, @storeId,
              @productId, @productName, @productSku, @countingId,
              @sysStock, @phyStock, @delta,
              @unitPrice, @isHighVar,
              @status, @createdAt, false
            )
          '''),
          parameters: {
            'id':          itemId,
            'batchId':     batchId,
            'wid':         _wid,
            'storeId':     storeId,
            'productId':   it.productId,
            'productName': it.productName,
            'productSku':  it.productSku,
            'countingId':  it.countingId,
            'sysStock':    it.systemStockAtCount,
            'phyStock':    it.physicalStock,
            'delta':       it.delta,
            'unitPrice':   it.unitPrice,
            'isHighVar':   it.isHighVariance,
            'status':      BalanceStatus.reviewPending.code,
            'createdAt':   now,
          },
        );

        // Log: 'created'
        await tx.execute(
          Sql.named('''
            INSERT INTO inventory_balance_log (
              id, item_id, batch_id, action,
              actor_id, actor_name, actor_role, created_at, is_synced
            ) VALUES (
              @id, @itemId, @batchId, 'created',
              @actorId, @actorName, 'warehouse', @createdAt, false
            )
          '''),
          parameters: {
            'id':        const Uuid().v4(),
            'itemId':    itemId,
            'batchId':   batchId,
            'actorId':   createdBy,
            'actorName': createdByName,
            'createdAt': now,
          },
        );
      }

      return BalanceBatchModel.fromMap(batchRow.first.toColumnMap());
    });
  }

  // ─────────────────────────────────────────────────────────
  // BATCHES: list (warehouse ke apne batches — history)
  // ─────────────────────────────────────────────────────────
  Future<List<BalanceBatchModel>> getBatches({
    DateTime? fromDate,
    DateTime? toDate,
    String?   storeId,
    int       limit = 100,
  }) async {
    final conn = await _db;
    final where = StringBuffer('WHERE warehouse_id = @wid');
    if (storeId  != null) where.write('\n        AND store_id = @storeId');
    if (fromDate != null) where.write('\n        AND created_at >= @fromDate');
    if (toDate   != null) where.write('\n        AND created_at <  @toDate');

    final rows = await conn.execute(
      Sql.named('''
        SELECT * FROM inventory_balance_batches
        $where
        ORDER BY created_at DESC
        LIMIT @limit
      '''),
      parameters: {
        'wid':    _wid,
        'limit':  limit,
        if (storeId  != null) 'storeId':  storeId,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate   != null) 'toDate':   toDate,
      },
    );

    return rows.map((r) => BalanceBatchModel.fromMap(r.toColumnMap())).toList();
  }

  // ─────────────────────────────────────────────────────────
  // ITEMS: batch ke saare items
  // ─────────────────────────────────────────────────────────
  Future<List<BalanceItemModel>> getBatchItems(String batchId) async {
    final conn = await _db;
    final rows = await conn.execute(
      Sql.named('''
        SELECT * FROM inventory_balance_items
        WHERE batch_id = @batchId
        ORDER BY created_at ASC
      '''),
      parameters: {'batchId': batchId},
    );
    return rows.map((r) => BalanceItemModel.fromMap(r.toColumnMap())).toList();
  }

  // ─────────────────────────────────────────────────────────
  // ITEMS: warehouse-wide filter (report screen)
  // ─────────────────────────────────────────────────────────
  Future<List<BalanceItemModel>> getItems({
    DateTime?       fromDate,
    DateTime?       toDate,
    BalanceStatus?  status,
    String?         storeId,
    int             limit = 500,
  }) async {
    final conn = await _db;
    final where = StringBuffer('WHERE warehouse_id = @wid');
    if (storeId  != null) where.write('\n        AND store_id = @storeId');
    if (status   != null) where.write('\n        AND status = @status');
    if (fromDate != null) where.write('\n        AND created_at >= @fromDate');
    if (toDate   != null) where.write('\n        AND created_at <  @toDate');

    final rows = await conn.execute(
      Sql.named('''
        SELECT * FROM inventory_balance_items
        $where
        ORDER BY created_at DESC
        LIMIT @limit
      '''),
      parameters: {
        'wid':    _wid,
        'limit':  limit,
        if (storeId  != null) 'storeId':  storeId,
        if (status   != null) 'status':   status.code,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate   != null) 'toDate':   toDate,
      },
    );

    return rows.map((r) => BalanceItemModel.fromMap(r.toColumnMap())).toList();
  }

  // ─────────────────────────────────────────────────────────
  // Counting IDs jo pehle se kisi batch mein consume ho chuke —
  // "Create Batch" panel se filter karne ke liye.
  // ─────────────────────────────────────────────────────────
  Future<Set<String>> getConsumedCountingIds() async {
    final conn = await _db;
    final rows = await conn.execute(
      Sql.named('''
        SELECT DISTINCT counting_id
        FROM inventory_balance_items
        WHERE warehouse_id = @wid AND counting_id IS NOT NULL
      '''),
      parameters: {'wid': _wid},
    );
    return rows
        .map((r) => r.toColumnMap()['counting_id'].toString())
        .toSet();
  }
}
