import '../../data/model/user_model.dart';
import '../repository/i_user_repository.dart';

class UpdateUserUseCase {
  final IUserRepository _repo;
  UpdateUserUseCase(this._repo);
  Future<UserModel> call(UserModel user) => _repo.update(user);
}
