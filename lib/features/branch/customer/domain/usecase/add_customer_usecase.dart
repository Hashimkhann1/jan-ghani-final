import '../../data/model/customer_model.dart';
import '../repository/i_customer_repository.dart';

class AddCustomerUseCase {
  final ICustomerRepository _repo;
  AddCustomerUseCase(this._repo);

  Future<CustomerModel> call(CustomerModel customer) =>
      _repo.add(customer);
}