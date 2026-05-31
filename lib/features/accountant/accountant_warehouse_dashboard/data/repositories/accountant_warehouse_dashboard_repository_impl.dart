import '../../domain/repositories/accountant_warehouse_dashboard_repository.dart';
import '../datasource/accountant_warehouse_dashboard_remote_datasource.dart';
import '../model/accountant_warehouse_dashboard_model.dart';

class WarehouseDashboardRepositoryImpl
    implements WarehouseDashboardRepository {
  final WarehouseDashboardRemoteDatasource datasource;
  const WarehouseDashboardRepositoryImpl(this.datasource);

  @override
  Future<WarehouseDashboardModel> getStats(String warehouseId) =>
      datasource.getStats(warehouseId);
}
