// =============================================================
// purchase_report_local_datasource.dart
// Purchase Report ke liye saari DB queries yahan hain
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';

// ─────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────

class PurchaseSummaryData {
  final int    totalPos;
  final double totalReceivedValue;
  final int    pendingCount;
  final double thisMonthValue;

  const PurchaseSummaryData({
    required this.totalPos,
    required this.totalReceivedValue,
    required this.pendingCount,
    required this.thisMonthValue,
  });
}

class PoStatusCount {
  final String status;
  final int    count;

  const PoStatusCount({required this.status, required this.count});

  String get label {
    switch (status) {
      case 'received':  return 'Received';
      case 'ordered':   return 'Ordered';
      case 'partial':   return 'Partial';
      case 'draft':     return 'Draft';
      case 'cancelled': return 'Cancelled';
      default:          return status;
    }
  }
}

class SupplierPoValue {
  final String supplierName;
  final double totalValue;

  const SupplierPoValue({required this.supplierName, required this.totalValue});
}

class MonthlyPoData {
  final DateTime month;
  final double   total;

  const MonthlyPoData({required this.month, required this.total});
}

class SupplierCompletionData {
  final String supplierName;
  final double totalOrdered;
  final double totalReceived;
  final int    totalPos;
  final int    receivedPos;

  const SupplierCompletionData({
    required this.supplierName,
    required this.totalOrdered,
    required this.totalReceived,
    required this.totalPos,
    required this.receivedPos,
  });

  double get completionRate =>
      totalOrdered == 0 ? 0 : (totalReceived / totalOrdered).clamp(0, 1);
}

class RecentPoEntry {
  final String    poNumber;
  final String?   supplierName;
  final String    status;
  final DateTime  orderDate;
  final DateTime? expectedDate;
  final double    totalAmount;
  final double    paidAmount;

  const RecentPoEntry({
    required this.poNumber,
    this.supplierName,
    required this.status,
    required this.orderDate,
    this.expectedDate,
    required this.totalAmount,
    required this.paidAmount,
  });

  double get remainingAmount =>
      (totalAmount - paidAmount).clamp(0, double.infinity);

  bool get isFullyPaid => remainingAmount <= 0;

  String get statusLabel {
    switch (status) {
      case 'received':  return 'Received';
      case 'ordered':   return 'Ordered';
      case 'partial':   return 'Partial';
      case 'draft':     return 'Draft';
      case 'cancelled': return 'Cancelled';
      default:          return status;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// DATASOURCE
// ─────────────────────────────────────────────────────────────

class PurchaseReportLocalDatasource {
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
