import 'dart:async';

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

// ── Dedicated Cash Requests screen abhi khuli hai? ───────────────────────────
// Screen initState par true, dispose par false. SideBar ka global listener
// isko dekh kar usi screen par dobara global dialog nahi dikhata (wahan
// pehle se cards mojood hote hain).
final cashRequestsScreenActiveProvider = StateProvider<bool>((ref) => false);

// ── Accept / Reject actions ──────────────────────────────────────────────────
final cashRequestActionProvider = Provider((ref) => CashRequestAction());

class CashRequestAction {
  final _client = Supabase.instance.client;

  // Offline mein Supabase HTTP client throw nahi karta — HANG karta hai,
  // isliye status update par timeout zaroori (warna Accept/Reject button
  // hamesha atka rehta). assign_stock jaisa 6s pattern.
  static const _kRemoteTimeout = Duration(seconds: 6);

  // ── ACCEPT ──────────────────────────────────────────────────
  // 1) Supabase status = accepted (guarded) → trigger reserve release
  // 2) Local warehouse_cash_transactions cash_in → local cash_in_hand plus,
  //    is_synced = false (baad mein Supabase sync ho jayega)
  Future<void> accept(WarehouseCashRequestModel req) async {
    final user = await AuthLocalStorage.loadUser();
    final userId   = user?['id']?.toString();
    final userName = user?['full_name']?.toString() ??
        user?['name']?.toString() ??
        'Warehouse';

    // Step 1: Supabase status update (guarded + offline-safe)
    await _updateStatusGuarded(
      req: req,
      status: 'accepted',
      userId: userId,
      userName: userName,
    );

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
  // Status = rejected (guarded). Trigger reserve release karega +
  // accountant ka reserved cash wapas cash_in_hand mein plus karega.
  Future<void> reject(WarehouseCashRequestModel req) async {
    final user = await AuthLocalStorage.loadUser();
    final userId   = user?['id']?.toString();
    final userName = user?['full_name']?.toString() ??
        user?['name']?.toString() ??
        'Warehouse';

    await _updateStatusGuarded(
      req: req,
      status: 'rejected',
      userId: userId,
      userName: userName,
    );
  }

  // ── Shared: status update (pending-guard + timeout + network detect) ──
  // Sirf tab update karta hai jab row abhi bhi 'pending' ho → trigger
  // exactly-once fire hota hai. Offline/timeout par friendly error, koi hang nahi.
  Future<void> _updateStatusGuarded({
    required WarehouseCashRequestModel req,
    required String status,
    required String? userId,
    required String userName,
  }) async {
    List updated;
    try {
      updated = await _client
          .from('janghani_warehouse_cash_transfers')
          .update({
            'status':            status,
            'responded_by_id':   userId,
            'responded_by_name': userName,
            'responded_at':      DateTime.now().toIso8601String(),
          })
          .eq('id', req.id)
          .eq('status', 'pending')
          .select()
          .timeout(_kRemoteTimeout) as List;
    } on TimeoutException {
      throw Exception('Internet nahi — online hokar dobara koshish karein');
    } catch (e) {
      if (_isNetworkError(e)) {
        throw Exception('Internet nahi — online hokar dobara koshish karein');
      }
      rethrow;
    }

    // Koi row update nahi hui → already accept/reject ho chuki
    if (updated.isEmpty) {
      throw Exception('Yeh request pehle hi process ho chuki hai');
    }
  }

  // Internet/connection error detect (SocketException, host lookup fail, etc.)
  bool _isNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('clientexception') ||
        s.contains('nodename nor servname') ||
        s.contains('network is unreachable') ||
        s.contains('connection closed') ||
        s.contains('connection refused') ||
        s.contains('connection timed out') ||
        s.contains('errno = 8') ||
        s.contains('errno = 7');
  }
}
