import '../entities/accountant_user_entity.dart';

abstract class AccountantAuthRepository {
  Future<AccountantUserEntity?> login({
    required String username,
    required String password,
  });

  Future<void> saveSession(AccountantUserEntity user);

  Future<AccountantUserEntity?> getSession();

  Future<void> clearSession();
}