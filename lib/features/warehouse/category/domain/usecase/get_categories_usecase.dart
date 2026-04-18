import '../../data/model/category_model.dart';
import '../repository/i_category_repository.dart';

class GetCategoriesUseCase {
  final ICategoryRepository _repo;
  GetCategoriesUseCase(this._repo);
  Future<List<CategoryModel>> call(String warehouseId) =>
      _repo.getAll(warehouseId);
}
