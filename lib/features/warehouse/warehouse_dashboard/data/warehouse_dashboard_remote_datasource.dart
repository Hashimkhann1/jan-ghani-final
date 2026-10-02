// Updated on 2026-10-02 09:35 AM
// =============================================================
// warehouse_dashboard_remote_datasource.dart
// Dashboard v2 (Stitch design) — LOCAL postgres queries.
//
// Period (filter) [start, end) Dart mein banta hai (DashboardPeriod)
// aur timestamptz params ke tor par jata hai. Period par chalte hain:
// cash in/out, purchases, expenses, chart, stock movements.
// Baaki (cash in hand, dues, inventory, low/out of stock, pending)
// hamesha LIVE.
//
// Rules (poore app ke saath consistent):
//   • Purchases = po_type 'purchase' + status 'received' (return/draft nahi)
//   • Cash out  = cash_in ke ilawa sab; supplier_payment_reversal MINUS
//   • Low stock = track stock, reorder_point > 0, available <= reorder_point
//   • Out of stock = track stock, available <= 0   (available = qty − reserved)
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/domain/warehouse_dashboard_models.dart';
import 'package:postgres/postgres.dart';

class WarehouseDashboardRemoteDataSource {
  Future<Connection> get _db => DatabaseService.getConnection();
  String get _wid => AppConfig.warehouseId;

  // Cash OUT ka signed amount (reversal = galat payment ki correction)
  static const _signedOut =
      "CASE WHEN entry_type = 'supplier_payment_reversal' "
      "THEN -amount ELSE amount END";

  // Available stock per product (inventory row na ho to 0)
  static const _availableCte = '''
    WITH stock AS (
      SELECT
        p.id, p.name, p.sku, p.unit_of_measure, p.reorder_point,
        p.purchase_price, p.is_track_stock,
        COALESCE(SUM(i.quantity), 0)                            AS qty,
        COALESCE(SUM(i.quantity - i.reserved_quantity), 0)      AS available
      FROM warehouse_products p
      LEFT JOIN warehouse_inventory i
        ON i.product_id = p.id AND i.warehouse_id = @wid
      WHERE p.warehouse_id = @wid
        AND p.is_active    = true
        AND p.deleted_at   IS NULL
      GROUP BY p.id
    )
  ''';

  // ── 1. KPI + Needs attention ──────────────────────────────
  Future<DashboardSummary> getSummary(DashboardPeriod period) async {
    final conn   = await _db;
    final result = await conn.execute(
      Sql.named('''
        $_availableCte
        SELECT
          (SELECT COALESCE(cash_in_hand, 0) FROM warehouse_finance
            WHERE warehouse_id = @wid LIMIT 1)                       AS cash_in_hand,

          (SELECT COALESCE(SUM(amount), 0) FROM warehouse_cash_transactions
            WHERE warehouse_id = @wid AND entry_type = 'cash_in'
              AND created_at >= @start AND created_at < @end)        AS period_in,

          (SELECT COALESCE(SUM($_signedOut), 0) FROM warehouse_cash_transactions
            WHERE warehouse_id = @wid AND entry_type <> 'cash_in'
              AND created_at >= @start AND created_at < @end)        AS period_out,

          (SELECT COALESCE(SUM(total_amount), 0) FROM purchase_orders
            WHERE warehouse_id = @wid AND deleted_at IS NULL
              AND po_type = 'purchase' AND status = 'received'
              AND created_at >= @start AND created_at < @end)        AS purchase_amount,

          (SELECT COUNT(*)::int FROM purchase_orders
            WHERE warehouse_id = @wid AND deleted_at IS NULL
              AND po_type = 'purchase' AND status = 'received'
              AND created_at >= @start AND created_at < @end)        AS purchase_count,

          (SELECT COALESCE(SUM(outstanding_balance), 0) FROM suppliers
            WHERE warehouse_id = @wid AND is_active = true
              AND deleted_at IS NULL AND outstanding_balance > 0)    AS supplier_outstanding,

          (SELECT COUNT(*)::int FROM suppliers
            WHERE warehouse_id = @wid AND is_active = true
              AND deleted_at IS NULL AND outstanding_balance > 0)    AS suppliers_with_dues,

          (SELECT COALESCE(SUM(amount), 0) FROM warehouse_expenses
            WHERE warehouse_id = @wid AND deleted_at IS NULL
              AND expense_date >= @start AND expense_date < @end)    AS expense_amount,

          (SELECT COALESCE(SUM(amount), 0) FROM warehouse_expenses
            WHERE warehouse_id = @wid AND deleted_at IS NULL
              AND expense_head = 'Salary'
              AND expense_date >= @start AND expense_date < @end)    AS salary_amount,

          (SELECT COALESCE(SUM(GREATEST(qty, 0) * purchase_price), 0)
             FROM stock)                                             AS inventory_value,

          (SELECT COUNT(*)::int FROM stock)                          AS active_products,

          (SELECT COUNT(*)::int FROM stock
            WHERE is_track_stock = true AND reorder_point > 0
              AND available <= reorder_point)                        AS low_stock_count,

          (SELECT COUNT(*)::int FROM stock
            WHERE is_track_stock = true AND available <= 0)          AS out_of_stock_count,

          (SELECT COUNT(*)::int FROM purchase_orders
            WHERE warehouse_id = @wid AND deleted_at IS NULL
              AND po_type = 'purchase'
              AND status IN ('draft','ordered','partial'))           AS pending_pos,

          (SELECT COUNT(*)::int FROM stock_transfers
            WHERE warehouse_id = @wid AND deleted_at IS NULL
              AND status = 'pending')                                AS pending_transfers,

          (SELECT COALESCE(SUM(unsynced_count), 0)::int FROM v_unsynced
            WHERE warehouse_id = @wid)                               AS unsynced_records
      '''),
      parameters: {'wid': _wid, 'start': period.start, 'end': period.end},
    );

    final m = result.first.toColumnMap();
    return DashboardSummary(
      cashInHand:          _toDouble(m['cash_in_hand']),
      periodCashIn:        _toDouble(m['period_in']),
      periodCashOut:       _toDouble(m['period_out']),
      purchaseAmount:      _toDouble(m['purchase_amount']),
      purchaseCount:       _toInt(m['purchase_count']),
      supplierOutstanding: _toDouble(m['supplier_outstanding']),
      suppliersWithDues:   _toInt(m['suppliers_with_dues']),
      expenseAmount:       _toDouble(m['expense_amount']),
      salaryAmount:        _toDouble(m['salary_amount']),
      inventoryValue:      _toDouble(m['inventory_value']),
      activeProducts:      _toInt(m['active_products']),
      lowStockCount:       _toInt(m['low_stock_count']),
      outOfStockCount:     _toInt(m['out_of_stock_count']),
      pendingPOs:          _toInt(m['pending_pos']),
      pendingTransfers:    _toInt(m['pending_transfers']),
      unsyncedRecords:     _toInt(m['unsynced_records']),
    );
  }

