// =============================================================
// cash_flow_report_remote_datasource.dart
//
// MAQSAD:
//   WEBSITE (kIsWeb) par Cash Flow Report ka data Supabase se laana.
//   (Windows/Mac/mobile local postgres use karte hain.)
//
// SOCH (kyun no RPC / no view):
//   Cash flow data chhota hai (~250 transactions, ~30 expenses). Isliye
//   yahan koi RPC/view NAHI banayi — bas RAW rows (transactions + finance +
//   expenses) Supabase se fetch karke saare aggregates APP mein (Dart)
//   compute karte hain. Logic local SQL ka exact mirror hai, to web aur
//   desktop ke numbers same aate hain.
//
//   Tables (sab READ-ONLY .select()):
//     warehouse_finance           → cash_in_hand (LIVE balance)
//     warehouse_cash_transactions → cash in/out, type breakdown, monthly, list
//     warehouse_expenses          → expense breakdown
// =============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'cash_flow_report_models.dart';
import 'cash_flow_report_source.dart';

class CashFlowReportRemoteDatasource implements CashFlowReportSource {
  final SupabaseClient _client;
  final String _wid; // selected warehouse id (web par config nahi)

  CashFlowReportRemoteDatasource(this._client, this._wid);

  static const int _pageSize = 1000;

  // ── 1. Summary ─────────────────────────────────────────────
  // cashInHand → LIVE (warehouse_finance). period in/out → date range ke
  // transactions ke ABS(amount) sums (cash_in vs baaki). prevNet → pichle
  // equal-length period ka net (vs-last % ke liye). Saare transactions ek
  // baar fetch karke period aur prev dono Dart mein compute karte hain.
  @override
  Future<CashFlowSummary> getSummary({
    DateTime? from,
    DateTime? to,
    DateTime? prevFrom,
    DateTime? prevTo,
  }) async {
    // LIVE cash in hand + saare transactions parallel
    final finFuture = _client
        .from('warehouse_finance')
        .select('cash_in_hand')
        .eq('warehouse_id', _wid)
        .limit(1)
        .maybeSingle();
    final txnsFuture = _fetchAllTxns(select: 'entry_type, amount, created_at');

    final fin  = await finFuture;
    final txns = await txnsFuture;

    final cashInHand = fin == null ? 0.0 : _dbl(fin['cash_in_hand']);
    final hasPrev    = prevFrom != null && prevTo != null;

    double periodIn = 0, periodOut = 0, prevIn = 0, prevOut = 0;
    for (final t in txns) {
      final dt      = _parseDate(t['created_at']);
      final isIn    = t['entry_type'] == 'cash_in';
      final amt     = _dbl(t['amount']).abs();

      if (_inRange(dt, from, to)) {
        if (isIn) {
          periodIn += amt;
        } else {
          periodOut += amt;
        }
      }
      if (hasPrev && _inRange(dt, prevFrom, prevTo)) {
        if (isIn) {
          prevIn += amt;
        } else {
          prevOut += amt;
        }
      }
    }

    return CashFlowSummary(
      cashInHand:    cashInHand,
      periodCashIn:  periodIn,
      periodCashOut: periodOut,
      prevPeriodNet: prevIn - prevOut,
      hasPrev:       hasPrev,
    );
  }

  // ── 2. Monthly cash flow — ALWAYS last 6 months ────────────
  // Har mahine: cash in/out (ABS sums) + month-end balance (us mahine ke
  // AAKHRI transaction ka cash_in_hand_after). Phir 6 mahine guarantee karne
  // ke liye missing months zero/carry-forward se bhar dete hain.
  @override
  Future<List<MonthlyCashFlowData>> getMonthlyData() async {
    final now    = DateTime.now();
    final cutoff = DateTime(now.year, now.month - 5, 1); // 6 mahine pehle ka start

    final txns = await _fetchAllTxns(
      select: 'entry_type, amount, cash_in_hand_after, created_at',
      from: cutoff,
    );

    final cashIn  = <DateTime, double>{};
    final cashOut = <DateTime, double>{};
    // Month-end balance ke liye: har mahine ke latest transaction ko track karo
    final lastAt  = <DateTime, DateTime>{};
    final endBal  = <DateTime, double>{};

    for (final t in txns) {
      final dt  = _parseDate(t['created_at']);
      final key = DateTime(dt.year, dt.month, 1);
      final amt = _dbl(t['amount']).abs();

      if (t['entry_type'] == 'cash_in') {
        cashIn[key] = (cashIn[key] ?? 0) + amt;
      } else {
        cashOut[key] = (cashOut[key] ?? 0) + amt;
      }

      // sabse naya (max created_at) transaction is mahine ka — uska balance
      if (lastAt[key] == null || dt.isAfter(lastAt[key]!)) {
        lastAt[key] = dt;
        endBal[key] = _dbl(t['cash_in_hand_after']);
      }
    }

    final keys = {...cashIn.keys, ...cashOut.keys, ...endBal.keys}.toList();
    final db = keys.map((k) => MonthlyCashFlowData(
          month:      k,
          cashIn:     cashIn[k] ?? 0,
          cashOut:    cashOut[k] ?? 0,
          endBalance: endBal[k] ?? 0,
        )).toList();

    return _fillMissingMonths(db);
  }

