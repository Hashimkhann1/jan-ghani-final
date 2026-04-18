import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/store_summary_model.dart';

class StoreSummaryDataSource {

  // ── GET ALL — Store level aggregated ─────────────────────
  Future<List<StoreSummaryModel>> getAll(String storeId) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
      SELECT
        gen_random_uuid()                 AS id,
        store_id,
        counter_date,
        SUM(total_cash_sale)              AS total_cash_sale,
        SUM(total_card_sale)              AS total_card_sale,
        SUM(total_credit_sale)            AS total_credit_sale,
        SUM(total_installment)            AS total_installment,
        SUM(total_cash_in)                AS total_cash_in,
        SUM(total_cash_out)               AS total_cash_out,
        SUM(total_expense)                AS total_expense,
        SUM(total_amount)                 AS total_amount,
        SUM(total_sale)                   AS total_sale,
        MIN(created_at)                   AS created_at,
        MAX(updated_at)                   AS updated_at
      FROM public.branch_summary
      WHERE store_id = @storeId
      GROUP BY store_id, counter_date
      ORDER BY counter_date DESC
    '''),
      parameters: {'storeId': storeId},
    );

    return result
        .map((r) => StoreSummaryModel.fromMap(_toMap(r)))
        .toList();
  }

  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':                m['id']?.toString()               ?? '',
      'store_id':          m['store_id']?.toString()         ?? '',
      'counter_date':      m['counter_date']?.toString(),
      'total_cash_sale':   m['total_cash_sale'],
      'total_card_sale':   m['total_card_sale'],
      'total_credit_sale': m['total_credit_sale'],
      'total_installment': m['total_installment'],
      'total_cash_in':     m['total_cash_in'],
      'total_cash_out':    m['total_cash_out'],
      'total_expense':     m['total_expense'],
      'total_amount':      m['total_amount'],
      'total_sale':        m['total_sale'],
      'created_at':        m['created_at']?.toString()       ?? DateTime.now().toIso8601String(),
      'updated_at':        m['updated_at']?.toString()       ?? DateTime.now().toIso8601String(),
    };
  }
}