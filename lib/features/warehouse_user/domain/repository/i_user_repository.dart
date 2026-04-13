import '../../data/model/user_model.dart';

abstract class IUserRepository {
  Future<List<UserModel>> getAll(String warehouseId);
  Future<UserModel?>      getById(String id);
  Future<UserModel>       add(UserModel user);
  Future<UserModel>       update(UserModel user);
  Future<void>            delete(String id);
  Future<bool>            usernameExists(String username, String warehouseId,
      {String? excludeId});
}
