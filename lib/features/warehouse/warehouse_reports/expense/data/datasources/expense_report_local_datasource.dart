// =============================================================
// expense_report_local_datasource.dart
// Expense Report ke liye LOCAL postgres queries (Windows/Mac/mobile).
// Models ab expense_report_models.dart mein hain (re-exported).
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';
import 'expense_report_models.dart';
import 'expense_report_source.dart';

// Purane imports (provider/screen) ke liye models yahin se mil jayein
export 'expense_report_models.dart';

class ExpenseReportLocalDatasource implements ExpenseReportSource {
  static final ExpenseReportLocalDatasource instance =
      ExpenseReportLocalDatasource._();
  ExpenseReportLocalDatasource._();

  Future<Connection> get _db  => DatabaseService.getConnection();
  String             get _wid => AppConfig.warehouseId;

  // ── Date filter helpers (expense_date::date range) ────────
  static String _dateWhere(DateTime? from, DateTime? to) {
    final parts = <String>[];
    if (from != null) parts.add('AND expense_date::date >= @from');
    if (to   != null) parts.add('AND expense_date::date <= @to');
    return parts.join(' ');
  }

  static Map<String, dynamic> _params(
      String wid, DateTime? from, DateTime? to) {
    return {
      'wid': wid,
      if (from != null) 'from': from.toIso8601String().substring(0, 10),
      if (to   != null) 'to'  : to.toIso8601String().substring(0, 10),
    };
  }

  // ── 1. Summary — total + entries + active days + prev total ─
  @override
  Future<ExpenseReportSummary> getSummary({
    DateTime? from,
    DateTime? to,
    DateTime? prevFrom,
    DateTime? prevTo,
  }) async {
    final conn = await _db;

    // Current period aggregates
    final res = await conn.execute(
      Sql.named('''
        SELECT
          COALESCE(SUM(amount), 0)                AS total,
          COUNT(*)                                AS entries,
          COUNT(DISTINCT expense_date::date)      AS active_days
        FROM warehouse_expenses
        WHERE warehouse_id = @wid AND deleted_at IS NULL
        ${_dateWhere(from, to)}
      '''),
      parameters: _params(_wid, from, to),
    );
    final m = res.first.toColumnMap();

    // Pichle equal-length period ka total (agar diya gaya ho)
    double prevTotal = 0;
    final hasPrev = prevFrom != null && prevTo != null;
    if (hasPrev) {
      final pres = await conn.execute(
        Sql.named('''
          SELECT COALESCE(SUM(amount), 0) AS prev_total
          FROM warehouse_expenses
          WHERE warehouse_id = @wid AND deleted_at IS NULL
            AND expense_date::date >= @pfrom AND expense_date::date <= @pto
        '''),
        parameters: {
          'wid':   _wid,
          'pfrom': prevFrom.toIso8601String().substring(0, 10),
          'pto':   prevTo.toIso8601String().substring(0, 10),
        },
      );
      prevTotal = _dbl(pres.first.toColumnMap()['prev_total']);
    }

    return ExpenseReportSummary(
      totalAmount: _dbl(m['total']),
      entryCount:  _int(m['entries']),
      activeDays:  _int(m['active_days']),
      prevTotal:   prevTotal,
      hasPrev:     hasPrev,
    );
  }

  // ── 2. Category breakdown — per expense head (amount DESC) ─
  @override
  Future<List<ExpenseCategoryRow>> getCategoryBreakdown({
    DateTime? from,
    DateTime? to,
  }) async {
    final conn = await _db;
    final res = await conn.execute(
      Sql.named('''
        SELECT
          expense_head,
          COALESCE(SUM(amount), 0) AS amount,
          COUNT(*)                 AS entries
        FROM warehouse_expenses
        WHERE warehouse_id = @wid AND deleted_at IS NULL
        ${_dateWhere(from, to)}
        GROUP BY expense_head
        ORDER BY amount DESC
      '''),
      parameters: _params(_wid, from, to),
    );
    return res.map((r) {
      final m = r.toColumnMap();
      return ExpenseCategoryRow(
        head:    (m['expense_head'] ?? '').toString(),
        amount:  _dbl(m['amount']),
        entries: _int(m['entries']),
      );
    }).toList();
  }

  // ── Helpers ───────────────────────────────────────────────
  static double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
