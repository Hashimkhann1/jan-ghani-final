import '../../data/model/company_model.dart';
import '../repository/i_company_repository.dart';

class AddCompanyUseCase {
  final ICompanyRepository _repo;
  AddCompanyUseCase(this._repo);
  Future<CompanyModel> call(CompanyModel company) => _repo.add(company);
}
