import '../../data/datasource/customer_ledger_remote_datasource.dart';
import '../../data/model/customer_ledger_model.dart';
import '../repository/i_customer_ledger_repository.dart';
class GetLedgersUseCase {
  final ICustomerLedgerRepository _repo;
  GetLedgersUseCase(this._repo);
  Future<List<CustomerLedgerModel>> call(String storeId, {DateTime? from, DateTime? to}) =>
      _repo.getAll(storeId, from: from, to: to);

  /// Server-side paged fetch.
  Future<LedgerPage> page(
    String storeId, {
    required String counterId,
    DateTime? from,
    DateTime? to,
    String    search = '',
    required int limit,
    required int offset,
  }) =>
      _repo.getPaged(
        storeId,
        counterId: counterId,
        from:   from,
        to:     to,
        search: search,
        limit:  limit,
        offset: offset,
      );
}