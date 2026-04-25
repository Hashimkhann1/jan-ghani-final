import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/domain/warehouse_dashboard_models.dart';
import 'package:postgres/postgres.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';

class WarehouseDashboardRemoteDataSource {
  Future<Connection> get _db => DatabaseService.getConnection();
  String get _wid => AppConfig.warehouseId;

  // ── DATE CONDITION HELPER ─────────────────────────────────
  String _buildDateCondition(
      PurchaseDateFilter filter,
      DateTime?          dateFrom,
      DateTime?          dateTo,
      ) {
    switch (filter) {
      case PurchaseDateFilter.today:
        return "DATE(created_at AT TIME ZONE 'Asia/Karachi') = CURRENT_DATE";

      case PurchaseDateFilter.thisWeek:
        return "created_at AT TIME ZONE 'Asia/Karachi' >= "
            "DATE_TRUNC('week', NOW() AT TIME ZONE 'Asia/Karachi')";

      case PurchaseDateFilter.thisMonth:
        return "DATE_TRUNC('month', created_at AT TIME ZONE 'Asia/Karachi') = "
            "DATE_TRUNC('month', NOW() AT TIME ZONE 'Asia/Karachi')";

      case PurchaseDateFilter.last3Months:
        return "created_at AT TIME ZONE 'Asia/Karachi' >= "
            "(NOW() AT TIME ZONE 'Asia/Karachi' - INTERVAL '3 months')";

      case PurchaseDateFilter.custom:
        if (dateFrom != null && dateTo != null) {
          return "DATE(created_at AT TIME ZONE 'Asia/Karachi') "
              "BETWEEN @dateFrom::date AND @dateTo::date";
        }
        return "DATE(created_at AT TIME ZONE 'Asia/Karachi') = CURRENT_DATE";
    }
  }

  // ── STATS ─────────────────────────────────────────────────
  Future<DashboardStats> getStats({
    PurchaseDateFilter filter    = PurchaseDateFilter.today,
    DateTime?          dateFrom,
    DateTime?          dateTo,
  }) async {
    final conn          = await _db;
    final dateCondition = _buildDateCondition(filter, dateFrom, dateTo);
    final Map<String, dynamic> params = {'wid': _wid};
    if (filter == PurchaseDateFilter.custom &&
        dateFrom != null &&
        dateTo != null) {
      params['dateFrom'] = dateFrom.toIso8601String().substring(0, 10);
      params['dateTo']   = dateTo.toIso8601String().substring(0, 10);
    }

    final result = await conn.execute(
      Sql.named('''
      SELECT
        (SELECT COUNT(*)::int
         FROM warehouse_products
         WHERE warehouse_id = @wid
           AND is_active    = true
           AND deleted_at   IS NULL
        ) AS total_products,

        (SELECT COUNT(*)::int
         FROM v_reorder_needed
         WHERE warehouse_id = @wid
        ) AS low_stock_count,

        (SELECT COUNT(*)::int
         FROM suppliers
         WHERE warehouse_id = @wid
           AND is_active    = true
           AND deleted_at   IS NULL
        ) AS active_suppliers,

        (SELECT COALESCE(SUM(outstanding_balance), 0)
         FROM suppliers
         WHERE warehouse_id = @wid
           AND is_active    = true
           AND deleted_at   IS NULL
        ) AS total_outstanding,

        (SELECT COUNT(*)::int
         FROM purchase_orders
         WHERE warehouse_id = @wid
           AND status       IN ('draft','ordered','partial')
           AND deleted_at   IS NULL
        ) AS pending_pos,

        (SELECT COUNT(*)::int
         FROM v_unsynced
         WHERE warehouse_id = @wid
        ) AS unsynced_records,

        (SELECT COALESCE(SUM(total_amount), 0)
         FROM purchase_orders
         WHERE warehouse_id = @wid
           AND status       != 'cancelled'
           AND deleted_at   IS NULL
           AND $dateCondition
        ) AS total_purchase_amount,

        (SELECT COUNT(*)::int
         FROM purchase_orders
         WHERE warehouse_id = @wid
           AND status       != 'cancelled'
           AND deleted_at   IS NULL
           AND $dateCondition
        ) AS total_orders_count
      '''),
      parameters: params,
    );

    final m = result.first.toColumnMap();
    return DashboardStats(
      totalProducts:       _toInt(m['total_products']),
      lowStockCount:       _toInt(m['low_stock_count']),
      activeSuppliers:     _toInt(m['active_suppliers']),
      totalOutstanding:    _toDouble(m['total_outstanding']),
      pendingPOs:          _toInt(m['pending_pos']),
      unsyncedRecords:     _toInt(m['unsynced_records']),
      totalPurchaseAmount: _toDouble(m['total_purchase_amount']),
      totalOrdersCount:    _toInt(m['total_orders_count']),
    );
  }

