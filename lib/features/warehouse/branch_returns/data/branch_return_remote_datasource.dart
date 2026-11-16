// Updated on 2026-11-16 09:59 AM
// =============================================================
// branch_return_remote_datasource.dart — Supabase (stock_returns)
//
//   • List / counts — HAR query `warehouse_id` se filter (doosre
//     warehouse ke returns kabhi nazar na aayein)
//   • Status sirf RPC se badalta hai (accept / reject / revert) —
//     app kabhi plain UPDATE nahi karti
//   • Har Supabase call par 6s timeout — offline mein client throw
//     nahi karta, HANG karta hai (S7 / S9 pattern)
// =============================================================

import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/branch_return_model.dart';

/// Internet / timeout ka masla — UI friendly message dikhati hai.
class ReturnNetworkException implements Exception {
  @override
  String toString() => 'Internet nahi — online hokar dobara koshish karein';
}

class BranchReturnRemoteDatasource {
  final SupabaseClient _client;
  final String         _warehouseId;

  BranchReturnRemoteDatasource(this._client, this._warehouseId);

  static const _kTimeout = Duration(seconds: 6);
  static const _kSelect  = '*, stock_return_items(*)';

  Future<T> _guard<T>(Future<T> f) async {
    try {
      return await f.timeout(_kTimeout);
    } on TimeoutException {
      throw ReturnNetworkException();
    } on SocketException {
      throw ReturnNetworkException();
    } catch (e) {
      final s = e.toString().toLowerCase();
      if (s.contains('socketexception') ||
          s.contains('failed host lookup') ||
          s.contains('clientexception') ||
          s.contains('connection refused') ||
          s.contains('network is unreachable')) {
        throw ReturnNetworkException();
      }
      rethrow;
    }
  }

  // PostgREST `.or()` filter ke liye — comma / brackets / % hata do
  static String _sanitize(String s) =>
      s.trim().replaceAll(RegExp(r'[,()%*\\]'), ' ').trim();

  // ── LIST (ek tab, ek page) ─────────────────────────────────
  Future<List<BranchReturn>> fetchPage({
    required String status,
    required int    page,
    required int    pageSize,
    String          search = '',
  }) async {
    final s = _sanitize(search);
    var q = _client
        .from('stock_returns')
        .select(_kSelect)
        .eq('warehouse_id', _warehouseId)
        .eq('status', status)
        .isFilter('deleted_at', null);
    if (s.isNotEmpty) {
      q = q.or('return_number.ilike.%$s%,from_store_name.ilike.%$s%');
    }
    final from = page * pageSize;
    final res  = await _guard(q
        .order('returned_at', ascending: false)
        .range(from, from + pageSize - 1));
    return (res as List)
        .map((e) => BranchReturn.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── COUNTS (teeno tabs, search ke baad) ────────────────────
  Future<Map<String, int>> fetchCounts({String search = ''}) async {
    final s = _sanitize(search);

    Future<int> c(String status) async {
      var q = _client
          .from('stock_returns')
          .count(CountOption.exact)
          .eq('warehouse_id', _warehouseId)
          .eq('status', status)
          .isFilter('deleted_at', null);
      if (s.isNotEmpty) {
        q = q.or('return_number.ilike.%$s%,from_store_name.ilike.%$s%');
      }
      return await q;
    }

    final r = await _guard(
        Future.wait([c('pending'), c('accepted'), c('rejected')]));
    return {'pending': r[0], 'accepted': r[1], 'rejected': r[2]};
  }

  // ── EK RETURN (taaza, items ke saath) ──────────────────────
  Future<BranchReturn?> fetchById(String id) async {
    final res = await _guard(_client
        .from('stock_returns')
        .select(_kSelect)
        .eq('id', id)
        .eq('warehouse_id', _warehouseId)
        .isFilter('deleted_at', null)
        .maybeSingle());
    return res == null ? null : BranchReturn.fromJson(res);
  }

  // ── Safety net: haal hi ke accepted returns ────────────────
  // (app band ho gayi ho accept ke baad lekin local stock add se pehle)
  Future<List<BranchReturn>> fetchRecentAccepted({int days = 30}) async {
    final since = DateTime.now()
        .toUtc()
        .subtract(Duration(days: days))
        .toIso8601String();
    final out = <BranchReturn>[];
    const pageSize = 500;
    for (var from = 0;; from += pageSize) {
      final res = await _guard(_client
          .from('stock_returns')
          .select(_kSelect)
          .eq('warehouse_id', _warehouseId)
          .eq('status', 'accepted')
          .isFilter('deleted_at', null)
          .gte('responded_at', since)
          .order('responded_at', ascending: true)
          .range(from, from + pageSize - 1));
      final rows = (res as List)
          .map((e) => BranchReturn.fromJson(e as Map<String, dynamic>))
          .toList();
      out.addAll(rows);
      if (rows.length < pageSize) break;
    }
    return out;
  }

  // ── RPCs ───────────────────────────────────────────────────
  /// true = humne claim kiya (pending → accepted). false = pehle se handle.
  Future<bool> accept(String returnId,
      {String? userId, String? userName}) async {
    final res = await _guard(_client.rpc('accept_stock_return', params: {
      'p_return_id': returnId,
      'p_user_id':   userId,
      'p_user_name': userName,
    }));
    return (res as Map?)?['success'] == true;
  }

  /// Local stock add fail ho to status wapas pending.
  Future<bool> revertAccept(String returnId) async {
    final res = await _guard(_client.rpc('revert_stock_return_accept',
        params: {'p_return_id': returnId}));
    return (res as Map?)?['success'] == true;
  }

  /// true = reject ho gaya. false = pehle se handle.
  Future<bool> reject(String returnId,
      {String? userId, String? userName, required String reason}) async {
    final res = await _guard(_client.rpc('reject_stock_return', params: {
      'p_return_id': returnId,
      'p_user_id':   userId,
      'p_user_name': userName,
      'p_reason':    reason,
    }));
    return (res as Map?)?['success'] == true;
  }
}
