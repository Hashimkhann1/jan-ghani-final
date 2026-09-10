// =============================================================
// balance_batch_model.dart
// inventory_balance_batches table ka model.
// =============================================================

class BalanceBatchModel {
  final String   id;
  final String   warehouseId;
  final String   storeId;
  final String   batchNumber;
  final String?  notes;
  final int      totalItems;
  final String?  createdBy;
  final String?  createdByName;
  final DateTime createdAt;
  final bool     isSynced;
  final DateTime? syncedAt;

  const BalanceBatchModel({
    required this.id,
    required this.warehouseId,
    required this.storeId,
    required this.batchNumber,
    this.notes,
    required this.totalItems,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
    this.isSynced = false,
    this.syncedAt,
  });

  factory BalanceBatchModel.fromMap(Map<String, dynamic> m) {
    return BalanceBatchModel(
      id:            m['id'].toString(),
      warehouseId:   m['warehouse_id'].toString(),
      storeId:       m['store_id'].toString(),
      batchNumber:   m['batch_number']?.toString() ?? '',
      notes:         m['notes']?.toString(),
      totalItems:    (m['total_items'] as num?)?.toInt() ?? 0,
      createdBy:     m['created_by']?.toString(),
      createdByName: m['created_by_name']?.toString(),
      createdAt:     m['created_at'] is DateTime
                        ? m['created_at'] as DateTime
                        : DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
      isSynced:      m['is_synced'] == true,
      syncedAt:      m['synced_at'] is DateTime
                        ? m['synced_at'] as DateTime
                        : DateTime.tryParse(m['synced_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toColumnMap() => {
    'id':              id,
    'warehouse_id':    warehouseId,
    'store_id':        storeId,
    'batch_number':    batchNumber,
    'notes':           notes,
    'total_items':     totalItems,
    'created_by':      createdBy,
    'created_by_name': createdByName,
    'created_at':      createdAt,
    'is_synced':       isSynced,
    'synced_at':       syncedAt,
  };
}
