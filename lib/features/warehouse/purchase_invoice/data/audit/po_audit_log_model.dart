// =============================================================
// po_audit_log_model.dart
// PO audit trail — har create/update/delete/status_change record
// =============================================================

// ── Action constants ──────────────────────────────────────────
class PoAuditAction {
  static const String created       = 'created';
  static const String updated       = 'updated';
  static const String deleted       = 'deleted';
  static const String statusChanged = 'status_changed';
}

// ── Model ─────────────────────────────────────────────────────
class PoAuditLog {
  final String    id;
  final String    warehouseId;
  final String    poId;
  final String    action;           // PoAuditAction constants
  final String?   changedById;
  final String?   changedByName;
  final Map<String, dynamic>? oldData;   // pehle kya tha
  final Map<String, dynamic>? newData;   // ab kya hai
  final String?   changeSummary;    // human readable diff
  final DateTime  createdAt;
  final bool      isSynced;

  const PoAuditLog({
    required this.id,
    required this.warehouseId,
    required this.poId,
    required this.action,
    this.changedById,
    this.changedByName,
    this.oldData,
    this.newData,
    this.changeSummary,
    required this.createdAt,
    this.isSynced = false,
  });

  factory PoAuditLog.fromMap(Map<String, dynamic> m) {
    return PoAuditLog(
      id:            m['id']              as String,
      warehouseId:   m['warehouse_id']    as String,
      poId:          m['po_id']           as String,
      action:        m['action']          as String,
      changedById:   m['changed_by_id']   as String?,
      changedByName: m['changed_by_name'] as String?,
      oldData:       m['old_data']        as Map<String, dynamic>?,
      newData:       m['new_data']        as Map<String, dynamic>?,
      changeSummary: m['change_summary']  as String?,
      createdAt: m['created_at'] is DateTime
          ? m['created_at'] as DateTime
          : DateTime.parse(m['created_at'].toString()),
      isSynced: m['is_synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':              id,
    'warehouse_id':    warehouseId,
    'po_id':           poId,
    'action':          action,
    'changed_by_id':   changedById,
    'changed_by_name': changedByName,
    'old_data':        oldData,
    'new_data':        newData,
    'change_summary':  changeSummary,
    'created_at':      createdAt.toIso8601String(),
    'is_synced':       isSynced,
  };
}