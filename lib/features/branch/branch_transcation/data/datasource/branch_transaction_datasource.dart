import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';
import '../model/branch_transaction_history_model.dart';

class BranchTransactionDataSource {

  // ── GET branch_cash_counter total_amount ──────────────────────
  // counterId diya ho to sirf us counter ka aaj ka total; warna
  // store ke sab counters ka total (pehle sirf "latest updated" counter
  // ka total aata tha, is liye counter 2 ka amount counter 1 user ko dikhta tha).
  Future<double> getBranchTotalAmount(String storeId, String? counterId) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT COALESCE(SUM(total_amount), 0) AS total_amount
        FROM public.branch_cash_counter
        WHERE store_id     = @storeId
          AND counter_date = CURRENT_DATE
          AND deleted_at   IS NULL
          ${counterId != null ? 'AND counter_id = @counterId::uuid' : ''}
      '''),
      parameters: {
        'storeId': storeId,
        if (counterId != null) 'counterId': counterId,
      },
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
    String? counterId,
    required String assignById,
    required String assignByName,
    required double beforeAmount,
    required double payAmount,
    required double afterAmount,
  }) async {
    final conn = await DataBaseService.getConnection();

    // Sirf local: counter minus + history row ek hi tx mein. Amount
    // janghani_net_amount mein tab add hota hai jab accountant is row ko
    // "Receive" karta hai (Supabase RPC receive_branch_cash_out) — branch
    // ka slow internet ab cash out ko nahi rokta.
    await conn.runTx((tx) async {
      final upd = await tx.execute(
        Sql.named('''
          UPDATE public.branch_cash_counter
          SET total_amount = total_amount - @payAmount,
              cash_out     = cash_out + @payAmount,
              updated_at   = NOW()
          WHERE store_id     = @storeId
            AND counter_date = CURRENT_DATE
            AND deleted_at   IS NULL
            AND total_amount >= @payAmount
            ${counterId != null
                ? 'AND counter_id = @counterId::uuid'
                : 'AND id = (SELECT id FROM public.branch_cash_counter '
                  'WHERE store_id = @storeId AND counter_date = CURRENT_DATE '
                  'AND deleted_at IS NULL AND total_amount >= @payAmount '
                  'ORDER BY total_amount DESC LIMIT 1)'}
        '''),
        parameters: {
          'payAmount': payAmount,
          'storeId':   branchId,
          if (counterId != null) 'counterId': counterId,
        },
      );
      if (upd.affectedRows != 1) {
        throw Exception(
            'Aaj ka cash counter nahi mila ya available balance kam hai');
      }

      await tx.execute(
        Sql.named('''
          INSERT INTO public.branch_transaction_to_janghani
            (branch_id, assign_by_id, assign_by_name, assign_to_id,
             type, before_amount, pay_amount, after_amount, is_synced)
          VALUES
            (@branchId::uuid, @assignById::uuid, @assignByName, NULL,
             'cash_out', @beforeAmount, @payAmount, @afterAmount, false)
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
    });
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
