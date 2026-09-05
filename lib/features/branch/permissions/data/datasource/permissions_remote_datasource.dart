import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';

/// `branch_user_permissions` + `branch_users.permissions_customized` par
/// CRUD. Schema: [permission.sql] (isi feature folder me).
class PermissionsRemoteDataSource {
  /// Store ke saare "customized" users ka granted-keys map load karta hai.
  /// Jo user is map me nahi hai, uske liye role default use ho (koi row
  /// hi nahi banti jab tak explicitly save na kiya jaye).
  Future<Map<String, Set<String>>> getCustomizedForStore(
      String storeId) async {
    final conn = await DataBaseService.getConnection();

    final customizedRows = await conn.execute(
      Sql.named('''
        SELECT id FROM public.branch_users
        WHERE store_id = @storeId AND permissions_customized = true
      '''),
      parameters: {'storeId': storeId},
    );
    final customizedIds = customizedRows
        .map((r) => r.toColumnMap()['id'].toString())
        .toList();
    if (customizedIds.isEmpty) return {};

    final permRows = await conn.execute(
      Sql.named('''
        SELECT user_id, perm_key FROM public.branch_user_permissions
        WHERE user_id = ANY(@ids::uuid[])
      '''),
      parameters: {'ids': customizedIds},
    );

    final out = <String, Set<String>>{
      for (final id in customizedIds) id: <String>{},
    };
    for (final row in permRows) {
      final m   = row.toColumnMap();
      final uid = m['user_id'].toString();
      out.putIfAbsent(uid, () => <String>{}).add(m['perm_key'].toString());
    }
    return out;
  }

  /// User ke exact granted keys save karo (poori list overwrite hoti hai).
  Future<void> save(String userId, Set<String> keys) async {
    final conn = await DataBaseService.getConnection();
    await conn.runTx((tx) async {
      await tx.execute(
        Sql.named('''
          UPDATE public.branch_users
          SET permissions_customized = true, updated_at = NOW()
          WHERE id = @userId
        '''),
        parameters: {'userId': userId},
      );
      await tx.execute(
        Sql.named('''
          DELETE FROM public.branch_user_permissions WHERE user_id = @userId
        '''),
        parameters: {'userId': userId},
      );
      for (final key in keys) {
        await tx.execute(
          Sql.named('''
            INSERT INTO public.branch_user_permissions (user_id, perm_key)
            VALUES (@userId, @key)
            ON CONFLICT DO NOTHING
          '''),
          parameters: {'userId': userId, 'key': key},
        );
      }
    });
  }

  /// Customization hata do — user wapas role defaults par chala jaye.
  Future<void> resetToDefaults(String userId) async {
    final conn = await DataBaseService.getConnection();
    await conn.runTx((tx) async {
      await tx.execute(
        Sql.named('''
          UPDATE public.branch_users
          SET permissions_customized = false, updated_at = NOW()
          WHERE id = @userId
        '''),
        parameters: {'userId': userId},
      );
      await tx.execute(
        Sql.named('''
          DELETE FROM public.branch_user_permissions WHERE user_id = @userId
        '''),
        parameters: {'userId': userId},
      );
    });
  }
}
