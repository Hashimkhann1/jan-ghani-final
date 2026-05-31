import '../../data/model/accountant_order_model.dart';

abstract class AccountantOrdersRepository {
  Future<List<AccOrderModel>> getAllOrders(String warehouseId);
  Future<List<AccOrderItemModel>> getOrderItems(String poId);
}
