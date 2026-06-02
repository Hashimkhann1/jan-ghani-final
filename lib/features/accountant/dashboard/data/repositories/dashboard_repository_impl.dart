import '../../domain/repositories/dashboard_repository.dart';
import '../datasource/dashboard_remote_datasource.dart';
import '../model/dashboard_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDatasource datasource;
  const DashboardRepositoryImpl(this.datasource);

  @override
  Future<JanghaniAmountModel?> getJanghaniAmount() =>
      datasource.getJanghaniAmount();

  @override
  Future<List<RecentTransactionModel>> getRecentTransactions() =>
      datasource.getRecentTransactions();
}