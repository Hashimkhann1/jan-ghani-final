// =============================================================
// cash_flow_report_local_datasource.dart
// Cash Flow Report ke liye LOCAL postgres queries (Windows/Mac/mobile).
// Models ab cash_flow_report_models.dart mein hain (re-exported).
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';
import 'cash_flow_report_models.dart';
import 'cash_flow_report_source.dart';

// Purane imports (provider/screen) ke liye models yahin se mil jayein
export 'cash_flow_report_models.dart';

// ─────────────────────────────────────────────────────────────
// DATASOURCE (LOCAL)
// ─────────────────────────────────────────────────────────────

class CashFlowReportLocalDatasource implements CashFlowReportSource {
  static final CashFlowReportLocalDatasource instance =
      CashFlowReportLocalDatasource._();
  CashFlowReportLocalDatasource._();

  Future<Connection> get _db  => DatabaseService.getConnection();
  String             get _wid => AppConfig.warehouseId;

  // ── Date filter helpers ───────────────────────────────────
  static String _dateWhere(String field, DateTime? from, DateTime? to) {
    final parts = <String>[];
    if (from != null) parts.add('$field::date >= @from');
    if (to   != null) parts.add('$field::date <= @to');
    return parts.isEmpty ? '' : 'AND ${parts.join(' AND ')}';
  }

  static Map<String, dynamic> _withDateParams(
      Map<String, dynamic> base, DateTime? from, DateTime? to) {
    return {
      ...base,
      if (from != null) 'from': from.toIso8601String().substring(0, 10),
      if (to   != null) 'to'  : to.toIso8601String().substring(0, 10),
    };
  }

  // ── 1. Summary — period in/out + prev period net ─────────
  @override
  Future<CashFlowSummary> getSummary({
    DateTime? from,
    DateTime? to,
    DateTime? prevFrom,
    DateTime? prevTo,
  }) async {
    final conn = await _db;

    // Current cash in hand — LIVE
    final finResult = await conn.execute(
      Sql.named('''
        SELECT COALESCE(cash_in_hand, 0) AS cash_in_hand
        FROM warehouse_finance
        WHERE warehouse_id = @wid
        LIMIT 1
      '''),
      parameters: {'wid': _wid},
    );

    // Period conditions
    final periodCond = _periodCond(from, to);
    final hasPrev    = prevFrom != null && prevTo != null;
    final prevCond   = hasPrev
        ? "AND created_at::date >= @pfrom AND created_at::date <= @pto"
        : "AND false";

    final params = <String, dynamic>{'wid': _wid};
    if (from != null) params['from'] = _d(from);
    if (to   != null) params['to']   = _d(to);
    if (hasPrev) {
      params['pfrom'] = _d(prevFrom);
      params['pto']   = _d(prevTo);
    }

    final txResult = await conn.execute(
      Sql.named('''
        SELECT
          COALESCE(SUM(ABS(amount)) FILTER (WHERE entry_type =  'cash_in' $periodCond), 0) AS period_in,
          COALESCE(SUM(ABS(amount)) FILTER (WHERE entry_type <> 'cash_in' $periodCond), 0) AS period_out,
          COALESCE(SUM(ABS(amount)) FILTER (WHERE entry_type =  'cash_in' $prevCond),   0) AS prev_in,
          COALESCE(SUM(ABS(amount)) FILTER (WHERE entry_type <> 'cash_in' $prevCond),   0) AS prev_out
        FROM warehouse_cash_transactions
        WHERE warehouse_id = @wid
      '''),
      parameters: params,
    );

    final cashInHand = finResult.isNotEmpty
        ? _parseDouble(finResult.first.toColumnMap()['cash_in_hand'])
        : 0.0;
    final tx = txResult.first.toColumnMap();

    final prevNet = _parseDouble(tx['prev_in']) - _parseDouble(tx['prev_out']);

    return CashFlowSummary(
      cashInHand:    cashInHand,
      periodCashIn:  _parseDouble(tx['period_in']),
      periodCashOut: _parseDouble(tx['period_out']),
      prevPeriodNet: prevNet,
      hasPrev:       hasPrev,
    );
  }

  // ── 2. Monthly cash flow — ALWAYS last 6 months (trend) ──
  // Triple LineChart + Grouped BarChart + Net Flow BarChart sab ye use karega.
  // Note: yeh trend visual hai — date filter se independent rehta hai.
  @override
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

    return _fillMissingMonths(dbData);
  }

  // ── 3. Expense breakdown — Donut PieChart ────────────────
  @override
  Future<List<ExpenseCategoryData>> getExpenseBreakdown({
    DateTime? from,
    DateTime? to,
  }) async {
    final conn     = await _db;
    final dateCond = _dateWhere('expense_date', from, to);
    final result   = await conn.execute(
      Sql.named('''
        SELECT
          expense_head                  AS category,
          COALESCE(SUM(amount), 0)      AS amount
        FROM warehouse_expenses
        WHERE warehouse_id = @wid
          AND deleted_at   IS NULL
          $dateCond
        GROUP BY expense_head
        ORDER BY amount DESC
        LIMIT 8
      '''),
      parameters: _withDateParams({'wid': _wid}, from, to),
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
  @override
  Future<List<TransactionTypeData>> getTypeBreakdown({
    DateTime? from,
    DateTime? to,
  }) async {
    final conn     = await _db;
    final dateCond = _dateWhere('created_at', from, to);
    final result   = await conn.execute(
      Sql.named('''
        SELECT
          entry_type,
          COALESCE(SUM(ABS(amount)), 0) AS amount
        FROM warehouse_cash_transactions
        WHERE warehouse_id = @wid
          $dateCond
        GROUP BY entry_type
        ORDER BY amount DESC
      '''),
      parameters: _withDateParams({'wid': _wid}, from, to),
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return TransactionTypeData(
        type:   m['entry_type'].toString(),
        amount: _parseDouble(m['amount']),
      );
    }).toList();
  }

  // ── 5. Recent transactions — drill-down list ──────────────
  @override
  Future<List<CashTransactionEntry>> getRecentTransactions({
    DateTime? from,
    DateTime? to,
    String?   type,        // null = all; warna sirf is entry_type ki
    int       limit = 200,
  }) async {
    final conn     = await _db;
    final dateCond = _dateWhere('created_at', from, to);
    final typeCond = type == null ? '' : 'AND entry_type = @type';

    final params = _withDateParams({'wid': _wid, 'limit': limit}, from, to);
    if (type != null) params['type'] = type;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id,
          entry_type,
          amount,
          cash_in_hand_after,
          notes,
          created_by_name,
          created_at
        FROM warehouse_cash_transactions
        WHERE warehouse_id = @wid
          $dateCond
          $typeCond
        ORDER BY created_at DESC
        LIMIT @limit
      '''),
      parameters: params,
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return CashTransactionEntry(
        id:           m['id'].toString(),
        entryType:    m['entry_type'].toString(),
        amount:       _parseDouble(m['amount']).abs(),
        balanceAfter: _parseDouble(m['cash_in_hand_after']),
        notes:        m['notes']?.toString(),
        byName:       m['created_by_name']?.toString(),
        createdAt:    _parseDate(m['created_at']),
      );
    }).toList();
  }

  // ── Period condition builder (created_at) ─────────────────
  static String _periodCond(DateTime? from, DateTime? to) {
    final parts = <String>[];
    if (from != null) parts.add('AND created_at::date >= @from');
    if (to   != null) parts.add('AND created_at::date <= @to');
    return parts.join(' ');
  }

  static String _d(DateTime? v) => v!.toIso8601String().substring(0, 10);

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
