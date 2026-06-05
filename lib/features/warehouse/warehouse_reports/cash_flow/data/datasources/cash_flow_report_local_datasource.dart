// =============================================================
// cash_flow_report_local_datasource.dart
// Cash Flow Report ke liye saari DB queries yahan hain
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';

// ─────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────

class CashFlowSummary {
  final double cashInHand;
  final double thisMonthCashIn;
  final double thisMonthCashOut;
  final double todayCashIn;
  final double todayCashOut;

  const CashFlowSummary({
    required this.cashInHand,
    required this.thisMonthCashIn,
    required this.thisMonthCashOut,
    required this.todayCashIn,
    required this.todayCashOut,
  });

  double get thisMonthNet  => thisMonthCashIn  - thisMonthCashOut;
  double get todayNet      => todayCashIn      - todayCashOut;
}

// Monthly data — Triple LineChart + Grouped BarChart + Net Flow BarChart
// sab isi se derive honge
class MonthlyCashFlowData {
  final DateTime month;
  final double   cashIn;
  final double   cashOut;
  final double   endBalance; // last transaction ka cash_in_hand_after

  const MonthlyCashFlowData({
    required this.month,
    required this.cashIn,
    required this.cashOut,
    required this.endBalance,
  });

  double get netFlow => cashIn - cashOut;
}

// Expense breakdown — Donut PieChart
class ExpenseCategoryData {
  final String category;
  final double amount;

  const ExpenseCategoryData({required this.category, required this.amount});
}

// Transaction type breakdown — Progress Bars
class TransactionTypeData {
  final String type;
  final double amount;

  const TransactionTypeData({required this.type, required this.amount});

  String get label {
    switch (type) {
      case 'cash_in':          return 'Cash In';
      case 'purchase':         return 'Purchase';
      case 'supplier_payment': return 'Supplier Payment';
      case 'expense':          return 'Expense';
      default:                 return type;
    }
  }

  bool get isCashIn => type == 'cash_in';
}

// ─────────────────────────────────────────────────────────────
// DATASOURCE
// ─────────────────────────────────────────────────────────────

class CashFlowReportLocalDatasource {
  static final CashFlowReportLocalDatasource instance =
      CashFlowReportLocalDatasource._();
  CashFlowReportLocalDatasource._();

  Future<Connection> get _db  => DatabaseService.getConnection();
  String             get _wid => AppConfig.warehouseId;

  // ── 1. Summary — 4 cards ─────────────────────────────────
  Future<CashFlowSummary> getSummary() async {
    final conn = await _db;

    // Current cash in hand
    final finResult = await conn.execute(
      Sql.named('''
        SELECT COALESCE(cash_in_hand, 0) AS cash_in_hand
        FROM warehouse_finance
        WHERE warehouse_id = @wid
        LIMIT 1
      '''),
      parameters: {'wid': _wid},
    );

    // This month + today stats from transactions
    final txResult = await conn.execute(
      Sql.named('''
        SELECT
          COALESCE(SUM(ABS(amount)) FILTER (
            WHERE entry_type = 'cash_in'
              AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', NOW())
          ), 0) AS this_month_cash_in,

          COALESCE(SUM(ABS(amount)) FILTER (
            WHERE entry_type != 'cash_in'
              AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', NOW())
          ), 0) AS this_month_cash_out,

          COALESCE(SUM(ABS(amount)) FILTER (
            WHERE entry_type = 'cash_in'
              AND created_at::date = CURRENT_DATE
          ), 0) AS today_cash_in,

          COALESCE(SUM(ABS(amount)) FILTER (
            WHERE entry_type != 'cash_in'
              AND created_at::date = CURRENT_DATE
          ), 0) AS today_cash_out
        FROM warehouse_cash_transactions
        WHERE warehouse_id = @wid
      '''),
      parameters: {'wid': _wid},
    );

    final cashInHand = finResult.isNotEmpty
        ? _parseDouble(finResult.first.toColumnMap()['cash_in_hand'])
        : 0.0;
    final tx = txResult.first.toColumnMap();

    return CashFlowSummary(
      cashInHand:        cashInHand,
      thisMonthCashIn:   _parseDouble(tx['this_month_cash_in']),
      thisMonthCashOut:  _parseDouble(tx['this_month_cash_out']),
      todayCashIn:       _parseDouble(tx['today_cash_in']),
      todayCashOut:      _parseDouble(tx['today_cash_out']),
    );
  }

