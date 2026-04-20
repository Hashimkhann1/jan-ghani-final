import '../../domain/repositories/dashboard_repository.dart';
import '../datasource/dashboard_remote_datasource.dart';
import '../model/dashboard_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDatasource datasource;
  const DashboardRepositoryImpl(this.datasource);

  @override
  Future<AccountantCounterModel?> getCounter({required String accountantId}) =>
      datasource.getCounter(accountantId: accountantId);

  @override
  Future<List<RecentTransactionModel>> getRecentTransactions({required String accountantId}) =>
      datasource.getRecentTransactions(accountantId: accountantId);
}