  // ── PURCHASE TREND ────────────────────────────────────────
  Future<List<PurchaseTrendPoint>> getPurchaseTrend({
    PurchaseDateFilter filter    = PurchaseDateFilter.today,
    DateTime?          dateFrom,
    DateTime?          dateTo,
  }) async {
    final conn = await _db;
    final Map<String, dynamic> params = {'wid': _wid};
    String query;

    switch (filter) {
      case PurchaseDateFilter.today:
        query = '''
          SELECT
            EXTRACT(HOUR FROM created_at AT TIME ZONE 'Asia/Karachi')::int AS period,
            COALESCE(SUM(total_amount), 0) AS amount
          FROM purchase_orders
          WHERE warehouse_id = @wid
            AND status       != 'cancelled'
            AND deleted_at   IS NULL
            AND DATE(created_at AT TIME ZONE 'Asia/Karachi') = CURRENT_DATE
          GROUP BY period
          ORDER BY period
        ''';
        break;

      case PurchaseDateFilter.thisWeek:
        query = '''
          SELECT
            DATE(created_at AT TIME ZONE 'Asia/Karachi') AS period,
            COALESCE(SUM(total_amount), 0) AS amount
          FROM purchase_orders
          WHERE warehouse_id = @wid
            AND status       != 'cancelled'
            AND deleted_at   IS NULL
            AND created_at AT TIME ZONE 'Asia/Karachi'
                >= DATE_TRUNC('week', NOW() AT TIME ZONE 'Asia/Karachi')
          GROUP BY period
          ORDER BY period
        ''';
        break;

      case PurchaseDateFilter.thisMonth:
        query = '''
          SELECT
            DATE(created_at AT TIME ZONE 'Asia/Karachi') AS period,
            COALESCE(SUM(total_amount), 0) AS amount
          FROM purchase_orders
          WHERE warehouse_id = @wid
            AND status       != 'cancelled'
            AND deleted_at   IS NULL
            AND DATE_TRUNC('month', created_at AT TIME ZONE 'Asia/Karachi')
                = DATE_TRUNC('month', NOW() AT TIME ZONE 'Asia/Karachi')
          GROUP BY period
          ORDER BY period
        ''';
        break;

      case PurchaseDateFilter.last3Months:
        query = '''
          SELECT
            DATE_TRUNC('week', created_at AT TIME ZONE 'Asia/Karachi')::date AS period,
            COALESCE(SUM(total_amount), 0) AS amount
          FROM purchase_orders
          WHERE warehouse_id = @wid
            AND status       != 'cancelled'
            AND deleted_at   IS NULL
            AND created_at AT TIME ZONE 'Asia/Karachi'
                >= (NOW() AT TIME ZONE 'Asia/Karachi' - INTERVAL '3 months')
          GROUP BY period
          ORDER BY period
        ''';
        break;

      case PurchaseDateFilter.custom:
        if (dateFrom == null || dateTo == null) return [];
        params['dateFrom'] = dateFrom.toIso8601String().substring(0, 10);
        params['dateTo']   = dateTo.toIso8601String().substring(0, 10);
        final diff = dateTo.difference(dateFrom).inDays;
        if (diff <= 14) {
          query = '''
            SELECT
              DATE(created_at AT TIME ZONE 'Asia/Karachi') AS period,
              COALESCE(SUM(total_amount), 0) AS amount
            FROM purchase_orders
            WHERE warehouse_id = @wid
              AND status       != 'cancelled'
              AND deleted_at   IS NULL
              AND DATE(created_at AT TIME ZONE 'Asia/Karachi')
                  BETWEEN @dateFrom::date AND @dateTo::date
            GROUP BY period
            ORDER BY period
          ''';
        } else {
          query = '''
            SELECT
              DATE_TRUNC('week', created_at AT TIME ZONE 'Asia/Karachi')::date AS period,
              COALESCE(SUM(total_amount), 0) AS amount
            FROM purchase_orders
            WHERE warehouse_id = @wid
              AND status       != 'cancelled'
              AND deleted_at   IS NULL
              AND DATE(created_at AT TIME ZONE 'Asia/Karachi')
                  BETWEEN @dateFrom::date AND @dateTo::date
            GROUP BY period
            ORDER BY period
          ''';
        }
        break;
    }

    final result = await conn.execute(
      Sql.named(query),
      parameters: params,
    );

    return result.map((row) {
      final m      = row.toColumnMap();
      final period = m['period'];
      final amount = _toDouble(m['amount']);

      String label;
      if (filter == PurchaseDateFilter.today) {
        final h   = (period as num).toInt();
        final am  = h < 12 ? 'AM' : 'PM';
        final h12 = h % 12 == 0 ? 12 : h % 12;
        label = '$h12$am';
      } else if (filter == PurchaseDateFilter.thisWeek) {
        final dt   = period is DateTime
            ? period : DateTime.parse(period.toString());
        final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
        label = days[dt.weekday - 1];
      } else {
        final dt     = period is DateTime
            ? period : DateTime.parse(period.toString());
        final months = ['Jan','Feb','Mar','Apr','May','Jun',
          'Jul','Aug','Sep','Oct','Nov','Dec'];
        label = '${dt.day} ${months[dt.month - 1]}';
      }

      return PurchaseTrendPoint(label: label, amount: amount);
    }).toList();
  }

