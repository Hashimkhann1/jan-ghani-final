// =============================================================
// warehouse_finance_repository.dart
// Data layer — PostgreSQL queries
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/domain/warehouse_finance_model.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

class WarehouseFinanceRepository {
  WarehouseFinanceRepository._();
  static final instance = WarehouseFinanceRepository._();

  Future<Connection> get _db  => DatabaseService.getConnection();
  String             get _wid => AppConfig.warehouseId;

  // ── Helper ────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────
  // 1. warehouse_finance row lo (ya banao agar nahi hai)
  // ─────────────────────────────────────────────────────────
  Future<WarehouseFinanceModel> getOrCreate() async {
    final conn = await _db;

    // Pehle check karo row hai ya nahi
    final result = await conn.execute(
      Sql.named('''
        SELECT id, warehouse_id, cash_in_hand, updated_at
        FROM warehouse_finance
        WHERE warehouse_id = @wid
        LIMIT 1
      '''),
      parameters: {'wid': _wid},
    );

    // Row hai toh return karo
    if (result.isNotEmpty) {
      return WarehouseFinanceModel.fromMap(result.first.toColumnMap());
    }

    // Row nahi hai toh banao
    final newResult = await conn.execute(
      Sql.named('''
        INSERT INTO warehouse_finance (id, warehouse_id, cash_in_hand)
        VALUES (@id, @wid, 0)
        RETURNING id, warehouse_id, cash_in_hand, updated_at
      '''),
      parameters: {
        'id':  const Uuid().v4(),
        'wid': _wid,
      },
    );

    return WarehouseFinanceModel.fromMap(newResult.first.toColumnMap());
  }

