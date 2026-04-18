// =============================================================
// i_category_repository.dart
// =============================================================

import '../../data/model/category_model.dart';

abstract class ICategoryRepository {
  Future<List<CategoryModel>> getAll(String warehouseId);
  Future<CategoryModel?>      getById(String id);
  Future<CategoryModel>       add(CategoryModel category);
  Future<CategoryModel>       update(CategoryModel category);
  Future<void>                delete(String id);
  Future<bool>                nameExists(String name, String warehouseId,
      {String? excludeId});
}