  // ── 2. Monthly cash flow — last 6 months ─────────────────
  // Triple LineChart + Grouped BarChart + Net Flow BarChart sab ye use karega
  // CTE + DISTINCT ON use kiya — correlated subquery se bachne ke liye (PostgreSQL 42803)
  Future<List<MonthlyCashFlowData>> getMonthlyData() async {
    final conn   = await _db;
    final result = await conn.execute(
      Sql.named('''
        WITH monthly_stats AS (
          SELECT
            DATE_TRUNC('month', created_at)::date                                  AS month,
            COALESCE(SUM(ABS(amount)) FILTER (WHERE entry_type = 'cash_in'),  0)  AS cash_in,
            COALESCE(SUM(ABS(amount)) FILTER (WHERE entry_type != 'cash_in'), 0)  AS cash_out
          FROM warehouse_cash_transactions
          WHERE warehouse_id = @wid
            AND created_at >= DATE_TRUNC('month', NOW()) - INTERVAL '5 months'
          GROUP BY DATE_TRUNC('month', created_at)
        ),
        last_balance_per_month AS (
          SELECT DISTINCT ON (DATE_TRUNC('month', created_at))
            DATE_TRUNC('month', created_at)::date AS month,
            cash_in_hand_after                    AS end_balance
          FROM warehouse_cash_transactions
          WHERE warehouse_id = @wid
            AND created_at >= DATE_TRUNC('month', NOW()) - INTERVAL '5 months'
          ORDER BY DATE_TRUNC('month', created_at), created_at DESC
        )
        SELECT
          ms.month,
          ms.cash_in,
          ms.cash_out,
          COALESCE(lb.end_balance, 0) AS end_balance
        FROM monthly_stats ms
        LEFT JOIN last_balance_per_month lb ON lb.month = ms.month
        ORDER BY ms.month
      '''),
      parameters: {'wid': _wid},
    );

    final dbData = result.map((row) {
      final m = row.toColumnMap();
      return MonthlyCashFlowData(
        month:      _parseDate(m['month']),
        cashIn:     _parseDouble(m['cash_in']),
        cashOut:    _parseDouble(m['cash_out']),
        endBalance: _parseDouble(m['end_balance']),
      );
    }).toList();

    // Missing months fill karo — last 6 months guaranteed dikhne chahiye
    return _fillMissingMonths(dbData);
  }

  // ── 3. Expense breakdown — Donut PieChart ────────────────
  Future<List<ExpenseCategoryData>> getExpenseBreakdown() async {
    final conn   = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT
          expense_head                  AS category,
          COALESCE(SUM(amount), 0)      AS amount
        FROM warehouse_expenses
        WHERE warehouse_id = @wid
          AND deleted_at   IS NULL
        GROUP BY expense_head
        ORDER BY amount DESC
        LIMIT 8
      '''),
      parameters: {'wid': _wid},
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return ExpenseCategoryData(
        category: m['category'].toString(),
        amount:   _parseDouble(m['amount']),
      );
    }).toList();
  }

  // ── 4. Transaction type breakdown — Progress Bars ─────────
  Future<List<TransactionTypeData>> getTypeBreakdown() async {
    final conn   = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT
          entry_type,
          COALESCE(SUM(ABS(amount)), 0) AS amount
        FROM warehouse_cash_transactions
        WHERE warehouse_id = @wid
        GROUP BY entry_type
        ORDER BY amount DESC
      '''),
      parameters: {'wid': _wid},
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return TransactionTypeData(
        type:   m['entry_type'].toString(),
        amount: _parseDouble(m['amount']),
      );
    }).toList();
  }

  // ── Fill missing months with zero data ───────────────────
  List<MonthlyCashFlowData> _fillMissingMonths(List<MonthlyCashFlowData> db) {
    final now    = DateTime.now();
    final result = <MonthlyCashFlowData>[];

    for (int i = 5; i >= 0; i--) {
      final target = DateTime(now.year, now.month - i, 1);
      final found  = db.where((d) =>
          d.month.year  == target.year &&
          d.month.month == target.month).firstOrNull;

      result.add(found ?? MonthlyCashFlowData(
        month:      target,
        cashIn:     0,
        cashOut:    0,
        endBalance: result.isNotEmpty ? result.last.endBalance : 0,
      ));
    }
    return result;
  }

  // ── Safe parsers ──────────────────────────────────────────
  static double _parseDouble(dynamic v) {
    if (v == null)   return 0.0;
    if (v is double) return v;
    if (v is num)    return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}
