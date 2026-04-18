import '../../data/model/user_model.dart';
import '../repository/i_user_repository.dart';


class GetUsersUseCase {
  final IUserRepository _repo;
  GetUsersUseCase(this._repo);
  Future<List<UserModel>> call(String storeId) => _repo.getAll(storeId);
}
