import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/cash_counter_model.dart';

// ── CashCounterRemoteDataSource ───────────────────────────────
class CashCounterRemoteDataSource {

  // GET ALL
  Future<List<CashCounterModel>> getAll(String storeId) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, counter_id, counter_date,
          cash_sale, card_sale, credit_sale,
          installment, cash_in, cash_out,
          total_sale, total_amount,
          created_at, updated_at, deleted_at
        FROM public.branch_cash_counter
        WHERE store_id   = @storeId
          AND deleted_at IS NULL
        ORDER BY counter_date DESC
      '''),
      parameters: {'storeId': storeId},
    );

    return result.map((r) => CashCounterModel.fromMap(_toMap(r))).toList();
  }

  // GET TODAY TOTAL — counter ka total_amount
  Future<double> getTodayTotal(String storeId, String? counterId) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT COALESCE(total_amount, 0) AS total
        FROM public.branch_cash_counter
        WHERE store_id    = @storeId
          AND counter_date = CURRENT_DATE
          AND deleted_at   IS NULL
          ${counterId != null ? 'AND counter_id = @counterId::uuid' : ''}
        LIMIT 1
      '''),
      parameters: {
        'storeId': storeId,
        if (counterId != null) 'counterId': counterId,
      },
    );

    if (result.isEmpty) return 0.0;
    final val = result.first.toColumnMap()['total'];
    if (val == null) return 0.0;
    if (val is num)  return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  // ROW → MAP
  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':           m['id']?.toString()           ?? '',
      'store_id':     m['store_id']?.toString()     ?? '',
      'counter_id':   m['counter_id']?.toString()   ?? '',
      'counter_date': m['counter_date']?.toString(),
      'cash_sale':    m['cash_sale'],
      'card_sale':    m['card_sale'],
      'credit_sale':  m['credit_sale'],
      'installment':  m['installment'],
      'cash_in':      m['cash_in'],       // ← FIX: add kiya
      'cash_out':     m['cash_out'],      // ← FIX: add kiya
      'total_sale':   m['total_sale'],    // ← FIX: add kiya
      'total_amount': m['total_amount'],
      'created_at':   m['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at':   m['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
      'deleted_at':   m['deleted_at']?.toString(),
    };
  }

  Future<String> registerOpeningAmount({
    required String storeId,
    required String counterId,
    required double amount,
  }) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
      SELECT fn_create_next_day_counter(
        @storeId::uuid,
        @counterId::uuid,
        @amount::numeric
      )
    '''),
      parameters: {
        'storeId':   storeId,
        'counterId': counterId,
        'amount':    amount,
      },
    );

    final status = result.first.toColumnMap().values.first.toString();
    print('✅ Counter status: $status');
    return status; // 'SUCCESS' ya 'ALREADY_REGISTERED'
  }
}