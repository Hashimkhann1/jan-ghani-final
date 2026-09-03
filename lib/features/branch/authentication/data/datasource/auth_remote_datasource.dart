import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';
import '../../../../../core/service/security/password_hasher.dart';
import '../../../store_user/data/model/user_model.dart';

/// Thrown when we cannot even reach the database, so callers can tell a real
/// "no branch configured" state apart from a transient connection failure.
class AuthConnectionException implements Exception {
  final Object cause;
  AuthConnectionException(this.cause);
  @override
  String toString() => 'AuthConnectionException: $cause';
}

class AuthRemoteDataSource {

  /// Returns true when the local DB already has a branch row.
  /// Throws [AuthConnectionException] only when the DB is unreachable — a
  /// query-level error still resolves to `false` so a fresh install can reach
  /// the setup screen.
  Future<bool> hasBranchData() async {
    final Connection conn;
    try {
      conn = await DataBaseService.getConnection();
    } catch (e) {
      throw AuthConnectionException(e);
    }
    try {
      final result = await conn.execute(
        Sql.named('SELECT COUNT(*) AS cnt FROM public.branch'),
      );
      final count = result.first.toColumnMap()['cnt'];
      return (count as int? ?? 0) > 0;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel?> login(String username, String password) async {
    final conn = await DataBaseService.getConnection();
    final uname = username.trim().toLowerCase();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, username, password_hash,
          full_name, phone, role, is_active,
          counter_id, last_login,
          created_at, updated_at, deleted_at
        FROM public.branch_users
        WHERE LOWER(username) = @username
          AND is_active       = TRUE
          AND deleted_at      IS NULL
        LIMIT 1
      '''),
      parameters: {'username': uname},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    final map = row.toColumnMap();
    final stored = map['password_hash']?.toString() ?? '';

    if (!PasswordHasher.verify(
      username: uname,
      password: password,
      stored: stored,
    )) {
      return null;
    }

    final rawId = map['id'];

    // Lazily upgrade a legacy plaintext row to a hash.
    if (!PasswordHasher.looksHashed(stored)) {
      await _bestEffort(() => conn.execute(
            Sql.named('''
              UPDATE public.branch_users
              SET password_hash = @hash, updated_at = NOW()
              WHERE id = @id
            '''),
            parameters: {
              'hash': PasswordHasher.hash(uname, password),
              'id': rawId,
            },
          ));
    }

    // Best-effort last-login stamp; must never block a valid login.
    await _bestEffort(() => conn.execute(
          Sql.named('''
            UPDATE public.branch_users
            SET last_login = NOW(), updated_at = NOW()
            WHERE id = @id
          '''),
          parameters: {'id': rawId},
        ));

    return UserModel.fromMap(_toMap(row));
  }

  /// Re-fetch a user by id for session restore. Returns null if the account is
  /// now inactive or deleted, so a stale session gets logged out.
  Future<UserModel?> getActiveById(String id) async {
    final conn = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, username, password_hash,
          full_name, phone, role, is_active,
          counter_id, last_login,
          created_at, updated_at, deleted_at
        FROM public.branch_users
        WHERE id        = @id
          AND is_active  = TRUE
          AND deleted_at IS NULL
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(_toMap(result.first));
  }

  Future<void> _bestEffort(Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      // ignore — non critical side effect
    }
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
