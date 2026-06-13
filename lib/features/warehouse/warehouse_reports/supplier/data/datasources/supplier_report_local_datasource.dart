// =============================================================
// supplier_report_local_datasource.dart
// Supplier Report ke liye LOCAL postgres queries (Windows/Mac/mobile).
// Models ab supplier_report_models.dart mein hain (re-exported).
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';
import 'supplier_report_models.dart';
import 'supplier_report_source.dart';

// Purane imports (provider/screen) ke liye models yahin se mil jayein
export 'supplier_report_models.dart';

// ─────────────────────────────────────────────────────────────
// DATASOURCE (LOCAL)
// ─────────────────────────────────────────────────────────────

class SupplierReportLocalDatasource implements SupplierReportSource {
  static final SupplierReportLocalDatasource instance =
      SupplierReportLocalDatasource._();
  SupplierReportLocalDatasource._();

  Future<Connection> get _db => DatabaseService.getConnection();
  String get _wid => AppConfig.warehouseId;

  // ── Date filter helpers ───────────────────────────────────
  // Codebase convention: column ko ::date cast karke YYYY-MM-DD
  // string ke saath compare karte hain (timezone/time-of-day safe).
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

  // ── Balance status helper ─────────────────────────────────
  static String _balanceWhere(BalanceStatusFilter f, {String col = 's.outstanding_balance'}) {
    switch (f) {
      case BalanceStatusFilter.outstanding: return 'AND $col > 0';
      case BalanceStatusFilter.clear:       return 'AND $col = 0';
      case BalanceStatusFilter.all:         return '';
    }
  }

  // ── 1. Summary stats ─────────────────────────────────────
  // Note: supplier counts/outstanding LIVE/current state hain (date se
  // filter nahi hote). Sirf total_purchased date range follow karta hai.
  @override
  Future<SupplierSummaryData> getSummary({DateTime? from, DateTime? to}) async {
    final conn = await _db;

    final suppResult = await conn.execute(
      Sql.named('''
        SELECT
          COUNT(*) FILTER (WHERE is_active = true AND deleted_at IS NULL)
            AS total_active,
          COALESCE(SUM(outstanding_balance)
            FILTER (WHERE outstanding_balance > 0 AND deleted_at IS NULL), 0)
            AS total_outstanding,
          COUNT(*) FILTER (WHERE outstanding_balance = 0 AND is_active = true AND deleted_at IS NULL)
            AS clear_count,
          COUNT(*) FILTER (WHERE outstanding_balance > 0 AND is_active = true AND deleted_at IS NULL)
            AS has_balance_count
        FROM suppliers
        WHERE warehouse_id = @wid
      '''),
      parameters: {'wid': _wid},
    );

    final poDateCond = _dateWhere('order_date', from, to);
    final poResult = await conn.execute(
      Sql.named('''
        SELECT COALESCE(SUM(total_amount), 0) AS total_purchased
        FROM purchase_orders
        WHERE warehouse_id = @wid AND deleted_at IS NULL AND status = 'received'
        $poDateCond
      '''),
      parameters: _withDateParams({'wid': _wid}, from, to),
    );

    final s = suppResult.first.toColumnMap();
    final p = poResult.first.toColumnMap();

    return SupplierSummaryData(
      totalActive:      _parseInt(s['total_active']),
      totalOutstanding: _parseDouble(s['total_outstanding']),
      clearCount:       _parseInt(s['clear_count']),
      hasBalanceCount:  _parseInt(s['has_balance_count']),
      totalPurchased:   _parseDouble(p['total_purchased']),
    );
  }

