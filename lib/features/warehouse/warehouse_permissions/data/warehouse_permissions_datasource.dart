// Updated on 2026-11-22 10:46 AM
// =============================================================
// warehouse_permissions_datasource.dart — SIRF LOCAL DB (S31)
//
// Table `warehouse_user_permissions` (migration:
// …/zero_start_schema/warehouse_user_permissions_migration.sql):
//   • Row NAHI  → user role ke defaults use karta hai
//   • Row HAI   → `perm_keys` hi us user ke exact permissions (khaali
//                 array = sab band, jaan-bujh kar save kiya gaya)
// `warehouse_users` ko chhoote nahi (owner postgres hai — ALTER nahi).
// Supabase sync NAHI (warehouse_backups jaisa — `_allTables` mein nahi).
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';

class WarehousePermissionsDatasource {
  WarehousePermissionsDatasource._();
  static final instance = WarehousePermissionsDatasource._();

  bool _tableReady = false;

  /// Migration file bhi hai — yeh safety net hai (Backup screen jaisa).
  Future<void> ensureTable() async {
    if (_tableReady) return;
    final conn = await DatabaseService.getConnection();
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS public.warehouse_user_permissions (
          user_id          uuid        NOT NULL PRIMARY KEY,
          warehouse_id     uuid        NOT NULL,
          perm_keys        text[]      NOT NULL DEFAULT '{}'::text[],
          updated_by       uuid,
          updated_by_name  character varying(150),
          created_at       timestamptz NOT NULL DEFAULT now(),
          updated_at       timestamptz NOT NULL DEFAULT now()
      )
    ''');
    await conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_wh_user_permissions_wh
          ON public.warehouse_user_permissions (warehouse_id)
    ''');
    _tableReady = true;
  }

  /// Is warehouse ke saare customized users → granted keys.
  Future<Map<String, Set<String>>> getCustomized() async {
    await ensureTable();
    final conn = await DatabaseService.getConnection();
    final res = await conn.execute(
      Sql.named('''
        SELECT user_id::text AS user_id, perm_keys
        FROM public.warehouse_user_permissions
        WHERE warehouse_id = @wid
      '''),
      parameters: {'wid': AppConfig.warehouseId},
    );
    final out = <String, Set<String>>{};
    for (final row in res) {
      final m    = row.toColumnMap();
      final raw  = m['perm_keys'];
      final keys = raw is List
          ? raw.map((e) => e.toString()).toSet()
          : <String>{};
      out[m['user_id'].toString()] = keys;
    }
    return out;
  }

  /// User ke exact keys save (poori list overwrite).
  Future<void> save(
    String userId,
    Set<String> keys, {
    String? byUserId,
    String? byUserName,
  }) async {
    await ensureTable();
    final conn = await DatabaseService.getConnection();
    final list = keys.toList()..sort();
    await conn.execute(
      Sql.named('''
        INSERT INTO public.warehouse_user_permissions
            (user_id, warehouse_id, perm_keys, updated_by, updated_by_name,
             created_at, updated_at)
        VALUES (@uid::uuid, @wid::uuid, @keys::text[], @by::uuid, @byName,
                now(), now())
        ON CONFLICT (user_id) DO UPDATE SET
            perm_keys       = EXCLUDED.perm_keys,
            updated_by      = EXCLUDED.updated_by,
            updated_by_name = EXCLUDED.updated_by_name,
            updated_at      = now()
      '''),
      parameters: {
        'uid':    userId,
        'wid':    AppConfig.warehouseId,
        'keys':   TypedValue(Type.textArray, list),
        'by':     (byUserId == null || byUserId.isEmpty) ? null : byUserId,
        'byName': byUserName,
      },
    );
  }

  /// Customization hatao → user wapas role defaults par.
  Future<void> resetToDefaults(String userId) async {
    await ensureTable();
    final conn = await DatabaseService.getConnection();
    await conn.execute(
      Sql.named('''
        DELETE FROM public.warehouse_user_permissions WHERE user_id = @uid::uuid
      '''),
      parameters: {'uid': userId},
    );
  }
}
