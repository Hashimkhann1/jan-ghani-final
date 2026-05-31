import '../../domain/repositories/accountant_finance_repository.dart';
import '../datasource/accountant_finance_remote_datasource.dart';
import '../model/accountant_finance_model.dart';

class AccountantFinanceRepositoryImpl implements AccountantFinanceRepository {
  final AccountantFinanceRemoteDatasource datasource;
  const AccountantFinanceRepositoryImpl(this.datasource);

  @override
  Future<AccFinanceSummary> getSummary(String warehouseId) =>
      datasource.getSummary(warehouseId);

  @override
  Future<List<AccCashTransactionModel>> getTransactions(String warehouseId) =>
      datasource.getTransactions(warehouseId);
}
