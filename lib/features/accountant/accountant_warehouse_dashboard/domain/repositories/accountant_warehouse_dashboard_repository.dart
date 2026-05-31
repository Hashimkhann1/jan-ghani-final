import '../../data/model/accountant_warehouse_dashboard_model.dart';

abstract class WarehouseDashboardRepository {
  Future<WarehouseDashboardModel> getStats(String warehouseId);
}
