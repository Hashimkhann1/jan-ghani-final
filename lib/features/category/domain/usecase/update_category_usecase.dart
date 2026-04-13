import '../../data/model/category_model.dart';
import '../repository/i_category_repository.dart';

class UpdateCategoryUseCase {
  final ICategoryRepository _repo;
  UpdateCategoryUseCase(this._repo);
  Future<CategoryModel> call(CategoryModel category) =>
      _repo.update(category);
}
