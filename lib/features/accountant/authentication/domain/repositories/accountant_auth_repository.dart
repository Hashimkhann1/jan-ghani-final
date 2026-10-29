import '../entities/accountant_user_entity.dart';

abstract class AccountantAuthRepository {
  Future<AccountantUserEntity?> login({
    required String username,
    required String password,
  });

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signInWithGoogle();

  Future<AccountantUserEntity?> profileOfCurrentSession();

  Future<void> signOut();

  Future<void> connectCustomerAccount(String customerId);


  Future<void> connectBranchUserAccount(String branchUserId);

  Future<void> saveSession(AccountantUserEntity user);

  Future<AccountantUserEntity?> getSession();

  Future<void> clearSession();
}