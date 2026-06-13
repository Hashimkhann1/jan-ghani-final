// =============================================================
// purchase_report_local_datasource.dart
// Purchase Report ke liye LOCAL postgres queries (Windows/Mac/mobile).
// Models ab purchase_report_models.dart mein hain (re-exported).
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';
import 'purchase_report_models.dart';
import 'purchase_report_source.dart';

// Purane imports (provider/screen) ke liye models yahin se mil jayein
export 'purchase_report_models.dart';

// ─────────────────────────────────────────────────────────────
// DATASOURCE (LOCAL)
// ─────────────────────────────────────────────────────────────

class PurchaseReportLocalDatasource implements PurchaseReportSource {
  static final PurchaseReportLocalDatasource instance =
      PurchaseReportLocalDatasource._();
  PurchaseReportLocalDatasource._();

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

  // ── 1. Summary stats ─────────────────────────────────────
  @override
  Future<PurchaseSummaryData> getSummary({DateTime? from, DateTime? to}) async {
    final conn     = await _db;
    final dateCond = _dateWhere('order_date', from, to);
    final result   = await conn.execute(
      Sql.named('''
        SELECT
          COUNT(*)                                                                           AS total_pos,
          COALESCE(SUM(total_amount) FILTER (WHERE status = 'received'),              0)   AS total_received_value,
          COUNT(*) FILTER (WHERE status IN ('draft', 'ordered', 'partial'))                AS pending_count,
          COALESCE(SUM(total_amount) FILTER (
            WHERE status = 'received'
              AND DATE_TRUNC('month', order_date) = DATE_TRUNC('month', NOW())
          ), 0)                                                                             AS this_month_value
        FROM purchase_orders
        WHERE warehouse_id = @wid AND deleted_at IS NULL
        $dateCond
      '''),
      parameters: _withDateParams({'wid': _wid}, from, to),
    );

    final r = result.first.toColumnMap();
    return PurchaseSummaryData(
      totalPos:           _parseInt(r['total_pos']),
      totalReceivedValue: _parseDouble(r['total_received_value']),
      pendingCount:       _parseInt(r['pending_count']),
      thisMonthValue:     _parseDouble(r['this_month_value']),
    );
  }

