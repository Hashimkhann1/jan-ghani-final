// Updated on 2026-10-02 09:49 AM
// =============================================================
// sidebar_sync_status_provider.dart
// Warehouse sidebar footer ka sync status — local DB mein kitne
// records abhi Supabase par nahi gaye (v_unsynced).
// SideBar har 60 sec invalidate karta hai. Error (DB band) → null,
// footer "Sync status maloom nahi" dikhata hai.
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';

class SidebarSyncStatus {
  final int      unsynced;
  final DateTime checkedAt;

  const SidebarSyncStatus({required this.unsynced, required this.checkedAt});
}

final sidebarSyncStatusProvider =
    FutureProvider.autoDispose<SidebarSyncStatus?>((ref) async {
  try {
    final conn   = await DatabaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT COALESCE(SUM(unsynced_count), 0)::int AS unsynced
        FROM v_unsynced
        WHERE warehouse_id = @wid
      '''),
      parameters: {'wid': AppConfig.warehouseId},
    );
    final v = result.first.toColumnMap()['unsynced'];
    return SidebarSyncStatus(
      unsynced:  v is int ? v : int.tryParse('$v') ?? 0,
      checkedAt: DateTime.now(),
    );
  } catch (_) {
    return null;
  }
});
