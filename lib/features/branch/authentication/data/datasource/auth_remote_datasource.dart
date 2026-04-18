import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../../../store_user/data/model/user_model.dart';

class AuthRemoteDataSource {
  Future<UserModel?> login(String username, String password) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, username, password_hash,
          full_name, phone, role, is_active,
          counter_id, last_login,
          created_at, updated_at, deleted_at
        FROM public.branch_users
        WHERE username      = @username
          AND password_hash = @password
          AND is_active     = TRUE
          AND deleted_at    IS NULL
        LIMIT 1
      '''),
      parameters: {
        'username': username.trim().toLowerCase(),
        'password': password,
      },
    );

    if (result.isEmpty) return null;

    // Last login update
    await conn.execute(
      Sql.named('''
        UPDATE public.branch_users
        SET last_login = NOW(), updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {
        'id': result.first.toColumnMap()['id'].toString(),
      },
    );

    return UserModel.fromMap(_toMap(result.first));
  }

  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':            m['id']?.toString()            ?? '',
      'store_id':      m['store_id']?.toString()      ?? '',
      'username':      m['username']?.toString()      ?? '',
      'password_hash': m['password_hash']?.toString() ?? '',
      'full_name':     m['full_name']?.toString()     ?? '',
      'phone':         m['phone']?.toString(),
      'role':          m['role']?.toString()           ?? 'cashier',
      'is_active':     m['is_active']                 ?? true,
      'counter_id':    m['counter_id']?.toString(),   // ← add
      'last_login':    m['last_login']?.toString(),
      'created_at':    m['created_at']?.toString()    ?? DateTime.now().toIso8601String(),
      'updated_at':    m['updated_at']?.toString()    ?? DateTime.now().toIso8601String(),
      'deleted_at':    m['deleted_at']?.toString(),
    };
  }
}