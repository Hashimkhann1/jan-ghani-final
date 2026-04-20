import '../entities/accountant_user_entity.dart';
import '../repositories/accountant_auth_repository.dart';

class LoginAccountantUseCase {
  final AccountantAuthRepository repository;
  const LoginAccountantUseCase(this.repository);

  Future<AccountantUserEntity?> call({
    required String username,
    required String password,
  }) {
    return repository.login(username: username, password: password);
  }
}