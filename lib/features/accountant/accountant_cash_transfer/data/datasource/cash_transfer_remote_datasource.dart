import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/cash_transfer_model.dart';

abstract class CashTransferRemoteDatasource {
  Future<void> sendCash({
    required String warehouseId,
    required String warehouseName,
    required double amount,
    String? sentById,
    required String sentByName,
    String? notes,
  });

  Future<List<CashTransferModel>> getMyTransfers();
  Future<List<CashTransferModel>> getTransfersByWarehouse(String warehouseId);
}

class CashTransferRemoteDatasourceImpl implements CashTransferRemoteDatasource {
  final SupabaseClient _client;
  const CashTransferRemoteDatasourceImpl(this._client);

  // ── Pending transfer insert karo (accountant cash abhi minus NAHI hoga) ──
  @override
  Future<void> sendCash({
    required String warehouseId,
    required String warehouseName,
    required double amount,
    String? sentById,
    required String sentByName,
    String? notes,
  }) async {
    try {
      await _client.from('janghani_warehouse_cash_transfers').insert({
        'warehouse_id':   warehouseId,
        'warehouse_name': warehouseName,
        'amount':         amount,
        'sent_by_id':     sentById,
        'sent_by_name':   sentByName,
        'status':         'pending',
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
    } catch (e) {
      print('❌ sendCash error: $e');
      rethrow;
    }
  }

  // ── Accountant ke saare bheje hue transfers (status ke saath) ──
  @override
  Future<List<CashTransferModel>> getMyTransfers() async {
    try {
      final res = await _client
          .from('janghani_warehouse_cash_transfers')
          .select(
              'id, warehouse_id, warehouse_name, amount, sent_by_name, '
              'status, notes, responded_by_name, responded_at, created_at')
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => CashTransferModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getMyTransfers error: $e');
      rethrow;
    }
  }

  // ── Selected warehouse ke saare transfers ──
  @override
  Future<List<CashTransferModel>> getTransfersByWarehouse(
      String warehouseId) async {
    try {
      final res = await _client
          .from('janghani_warehouse_cash_transfers')
          .select(
              'id, warehouse_id, warehouse_name, amount, sent_by_name, '
              'status, notes, responded_by_name, responded_at, created_at')
          .eq('warehouse_id', warehouseId)
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => CashTransferModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getTransfersByWarehouse error: $e');
      rethrow;
    }
  }
}
