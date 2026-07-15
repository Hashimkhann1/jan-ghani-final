// =============================================================
// expense_report_remote_datasource.dart
//
// MAQSAD:
//   WEBSITE / IPA (kIsWeb) par Expense Report ka data Supabase se laana.
//   (Windows/Mac/mobile local postgres use karte hain.)
//
// SOCH (kyun no RPC / no view):
//   Expense data chhota hai. Isliye yahan koi RPC/view NAHI banayi — bas RAW
//   rows (warehouse_expenses) fetch karke saare aggregates APP mein (Dart)
//   compute karte hain. Logic local SQL ka exact mirror hai, to web/desktop
//   ke numbers same aate hain.
//
//   Date boundary local `::date <= to` ka mirror: gte(from-midnight) +
//   lt(to + 1 din). Rows paginated (.range) — 1000-cap safe.
// =============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'expense_report_models.dart';
import 'expense_report_source.dart';

class ExpenseReportRemoteDatasource implements ExpenseReportSource {
  final SupabaseClient _client;
  final String _wid; // selected warehouse id (web par config nahi)

  ExpenseReportRemoteDatasource(this._client, this._wid);

  static const int _pageSize = 1000;

  // Saare (date-filtered) expenses fetch — paginated.
  Future<List<Map<String, dynamic>>> _fetchAll({
    DateTime? from,
    DateTime? to,
  }) async {
    final out = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      var q = _client
          .from('warehouse_expenses')
          .select('expense_head, amount, expense_date')
          .eq('warehouse_id', _wid)
          .filter('deleted_at', 'is', null);
      if (from != null) q = q.gte('expense_date', _dayStart(from));
      if (to   != null) q = q.lt('expense_date', _dayAfter(to));

      final res = await q
          .order('expense_date', ascending: true)
          .range(offset, offset + _pageSize - 1);
      final rows = (res as List).cast<Map<String, dynamic>>();
      out.addAll(rows);
      if (rows.length < _pageSize) break;
      offset += _pageSize;
    }
    return out;
  }

  // ── 1. Summary — total + entries + active days + prev total ─
  @override
  Future<ExpenseReportSummary> getSummary({
    DateTime? from,
    DateTime? to,
    DateTime? prevFrom,
    DateTime? prevTo,
  }) async {
    final rows = await _fetchAll(from: from, to: to);

    double total = 0;
    final days = <String>{};
    for (final e in rows) {
      total += _dbl(e['amount']);
      final d = _parseDate(e['expense_date']);
      days.add('${d.year}-${d.month}-${d.day}');
    }

    // Pichle equal-length period ka total (agar diya gaya ho)
    double prevTotal = 0;
    final hasPrev = prevFrom != null && prevTo != null;
    if (hasPrev) {
      final prevRows = await _fetchAll(from: prevFrom, to: prevTo);
      for (final e in prevRows) {
        prevTotal += _dbl(e['amount']);
      }
    }

    return ExpenseReportSummary(
      totalAmount: total,
      entryCount:  rows.length,
      activeDays:  days.length,
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
    final rows = await _fetchAll(from: from, to: to);

    final amount  = <String, double>{};
    final entries = <String, int>{};
    for (final e in rows) {
      final head = (e['expense_head'] ?? '').toString();
      amount[head]  = (amount[head] ?? 0) + _dbl(e['amount']);
      entries[head] = (entries[head] ?? 0) + 1;
    }

    final list = amount.entries
        .map((e) => ExpenseCategoryRow(
              head:    e.key,
              amount:  e.value,
              entries: entries[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  // ── Helpers ───────────────────────────────────────────────
  static String _dayStart(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

  static String _dayAfter(DateTime d) => DateTime(d.year, d.month, d.day)
      .add(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);

  static DateTime _parseDate(dynamic v) =>
      v is DateTime ? v : (DateTime.tryParse(v.toString()) ?? DateTime.now());

  static double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
