import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/service/db/db_service.dart';
import '../model/branch_transaction_history_model.dart';

class BranchTransactionDataSource {

  // ── GET branch_cash_counter total_amount ──────────────────────
  Future<double> getBranchTotalAmount(String storeId) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT total_amount FROM public.branch_cash_counter
        WHERE store_id = @storeId AND counter_date = CURRENT_DATE
        ORDER BY updated_at DESC
        LIMIT 1
      '''),
      parameters: {'storeId': storeId},
    );
    if (result.isEmpty) return 0.0;
    final raw = result.first.toColumnMap()['total_amount'];
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  // ── CASH OUT ──────────────────────────────────────────────
  Future<void> cashOut({
    required String branchId,
    required String assignById,
    required String assignByName,
    required double beforeAmount,
    required double payAmount,
    required double afterAmount,
  }) async {
    final conn = await DataBaseService.getConnection();

    // Local money-move is atomic: decrement today's counter (only if it
    // actually has the balance) and record the history row in one tx.
    late String rowId;
    await conn.runTx((tx) async {
      final upd = await tx.execute(
        Sql.named('''
          UPDATE public.branch_cash_counter
          SET total_amount = total_amount - @payAmount,
              cash_out     = cash_out + @payAmount,
              updated_at   = NOW()
          WHERE store_id     = @storeId
            AND counter_date = CURRENT_DATE
            AND total_amount >= @payAmount
        '''),
        parameters: {'payAmount': payAmount, 'storeId': branchId},
      );
      if (upd.affectedRows != 1) {
        throw Exception(
            'Aaj ka cash counter nahi mila ya available balance kam hai');
      }

      final ins = await tx.execute(
        Sql.named('''
          INSERT INTO public.branch_transaction_to_janghani
            (branch_id, assign_by_id, assign_by_name, assign_to_id,
             type, before_amount, pay_amount, after_amount, is_synced)
          VALUES
            (@branchId::uuid, @assignById::uuid, @assignByName, NULL,
             'cash_out', @beforeAmount, @payAmount, @afterAmount, false)
          RETURNING id
        '''),
        parameters: {
          'branchId':     branchId,
          'assignById':   assignById,
          'assignByName': assignByName,
          'beforeAmount': beforeAmount,
          'payAmount':    payAmount,
          'afterAmount':  afterAmount,
        },
      );
      rowId = ins.first.toColumnMap()['id'].toString();
    });

    // Remote sync is best-effort with a short timeout — on slow/no internet it
    // just stays "pending" and the background SyncService applies it later.
    try {
      await _pushToJanghani(conn, rowId, payAmount)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      if (kDebugMode) debugPrint('cashOut: janghani sync pending — $e');
    }
  }

  // ── SYNC single pending row (manual retry) ────────────────
  Future<void> syncToJanghani(String rowId, double payAmount) async {
    final conn = await DataBaseService.getConnection();
    await _pushToJanghani(conn, rowId, payAmount);
  }

  /// Push one pending cash-out to the central `janghani_net_amount`.
  ///
  /// Idempotency: the local row is claimed FIRST (`is_synced` flipped to true
  /// only if it was false). Whoever wins that atomic update is the only caller
  /// that touches Supabase; if the remote update then fails the claim is rolled
  /// back so a later cycle retries. This keeps the app's manual "Sync" button
  /// and the background SyncService from double-applying the same row.
  Future<void> _pushToJanghani(
      Connection conn, String rowId, double payAmount) async {
    // 1. Claim the row.
    final claim = await conn.execute(
      Sql.named('''
        UPDATE public.branch_transaction_to_janghani
        SET is_synced = true, updated_at = NOW()
        WHERE id = @id::uuid AND is_synced = false
      '''),
      parameters: {'id': rowId},
    );
    if (claim.affectedRows != 1) return; // already synced / claimed elsewhere

    try {
      final res = await Supabase.instance.client
          .from('janghani_net_amount')
          .select('id, cash_in_hand')
          .limit(1)
          .maybeSingle();

      if (res == null) {
        throw Exception('janghani_net_amount row not found');
      }

      final janghaniId  = res['id'].toString();
      final currentCash = double.tryParse(
          res['cash_in_hand']?.toString() ?? '0') ?? 0.0;

      await Supabase.instance.client
          .from('janghani_net_amount')
          .update({'cash_in_hand': currentCash + payAmount})
          .eq('id', janghaniId);

      await conn.execute(
        Sql.named('''
          UPDATE public.branch_transaction_to_janghani
          SET assign_to_id = @janghaniId::uuid, updated_at = NOW()
          WHERE id = @rowId::uuid
        '''),
        parameters: {'rowId': rowId, 'janghaniId': janghaniId},
      );
    } catch (e) {
      // Release the claim so the next sync attempt retries this row.
      await conn.execute(
        Sql.named('''
          UPDATE public.branch_transaction_to_janghani
          SET is_synced = false, updated_at = NOW()
          WHERE id = @id::uuid
        '''),
        parameters: {'id': rowId},
      );
      rethrow;
    }
  }

  // ── GET history (with optional date range filter) ─────────
  Future<List<BranchTransactionHistoryModel>> getHistory(
      String branchId, {
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    final conn = await DataBaseService.getConnection();

    final params = <String, dynamic>{'branchId': branchId};

    String dateFilter = '';
    if (startDate != null && endDate != null) {
      // endDate ko din ke end tak include karne ke liye +1 day, < use kiya
      final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
      final endOnly   = DateTime(endDate.year, endDate.month, endDate.day)
          .add(const Duration(days: 1));

      dateFilter = 'AND created_at >= @startDate AND created_at < @endDate';
      params['startDate'] = startOnly.toIso8601String();
      params['endDate']   = endOnly.toIso8601String();
    }

    final result = await conn.execute(
      Sql.named('''
        SELECT * FROM public.branch_transaction_to_janghani
        WHERE branch_id = @branchId::uuid
        $dateFilter
        ORDER BY created_at DESC
      '''),
      parameters: params,
    );
    return result
        .map((r) => BranchTransactionHistoryModel.fromMap(_toMap(r)))
        .toList();
  }

  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':             m['id']?.toString()              ?? '',
      'branch_id':      m['branch_id']?.toString()       ?? '',
      'assign_by_id':   m['assign_by_id']?.toString()    ?? '',
      'assign_by_name': m['assign_by_name']?.toString()  ?? '',
      'assign_to_id':   m['assign_to_id']?.toString()    ?? '',
      'type':           m['type']?.toString()            ?? 'cash_out',
      'before_amount':  m['before_amount'],
      'pay_amount':     m['pay_amount'],
      'after_amount':   m['after_amount'],
      'is_synced':      m['is_synced'] as bool?          ?? false,
      'created_at':     m['created_at']?.toString()      ?? DateTime.now().toIso8601String(),
      'updated_at':     m['updated_at']?.toString()      ?? DateTime.now().toIso8601String(),
    };
  }
}
