import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/auth/local/auth_local_storage.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/data/warehouse_finance_repository.dart';
import '../../data/model/warehouse_cash_request_model.dart';

// ── Pending cash requests (REALTIME) ─────────────────────────────────────────
// Supabase .stream() — accountant cash bheje to turant card aa jayega
// (app restart ki zaroorat nahi)
final pendingCashRequestsProvider =
    StreamProvider<List<WarehouseCashRequestModel>>((ref) {
  return Supabase.instance.client
      .from('janghani_warehouse_cash_transfers')
      .stream(primaryKey: ['id'])
      .eq('warehouse_id', AppConfig.warehouseId)
      .order('created_at', ascending: false)
      .map((rows) => rows
          // status filter client-side (stream sirf ek eq filter deta hai)
          .where((e) => (e['status']?.toString() ?? '') == 'pending')
          .map((e) => WarehouseCashRequestModel.fromMap(e))
          .toList());
});

// ── Accept / Reject actions ──────────────────────────────────────────────────
final cashRequestActionProvider = Provider((ref) => CashRequestAction());

class CashRequestAction {
  final _client = Supabase.instance.client;

  // ── ACCEPT ──────────────────────────────────────────────────
  // 1) Supabase status = accepted (guarded) → trigger accountant cash minus
  // 2) Local warehouse_cash_transactions cash_in → local cash_in_hand plus,
  //    is_synced = false (baad mein Supabase sync ho jayega)
  Future<void> accept(WarehouseCashRequestModel req) async {
    final user = await AuthLocalStorage.loadUser();
    final userId   = user?['id']?.toString();
    final userName = user?['full_name']?.toString() ??
        user?['name']?.toString() ??
        'Warehouse';

    // Step 1: Supabase status update (sirf agar abhi bhi pending hai)
    final updated = await _client
        .from('janghani_warehouse_cash_transfers')
        .update({
          'status':            'accepted',
          'responded_by_id':   userId,
          'responded_by_name': userName,
          'responded_at':      DateTime.now().toIso8601String(),
        })
        .eq('id', req.id)
        .eq('status', 'pending')
        .select();

    // Agar koi row update nahi hui (already accept/reject) to ruk jao
    if ((updated as List).isEmpty) {
      throw Exception('Yeh request pehle hi process ho chuki hai');
    }

    // Step 2: Local cash in hand barhao (trigger + sync handle karega)
    await WarehouseFinanceRepository.instance.addCashIn(
      amount: req.amount,
      notes: 'Cash received from accountant'
          '${req.sentByName != null ? ' — ${req.sentByName}' : ''}',
      createdBy: userId,
      createdByName: userName,
    );
  }

  // ── REJECT ──────────────────────────────────────────────────
  // Sirf status = rejected. Accountant ka cash minus hua hi nahi tha.
  Future<void> reject(WarehouseCashRequestModel req) async {
    final user = await AuthLocalStorage.loadUser();
    final userId   = user?['id']?.toString();
    final userName = user?['full_name']?.toString() ??
        user?['name']?.toString() ??
        'Warehouse';

    await _client
        .from('janghani_warehouse_cash_transfers')
        .update({
          'status':            'rejected',
          'responded_by_id':   userId,
          'responded_by_name': userName,
          'responded_at':      DateTime.now().toIso8601String(),
        })
        .eq('id', req.id)
        .eq('status', 'pending');
  }
}
