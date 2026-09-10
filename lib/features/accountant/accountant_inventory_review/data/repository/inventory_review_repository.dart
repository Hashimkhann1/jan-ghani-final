// =============================================================
// inventory_review_repository.dart
// Reviewer-side thin wrapper.
// =============================================================

import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_batch_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_item_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/domain/balance_status.dart';

import '../datasource/inventory_review_remote_datasource.dart';

class InventoryReviewRepository {
  InventoryReviewRepository._();
  static final instance = InventoryReviewRepository._();

  final _remote = InventoryReviewRemoteDatasource();

  Future<List<BalanceItemModel>> getPendingItems() =>
      _remote.fetchPendingItems();

  Future<List<BalanceItemModel>> getItems({
    DateTime? fromDate,
    DateTime? toDate,
    BalanceStatus? status,
    String? storeId,
  }) => _remote.fetchItems(
    fromDate: fromDate, toDate: toDate, status: status, storeId: storeId,
  );

  Future<List<BalanceBatchModel>> getBatchesByIds(Set<String> ids) =>
      _remote.fetchBatchesByIds(ids);

  Future<void> accept({
    required String itemId,
    required String batchId,
    required String reviewerId,
    required String reviewerName,
  }) => _remote.acceptItem(
    itemId:       itemId,
    batchId:      batchId,
    reviewerId:   reviewerId,
    reviewerName: reviewerName,
  );

  Future<void> reject({
    required String itemId,
    required String batchId,
    required String reason,
    required String reviewerId,
    required String reviewerName,
  }) => _remote.rejectItem(
    itemId:       itemId,
    batchId:      batchId,
    reason:       reason,
    reviewerId:   reviewerId,
    reviewerName: reviewerName,
  );
}
