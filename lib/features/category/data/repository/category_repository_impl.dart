// =============================================================
// category_repository_impl.dart
// =============================================================

import '../../domain/repository/i_category_repository.dart';
import '../datasource/category_remote_datasource.dart';
import '../model/category_model.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  final CategoryRemoteDataSource _ds;
  CategoryRepositoryImpl() : _ds = CategoryRemoteDataSource();

  @override Future<List<CategoryModel>> getAll(String warehouseId) =>
      _ds.getAll(warehouseId);
  @override Future<CategoryModel?>      getById(String id)          =>
      _ds.getById(id);
  @override Future<CategoryModel>       add(CategoryModel c)         =>
      _ds.add(c);
  @override Future<CategoryModel>       update(CategoryModel c)      =>
      _ds.update(c);
  @override Future<void>                delete(String id)            =>
      _ds.delete(id);
  @override Future<bool> nameExists(String name, String warehouseId,
      {String? excludeId}) =>
      _ds.nameExists(name, warehouseId, excludeId: excludeId);
}
