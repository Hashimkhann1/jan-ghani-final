import 'package:postgres/postgres.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import '../model/user_model.dart';

class UserRemoteDataSource {

  // ── GET ALL ───────────────────────────────────────────────
  Future<List<UserModel>> getAll(String warehouseId) async {
    final conn = await DatabaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, warehouse_id, username, password_hash,
          full_name, phone, role, is_active,
          last_login, created_at, updated_at, deleted_at
        FROM users
        WHERE warehouse_id = @warehouseId
          AND deleted_at   IS NULL
        ORDER BY created_at DESC
      '''),
      parameters: {'warehouseId': warehouseId},
    );

    return result.map((row) => UserModel.fromMap(_toMap(row))).toList();
  }

  // ── GET BY ID ─────────────────────────────────────────────
  Future<UserModel?> getById(String id) async {
    final conn = await DatabaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, warehouse_id, username, password_hash,
          full_name, phone, role, is_active,
          last_login, created_at, updated_at, deleted_at
        FROM users
        WHERE id = @id AND deleted_at IS NULL
        LIMIT 1
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return UserModel.fromMap(_toMap(result.first));
  }

  // ── ADD ───────────────────────────────────────────────────
  Future<UserModel> add(UserModel user) async {
    final conn = await DatabaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        INSERT INTO users (
          warehouse_id, username, password_hash,
          full_name, phone, role, is_active
        ) VALUES (
          @warehouseId, @username, @passwordHash,
          @fullName, @phone, @role, @isActive
        )
        RETURNING *
      '''),
      parameters: {
        'warehouseId':  user.warehouseId,
        'username':     user.username,
        'passwordHash': user.passwordHash,
        'fullName':     user.fullName,
        'phone':        user.phone,
        'role':         user.role,
        'isActive':     user.isActive,
      },
    );

    return UserModel.fromMap(_toMap(result.first));
  }

  // ── UPDATE ────────────────────────────────────────────────
  Future<UserModel> update(UserModel user) async {
    final conn = await DatabaseService.getConnection();

    await conn.execute(
      Sql.named('''
        UPDATE users SET
          full_name  = @fullName,
          phone      = @phone,
          role       = @role,
          is_active  = @isActive
          ${user.passwordHash.isNotEmpty ? ', password_hash = @passwordHash' : ''}
        WHERE id = @id
      '''),
      parameters: {
        'id':       user.id,
        'fullName': user.fullName,
        'phone':    user.phone,
        'role':     user.role,
        'isActive': user.isActive,
        if (user.passwordHash.isNotEmpty)
          'passwordHash': user.passwordHash,
      },
    );

    return (await getById(user.id))!;
  }

  // ── SOFT DELETE ───────────────────────────────────────────
  Future<void> delete(String id) async {
    final conn = await DatabaseService.getConnection();

    await conn.execute(
      Sql.named('''
        UPDATE users
        SET deleted_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );
  }

  // ── USERNAME EXISTS CHECK ─────────────────────────────────
  Future<bool> usernameExists(String username, String warehouseId,
      {String? excludeId}) async {
    final conn = await DatabaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT 1 FROM users
        WHERE username     = @username
          AND warehouse_id = @warehouseId
          AND deleted_at   IS NULL
          ${excludeId != null ? 'AND id != @excludeId' : ''}
        LIMIT 1
      '''),
      parameters: {
        'username':    username,
        'warehouseId': warehouseId,
        if (excludeId != null) 'excludeId': excludeId,
      },
    );

    return result.isNotEmpty;
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
