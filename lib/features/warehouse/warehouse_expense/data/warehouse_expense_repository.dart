// =============================================================
// warehouse_expense_repository.dart
// Data layer — PostgreSQL queries
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_expense/domain/warehouse_expense_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/data/warehouse_finance_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

class WarehouseExpenseRepository {
  WarehouseExpenseRepository._();
  static final instance = WarehouseExpenseRepository._();

  Future<Connection> get _db  => DatabaseService.getConnection();
  String             get _wid => AppConfig.warehouseId;

  // ─────────────────────────────────────────────────────────
  // 1. Sab expenses lo (latest first)
  // ─────────────────────────────────────────────────────────
  Future<List<WarehouseExpenseModel>> getAll({
    String? filter,   // 'today' / 'this_week' / 'this_month' / null = all
    String? search,   // expense_head search
  }) async {
    final conn = await _db;

    String dateFilter = '';
    if (filter == 'today') {
      dateFilter = 'AND DATE(e.expense_date) = CURRENT_DATE';
    } else if (filter == 'this_week') {
      dateFilter = 'AND e.expense_date >= DATE_TRUNC(\'week\', NOW())';
    } else if (filter == 'this_month') {
      dateFilter = 'AND e.expense_date >= DATE_TRUNC(\'month\', NOW())';
    }

    String searchFilter = '';
    if (search != null && search.isNotEmpty) {
      searchFilter = 'AND LOWER(e.expense_head) LIKE LOWER(\'%$search%\')';
    }

    final result = await conn.execute(
      Sql.named('''
        SELECT
          e.id, e.warehouse_id, e.cash_transaction_id,
          e.expense_head, e.amount, e.description,
          e.expense_date, e.created_by, e.created_by_name,
          e.created_at, e.updated_at, e.deleted_at,
          e.sync_id, e.is_synced
        FROM warehouse_expenses e
        WHERE e.warehouse_id = @wid
          AND e.deleted_at   IS NULL
          $dateFilter
          $searchFilter
        ORDER BY e.expense_date DESC, e.created_at DESC
      '''),
      parameters: {'wid': _wid},
    );

    return result
        .map((row) => WarehouseExpenseModel.fromMap(row.toColumnMap()))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // 2. Stats (3 cards ke liye)
  // ─────────────────────────────────────────────────────────
  Future<ExpenseStats> getStats() async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          COUNT(*)                                              AS total_count,
          COALESCE(SUM(amount) FILTER (
            WHERE DATE(expense_date) = CURRENT_DATE
          ), 0)                                                 AS today_total,
          COALESCE(SUM(amount) FILTER (
            WHERE expense_date >= DATE_TRUNC('month', NOW())
          ), 0)                                                 AS month_total
        FROM warehouse_expenses
        WHERE warehouse_id = @wid
          AND deleted_at   IS NULL
      '''),
      parameters: {'wid': _wid},
    );

    final m = result.first.toColumnMap();
    return ExpenseStats(
      totalCount:     _toInt(m['total_count']),
      todayTotal:     _toDouble(m['today_total']),
      thisMonthTotal: _toDouble(m['month_total']),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 3. Expense add karo
  //    → expenses table mein insert
  //    → cash_transactions mein 'expense' entry
  //    → warehouse_finance.cash_in_hand auto minus (trigger)
  // ─────────────────────────────────────────────────────────
  Future<WarehouseExpenseModel> addExpense({
    required String expenseHead,
    required double amount,
    String?         description,
    DateTime?       expenseDate,
    String?         createdBy,
    String?         createdByName,
  }) async {
    final conn = await _db;
    final expId = const Uuid().v4();

    // Step 1: cash_transactions mein expense entry karo
    // WarehouseFinanceRepository trigger se cash_in_hand minus karega
    final cashTx = await WarehouseFinanceRepository.instance.addExpenseEntry(
      amount:        amount,
      expenseId:     expId,
      notes:         '$expenseHead — ${description ?? 'Expense'}',
      createdBy:     createdBy,
      createdByName: createdByName,
    );

    // Step 2: expenses table mein insert karo
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO warehouse_expenses (
          id,               warehouse_id,        cash_transaction_id,
          expense_head,     amount,              description,
          expense_date,     created_by,          created_by_name
        ) VALUES (
          @id,              @wid,                @cashTxId,
          @expenseHead,     @amount,             @description,
          @expenseDate,     @createdBy,          @createdByName
        )
        RETURNING *
      '''),
      parameters: {
        'id':            expId,
        'wid':           _wid,
        'cashTxId':      cashTx.id,
        'expenseHead':   expenseHead,
        'amount':        amount,
        'description':   description,
        'expenseDate':   expenseDate ?? DateTime.now(),
        'createdBy':     createdBy,
        'createdByName': createdByName,
      },
    );

    return WarehouseExpenseModel.fromMap(result.first.toColumnMap());
  }

  // ─────────────────────────────────────────────────────────
  // 4. Soft delete
  // ─────────────────────────────────────────────────────────
  Future<void> deleteExpense(String expenseId) async {
    final conn = await _db;
    await conn.execute(
      Sql.named('''
        UPDATE warehouse_expenses
        SET deleted_at = NOW()
        WHERE id           = @id
          AND warehouse_id = @wid
      '''),
      parameters: {'id': expenseId, 'wid': _wid},
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int)  return v;
    if (v is num)  return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}