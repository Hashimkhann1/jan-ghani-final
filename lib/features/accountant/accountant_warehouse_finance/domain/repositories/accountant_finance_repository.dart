import '../../data/model/accountant_finance_model.dart';

abstract class AccountantFinanceRepository {
  Future<AccFinanceSummary> getSummary(String warehouseId);
  Future<List<AccCashTransactionModel>> getTransactions(String warehouseId);
}
