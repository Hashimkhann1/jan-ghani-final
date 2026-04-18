import '../../domain/repository/i_customer_repository.dart';
import '../datasource/customer_remote_datasource.dart';
import '../model/customer_model.dart';

class CustomerRepositoryImpl implements ICustomerRepository {
  final CustomerRemoteDataSource _dataSource;

  CustomerRepositoryImpl({CustomerRemoteDataSource? dataSource}) : _dataSource = dataSource ?? CustomerRemoteDataSource();

  @override
  Future<List<CustomerModel>> getAll(String storeId) => _dataSource.getAll(storeId);

  @override
  Future<CustomerModel?> getById(String id) => _dataSource.getById(id);

  @override
  Future<CustomerModel> add(CustomerModel customer) => _dataSource.add(customer);

  @override
  Future<CustomerModel> update(CustomerModel customer) => _dataSource.update(customer);

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  @override
  Future<String> generateCode(String storeId) => _dataSource.generateCode(storeId);
}