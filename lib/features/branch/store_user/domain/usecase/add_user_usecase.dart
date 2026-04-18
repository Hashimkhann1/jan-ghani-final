import '../../data/model/user_model.dart';
import '../repository/i_user_repository.dart';
class AddUserUseCase {
  final IUserRepository _repo;
  AddUserUseCase(this._repo);
  Future<UserModel> call(UserModel user) => _repo.add(user);
}