  // ── 2. Status distribution — PieChart ────────────────────
  @override
  Future<List<PoStatusCount>> getStatusDistribution({DateTime? from, DateTime? to}) async {
    final conn     = await _db;
    final dateCond = _dateWhere('order_date', from, to);
    final result   = await conn.execute(
      Sql.named('''
        SELECT status, COUNT(*) AS count
        FROM purchase_orders
        WHERE warehouse_id = @wid AND deleted_at IS NULL
        $dateCond
        GROUP BY status
        ORDER BY count DESC
      '''),
      parameters: _withDateParams({'wid': _wid}, from, to),
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return PoStatusCount(
        status: m['status'].toString(),
        count:  _parseInt(m['count']),
      );
    }).toList();
  }

  // ── 3. Top suppliers by PO value — BarChart ──────────────
  @override
  Future<List<SupplierPoValue>> getTopSuppliersByValue({
    int limit = 6,
    DateTime? from,
    DateTime? to,
  }) async {
    final conn     = await _db;
    final dateCond = _dateWhere('po.order_date', from, to);
    final result   = await conn.execute(
      Sql.named('''
        SELECT
          COALESCE(s.name, 'Unknown') AS supplier_name,
          COALESCE(SUM(po.total_amount), 0) AS total_value
        FROM purchase_orders po
        LEFT JOIN suppliers s ON s.id = po.supplier_id
        WHERE po.warehouse_id = @wid AND po.deleted_at IS NULL
        $dateCond
        GROUP BY po.supplier_id, s.name
        HAVING COALESCE(SUM(po.total_amount), 0) > 0
        ORDER BY total_value DESC
        LIMIT @limit
      '''),
      parameters: _withDateParams({'wid': _wid, 'limit': limit}, from, to),
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return SupplierPoValue(
        supplierName: m['supplier_name'].toString(),
        totalValue:   _parseDouble(m['total_value']),
      );
    }).toList();
  }

  // ── 4. Monthly trend — LineChart ─────────────────────────
  @override
  Future<List<MonthlyPoData>> getMonthlyTrend({DateTime? from, DateTime? to}) async {
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
      return MonthlyPoData(
        month: m['month'] is DateTime
            ? m['month'] as DateTime
            : DateTime.parse(m['month'].toString()),
        total: _parseDouble(m['total']),
      );
    }).toList();
  }

  // ── 5. Supplier completion rate — Progress Bars ───────────
  @override
  Future<List<SupplierCompletionData>> getSupplierCompletion({
    int limit = 8,
    DateTime? from,
    DateTime? to,
  }) async {
    final conn     = await _db;
    final dateCond = _dateWhere('po.order_date', from, to);
    final result   = await conn.execute(
      Sql.named('''
        SELECT
          COALESCE(s.name, 'Unknown')                                        AS supplier_name,
          COALESCE(SUM(poi.quantity_ordered),  0)                            AS total_ordered,
          COALESCE(SUM(poi.quantity_received), 0)                            AS total_received,
          COUNT(DISTINCT po.id)                                              AS total_pos,
          COUNT(DISTINCT po.id) FILTER (WHERE po.status = 'received')       AS received_pos
        FROM purchase_orders po
        LEFT JOIN suppliers s ON s.id = po.supplier_id
        LEFT JOIN purchase_order_items poi ON poi.po_id = po.id
        WHERE po.warehouse_id = @wid AND po.deleted_at IS NULL
        $dateCond
        GROUP BY po.supplier_id, s.name
        HAVING COUNT(DISTINCT po.id) > 0
        ORDER BY total_pos DESC
        LIMIT @limit
      '''),
      parameters: _withDateParams({'wid': _wid, 'limit': limit}, from, to),
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return SupplierCompletionData(
        supplierName:  m['supplier_name'].toString(),
        totalOrdered:  _parseDouble(m['total_ordered']),
        totalReceived: _parseDouble(m['total_received']),
        totalPos:      _parseInt(m['total_pos']),
        receivedPos:   _parseInt(m['received_pos']),
      );
    }).toList();
  }

  // ── 6. Recent POs — latest 20 ────────────────────────────
  @override
  Future<List<RecentPoEntry>> getRecentPos({
    int limit = 20,
    DateTime? from,
    DateTime? to,
  }) async {
    final conn     = await _db;
    final dateCond = _dateWhere('po.order_date', from, to);
    final result   = await conn.execute(
      Sql.named('''
        SELECT
          po.po_number,
          po.status,
          po.order_date::text     AS order_date,
          po.expected_date::text  AS expected_date,
          po.total_amount,
          po.paid_amount,
          COALESCE(s.name, 'No Supplier') AS supplier_name
        FROM purchase_orders po
        LEFT JOIN suppliers s ON s.id = po.supplier_id
        WHERE po.warehouse_id = @wid AND po.deleted_at IS NULL
        $dateCond
        ORDER BY po.created_at DESC
        LIMIT @limit
      '''),
      parameters: _withDateParams({'wid': _wid, 'limit': limit}, from, to),
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return RecentPoEntry(
        poNumber:     m['po_number'].toString(),
        supplierName: m['supplier_name']?.toString(),
        status:       m['status'].toString(),
        orderDate:    DateTime.parse(m['order_date'].toString()),
        expectedDate: m['expected_date'] != null
            ? DateTime.tryParse(m['expected_date'].toString())
            : null,
        totalAmount: _parseDouble(m['total_amount']),
        paidAmount:  _parseDouble(m['paid_amount']),
      );
    }).toList();
  }

  // ── 7. Pending POs only ───────────────────────────────────
  @override
  Future<List<RecentPoEntry>> getPendingPos({DateTime? from, DateTime? to}) async {
    final conn     = await _db;
    final dateCond = _dateWhere('po.order_date', from, to);
    final result   = await conn.execute(
      Sql.named('''
        SELECT
          po.po_number,
          po.status,
          po.order_date::text    AS order_date,
          po.expected_date::text AS expected_date,
          po.total_amount,
          po.paid_amount,
          COALESCE(s.name, 'No Supplier') AS supplier_name
        FROM purchase_orders po
        LEFT JOIN suppliers s ON s.id = po.supplier_id
        WHERE po.warehouse_id = @wid
          AND po.deleted_at IS NULL
          AND po.status IN ('draft', 'ordered', 'partial')
          $dateCond
        ORDER BY po.order_date ASC
      '''),
      parameters: _withDateParams({'wid': _wid}, from, to),
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return RecentPoEntry(
        poNumber:     m['po_number'].toString(),
        supplierName: m['supplier_name']?.toString(),
        status:       m['status'].toString(),
        orderDate:    DateTime.parse(m['order_date'].toString()),
        expectedDate: m['expected_date'] != null
            ? DateTime.tryParse(m['expected_date'].toString())
            : null,
        totalAmount: _parseDouble(m['total_amount']),
        paidAmount:  _parseDouble(m['paid_amount']),
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