  // ─────────────────────────────────────────────────────────
  // 2. Cash transactions list lo
  // ─────────────────────────────────────────────────────────
  Future<List<CashTransactionModel>> getTransactions({
    String? entryType,   // filter by type
    int     limit = 50,
  }) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          ct.id,
          ct.warehouse_id,
          ct.entry_type,
          ct.amount,
          ct.cash_in_hand_before,
          ct.cash_in_hand_after,
          ct.reference_id,
          ct.notes,
          ct.created_by,
          ct.created_by_name,
          ct.created_at,
          ct.sync_id,
          ct.is_synced,
          ct.synced_at
        FROM warehouse_cash_transactions ct
        WHERE ct.warehouse_id = @wid
          ${entryType != null ? 'AND ct.entry_type = @entryType' : ''}
        ORDER BY ct.created_at DESC
        LIMIT @limit
      '''),
      parameters: {
        'wid':       _wid,
        if (entryType != null) 'entryType': entryType,
        'limit':     limit,
      },
    );

    return result
        .map((row) => CashTransactionModel.fromMap(row.toColumnMap()))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // 3. Cash In entry karo
  // ─────────────────────────────────────────────────────────
  Future<CashTransactionModel> addCashIn({
    required double amount,
    String?         notes,
    String?         createdBy,
    String?         createdByName,
  }) async {
    return _insertTransaction(
      entryType:     'cash_in',
      amount:        amount,
      notes:         notes,
      createdBy:     createdBy,
      createdByName: createdByName,
    );
  }

  // ─────────────────────────────────────────────────────────
  // 4. Purchase entry karo (PO se auto call hoga)
  // ─────────────────────────────────────────────────────────
  Future<CashTransactionModel> addPurchaseEntry({
    required double amount,
    required String poId,
    String?         notes,
    String?         createdBy,
    String?         createdByName,
  }) async {
    return _insertTransaction(
      entryType:     'purchase',
      amount:        amount,
      referenceId:   poId,
      notes:         notes ?? 'Purchase Order payment',
      createdBy:     createdBy,
      createdByName: createdByName,
    );
  }

  // ─────────────────────────────────────────────────────────
  // 5. Supplier payment entry karo
  // ─────────────────────────────────────────────────────────
  Future<CashTransactionModel> addSupplierPayment({
    required double amount,
    required String supplierId,
    String?         notes,
    String?         createdBy,
    String?         createdByName,
  }) async {
    return _insertTransaction(
      entryType:     'supplier_payment',
      amount:        amount,
      referenceId:   supplierId,
      notes:         notes ?? 'Supplier payment',
      createdBy:     createdBy,
      createdByName: createdByName,
    );
  }

  // ─────────────────────────────────────────────────────────
  // 6. Expense entry karo
  // ─────────────────────────────────────────────────────────
  Future<CashTransactionModel> addExpenseEntry({
    required double amount,
    required String expenseId,
    String?         notes,
    String?         createdBy,
    String?         createdByName,
  }) async {
    return _insertTransaction(
      entryType:     'expense',
      amount:        amount,
      referenceId:   expenseId,
      notes:         notes ?? 'Expense',
      createdBy:     createdBy,
      createdByName: createdByName,
    );
  }

  // ─────────────────────────────────────────────────────────
  // 7. Finance Summary lo (dashboard ke liye)
  // ─────────────────────────────────────────────────────────
  Future<WarehouseFinanceSummary> getSummary() async {
    final conn = await _db;

    final results = await Future.wait([
      // cash_in_hand
      getOrCreate(),

      // Aaj ka in/out
      conn.execute(
        Sql.named('''
          SELECT
            COALESCE(SUM(amount) FILTER (WHERE entry_type = 'cash_in'),  0) AS today_in,
            COALESCE(SUM(amount) FILTER (WHERE entry_type != 'cash_in'), 0) AS today_out
          FROM warehouse_cash_transactions
          WHERE warehouse_id = @wid
            AND created_at  >= CURRENT_DATE
        '''),
        parameters: {'wid': _wid},
      ),

      // Is mahine ka in/out
      conn.execute(
        Sql.named('''
          SELECT
            COALESCE(SUM(amount) FILTER (WHERE entry_type = 'cash_in'),  0) AS month_in,
            COALESCE(SUM(amount) FILTER (WHERE entry_type != 'cash_in'), 0) AS month_out
          FROM warehouse_cash_transactions
          WHERE warehouse_id = @wid
            AND created_at  >= date_trunc('month', CURRENT_DATE)
        '''),
        parameters: {'wid': _wid},
      ),

      // Total supplier due
      conn.execute(
        Sql.named('''
          SELECT COALESCE(SUM(outstanding_balance), 0) AS total_due
          FROM suppliers
          WHERE warehouse_id = @wid
            AND is_active    = true
            AND deleted_at   IS NULL
        '''),
        parameters: {'wid': _wid},
      ),
    ]);

    final finance    = results[0] as WarehouseFinanceModel;
    final todayRows  = (results[1] as List).first.toColumnMap();
    final monthRows  = (results[2] as List).first.toColumnMap();
    final supRows    = (results[3] as List).first.toColumnMap();

    return WarehouseFinanceSummary(
      cashInHand:       finance.cashInHand,
      todayCashIn:      _toDouble(todayRows['today_in']),
      todayCashOut:     _toDouble(todayRows['today_out']),
      thisMonthCashIn:  _toDouble(monthRows['month_in']),
      thisMonthCashOut: _toDouble(monthRows['month_out']),
      totalSupplierDue: _toDouble(supRows['total_due']),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PRIVATE: Transaction insert karo
  // balance_before/after calculate karke save karo
  // ─────────────────────────────────────────────────────────
  Future<CashTransactionModel> _insertTransaction({
    required String entryType,
    required double amount,
    String?         referenceId,
    String?         notes,
    String?         createdBy,
    String?         createdByName,
  }) async {
    final conn = await _db;

    // 1. Current cash_in_hand lo
    final finance        = await getOrCreate();
    final balanceBefore  = finance.cashInHand;

    // 2. Balance calculate karo
    final balanceAfter = entryType == 'cash_in'
        ? balanceBefore + amount
        : balanceBefore - amount;

    // 3. Transaction insert karo
    // Trigger automatically warehouse_finance.cash_in_hand update karega
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO warehouse_cash_transactions (
          id,                  warehouse_id,
          entry_type,          amount,
          cash_in_hand_before, cash_in_hand_after,
          reference_id,        notes,
          created_by,          created_by_name
        ) VALUES (
          @id,                 @wid,
          @entryType,          @amount,
          @balanceBefore,      @balanceAfter,
          @referenceId,        @notes,
          @createdBy,          @createdByName
        )
        RETURNING *
      '''),
      parameters: {
        'id':            const Uuid().v4(),
        'wid':           _wid,
        'entryType':     entryType,
        'amount':        amount,
        'balanceBefore': balanceBefore,
        'balanceAfter':  balanceAfter,
        'referenceId':   referenceId,
        'notes':         notes,
        'createdBy':     createdBy,
        'createdByName': createdByName,
      },
    );

    return CashTransactionModel.fromMap(result.first.toColumnMap());
  }
}