  // ── SUPPLIER OUTSTANDING BARS ─────────────────────────────
  Future<List<SupplierOutstandingBar>> getSupplierOutstandingBars() async {
    final conn   = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT
          id                  AS supplier_id,
          name                AS supplier_name,
          outstanding_balance
        FROM suppliers
        WHERE warehouse_id        = @wid
          AND is_active           = true
          AND deleted_at          IS NULL
          AND outstanding_balance > 0
        ORDER BY outstanding_balance DESC
        LIMIT 6
      '''),
      parameters: {'wid': _wid},
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return SupplierOutstandingBar(
        supplierId:        m['supplier_id'].toString(),
        supplierName:      m['supplier_name'].toString(),
        outstandingAmount: _toDouble(m['outstanding_balance']),
      );
    }).toList();
  }

  // ── RECENT POs — pending pehle ────────────────────────────
  Future<List<RecentPurchaseOrder>> getRecentPOs() async {
    final conn   = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT
          po.id,
          po.po_number,
          COALESCE(s.name, 'Unknown') AS supplier_name,
          po.status,
          po.total_amount,
          po.order_date
        FROM purchase_orders po
        LEFT JOIN suppliers s ON s.id = po.supplier_id
        WHERE po.warehouse_id = @wid
          AND po.deleted_at   IS NULL
        ORDER BY
          CASE po.status
            WHEN 'ordered'   THEN 1
            WHEN 'partial'   THEN 2
            WHEN 'draft'     THEN 3
            WHEN 'received'  THEN 4
            WHEN 'cancelled' THEN 5
            ELSE 6
          END,
          po.created_at DESC
        LIMIT 5
      '''),
      parameters: {'wid': _wid},
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return RecentPurchaseOrder(
        id:           m['id'].toString(),
        poNumber:     m['po_number'].toString(),
        supplierName: m['supplier_name'].toString(),
        status:       m['status'].toString(),
        totalAmount:  _toDouble(m['total_amount']),
        orderDate:    m['order_date'] is DateTime
            ? m['order_date'] as DateTime
            : DateTime.parse(m['order_date'].toString()),
      );
    }).toList();
  }

  // ── LOW STOCK ─────────────────────────────────────────────
  Future<List<LowStockItem>> getLowStockItems() async {
    final conn   = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT
          product_id,
          product_name,
          sku,
          current_stock,
          reorder_point,
          max_stock_level,
          quantity_to_order
        FROM v_reorder_needed
        WHERE warehouse_id = @wid
        ORDER BY current_stock ASC
        LIMIT 5
      '''),
      parameters: {'wid': _wid},
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return LowStockItem(
        productId:       m['product_id'].toString(),
        productName:     m['product_name'].toString(),
        sku:             m['sku'].toString(),
        currentStock:    _toDouble(m['current_stock']),
        reorderPoint:    _toInt(m['reorder_point']),
        maxStockLevel:   m['max_stock_level'] != null
            ? _toInt(m['max_stock_level']) : null,
        quantityToOrder: _toDouble(m['quantity_to_order']),
      );
    }).toList();
  }

  // ── SUPPLIER DUES ─────────────────────────────────────────
  Future<List<SupplierDue>> getSupplierDues() async {
    final conn   = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT
          s.id            AS supplier_id,
          s.name          AS supplier_name,
          COALESCE(s.company_name, s.name) AS company_name,
          s.payment_terms,
          s.outstanding_balance
        FROM suppliers s
        WHERE s.warehouse_id        = @wid
          AND s.is_active           = true
          AND s.deleted_at          IS NULL
          AND s.outstanding_balance > 0
        ORDER BY s.outstanding_balance DESC
        LIMIT 5
      '''),
      parameters: {'wid': _wid},
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return SupplierDue(
        supplierId:        m['supplier_id'].toString(),
        supplierName:      m['supplier_name'].toString(),
        companyName:       m['company_name'].toString(),
        paymentTerms:      _toInt(m['payment_terms']),
        outstandingAmount: _toDouble(m['outstanding_balance']),
      );
    }).toList();
  }

  // ── HELPERS ───────────────────────────────────────────────
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}