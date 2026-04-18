import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/expense_model.dart';

class ExpenseRemoteDataSource {

  // ── GET ALL ───────────────────────────────────────────────
  Future<List<ExpenseModel>> getAll(String storeId) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, expense_head,
          amount, description,
          created_at, updated_at, deleted_at
        FROM public.branch_expense
        WHERE store_id  = @storeId
          AND deleted_at IS NULL
        ORDER BY created_at DESC
      '''),
      parameters: {'storeId': storeId},
    );

    return result.map((r) => ExpenseModel.fromMap(_toMap(r))).toList();
  }

  // ── ADD ───────────────────────────────────────────────────
  Future<ExpenseModel> add(ExpenseModel expense) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        INSERT INTO public.branch_expense
          (store_id, expense_head, amount, description)
        VALUES
          (@storeId, @expenseHead, @amount, @description)
        RETURNING *
      '''),
      parameters: {
        'storeId':     expense.storeId,
        'expenseHead': expense.expenseHead,
        'amount':      expense.amount,
        'description': expense.description,
      },
    );

    return ExpenseModel.fromMap(_toMap(result.first));
  }

  // ── UPDATE ────────────────────────────────────────────────
  Future<ExpenseModel> update(ExpenseModel expense) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        UPDATE public.branch_expense SET
          expense_head = @expenseHead,
          amount       = @amount,
          description  = @description,
          updated_at   = NOW()
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id':          expense.id,
        'expenseHead': expense.expenseHead,
        'amount':      expense.amount,
        'description': expense.description,
      },
    );

    return ExpenseModel.fromMap(_toMap(result.first));
  }

  // ── SOFT DELETE ───────────────────────────────────────────
  Future<void> delete(String id) async {
    final conn = await DataBaseService.getConnection();

    await conn.execute(
      Sql.named('''
        UPDATE public.branch_expense
        SET deleted_at = NOW(), updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );
  }

  // ── ROW → MAP ─────────────────────────────────────────────
  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':           m['id']?.toString()           ?? '',
      'store_id':     m['store_id']?.toString()     ?? '',
      'expense_head': m['expense_head']?.toString() ?? '',
      'amount':       m['amount'],
      'description':  m['description']?.toString(),
      'created_at':   m['created_at']?.toString()   ?? DateTime.now().toIso8601String(),
      'updated_at':   m['updated_at']?.toString()   ?? DateTime.now().toIso8601String(),
      'deleted_at':   m['deleted_at']?.toString(),
    };
  }
}