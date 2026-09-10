// =============================================================
// inventory_balance_repository.dart
// Thin wrapper over local + remote datasources.
// =============================================================

import 'dart:math';
import 'package:jan_ghani_final/core/config/app_config.dart';

import '../../domain/balance_status.dart';
import '../datasource/inventory_balance_local_datasource.dart';
import '../datasource/inventory_balance_remote_datasource.dart';
import '../model/balance_batch_model.dart';
import '../model/balance_item_model.dart';

// re-export for provider convenience

class InventoryBalanceRepository {
  InventoryBalanceRepository._();
  static final instance = InventoryBalanceRepository._();

  final _local  = InventoryBalanceLocalDatasource.instance;
  final _remote = InventoryBalanceRemoteDatasource();

  // ── Batch number generator — 'IB-<wh_code>-YYYYMMDD-XXXXXXX' ──
  String generateBatchNumber() {
    final now = DateTime.now();
    final ymd = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand  = Random().nextInt(9999).toString().padLeft(4, '0');
    final epoch = now.millisecondsSinceEpoch.toString().substring(9);
    final code  = AppConfig.warehouseCode.isNotEmpty
        ? AppConfig.warehouseCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase()
        : 'WH';
    return 'IB-$code-$ymd-$epoch$rand';
  }

  // ── Create batch (offline-safe local write) ───────────────
  Future<BalanceBatchModel> createBatch({
    required String storeId,
    required List<BalanceItemModel> items,
    String?         notes,
    String?         createdBy,
    String?         createdByName,
  }) {
    return _local.createBatch(
      storeId:       storeId,
      batchNumber:   generateBatchNumber(),
      notes:         notes,
      items:         items,
      createdBy:     createdBy,
      createdByName: createdByName,
    );
  }

  // ── Local reads ───────────────────────────────────────────
  Future<List<BalanceBatchModel>> getBatches({
    DateTime? fromDate,
    DateTime? toDate,
    String?   storeId,
  }) => _local.getBatches(fromDate: fromDate, toDate: toDate, storeId: storeId);

  Future<List<BalanceItemModel>> getBatchItems(String batchId) =>
      _local.getBatchItems(batchId);

  Future<List<BalanceItemModel>> getLocalItems({
    DateTime?       fromDate,
    DateTime?       toDate,
    BalanceStatus?  status,
    String?         storeId,
  }) => _local.getItems(
    fromDate: fromDate, toDate: toDate, status: status, storeId: storeId,
  );

  // ── Pending counts (Supabase read) ────────────────────────
  Future<List<PendingCountRow>> fetchPendingCounts({
    required String storeId,
    int daysBack = 7,
  }) async {
    final consumed = await _local.getConsumedCountingIds();
    return _remote.fetchPendingCounts(
      storeId: storeId,
      daysBack: daysBack,
      excludeCountingIds: consumed,
    );
  }

  // ── Batches by ids (report grouping) ──────────────────────
  Future<List<BalanceBatchModel>> fetchBatchesByIds(Set<String> ids) =>
      _remote.fetchBatchesByIds(ids);

  // ── Cloud refresh (Supabase read — reviewer+branch updates) ──
  Future<List<BalanceItemModel>> fetchItemsFromCloud({
    DateTime?       fromDate,
    DateTime?       toDate,
    BalanceStatus?  status,
    String?         storeId,
    int             limit = 500,
  }) => _remote.fetchItems(
    warehouseId: AppConfig.warehouseId,
    fromDate:    fromDate,
    toDate:      toDate,
    status:      status,
    storeId:     storeId,
    limit:       limit,
  );
}