  // ── 2. Top suppliers by outstanding balance — PieChart ───
  @override
  Future<List<SupplierBalanceItem>> getTopByBalance({int limit = 6}) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT name, outstanding_balance
        FROM suppliers
        WHERE warehouse_id = @wid
          AND deleted_at       IS NULL
          AND is_active        = true
          AND outstanding_balance > 0
        ORDER BY outstanding_balance DESC
        LIMIT @limit
      '''),
      parameters: {'wid': _wid, 'limit': limit},
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return SupplierBalanceItem(
        name:               m['name'].toString(),
        outstandingBalance: _parseDouble(m['outstanding_balance']),
        totalOrders:        0,
        totalPurchased:     0,
      );
    }).toList();
  }

  // ── 3. Top suppliers by purchase volume — BarChart ───────
  @override
  Future<List<SupplierPurchaseItem>> getTopByPurchase({
    int limit = 6,
    DateTime? from,
    DateTime? to,
  }) async {
    final conn     = await _db;
    final dateCond = _dateWhere('po.order_date', from, to);

    final result = await conn.execute(
      Sql.named('''
        SELECT s.name, COALESCE(SUM(po.total_amount), 0) AS total_purchased
        FROM suppliers s
        LEFT JOIN purchase_orders po
          ON  po.supplier_id   = s.id
          AND po.warehouse_id  = @wid
          AND po.deleted_at    IS NULL
          AND po.status        = 'received'
          $dateCond
        WHERE s.warehouse_id = @wid
          AND s.deleted_at   IS NULL
          AND s.is_active    = true
        GROUP BY s.id, s.name
        HAVING COALESCE(SUM(po.total_amount), 0) > 0
        ORDER BY total_purchased DESC
        LIMIT @limit
      '''),
      parameters: _withDateParams({'wid': _wid, 'limit': limit}, from, to),
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return SupplierPurchaseItem(
        name:           m['name'].toString(),
        totalPurchased: _parseDouble(m['total_purchased']),
      );
    }).toList();
  }

  // ── 4. Monthly purchase trend — LineChart ────────────────
  @override
  Future<List<MonthlyPurchaseData>> getMonthlyTrend({DateTime? from, DateTime? to}) async {
    final conn = await _db;

    final String dateCond;
    final Map<String, dynamic> params = {'wid': _wid};

    if (from != null || to != null) {
      dateCond = _dateWhere('order_date', from, to);
      if (from != null) params['from'] = from.toIso8601String().substring(0, 10);
      if (to   != null) params['to']   = to.toIso8601String().substring(0, 10);
    } else {
      // default: last 6 months
      dateCond = "AND order_date >= DATE_TRUNC('month', NOW()) - INTERVAL '5 months'";
    }

    final result = await conn.execute(
      Sql.named('''
        SELECT
          DATE_TRUNC('month', order_date)::date AS month,
          COALESCE(SUM(total_amount), 0)        AS total
        FROM purchase_orders
        WHERE warehouse_id = @wid
          AND deleted_at IS NULL
          AND status     = 'received'
          $dateCond
        GROUP BY DATE_TRUNC('month', order_date)
        ORDER BY month
      '''),
      parameters: params,
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return MonthlyPurchaseData(
        month: m['month'] is DateTime
            ? m['month'] as DateTime
            : DateTime.parse(m['month'].toString()),
        total: _parseDouble(m['total']),
      );
    }).toList();
  }

  // ── 5. All suppliers list for table ──────────────────────
  // Date filter → PO aggregation (orders/purchased) pe.
  // Balance status filter → kaunse supplier rows dikhein.
  @override
  Future<List<SupplierBalanceItem>> getAllSuppliers({
    DateTime? from,
    DateTime? to,
    BalanceStatusFilter balanceStatus = BalanceStatusFilter.all,
  }) async {
    final conn        = await _db;
    final dateCond    = _dateWhere('order_date', from, to);
    final balanceCond = _balanceWhere(balanceStatus);

    final result = await conn.execute(
      Sql.named('''
        SELECT
          s.name,
          s.phone,
          s.code,
          s.outstanding_balance,
          COALESCE(po_agg.total_orders,    0) AS total_orders,
          COALESCE(po_agg.total_purchased, 0) AS total_purchased
        FROM suppliers s
        LEFT JOIN (
          SELECT
            supplier_id,
            COUNT(*)          AS total_orders,
            SUM(total_amount) AS total_purchased
          FROM purchase_orders
          WHERE warehouse_id = @wid AND deleted_at IS NULL AND status = 'received'
            $dateCond
          GROUP BY supplier_id
        ) po_agg ON po_agg.supplier_id = s.id
        WHERE s.warehouse_id = @wid
          AND s.deleted_at   IS NULL
          AND s.is_active    = true
          $balanceCond
        ORDER BY s.outstanding_balance DESC
      '''),
      parameters: _withDateParams({'wid': _wid}, from, to),
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return SupplierBalanceItem(
        name:               m['name'].toString(),
        phone:              m['phone']?.toString(),
        code:               m['code']?.toString(),
        outstandingBalance: _parseDouble(m['outstanding_balance']),
        totalOrders:        _parseInt(m['total_orders']),
        totalPurchased:     _parseDouble(m['total_purchased']),
      );
    }).toList();
  }

  // ── 6. Recent ledger entries (last 20) ───────────────────
  @override
  Future<List<RecentLedgerEntry>> getRecentLedger({
    int limit = 20,
    DateTime? from,
    DateTime? to,
  }) async {
    final conn     = await _db;
    final dateCond = _dateWhere('sl.created_at', from, to);

    final result = await conn.execute(
      Sql.named('''
        SELECT
          sl.id,
          sl.entry_type,
          sl.amount,
          sl.balance_after,
          sl.notes,
          sl.created_at,
          s.name AS supplier_name
        FROM supplier_ledger sl
        JOIN suppliers s ON s.id = sl.supplier_id
        WHERE sl.warehouse_id = @wid
          $dateCond
        ORDER BY sl.created_at DESC
        LIMIT @limit
      '''),
      parameters: _withDateParams({'wid': _wid, 'limit': limit}, from, to),
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return RecentLedgerEntry(
        id:           m['id'].toString(),
        supplierName: m['supplier_name'].toString(),
        entryType:    m['entry_type'].toString(),
        amount:       _parseDouble(m['amount']),
        balanceAfter: _parseDouble(m['balance_after']),
        notes:        m['notes']?.toString(),
        createdAt:    m['created_at'] is DateTime
            ? m['created_at'] as DateTime
            : DateTime.parse(m['created_at'].toString()),
      );
    }).toList();
  }

  // ── Safe parsers ──────────────────────────────────────────
  static double _parseDouble(dynamic v) {
    if (v == null)   return 0.0;
    if (v is double) return v;
    if (v is num)    return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int)  return v;
    if (v is num)  return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
