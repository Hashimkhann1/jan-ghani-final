// =============================================================
// branch_inventory_balance_repository.dart
// Branch-side thin wrapper.
// =============================================================

import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_batch_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_item_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/domain/balance_status.dart';

import '../datasource/branch_inventory_balance_datasource.dart';

class BranchInventoryBalanceRepository {
  BranchInventoryBalanceRepository._();
  static final instance = BranchInventoryBalanceRepository._();

  final _remote = BranchInventoryBalanceDatasource();

  Future<List<BalanceItemModel>> getPendingItems(String storeId) =>
      _remote.fetchPendingItems(storeId: storeId);

  Future<List<BalanceItemModel>> getItems({
    required String storeId,
    DateTime?       fromDate,
    DateTime?       toDate,
    BalanceStatus?  status,
  }) => _remote.fetchItems(
    storeId: storeId, fromDate: fromDate, toDate: toDate, status: status,
  );

  Future<List<BalanceBatchModel>> getBatchesByIds(Set<String> ids) =>
      _remote.fetchBatchesByIds(ids);

  Future<void> acceptAndApply({
    required String itemId,
    required String branchUserId,
    required String branchUserName,
  }) => _remote.acceptAndApplyItem(
    itemId: itemId, branchUserId: branchUserId, branchUserName: branchUserName,
  );

  Future<void> reject({
    required String itemId,
    required String batchId,
    required String reason,
    required String branchUserId,
    required String branchUserName,
  }) => _remote.rejectItem(
    itemId: itemId, batchId: batchId, reason: reason,
    branchUserId: branchUserId, branchUserName: branchUserName,
  );
}
