import '../../data/model/company_model.dart';
import '../repository/i_company_repository.dart';

class GetCompaniesUseCase {
  final ICompanyRepository _repo;
  GetCompaniesUseCase(this._repo);
  Future<List<CompanyModel>> call(String warehouseId) =>
      _repo.getAll(warehouseId);
}
