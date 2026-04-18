import '../repository/i_customer_repository.dart';

class DeleteCustomerUseCase {
  final ICustomerRepository _repo;
  DeleteCustomerUseCase(this._repo);

  Future<void> call(String id) => _repo.delete(id);
}