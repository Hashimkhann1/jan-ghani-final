import '../../data/model/category_model.dart';
import '../repository/i_category_repository.dart';

class AddCategoryUseCase {
  final ICategoryRepository _repo;
  AddCategoryUseCase(this._repo);
  Future<CategoryModel> call(CategoryModel category) =>
      _repo.add(category);
}
