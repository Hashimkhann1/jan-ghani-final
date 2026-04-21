import '../entities/accountant_user_entity.dart';
import '../repositories/accountant_auth_repository.dart';

class SaveSessionUseCase {
  final AccountantAuthRepository repository;
  const SaveSessionUseCase(this.repository);

  Future<void> call(AccountantUserEntity user) => repository.saveSession(user);
}