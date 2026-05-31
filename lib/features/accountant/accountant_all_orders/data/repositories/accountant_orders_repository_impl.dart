import '../../domain/repositories/accountant_orders_repository.dart';
import '../datasource/accountant_orders_remote_datasource.dart';
import '../model/accountant_order_model.dart';

class AccountantOrdersRepositoryImpl implements AccountantOrdersRepository {
  final AccountantOrdersRemoteDatasource datasource;
  const AccountantOrdersRepositoryImpl(this.datasource);

  @override
  Future<List<AccOrderModel>> getAllOrders(String warehouseId) =>
      datasource.getAllOrders(warehouseId);

  @override
  Future<List<AccOrderItemModel>> getOrderItems(String poId) =>
      datasource.getOrderItems(poId);
}
