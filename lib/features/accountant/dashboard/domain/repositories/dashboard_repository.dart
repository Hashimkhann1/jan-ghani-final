import '../../data/model/dashboard_model.dart';

abstract class DashboardRepository {
  Future<JanghaniAmountModel?> getJanghaniAmount();
  Future<List<RecentTransactionModel>> getRecentTransactions();
}