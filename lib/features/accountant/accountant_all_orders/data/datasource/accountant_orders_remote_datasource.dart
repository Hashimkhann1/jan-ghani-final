import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_order_model.dart';

abstract class AccountantOrdersRemoteDatasource {
  Future<List<AccOrderModel>> getAllOrders(String warehouseId);
  Future<List<AccOrderItemModel>> getOrderItems(String poId);
}

class AccountantOrdersRemoteDatasourceImpl
    implements AccountantOrdersRemoteDatasource {
  final SupabaseClient _client;
  const AccountantOrdersRemoteDatasourceImpl(this._client);

  // ── Sare orders (supplier name embedded) ────────────────────
  @override
  Future<List<AccOrderModel>> getAllOrders(String warehouseId) async {
    try {
      final res = await _client
          .from('purchase_orders')
          .select(
            'id, po_number, order_date, expected_date, received_date, status, '
            'subtotal, discount_amount, tax_amount, total_amount, paid_amount, '
            'notes, created_by_name, created_at, suppliers(name, company_name)',
          )
          .eq('warehouse_id', warehouseId)
          .filter('deleted_at', 'is', null)
          .order('order_date', ascending: false);

      return (res as List)
          .map((e) => AccOrderModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getAllOrders error: $e');
      rethrow;
    }
  }

  // ── Ek order ke items ───────────────────────────────────────
  @override
  Future<List<AccOrderItemModel>> getOrderItems(String poId) async {
    try {
      final res = await _client
          .from('purchase_order_items')
          .select(
              'id, product_name, sku, quantity_ordered, quantity_received, '
              'unit_cost, total_cost')
          .eq('po_id', poId);

      return (res as List)
          .map((e) => AccOrderItemModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getOrderItems error: $e');
      rethrow;
    }
  }
}
