// =============================================================
// supplier_detail_provider.dart
// Supplier detail screen — real DB data
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/features/supplier/domian/supplier_detail_models.dart';
import 'package:jan_ghani_final/features/warehouse_finance/data/warehouse_finance_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────
class SupplierDetailState {
  final List<SupplierLedgerEntry>   ledgerEntries;
  final List<SupplierPurchaseOrder> purchaseOrders;
  final SupplierFinancialSummary?   financialSummary;
  final bool                        isLoading;
  final String?                     errorMessage;
  final String                      activeTab;

  const SupplierDetailState({
    this.ledgerEntries    = const [],
    this.purchaseOrders   = const [],
    this.financialSummary,
    this.isLoading        = false,
    this.errorMessage,
    this.activeTab        = 'ledger',
  });

  SupplierDetailState copyWith({
    List<SupplierLedgerEntry>?   ledgerEntries,
    List<SupplierPurchaseOrder>? purchaseOrders,
    SupplierFinancialSummary?    financialSummary,
    bool?                        isLoading,
    String?                      errorMessage,
    String?                      activeTab,
  }) {
    return SupplierDetailState(
      ledgerEntries:    ledgerEntries    ?? this.ledgerEntries,
      purchaseOrders:   purchaseOrders   ?? this.purchaseOrders,
      financialSummary: financialSummary ?? this.financialSummary,
      isLoading:        isLoading        ?? this.isLoading,
      errorMessage:     errorMessage     ?? this.errorMessage,
      activeTab:        activeTab        ?? this.activeTab,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────
class SupplierDetailNotifier extends StateNotifier<SupplierDetailState> {
  SupplierDetailNotifier() : super(const SupplierDetailState());

  Future<Connection> get _db => DatabaseService.getConnection();
  String get _wid => AppConfig.warehouseId;

  Future<void> loadData(String supplierId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 3 queries parallel chalao
      final results = await Future.wait([
        _loadLedgerEntries(supplierId),
        _loadPurchaseOrders(supplierId),
        _loadFinancialSummary(supplierId),
      ]);

      state = state.copyWith(
        ledgerEntries:    results[0] as List<SupplierLedgerEntry>,
        purchaseOrders:   results[1] as List<SupplierPurchaseOrder>,
        financialSummary: results[2] as SupplierFinancialSummary,
        isLoading:        false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Data load karne mein masla: $e',
      );
    }
  }

  void switchTab(String tab) => state = state.copyWith(activeTab: tab);

  // ── Pay to supplier ───────────────────────────────────────
  Future<void> payOutstanding({
    required String supplierId,
    required double amount,
    String?         notes,
    String?         userId,
    String? userName
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final conn = await _db;

      // 1. Current balance lo
      final balResult = await conn.execute(
        Sql.named('''
        SELECT outstanding_balance FROM suppliers
        WHERE id = @supplierId AND warehouse_id = @wid
        LIMIT 1
      '''),
        parameters: {'supplierId': supplierId, 'wid': _wid},
      );

      final balanceBefore = balResult.isEmpty
          ? 0.0
          : _toDouble(balResult.first.toColumnMap()['outstanding_balance']);
      final balanceAfter = balanceBefore - amount;

      // 2. Supplier ledger mein payment entry karo
      await conn.execute(
        Sql.named('''
        INSERT INTO supplier_ledger (
          id,          warehouse_id, supplier_id,
          entry_type,  amount,       balance_before,
          balance_after, notes,      created_by
        ) VALUES (
          @id,         @wid,         @supplierId,
          'payment',   @amount,      @balanceBefore,
          @balanceAfter, @notes,     @userId
        )
      '''),
        parameters: {
          'id':            const Uuid().v4(),
          'wid':           _wid,
          'supplierId':    supplierId,
          'amount':        -amount,
          'balanceBefore': balanceBefore,
          'balanceAfter':  balanceAfter,
          'notes':         notes ?? 'Manual payment',
          'userId':        userId,
        },
      );

      // 3. Warehouse finance mein cash out entry karo
      await WarehouseFinanceRepository.instance.addSupplierPayment(
        amount:        amount,
        supplierId:    supplierId,
        notes:         notes ?? 'Supplier payment',
        createdBy:     userId,
        createdByName: userName,
      );

      // 4. Data reload karo
      await loadData(supplierId);
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Payment mein masla: $e',
      );
    }
  }

  // ── 1. Ledger entries ─────────────────────────────────────
  Future<List<SupplierLedgerEntry>> _loadLedgerEntries(
      String supplierId) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          sl.id,
          sl.supplier_id,
          sl.po_id,
          sl.entry_type,
          sl.amount,
          sl.balance_before,
          sl.balance_after,
          sl.notes,
          sl.created_at,
          u.full_name AS created_by_name
        FROM supplier_ledger sl
        LEFT JOIN users u ON u.id = sl.created_by
        WHERE sl.supplier_id  = @supplierId
          AND sl.warehouse_id = @wid
        ORDER BY sl.created_at DESC
      '''),
      parameters: {
        'supplierId': supplierId,
        'wid':        _wid,
      },
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return SupplierLedgerEntry(
        id:            m['id'].toString(),
        supplierId:    m['supplier_id'].toString(),
        poId:          m['po_id']?.toString(),
        entryType:     m['entry_type'].toString(),
        amount:        _toDouble(m['amount']),
        balanceBefore: _toDouble(m['balance_before']),
        balanceAfter:  _toDouble(m['balance_after']),
        notes:         m['notes']?.toString(),
        createdByName: m['created_by_name']?.toString(),
        createdAt:     m['created_at'] is DateTime
            ? m['created_at'] as DateTime
            : DateTime.parse(m['created_at'].toString()),
      );
    }).toList();
  }

  // ── 2. Purchase orders ────────────────────────────────────
  Future<List<SupplierPurchaseOrder>> _loadPurchaseOrders(
      String supplierId) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, po_number, order_date, expected_date,
          received_date, status, subtotal, discount_amount,
          tax_amount, total_amount, paid_amount, notes, created_at
        FROM purchase_orders
        WHERE supplier_id  = @supplierId
          AND warehouse_id = @wid
          AND deleted_at   IS NULL
        ORDER BY order_date DESC
      '''),
      parameters: {
        'supplierId': supplierId,
        'wid':        _wid,
      },
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return SupplierPurchaseOrder(
        id:             m['id'].toString(),
        poNumber:       m['po_number'].toString(),
        orderDate:      _toDate(m['order_date'])!,
        expectedDate:   _toDate(m['expected_date']),
        receivedDate:   _toDate(m['received_date']),
        status:         m['status'].toString(),
        subtotal:       _toDouble(m['subtotal']),
        discountAmount: _toDouble(m['discount_amount']),
        taxAmount:      _toDouble(m['tax_amount']),
        totalAmount:    _toDouble(m['total_amount']),
        paidAmount:     _toDouble(m['paid_amount']),
        notes:          m['notes']?.toString(),
        createdAt:      _toDate(m['created_at'])!,
      );
    }).toList();
  }

  // ── 3. Financial summary ──────────────────────────────────
  Future<SupplierFinancialSummary> _loadFinancialSummary(
      String supplierId) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          s.outstanding_balance,
          COALESCE(SUM(po.total_amount), 0)  AS total_purchased,
          COALESCE(SUM(po.paid_amount),  0)  AS total_paid,
          COUNT(po.id)                        AS total_orders,
          COUNT(po.id) FILTER (
            WHERE po.status IN ('draft','ordered','partial')
          )                                   AS pending_orders,
          -- Ledger se total paid (payments + returns)
          ABS(COALESCE((
            SELECT SUM(sl.amount)
            FROM supplier_ledger sl
            WHERE sl.supplier_id  = s.id
              AND sl.warehouse_id = @wid
              AND sl.entry_type   IN ('payment','return')
          ), 0))                              AS total_paid_ledger
        FROM suppliers s
        LEFT JOIN purchase_orders po
          ON  po.supplier_id  = s.id
          AND po.warehouse_id = @wid
          AND po.deleted_at   IS NULL
        WHERE s.id           = @supplierId
          AND s.warehouse_id = @wid
        GROUP BY s.id, s.outstanding_balance
      '''),
      parameters: {
        'supplierId': supplierId,
        'wid':        _wid,
      },
    );

    if (result.isEmpty) {
      return const SupplierFinancialSummary(
        outstandingBalance: 0,
        totalPurchased:     0,
        totalPaid:          0,
        totalOrders:        0,
        pendingOrders:      0,
      );
    }

    final m = result.first.toColumnMap();
    return SupplierFinancialSummary(
      outstandingBalance: _toDouble(m['outstanding_balance']),
      totalPurchased:     _toDouble(m['total_purchased']),
      totalPaid:          _toDouble(m['total_paid_ledger']),
      totalOrders:        _toInt(m['total_orders']),
      pendingOrders:      _toInt(m['pending_orders']),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int)  return v;
    if (v is num)  return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null)         return null;
    if (v is DateTime)     return v;
    return DateTime.tryParse(v.toString());
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────
final supplierDetailProvider =
StateNotifierProvider.autoDispose<SupplierDetailNotifier, SupplierDetailState>(
        (ref) => SupplierDetailNotifier());