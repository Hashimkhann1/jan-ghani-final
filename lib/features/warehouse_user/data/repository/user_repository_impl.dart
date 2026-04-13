import '../../domain/repository/i_user_repository.dart';
import '../datasource/user_remote_datasource.dart';
import '../model/user_model.dart';

class UserRepositoryImpl implements IUserRepository {
  final UserRemoteDataSource _ds;
  UserRepositoryImpl() : _ds = UserRemoteDataSource();

  @override Future<List<UserModel>> getAll(String warehouseId) =>
      _ds.getAll(warehouseId);
  @override Future<UserModel?>      getById(String id)          =>
      _ds.getById(id);
  @override Future<UserModel>       add(UserModel u)             =>
      _ds.add(u);
  @override Future<UserModel>       update(UserModel u)          =>
      _ds.update(u);
  @override Future<void>            delete(String id)            =>
      _ds.delete(id);
  @override Future<bool> usernameExists(String u, String wid,
      {String? excludeId}) =>
      _ds.usernameExists(u, wid, excludeId: excludeId);
}
