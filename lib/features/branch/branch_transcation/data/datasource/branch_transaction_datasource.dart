import 'package:postgres/postgres.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/service/db/db_service.dart';
import '../model/branch_transaction_history_model.dart';

class BranchTransactionDataSource {

  // ── GET branch_cash_counter total_amount ──────────────────────
  Future<double> getBranchTotalAmount(String storeId) async {
    try {
      final conn   = await DataBaseService.getConnection();
      final result = await conn.execute(
        Sql.named('''
          SELECT total_amount FROM public.branch_cash_counter
          WHERE store_id = @storeId AND counter_date = CURRENT_DATE
          LIMIT 1
        '''),
        parameters: {'storeId': storeId},
      );
      if (result.isEmpty) return 0.0;
      final raw = result.first.toColumnMap()['total_amount'];
      if (raw == null) return 0.0;
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString()) ?? 0.0;
    } catch (e) {
      print('❌ getBranchTotalAmount error: $e');
      rethrow;
    }
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

    // 1. branch_cash_counter update (local)
    await conn.execute(
      Sql.named('''
        UPDATE public.branch_cash_counter
        SET total_amount   = total_amount  - @payAmount,
            cash_out       = cash_out      + @payAmount,
            updated_at     = NOW()
        WHERE store_id     = @storeId
          AND counter_date = CURRENT_DATE
      '''),
      parameters: {
        'payAmount': payAmount,
        'storeId':   branchId,
      },
    );

    // 2. Supabase se janghani id fetch + sync karne ki koshish
    String  janghaniId = '';
    bool    isSynced   = false;

    try {
      final res = await Supabase.instance.client
          .from('janghani_net_amount')
          .select('id, cash_in_hand')
          .limit(1)
          .single();

      janghaniId = res['id'].toString();
      final currentCash = double.tryParse(
          res['cash_in_hand']?.toString() ?? '0') ?? 0.0;
      final newCash = currentCash + payAmount;

      await Supabase.instance.client
          .from('janghani_net_amount')
          .update({'cash_in_hand': newCash})
          .eq('id', janghaniId);

      isSynced = true;
      print('✅ Supabase sync successful');
    } catch (e) {
      print('⚠️ Offline — Supabase sync pending: $e');
      isSynced = false;
    }

    // 3. History insert (local) — is_synced flag ke saath
    await conn.execute(
      Sql.named('''
        INSERT INTO public.branch_transaction_to_janghani
          (branch_id, assign_by_id, assign_by_name, assign_to_id,
           type, before_amount, pay_amount, after_amount, is_synced)
        VALUES
          (@branchId::uuid, @assignById::uuid, @assignByName, 
           CASE WHEN @assignToId = '' THEN NULL ELSE @assignToId::uuid END,
           'cash_out', @beforeAmount, @payAmount, @afterAmount, @isSynced)
      '''),
      parameters: {
        'branchId':     branchId,
        'assignById':   assignById,
        'assignByName': assignByName,
        'assignToId':   janghaniId,
        'beforeAmount': beforeAmount,
        'payAmount':    payAmount,
        'afterAmount':  afterAmount,
        'isSynced':     isSynced,
      },
    );
  }

  // ── SYNC single row ───────────────────────────────────────
  Future<void> syncToJanghani(String rowId, double payAmount) async {
    final conn = await DataBaseService.getConnection();

    try {
      final res = await Supabase.instance.client
          .from('janghani_net_amount')
          .select('id, cash_in_hand')
          .limit(1)
          .single();

      final janghaniId  = res['id'].toString();
      final currentCash = double.tryParse(
          res['cash_in_hand']?.toString() ?? '0') ?? 0.0;
      final newCash     = currentCash + payAmount;

      await Supabase.instance.client
          .from('janghani_net_amount')
          .update({'cash_in_hand': newCash})
          .eq('id', janghaniId);

      await conn.execute(
        Sql.named('''
          UPDATE public.branch_transaction_to_janghani
          SET is_synced    = true,
              assign_to_id = @janghaniId::uuid,
              updated_at   = NOW()
          WHERE id = @rowId::uuid
        '''),
        parameters: {
          'rowId':      rowId,
          'janghaniId': janghaniId,
        },
      );

      print('✅ Row $rowId synced successfully');
    } catch (e) {
      print('❌ Sync error: $e');
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