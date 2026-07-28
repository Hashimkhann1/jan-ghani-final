import '../../data/model/company_model.dart';
import '../repository/i_company_repository.dart';

class UpdateCompanyUseCase {
  final ICompanyRepository _repo;
  UpdateCompanyUseCase(this._repo);
  Future<CompanyModel> call(CompanyModel company) => _repo.update(company);
}
