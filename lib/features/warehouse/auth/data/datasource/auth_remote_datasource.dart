
import 'package:jan_ghani_final/features/warehouse/warehouse_user/data/model/user_model.dart';
import 'package:postgres/postgres.dart';
import 'package:jan_ghani_final/core/helper/password_helper.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';

class AuthRemoteDataSource {

  Future<UserModel?> login(String username, String password) async {
    final conn = await DatabaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, warehouse_id, username, password_hash,
          full_name, phone, role, is_active,
          last_login, created_at, updated_at, deleted_at
        FROM warehouse_users
        WHERE username     = @username
          AND password_hash = @password
          AND is_active    = TRUE
          AND deleted_at   IS NULL
        LIMIT 1
      '''),
      parameters: {
        'username': username.trim().toLowerCase(),
        'password': PasswordHelper.hash(password), // hash karke compare karo
      },
    );

    if (result.isEmpty) return null;

    // Last login update karo
    await conn.execute(
      Sql.named('''
        UPDATE warehouse_users
        SET last_login = NOW()
        WHERE id = @id
      '''),
      parameters: {
        'id': result.first.toColumnMap()['id'].toString(),
      },
    );

    return UserModel.fromMap(_toMap(result.first));
  }

  // ── ROW → MAP ─────────────────────────────────────────────
  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':            m['id']?.toString()            ?? '',
      'warehouse_id':  m['warehouse_id']?.toString()  ?? '',
      'username':      m['username']?.toString()      ?? '',
      'password_hash': m['password_hash']?.toString() ?? '',
      'full_name':     m['full_name']?.toString()     ?? '',
      'phone':         m['phone']?.toString(),
      'role':          m['role']?.toString()           ?? 'warehouse_staff',
      'is_active':     m['is_active']                  ?? true,
      'last_login':    m['last_login'],
      'created_at':    m['created_at'],
      'updated_at':    m['updated_at'],
      'deleted_at':    m['deleted_at'],
    };
  }
}