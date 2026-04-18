import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/user_model.dart';

class UserRemoteDataSource {

  Future<List<UserModel>> getAll(String storeId) async {
    final conn = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, username, password_hash,
          full_name, phone, role, is_active,
          counter_id, last_login,
          created_at, updated_at, deleted_at
        FROM public.branch_users
        WHERE store_id  = @storeId
          AND deleted_at IS NULL
        ORDER BY created_at DESC
      '''),
      parameters: {'storeId': storeId},
    );
    return result.map((row) => UserModel.fromMap(_toMap(row))).toList();
  }

  Future<UserModel?> getById(String id) async {
    final conn = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, username, password_hash,
          full_name, phone, role, is_active,
          counter_id, last_login,
          created_at, updated_at, deleted_at
        FROM public.branch_users
        WHERE id = @id AND deleted_at IS NULL
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(_toMap(result.first));
  }

  Future<UserModel> add(UserModel user) async {
    final conn = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO public.branch_users
          (store_id, username, password_hash, full_name,
           phone, role, is_active, counter_id)
        VALUES
          (@storeId, @username, @passwordHash, @fullName,
           @phone, @role, @isActive, @counterId)
        RETURNING *
      '''),
      parameters: {
        'storeId':      user.storeId,
        'username':     user.username,
        'passwordHash': user.passwordHash,
        'fullName':     user.fullName,
        'phone':        user.phone,
        'role':         user.role,
        'isActive':     user.isActive,
        'counterId':    user.counterId,
      },
    );
    return UserModel.fromMap(_toMap(result.first));
  }

  Future<UserModel> update(UserModel user) async {
    final conn = await DataBaseService.getConnection();
    await conn.execute(
      Sql.named('''
        UPDATE public.branch_users SET
          full_name   = @fullName,
          phone       = @phone,
          role        = @role,
          is_active   = @isActive,
          counter_id  = @counterId,
          updated_at  = NOW()
          ${user.passwordHash.isNotEmpty ? ', password_hash = @passwordHash' : ''}
        WHERE id = @id
      '''),
      parameters: {
        'id':        user.id,
        'fullName':  user.fullName,
        'phone':     user.phone,
        'role':      user.role,
        'isActive':  user.isActive,
        'counterId': user.counterId,
        if (user.passwordHash.isNotEmpty)
          'passwordHash': user.passwordHash,
      },
    );
    return (await getById(user.id))!;
  }

  Future<void> delete(String id) async {
    final conn = await DataBaseService.getConnection();
    await conn.execute(
      Sql.named('''
        UPDATE public.branch_users
        SET deleted_at = NOW(), updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );
  }

  Future<bool> usernameExists(String username, String storeId,
      {String? excludeId}) async {
    final conn = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT 1 FROM public.branch_users
        WHERE username   = @username
          AND store_id   = @storeId
          AND deleted_at IS NULL
          ${excludeId != null ? 'AND id != @excludeId' : ''}
        LIMIT 1
      '''),
      parameters: {
        'username': username,
        'storeId':  storeId,
        if (excludeId != null) 'excludeId': excludeId,
      },
    );
    return result.isNotEmpty;
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
      'counter_id':    m['counter_id']?.toString(),
      'last_login':    m['last_login']?.toString(),
      'created_at':    m['created_at']?.toString()    ?? DateTime.now().toIso8601String(),
      'updated_at':    m['updated_at']?.toString()    ?? DateTime.now().toIso8601String(),
      'deleted_at':    m['deleted_at']?.toString(),
    };
  }
}