// =============================================================
// supplier_report_local_datasource.dart
// Supplier Report ke liye saari DB queries yahan hain
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';

// ─────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────

class SupplierSummaryData {
  final int totalActive;
  final double totalOutstanding;
  final int clearCount;
  final int hasBalanceCount;
  final double totalPurchased;

  const SupplierSummaryData({
    required this.totalActive,
    required this.totalOutstanding,
    required this.clearCount,
    required this.hasBalanceCount,
    required this.totalPurchased,
  });
}

class SupplierBalanceItem {
  final String name;
  final String? phone;
  final String? code;
  final double outstandingBalance;
  final int totalOrders;
  final double totalPurchased;

  const SupplierBalanceItem({
    required this.name,
    this.phone,
    this.code,
    required this.outstandingBalance,
    required this.totalOrders,
    required this.totalPurchased,
  });
}

class SupplierPurchaseItem {
  final String name;
  final double totalPurchased;

  const SupplierPurchaseItem({
    required this.name,
    required this.totalPurchased,
  });
}

class MonthlyPurchaseData {
  final DateTime month;
  final double total;

  const MonthlyPurchaseData({required this.month, required this.total});
}

class RecentLedgerEntry {
  final String id;
  final String supplierName;
  final String entryType;
  final double amount;
  final double balanceAfter;
  final String? notes;
  final DateTime createdAt;

  const RecentLedgerEntry({
    required this.id,
    required this.supplierName,
    required this.entryType,
    required this.amount,
    required this.balanceAfter,
    this.notes,
    required this.createdAt,
  });

  bool get isCredit => amount < 0;
  bool get isDebit  => amount > 0;

  String get entryTypeLabel {
    switch (entryType) {
      case 'purchase':   return 'Purchase';
      case 'payment':    return 'Payment';
      case 'return':     return 'Return';
      case 'opening':    return 'Opening';
      case 'adjustment': return 'Adjustment';
      default:           return entryType;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// DATASOURCE
// ─────────────────────────────────────────────────────────────

class SupplierReportLocalDatasource {
  static final SupplierReportLocalDatasource instance =
      SupplierReportLocalDatasource._();
  SupplierReportLocalDatasource._();

  Future<Connection> get _db => DatabaseService.getConnection();
  String get _wid => AppConfig.warehouseId;

  // ── 1. Summary stats ─────────────────────────────────────
  Future<SupplierSummaryData> getSummary() async {
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

    final poResult = await conn.execute(
      Sql.named('''
        SELECT COALESCE(SUM(total_amount), 0) AS total_purchased
        FROM purchase_orders
        WHERE warehouse_id = @wid AND deleted_at IS NULL AND status = 'received'
      '''),
      parameters: {'wid': _wid},
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
  Future<List<SupplierPurchaseItem>> getTopByPurchase({int limit = 6}) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT s.name, COALESCE(SUM(po.total_amount), 0) AS total_purchased
        FROM suppliers s
        LEFT JOIN purchase_orders po
          ON  po.supplier_id   = s.id
          AND po.warehouse_id  = @wid
          AND po.deleted_at    IS NULL
          AND po.status        = 'received'
        WHERE s.warehouse_id = @wid
          AND s.deleted_at   IS NULL
          AND s.is_active    = true
        GROUP BY s.id, s.name
        HAVING COALESCE(SUM(po.total_amount), 0) > 0
        ORDER BY total_purchased DESC
        LIMIT @limit
      '''),
      parameters: {'wid': _wid, 'limit': limit},
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return SupplierPurchaseItem(
        name:           m['name'].toString(),
        totalPurchased: _parseDouble(m['total_purchased']),
      );
    }).toList();
  }

  // ── 4. Monthly purchase trend — last 6 months — LineChart ─
  Future<List<MonthlyPurchaseData>> getMonthlyTrend() async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          DATE_TRUNC('month', order_date)::date AS month,
          COALESCE(SUM(total_amount), 0)        AS total
        FROM purchase_orders
        WHERE warehouse_id = @wid
          AND deleted_at IS NULL
          AND status     = 'received'
          AND order_date >= DATE_TRUNC('month', NOW()) - INTERVAL '5 months'
        GROUP BY DATE_TRUNC('month', order_date)
        ORDER BY month
      '''),
      parameters: {'wid': _wid},
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
  Future<List<SupplierBalanceItem>> getAllSuppliers() async {
    final conn = await _db;

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
          GROUP BY supplier_id
        ) po_agg ON po_agg.supplier_id = s.id
        WHERE s.warehouse_id = @wid
          AND s.deleted_at   IS NULL
          AND s.is_active    = true
        ORDER BY s.outstanding_balance DESC
      '''),
      parameters: {'wid': _wid},
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
  Future<List<RecentLedgerEntry>> getRecentLedger({int limit = 20}) async {
    final conn = await _db;

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
        ORDER BY sl.created_at DESC
        LIMIT @limit
      '''),
      parameters: {'wid': _wid, 'limit': limit},
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
