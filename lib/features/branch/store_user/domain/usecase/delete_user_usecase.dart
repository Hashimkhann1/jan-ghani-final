import '../repository/i_user_repository.dart';
class DeleteUserUseCase {
  final IUserRepository _repo;
  DeleteUserUseCase(this._repo);
  Future<void> call(String id) => _repo.delete(id);
}