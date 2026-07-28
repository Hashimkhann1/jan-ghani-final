// =============================================================
// company_repository_impl.dart
// =============================================================

import '../../domain/repository/i_company_repository.dart';
import '../datasource/company_remote_datasource.dart';
import '../model/company_model.dart';

class CompanyRepositoryImpl implements ICompanyRepository {
  final CompanyRemoteDataSource _ds;
  CompanyRepositoryImpl() : _ds = CompanyRemoteDataSource();

  @override Future<List<CompanyModel>> getAll(String warehouseId) =>
      _ds.getAll(warehouseId);
  @override Future<CompanyModel?>      getById(String id)          =>
      _ds.getById(id);
  @override Future<CompanyModel>       add(CompanyModel c)         =>
      _ds.add(c);
  @override Future<CompanyModel>       update(CompanyModel c)      =>
      _ds.update(c);
  @override Future<void>               delete(String id)           =>
      _ds.delete(id);
  @override Future<bool> nameExists(String name, String warehouseId,
      {String? excludeId}) =>
      _ds.nameExists(name, warehouseId, excludeId: excludeId);
}
