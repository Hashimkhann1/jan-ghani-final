import '../../data/model/dashboard_model.dart';

abstract class DashboardRepository {
  Future<AccountantCounterModel?> getCounter({required String accountantId});
  Future<List<RecentTransactionModel>> getRecentTransactions({required String accountantId});
}