import '../../data/model/customer_model.dart';
import '../repository/i_customer_repository.dart';

class GetCustomersUseCase {
  final ICustomerRepository _repo;
  GetCustomersUseCase(this._repo);

  Future<List<CustomerModel>> call(String storeId) =>
      _repo.getAll(storeId);
}