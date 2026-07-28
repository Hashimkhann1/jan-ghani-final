// =============================================================
// i_company_repository.dart
// =============================================================

import '../../data/model/company_model.dart';

abstract class ICompanyRepository {
  Future<List<CompanyModel>> getAll(String warehouseId);
  Future<CompanyModel?>      getById(String id);
  Future<CompanyModel>       add(CompanyModel company);
  Future<CompanyModel>       update(CompanyModel company);
  Future<void>               delete(String id);
  Future<bool>               nameExists(String name, String warehouseId,
      {String? excludeId});
}
