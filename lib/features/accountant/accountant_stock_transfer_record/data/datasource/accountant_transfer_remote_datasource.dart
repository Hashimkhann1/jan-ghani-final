// Updated on 2026-09-25 04:51 PM
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_transfer_model.dart';

abstract class AccountantTransferRemoteDatasource {
  Future<List<AccTransferModel>> getAllTransfers(String warehouseId);
  Future<List<AccTransferItemModel>> getTransferItems(String transferId);
}

class AccountantTransferRemoteDatasourceImpl
    implements AccountantTransferRemoteDatasource {
  final SupabaseClient _client;
  const AccountantTransferRemoteDatasourceImpl(this._client);

  // ── Sare transfers ──────────────────────────────────────────
  @override
  Future<List<AccTransferModel>> getAllTransfers(String warehouseId) async {
    try {
      final res = await _client
          .from('stock_transfers')
          .select(
            'id, transfer_number, to_store_name, status, assigned_by_name, '
            'assigned_at, notes, total_items, total_cost, total_sale_price, '
            'created_at',
          )
          .eq('warehouse_id', warehouseId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => AccTransferModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getAllTransfers error: $e');
      rethrow;
    }
  }

  // ── Ek transfer ke items ────────────────────────────────────
  @override
  Future<List<AccTransferItemModel>> getTransferItems(
      String transferId) async {
    try {
      // Note: `unit_cost` column stock_transfer_items par kabhi populate nahi
      // hoti (assign_stock flow sirf `purchase_price`/`sale_price` insert
      // karta hai). Isliye price display ke liye `purchase_price` use karo.
      final res = await _client
          .from('stock_transfer_items')
          .select(
              'id, product_name, sku, unit_of_measure, quantity_sent, '
              'quantity_received, purchase_price, sale_price, total_cost')
          .eq('transfer_id', transferId);

      return (res as List)
          .map((e) =>
              AccTransferItemModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getTransferItems error: $e');
      rethrow;
    }
  }
}
