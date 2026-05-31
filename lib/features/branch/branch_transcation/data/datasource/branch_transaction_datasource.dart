import 'package:postgres/postgres.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/branch_transaction_history_model.dart';

class BranchTransactionDataSource {

  // ── GET branch_summary total_amount ──────────────────────
  Future<double> getBranchTotalAmount(String storeId) async {
    try {
      final conn   = await DataBaseService.getConnection();
      final result = await conn.execute(
        Sql.named('''
          SELECT total_amount FROM public.branch_summary
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
  // 1. branch_summary se minus karo (local)
  // 2. history insert karo is_synced=false (local)
  // 3. Internet ho to Supabase sync karo is_synced=true
  Future<void> cashOut({
    required String branchId,
    required String assignById,
    required String assignByName,
    required double beforeAmount,
    required double payAmount,
    required double afterAmount,
  }) async {
    final conn = await DataBaseService.getConnection();

    // 1. branch_summary update (local)
    await conn.execute(
      Sql.named('''
        UPDATE public.branch_summary
        SET total_amount    = total_amount    - @payAmount,
            total_cash_out  = total_cash_out  + @payAmount,
            updated_at      = NOW()
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
      // Supabase se janghani fetch + update
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

      // Local row is_synced = true update
      await conn.execute(
        Sql.named('''
          UPDATE public.branch_transaction_to_janghani
          SET is_synced   = true,
              assign_to_id = @janghaniId::uuid,
              updated_at  = NOW()
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

  // ── GET history ───────────────────────────────────────────
  Future<List<BranchTransactionHistoryModel>> getHistory(
      String branchId) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT * FROM public.branch_transaction_to_janghani
        WHERE branch_id = @branchId::uuid
        ORDER BY created_at DESC
      '''),
      parameters: {'branchId': branchId},
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