  // ── 2. Purchases vs Cash out (chart) ──────────────────────
  // Bucket: Today → ghanta · ≤ 31 din → din · zyada → hafta (Monday).
  // Khaali buckets 0 se bharte hain taake chart poora period dikhaye.
  Future<List<DashboardTrendPoint>> getTrend(
      DashboardPeriod period, PurchaseDateFilter filter) async {
    final days = period.end.difference(period.start).inDays;
    final unit = filter == PurchaseDateFilter.today
        ? 'hour' : (days <= 31 ? 'day' : 'week');

    final conn   = await _db;
    final params = {
      'wid': _wid, 'start': period.start, 'end': period.end, 'unit': unit,
    };

    final purchases = await conn.execute(
      Sql.named('''
        SELECT date_trunc(@unit::text, created_at AT TIME ZONE 'Asia/Karachi') AS bucket,
               COALESCE(SUM(total_amount), 0) AS amount
        FROM purchase_orders
        WHERE warehouse_id = @wid AND deleted_at IS NULL
          AND po_type = 'purchase' AND status = 'received'
          AND created_at >= @start AND created_at < @end
        GROUP BY bucket
      '''),
      parameters: params,
    );
    final cashOut = await conn.execute(
      Sql.named('''
        SELECT date_trunc(@unit::text, created_at AT TIME ZONE 'Asia/Karachi') AS bucket,
               COALESCE(SUM($_signedOut), 0) AS amount
        FROM warehouse_cash_transactions
        WHERE warehouse_id = @wid AND entry_type <> 'cash_in'
          AND created_at >= @start AND created_at < @end
        GROUP BY bucket
      '''),
      parameters: params,
    );

    Map<String, double> toMap(Result rows) => {
      for (final r in rows)
        _key(_toDate(r.toColumnMap()['bucket']), unit):
            _toDouble(r.toColumnMap()['amount']),
    };
    final pMap = toMap(purchases);
    final cMap = toMap(cashOut);

    // Saare buckets banao (period ke shuru se aakhir tak)
    final buckets = <DateTime>[];
    if (unit == 'hour') {
      for (var h = 0; h < 24; h++) {
        buckets.add(DateTime(period.start.year, period.start.month,
            period.start.day, h));
      }
    } else if (unit == 'day') {
      for (var d = period.start; d.isBefore(period.end);
           d = DateTime(d.year, d.month, d.day + 1)) {
        buckets.add(d);
      }
    } else {
      var w = period.start.subtract(Duration(days: period.start.weekday - 1));
      w = DateTime(w.year, w.month, w.day);
      for (; w.isBefore(period.end); w = DateTime(w.year, w.month, w.day + 7)) {
        buckets.add(w);
      }
    }

    return buckets.map((b) {
      final k = _key(b, unit);
      return DashboardTrendPoint(
        label:     _label(b, unit, filter),
        purchases: pMap[k] ?? 0,
        cashOut:   cMap[k] ?? 0,
      );
    }).toList();
  }

