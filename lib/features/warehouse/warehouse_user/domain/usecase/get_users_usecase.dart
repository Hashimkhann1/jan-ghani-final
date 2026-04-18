import '../../data/model/user_model.dart';
import '../repository/i_user_repository.dart';

class GetUsersUseCase {
  final IUserRepository _repo;
  GetUsersUseCase(this._repo);
  Future<List<UserModel>> call(String warehouseId) =>
      _repo.getAll(warehouseId);
}
