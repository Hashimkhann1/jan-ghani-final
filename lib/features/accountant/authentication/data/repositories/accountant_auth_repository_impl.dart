import '../../domain/entities/accountant_user_entity.dart';
import '../../domain/repositories/accountant_auth_repository.dart';
import '../datasources/accountant_auth_local_datasource.dart';
import '../datasources/accountant_auth_remote_datasource.dart';
import '../model/accountant_user_model.dart';

class AccountantAuthRepositoryImpl implements AccountantAuthRepository {
  final AccountantAuthRemoteDatasource remote;
  final AccountantAuthLocalDatasource local;

  const AccountantAuthRepositoryImpl({
    required this.remote,
    required this.local,
  });

  @override
  Future<AccountantUserEntity?> login({
    required String username,
    required String password,
  }) => remote.login(email: username, password: password);

  @override
  Future<void> saveSession(AccountantUserEntity user) async {
    await local.saveUser({
      'id'             : user.id,
      'full_name'      : user.fullName,
      'email'          : user.email,
      'role'           : user.role,
      'branch_id'      : user.branchId,
      'warehouse_id'   : user.warehouseId,
      'customer_token' : user.customerToken,
      'is_active'      : user.isActive,
      'created_at'     : user.createdAt.toIso8601String(),
    });
  }

  @override
  Future<AccountantUserEntity?> getSession() async {
    final map = await local.getUser();
    if (map == null) return null;
    return AccountantUserModel.fromMap(map);
  }

  @override
  Future<void> clearSession() => local.clearUser();
}