import '../repository/i_company_repository.dart';

class DeleteCompanyUseCase {
  final ICompanyRepository _repo;
  DeleteCompanyUseCase(this._repo);
  Future<void> call(String id) => _repo.delete(id);
}
