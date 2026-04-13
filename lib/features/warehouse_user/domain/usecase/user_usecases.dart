import '../../data/model/user_model.dart';
import '../repository/i_user_repository.dart';

class AddUserUseCase {
  final IUserRepository _repo;
  AddUserUseCase(this._repo);
  Future<UserModel> call(UserModel user) => _repo.add(user);
}

class UpdateUserUseCase {
  final IUserRepository _repo;
  UpdateUserUseCase(this._repo);
  Future<UserModel> call(UserModel user) => _repo.update(user);
}

class DeleteUserUseCase {
  final IUserRepository _repo;
  DeleteUserUseCase(this._repo);
  Future<void> call(String id) => _repo.delete(id);
}
