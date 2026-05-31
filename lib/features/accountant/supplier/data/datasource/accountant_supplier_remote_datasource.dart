import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_supplier_model.dart';
import '../model/accountant_supplier_detail_models.dart';

abstract class AccountantSupplierRemoteDatasource {
  Future<List<AccountantSupplierModel>> getAllSuppliers(String warehouseId);
  Future<List<AccSupplierLedgerEntry>> getLedger(String supplierId);
  Future<List<AccSupplierOrder>> getOrders(String supplierId);
  Future<List<AccSupplierOrderItem>> getOrderItems(String poId);
}

class AccountantSupplierRemoteDatasourceImpl
    implements AccountantSupplierRemoteDatasource {
  final SupabaseClient _client;
  const AccountantSupplierRemoteDatasourceImpl(this._client);

  // ── All suppliers (read-only list) ──────────────────────────
  @override
  Future<List<AccountantSupplierModel>> getAllSuppliers(
      String warehouseId) async {
    try {
      final res = await _client
          .from('suppliers')
          .select(
              'id, name, company_name, code, phone, outstanding_balance, is_active')
          .eq('warehouse_id', warehouseId)
          .filter('deleted_at', 'is', null)
          .order('name', ascending: true);

      return (res as List)
          .map((e) =>
              AccountantSupplierModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getAllSuppliers error: $e');
      rethrow;
    }
  }

  // ── Ledger / Transactions ───────────────────────────────────
  @override
  Future<List<AccSupplierLedgerEntry>> getLedger(String supplierId) async {
    try {
      final res = await _client
          .from('supplier_ledger')
          .select(
              'id, po_id, entry_type, amount, balance_after, notes, created_at')
          .eq('supplier_id', supplierId)
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) =>
              AccSupplierLedgerEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getLedger error: $e');
      rethrow;
    }
  }

  // ── Purchase Orders ─────────────────────────────────────────
  @override
  Future<List<AccSupplierOrder>> getOrders(String supplierId) async {
    try {
      final res = await _client
          .from('purchase_orders')
          .select(
              'id, po_number, order_date, received_date, status, subtotal, '
              'discount_amount, tax_amount, total_amount, paid_amount, notes')
          .eq('supplier_id', supplierId)
          .filter('deleted_at', 'is', null)
          .order('order_date', ascending: false);

      return (res as List)
          .map((e) => AccSupplierOrder.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getOrders error: $e');
      rethrow;
    }
  }

  // ── Order Items (PO expand karne par) ───────────────────────
  @override
  Future<List<AccSupplierOrderItem>> getOrderItems(String poId) async {
    try {
      final res = await _client
          .from('purchase_order_items')
          .select(
              'id, product_name, sku, quantity_ordered, quantity_received, '
              'unit_cost, total_cost')
          .eq('po_id', poId);

      return (res as List)
          .map((e) =>
              AccSupplierOrderItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getOrderItems error: $e');
      rethrow;
    }
  }
}
