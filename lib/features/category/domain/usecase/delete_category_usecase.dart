import '../repository/i_category_repository.dart';

class DeleteCategoryUseCase {
  final ICategoryRepository _repo;
  DeleteCategoryUseCase(this._repo);
  Future<void> call(String id) => _repo.delete(id);
}