  // ── 3. Expense breakdown — donut ───────────────────────────
  // warehouse_expenses ko expense_head se group karke top 8 (value DESC).
  @override
  Future<List<ExpenseCategoryData>> getExpenseBreakdown({
    DateTime? from,
    DateTime? to,
  }) async {
    var q = _client
        .from('warehouse_expenses')
        .select('expense_head, amount')
        .eq('warehouse_id', _wid)
        .filter('deleted_at', 'is', null);
    if (from != null) q = q.gte('expense_date', _dayStart(from));
    if (to   != null) q = q.lt('expense_date', _dayAfter(to));

    final rows = (await q) as List;

    final byHead = <String, double>{};
    for (final e in rows) {
      final m = e as Map<String, dynamic>;
      final head = (m['expense_head'] ?? '').toString();
      byHead[head] = (byHead[head] ?? 0) + _dbl(m['amount']);
    }

    final list = byHead.entries
        .map((e) => ExpenseCategoryData(category: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list.take(8).toList();
  }

  // ── 4. Transaction type breakdown — progress bars ──────────
  // Date-filtered transactions ko entry_type se group karke ABS sum.
  @override
  Future<List<TransactionTypeData>> getTypeBreakdown({
    DateTime? from,
    DateTime? to,
  }) async {
    final txns = await _fetchAllTxns(
      select: 'entry_type, amount, created_at',
      from: from,
      to: to,
    );

    final byType = <String, double>{};
    for (final t in txns) {
      final type = (t['entry_type'] ?? '').toString();
      byType[type] = (byType[type] ?? 0) + _dbl(t['amount']).abs();
    }

    final list = byType.entries
        .map((e) => TransactionTypeData(type: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  // ── 5. Recent transactions — drill-down list ──────────────
  // Date + optional type filter, created_at DESC, limit. (Server-side limit.)
  @override
  Future<List<CashTransactionEntry>> getRecentTransactions({
    DateTime? from,
    DateTime? to,
    String? type,
    int limit = 200,
  }) async {
    var q = _client
        .from('warehouse_cash_transactions')
        .select('id, entry_type, amount, cash_in_hand_after, notes, created_by_name, created_at')
        .eq('warehouse_id', _wid);
    if (from != null) q = q.gte('created_at', _dayStart(from));
    if (to   != null) q = q.lt('created_at', _dayAfter(to));
    if (type != null) q = q.eq('entry_type', type);

    final rows = (await q.order('created_at', ascending: false).limit(limit)) as List;

    return rows.map((e) {
      final m = e as Map<String, dynamic>;
      return CashTransactionEntry(
        id:           m['id'].toString(),
        entryType:    (m['entry_type'] ?? '').toString(),
        amount:       _dbl(m['amount']).abs(),
        balanceAfter: _dbl(m['cash_in_hand_after']),
        notes:        m['notes']?.toString(),
        byName:       m['created_by_name']?.toString(),
        createdAt:    _parseDate(m['created_at']),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────
  // RAW FETCH + HELPERS
  // ─────────────────────────────────────────────────────────

  // Date-filtered transactions (paginated — 1000-cap safe). `select` se
  // sirf zaroori columns aate hain. Date boundary local `::date` ka mirror:
  // gte(from-midnight) + lt(to+1 din) → poora `to` din shaamil.
  Future<List<Map<String, dynamic>>> _fetchAllTxns({
    required String select,
    DateTime? from,
    DateTime? to,
  }) async {
    final out = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      var q = _client
          .from('warehouse_cash_transactions')
          .select(select)
          .eq('warehouse_id', _wid);
      if (from != null) q = q.gte('created_at', _dayStart(from));
      if (to   != null) q = q.lt('created_at', _dayAfter(to));

      final res = await q
          .order('created_at', ascending: true)
          .range(offset, offset + _pageSize - 1);
      final rows = (res as List).cast<Map<String, dynamic>>();
      out.addAll(rows);
      if (rows.length < _pageSize) break;
      offset += _pageSize;
    }
    return out;
  }

  // 6 mahine guarantee — missing months ko zero (balance carry-forward) se bhar.
  // (Local datasource ke _fillMissingMonths ka exact mirror.)
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

  // created_at ki DATE [from..to] range mein hai? (time ignore — local ::date)
  static bool _inRange(DateTime dt, DateTime? from, DateTime? to) {
    final d = DateTime(dt.year, dt.month, dt.day);
    if (from != null && d.isBefore(DateTime(from.year, from.month, from.day))) {
      return false;
    }
    if (to != null && d.isAfter(DateTime(to.year, to.month, to.day))) {
      return false;
    }
    return true;
  }

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
