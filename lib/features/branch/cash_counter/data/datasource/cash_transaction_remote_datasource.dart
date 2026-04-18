import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';
import '../model/cash_transaction_model.dart';

class CashTransactionRemoteDataSource {

  // GET ALL
  Future<List<CashTransactionModel>> getAll(String storeId) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, counter_id, previous_amount,
          cash_out_amount, remaining_amount,
          description, transaction_type,
          created_at, updated_at, deleted_at
        FROM public.branch_cash_transaction
        WHERE store_id   = @storeId
          AND deleted_at IS NULL
        ORDER BY created_at DESC
      '''),
      parameters: {'storeId': storeId},
    );

    return result.map((r) => CashTransactionModel.fromMap(_toMap(r))).toList();
  }

  // GET TODAY TOTAL — cash_counter se
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

  // ADD
  Future<CashTransactionModel> add({
    required String  storeId,
    required String? counterId,
    required double  previousAmount,
    required double  cashOutAmount,
    required double  remainingAmount,
    required String  transactionType,
    String?          description,
  }) async {
    final conn      = await DataBaseService.getConnection();
    final counterSql = counterId != null ? '@counterId::uuid' : 'NULL';

    final result = await conn.execute(
      Sql.named('''
        INSERT INTO public.branch_cash_transaction (
          store_id, counter_id, previous_amount,
          cash_out_amount, remaining_amount,
          description, transaction_type
        ) VALUES (
          @storeId, $counterSql, @previousAmount,
          @cashOutAmount, @remainingAmount,
          @description, @transactionType
        ) RETURNING *
      '''),
      parameters: {
        'storeId':         storeId,
        if (counterId != null) 'counterId': counterId,
        'previousAmount':  previousAmount,
        'cashOutAmount':   cashOutAmount,
        'remainingAmount': remainingAmount,
        'description':     description,
        'transactionType': transactionType,
      },
    );

    return CashTransactionModel.fromMap(_toMap(result.first));
  }

  // ROW → MAP
  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':               m['id']?.toString()               ?? '',
      'store_id':         m['store_id']?.toString()         ?? '',
      'counter_id':       m['counter_id']?.toString(),      // ← FIX: add kiya
      'previous_amount':  m['previous_amount'],
      'cash_out_amount':  m['cash_out_amount'],
      'remaining_amount': m['remaining_amount'],
      'description':      m['description']?.toString(),
      'transaction_type': m['transaction_type']?.toString() ?? 'cash_in',
      'created_at':       m['created_at']?.toString()       ?? DateTime.now().toIso8601String(),
      'updated_at':       m['updated_at']?.toString()       ?? DateTime.now().toIso8601String(),
      'deleted_at':       m['deleted_at']?.toString(),
    };
  }
}
 