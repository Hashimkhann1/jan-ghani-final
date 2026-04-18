import '../../data/model/customer_model.dart';

abstract class ICustomerRepository {
  Future<List<CustomerModel>> getAll(String storeId);
  Future<CustomerModel?>      getById(String id);
  Future<CustomerModel>       add(CustomerModel customer);
  Future<CustomerModel>       update(CustomerModel customer);
  Future<void>                delete(String id);
  Future<String>              generateCode(String storeId);
}