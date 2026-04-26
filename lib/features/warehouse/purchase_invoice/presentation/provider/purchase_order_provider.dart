// =============================================================
// purchase_order_provider.dart  — UPDATED (real DB)
// =============================================================

import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/datasource/purchase_order_remote_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';

// ─────────────────────────────────────────────────────────────
// STATS MODEL  (dummy_data se yahan move kiya)
// ─────────────────────────────────────────────────────────────

class PurchaseOrderStats {
  final int    totalPOs;
  final int    pendingCount;
  final int    receivedCount;
  final double thisMonthTotal;
  final double totalOutstanding;

  const PurchaseOrderStats({
    required this.totalPOs,
    required this.pendingCount,
    required this.receivedCount,
    required this.thisMonthTotal,
    required this.totalOutstanding,
  });
}

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class PurchaseOrderState {
  final List<PurchaseOrderModel> allOrders;
  final PurchaseOrderStats?      stats;
  final String                   searchQuery;
  final String                   filterStatus;
  final bool                     isLoading;
  final String?                  errorMessage;
  final List<PurchaseOrderModel> filteredOrders; // ✅ getter nahi, cached field

  const PurchaseOrderState({
    this.allOrders      = const [],
    this.stats,
    this.searchQuery    = '',
    this.filterStatus   = 'all',
    this.isLoading      = false,
    this.errorMessage,
    this.filteredOrders = const [], // ✅
  });

  PurchaseOrderState copyWith({
    List<PurchaseOrderModel>? allOrders,
    PurchaseOrderStats?       stats,
    String?                   searchQuery,
    String?                   filterStatus,
    bool?                     isLoading,
    String?                   errorMessage,
  }) {
    final newAllOrders    = allOrders    ?? this.allOrders;
    final newSearchQuery  = searchQuery  ?? this.searchQuery;
    final newFilterStatus = filterStatus ?? this.filterStatus;

    // ✅ Sirf tab recalculate hoga jab in teen mein se koi change ho
    final newFiltered = (allOrders != null || searchQuery != null || filterStatus != null)
        ? _computeFiltered(newAllOrders, newSearchQuery, newFilterStatus)
        : filteredOrders; // ← same list reuse, no loop

    return PurchaseOrderState(
      allOrders:      newAllOrders,
      stats:          stats        ?? this.stats,
      searchQuery:    newSearchQuery,
      filterStatus:   newFilterStatus,
      isLoading:      isLoading    ?? this.isLoading,
      errorMessage:   errorMessage,
      filteredOrders: newFiltered,  // ✅
    );
  }

  static List<PurchaseOrderModel> _computeFiltered(
      List<PurchaseOrderModel> all,
      String query,
      String status,
      ) {
    var result = all;

    if (status != 'all') {
      result = result.where((o) => o.status == status).toList();
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((o) =>
      o.poNumber.toLowerCase().contains(q) ||
          (o.supplierName?.toLowerCase().contains(q) ?? false) ||
          (o.supplierCompany?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    return result;
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class PurchaseOrderNotifier
    extends StateNotifier<PurchaseOrderState> {

  final PurchaseOrderRemoteDataSource _ds;
  String get _wid => AppConfig.warehouseId;

  PurchaseOrderNotifier()
      : _ds = PurchaseOrderRemoteDataSource(),
        super(const PurchaseOrderState()) {
    loadOrders();
  }

  // ── Load ──────────────────────────────────────────────────
  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Orders aur stats parallel mein fetch karo
      final results = await Future.wait([
        _ds.getAll(_wid),
        _ds.getStats(_wid),
      ]);

      state = state.copyWith(
        allOrders: results[0] as List<PurchaseOrderModel>,
        stats:     results[1] as PurchaseOrderStats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Orders load karne mein masla: $e',
      );
    }
  }

  // ── Filters ───────────────────────────────────────────────
  void onSearchChanged(String query) =>
      state = state.copyWith(searchQuery: query);

  void onFilterChanged(String status) =>
      state = state.copyWith(filterStatus: status);

  // ── Delete (soft) ─────────────────────────────────────────
  Future<void> deleteOrder(String id) async {
    try {
      await _ds.delete(id);
      state = state.copyWith(
        allOrders: state.allOrders.where((o) => o.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Delete mein masla: $e');
    }
  }

  // ── Status update ─────────────────────────────────────────
  Future<void> updateStatus(String id, String newStatus) async {
    try {
      await _ds.updateStatus(id, newStatus);
      // Local state update — DB se dobara fetch nahi karna
      final updated = state.allOrders.map((o) {
        if (o.id != id) return o;
        return PurchaseOrderModel(
          id:                    o.id,
          tenantId:              o.tenantId,
          poNumber:              o.poNumber,
          supplierId:            o.supplierId,
          supplierName:          o.supplierName,
          supplierCompany:       o.supplierCompany,
          supplierPhone:         o.supplierPhone,
          supplierAddress:       o.supplierAddress,
          supplierTaxId:         o.supplierTaxId,
          supplierPaymentTerms:  o.supplierPaymentTerms,
          destinationLocationId: o.destinationLocationId,
          destinationName:       o.destinationName,
          status:                newStatus,
          orderDate:             o.orderDate,
          expectedDate:          o.expectedDate,
          receivedDate:          newStatus == 'received'
              ? DateTime.now() : o.receivedDate,
          subtotal:              o.subtotal,
          discountAmount:        o.discountAmount,
          taxAmount:             o.taxAmount,
          totalAmount:           o.totalAmount,
          paidAmount:            o.paidAmount,
          notes:                 o.notes,
          createdByName:         o.createdByName,
          createdAt:             o.createdAt,
          updatedAt:             DateTime.now(),
          items:                 o.items,
        );
      }).toList();
      state = state.copyWith(allOrders: updated);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Status update mein masla: $e');
    }
  }

  // ── Add (create ke baad call karo) ───────────────────────
  Future<void> addOrder(PurchaseOrderModel order) async {
    state = state.copyWith(
      allOrders: [order, ...state.allOrders],
    );
    // Stats refresh
    try {
      final PurchaseOrderStats? stats = await _ds.getStats(_wid);
      state = state.copyWith(stats: stats);
    } catch (_) {}
  }

  Future<void> refresh() => loadOrders();

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

final purchaseOrderProvider = StateNotifierProvider<
    PurchaseOrderNotifier, PurchaseOrderState>(
      (ref) => PurchaseOrderNotifier(),
);