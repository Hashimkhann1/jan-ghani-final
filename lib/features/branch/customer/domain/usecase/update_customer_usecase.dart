import '../../data/model/customer_model.dart';
import '../repository/i_customer_repository.dart';

class UpdateCustomerUseCase {
  final ICustomerRepository _repo;
  UpdateCustomerUseCase(this._repo);

  Future<CustomerModel> call(CustomerModel customer) =>
      _repo.update(customer);
}