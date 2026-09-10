// =============================================================
// balance_item_model.dart
// inventory_balance_items table ka model — real data + state.
// =============================================================

import '../../domain/balance_status.dart';

class BalanceItemModel {
  final String   id;
  final String   batchId;
  final String   warehouseId;
  final String   storeId;

  final String   productId;
  final String   productName;
  final String?  productSku;
  final String?  countingId;

  final double   systemStockAtCount;
  final double   physicalStock;
  final double   delta;
  final double   unitPrice;
  final bool     isHighVariance;

  final BalanceStatus status;

  final DateTime? reviewerReviewedAt;
  final String?   reviewerId;
  final String?   reviewerName;
  final String?   reviewerReason;

  final DateTime? branchReviewedAt;
  final String?   branchUserId;
  final String?   branchUserName;
  final String?   branchReason;

  final DateTime? appliedAt;
  final double?   appliedStockBefore;
  final double?   appliedStockAfter;

  final bool      isSynced;
  final DateTime? syncedAt;
  final DateTime  createdAt;

  const BalanceItemModel({
    required this.id,
    required this.batchId,
    required this.warehouseId,
    required this.storeId,
    required this.productId,
    required this.productName,
    this.productSku,
    this.countingId,
    required this.systemStockAtCount,
    required this.physicalStock,
    required this.delta,
    this.unitPrice = 0,
    this.isHighVariance = false,
    this.status = BalanceStatus.reviewPending,
    this.reviewerReviewedAt,
    this.reviewerId,
    this.reviewerName,
    this.reviewerReason,
    this.branchReviewedAt,
    this.branchUserId,
    this.branchUserName,
    this.branchReason,
    this.appliedAt,
    this.appliedStockBefore,
    this.appliedStockAfter,
    this.isSynced = false,
    this.syncedAt,
    required this.createdAt,
  });

  double get rupeeImpact => (delta * unitPrice).abs();

  factory BalanceItemModel.fromMap(Map<String, dynamic> m) {
    double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
    double? _dn(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    DateTime? _dt(dynamic v) => v == null ? null : (v is DateTime ? v : DateTime.tryParse(v.toString()));

    return BalanceItemModel(
      id:                 m['id'].toString(),
      batchId:            m['batch_id'].toString(),
      warehouseId:        m['warehouse_id'].toString(),
      storeId:            m['store_id'].toString(),
      productId:          m['product_id'].toString(),
      productName:        m['product_name']?.toString() ?? '',
      productSku:         m['product_sku']?.toString(),
      countingId:         m['counting_id']?.toString(),
      systemStockAtCount: _d(m['system_stock_at_count']),
      physicalStock:      _d(m['physical_stock']),
      delta:              _d(m['delta']),
      unitPrice:          _d(m['unit_price']),
      isHighVariance:     m['is_high_variance'] == true,
      status:             BalanceStatus.fromCode(m['status']?.toString() ?? 'review_pending'),
      reviewerReviewedAt: _dt(m['reviewer_reviewed_at']),
      reviewerId:         m['reviewer_id']?.toString(),
      reviewerName:       m['reviewer_name']?.toString(),
      reviewerReason:     m['reviewer_reason']?.toString(),
      branchReviewedAt:   _dt(m['branch_reviewed_at']),
      branchUserId:       m['branch_user_id']?.toString(),
      branchUserName:     m['branch_user_name']?.toString(),
      branchReason:       m['branch_reason']?.toString(),
      appliedAt:          _dt(m['applied_at']),
      appliedStockBefore: _dn(m['applied_stock_before']),
      appliedStockAfter:  _dn(m['applied_stock_after']),
      isSynced:           m['is_synced'] == true,
      syncedAt:           _dt(m['synced_at']),
      createdAt:          _dt(m['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toColumnMap() => {
    'id':                     id,
    'batch_id':               batchId,
    'warehouse_id':           warehouseId,
    'store_id':               storeId,
    'product_id':             productId,
    'product_name':           productName,
    'product_sku':            productSku,
    'counting_id':            countingId,
    'system_stock_at_count':  systemStockAtCount,
    'physical_stock':         physicalStock,
    'delta':                  delta,
    'unit_price':             unitPrice,
    'is_high_variance':       isHighVariance,
    'status':                 status.code,
    'reviewer_reviewed_at':   reviewerReviewedAt,
    'reviewer_id':            reviewerId,
    'reviewer_name':          reviewerName,
    'reviewer_reason':        reviewerReason,
    'branch_reviewed_at':     branchReviewedAt,
    'branch_user_id':         branchUserId,
    'branch_user_name':       branchUserName,
    'branch_reason':          branchReason,
    'applied_at':             appliedAt,
    'applied_stock_before':   appliedStockBefore,
    'applied_stock_after':    appliedStockAfter,
    'is_synced':              isSynced,
    'synced_at':              syncedAt,
    'created_at':              createdAt,
  };
}

// Pending count row from inventory_counting join products — for Create Batch panel.
class PendingCountRow {
  final String   countingId;
  final String   productId;
  final String   productName;
  final String?  productSku;
  final double   systemStock;   // product_stock (at count time)
  final double   physicalStock; // counting_stock
  final double   unitPrice;     // sale_price
  final DateTime countedAt;
  final String   storeId;

  const PendingCountRow({
    required this.countingId,
    required this.productId,
    required this.productName,
    this.productSku,
    required this.systemStock,
    required this.physicalStock,
    required this.unitPrice,
    required this.countedAt,
    required this.storeId,
  });

  double get delta      => physicalStock - systemStock;
  double get rupeeImpact => (delta * unitPrice).abs();
  bool   get isHighVariance => rupeeImpact > kHighVarianceRupeeThreshold;
}