  // ── 3. Top supplier dues ──────────────────────────────────
  Future<List<SupplierDue>> getSupplierDues({int limit = 5}) async {
    final conn   = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT id AS supplier_id, name AS supplier_name,
               payment_terms, outstanding_balance
        FROM suppliers
        WHERE warehouse_id = @wid AND is_active = true
          AND deleted_at IS NULL AND outstanding_balance > 0
        ORDER BY outstanding_balance DESC
        LIMIT @limit
      '''),
      parameters: {'wid': _wid, 'limit': limit},
    );
    return result.map((row) {
      final m = row.toColumnMap();
      return SupplierDue(
        supplierId:        m['supplier_id'].toString(),
        supplierName:      m['supplier_name'].toString(),
        paymentTerms:      _toInt(m['payment_terms']),
        outstandingAmount: _toDouble(m['outstanding_balance']),
      );
    }).toList();
  }

  // ── 4. Low stock — reorder (sab se kam level pehle) ───────
  Future<List<DashboardLowStockRow>> getLowStock({int limit = 5}) async {
    final conn   = await _db;
    final result = await conn.execute(
      Sql.named('''
        $_availableCte
        SELECT name, sku, unit_of_measure, available, reorder_point
        FROM stock
        WHERE is_track_stock = true AND reorder_point > 0
          AND available <= reorder_point
        ORDER BY (available / NULLIF(reorder_point, 0)) ASC, name
        LIMIT @limit
      '''),
      parameters: {'wid': _wid, 'limit': limit},
    );
    return result.map((row) {
      final m = row.toColumnMap();
      return DashboardLowStockRow(
        productName:  m['name'].toString(),
        sku:          m['sku']?.toString() ?? '',
        unit:         m['unit_of_measure']?.toString() ?? '',
        available:    _toDouble(m['available']),
        reorderPoint: _toInt(m['reorder_point']),
      );
    }).toList();
  }

  // ── 5. Recent stock movements (period, latest pehle) ──────
  Future<List<DashboardMovement>> getMovements(DashboardPeriod period,
      {int limit = 6}) async {
    final conn   = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT m.id, m.movement_type, m.quantity, m.created_at,
               COALESCE(p.name, 'Product') AS product_name,
               CASE m.reference_type
                 WHEN 'purchase' THEN po.po_number
                 WHEN 'transfer' THEN st.transfer_number
               END AS reference
        FROM warehouse_stock_movements m
        LEFT JOIN warehouse_products p ON p.id = m.product_id
        LEFT JOIN purchase_orders   po ON po.id = m.reference_id
                                      AND m.reference_type = 'purchase'
        LEFT JOIN stock_transfers   st ON st.id = m.reference_id
                                      AND m.reference_type = 'transfer'
        WHERE m.warehouse_id = @wid
          AND m.created_at >= @start AND m.created_at < @end
        ORDER BY m.created_at DESC
        LIMIT @limit
      '''),
      parameters: {
        'wid': _wid, 'start': period.start, 'end': period.end, 'limit': limit,
      },
    );
    return result.map((row) {
      final m    = row.toColumnMap();
      final type = m['movement_type'].toString();
      final qty  = _toDouble(m['quantity']);
      // transfer_out / return_out positive save hote hain → minus dikhao.
      // adjustment pehle se signed hai.
      final signed = switch (type) {
        'transfer_out' || 'return_out' => -qty.abs(),
        'adjustment'                   => qty,
        _                              => qty.abs(),
      };
      return DashboardMovement(
        id:           m['id'].toString(),
        productName:  m['product_name'].toString(),
        movementType: type,
        reference:    m['reference']?.toString(),
        signedQty:    signed,
        createdAt:    _toDate(m['created_at']),
      );
    }).toList();
  }

  // ── HELPERS ───────────────────────────────────────────────
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun',
                          'Jul','Aug','Sep','Oct','Nov','Dec'];
  static const _days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

  // date_trunc ka "timestamp without tz" driver se UTC-flag ke saath aata
  // hai lekin fields Karachi-local hote hain — isliye fields seedha padho.
  static String _key(DateTime d, String unit) {
    final ymd = '${d.year}-${d.month}-${d.day}';
    return unit == 'hour' ? '$ymd-${d.hour}' : ymd;
  }

  static String _label(DateTime d, String unit, PurchaseDateFilter f) {
    if (unit == 'hour') {
      final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
      return '$h12${d.hour < 12 ? 'AM' : 'PM'}';
    }
    if (f == PurchaseDateFilter.thisWeek) return _days[d.weekday - 1];
    return '${d.day} ${_months[d.month - 1]}';
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime _toDate(dynamic v) {
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}
