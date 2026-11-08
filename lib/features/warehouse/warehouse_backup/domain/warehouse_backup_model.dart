// Updated on 2026-11-08 09:48 AM
// =============================================================
// warehouse_backup_model.dart
// Local DB backup ka ek record (warehouse_backups table — sirf local)
// =============================================================

class WarehouseBackupRecord {
  final String   id;
  final String   fileName;
  final String   filePath;
  final int      fileSizeBytes;
  final String   status;        // 'success' | 'failed'
  final String?  errorMessage;
  final int?     durationMs;
  final String?  createdByName;
  final DateTime createdAt;     // UTC/driver value — display par .toLocal()

  const WarehouseBackupRecord({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.status,
    this.errorMessage,
    this.durationMs,
    this.createdByName,
    required this.createdAt,
  });

  bool get isSuccess => status == 'success';

  factory WarehouseBackupRecord.fromMap(Map<String, dynamic> m) {
    return WarehouseBackupRecord(
      id:            m['id'].toString(),
      fileName:      (m['file_name'] ?? '') as String,
      filePath:      (m['file_path'] ?? '') as String,
      fileSizeBytes: (m['file_size_bytes'] as num?)?.toInt() ?? 0,
      status:        (m['status'] ?? 'failed') as String,
      errorMessage:  m['error_message'] as String?,
      durationMs:    (m['duration_ms'] as num?)?.toInt(),
      createdByName: m['created_by_name'] as String?,
      createdAt:     m['created_at'] as DateTime,
    );
  }
}

/// Size ko insani format mein: 1536 → "1.5 KB", 5242880 → "5.0 MB"
String formatBackupSize(int bytes) {
  if (bytes <= 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB'];
  double v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return i == 0 ? '$bytes B' : '${v.toStringAsFixed(1)} ${units[i]}';
}
