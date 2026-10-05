// Updated on 2026-10-05 03:08 PM
// =============================================================
// purchase_order_provider.dart  — UPDATED (real DB)
// =============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final String                   filterType;      // 'all' | 'purchase' | 'return'
  final String?                  filterSupplierId; // null = sab suppliers
  final DateTime?                fromDate;        // null = koi date filter nahi
  final DateTime?                toDate;
  final int                      page;            // 0-based
  final int                      pageSize;
  final bool                     isLoading;
  final String?                  errorMessage;
  final List<PurchaseOrderModel> filteredOrders; // ✅ getter nahi, cached field
  /// Status tabs ke counts — status ke ilawa baaqi saare filters ke baad
  final Map<String, int>         statusCounts;

  const PurchaseOrderState({
    this.allOrders        = const [],
    this.stats,
    this.searchQuery      = '',
    this.filterStatus     = 'all',
    this.filterType       = 'all',
    this.filterSupplierId,
    this.fromDate,
    this.toDate,
    this.page             = 0,
    this.pageSize         = 25,
    this.isLoading        = false,
    this.errorMessage,
    this.filteredOrders   = const [], // ✅
    this.statusCounts     = const {},
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      filterStatus != 'all' ||
      filterType != 'all' ||
      filterSupplierId != null ||
      fromDate != null;

  int get pageCount => filteredOrders.isEmpty
      ? 1
      : ((filteredOrders.length - 1) ~/ pageSize) + 1;

  /// Current page ki rows — sirf sublist, koi naya loop nahi
  List<PurchaseOrderModel> get pagedOrders {
    if (filteredOrders.isEmpty) return const [];
    final start = page * pageSize;
    if (start >= filteredOrders.length) return const [];
    final end = (start + pageSize).clamp(0, filteredOrders.length);
    return filteredOrders.sublist(start, end);
  }

  PurchaseOrderState copyWith({
    List<PurchaseOrderModel>? allOrders,
    PurchaseOrderStats?       stats,
    String?                   searchQuery,
    String?                   filterStatus,
    String?                   filterType,
    String?                   filterSupplierId,
    bool                      clearSupplier = false,
    DateTime?                 fromDate,
    DateTime?                 toDate,
    bool                      clearDates    = false,
    int?                      page,
    int?                      pageSize,
    bool?                     isLoading,
    String?                   errorMessage,
  }) {
    final newAllOrders    = allOrders    ?? this.allOrders;
    final newSearchQuery  = searchQuery  ?? this.searchQuery;
    final newFilterStatus = filterStatus ?? this.filterStatus;
    final newFilterType   = filterType   ?? this.filterType;
    final newSupplierId   = clearSupplier
        ? null : (filterSupplierId ?? this.filterSupplierId);
    final newFrom         = clearDates ? null : (fromDate ?? this.fromDate);
    final newTo           = clearDates ? null : (toDate   ?? this.toDate);

    // ✅ Sirf tab recalculate hoga jab list ya koi filter change ho
    final needsRecompute = allOrders != null ||
        searchQuery != null || filterStatus != null ||
        filterType != null || filterSupplierId != null || clearSupplier ||
        fromDate != null || toDate != null || clearDates;

    var newFiltered = filteredOrders; // ← same list reuse, no loop
    var newCounts   = statusCounts;
    if (needsRecompute) {
      final base = _computeBase(newAllOrders, newSearchQuery, newFilterType,
          newSupplierId, newFrom, newTo);
      newCounts   = _computeCounts(base);
      newFiltered = newFilterStatus == 'all'
          ? base
          : base.where((o) => o.status == newFilterStatus).toList();
    }

    final newPageSize = pageSize ?? this.pageSize;
    final maxPage = newFiltered.isEmpty
        ? 0 : (newFiltered.length - 1) ~/ newPageSize;
    final newPage = (page ?? this.page).clamp(0, maxPage);

    return PurchaseOrderState(
      allOrders:        newAllOrders,
      stats:            stats        ?? this.stats,
      searchQuery:      newSearchQuery,
      filterStatus:     newFilterStatus,
      filterType:       newFilterType,
      filterSupplierId: newSupplierId,
      fromDate:         newFrom,
      toDate:           newTo,
      page:             newPage,
      pageSize:         newPageSize,
      isLoading:        isLoading    ?? this.isLoading,
      errorMessage:     errorMessage,
      filteredOrders:   newFiltered,  // ✅
      statusCounts:     newCounts,
    );
  }

  /// Status ke ilawa saare filters (search, type, supplier, date)
  static List<PurchaseOrderModel> _computeBase(
      List<PurchaseOrderModel> all,
      String query,
      String type,
      String? supplierId,
      DateTime? from,
      DateTime? to,
      ) {
    var result = all;

    if (type == 'purchase') {
      result = result.where((o) => !o.isReturn).toList();
    } else if (type == 'return') {
      result = result.where((o) => o.isReturn).toList();
    }

    if (supplierId != null) {
      result = result.where((o) => o.supplierId == supplierId).toList();
    }

    if (from != null && to != null) {
      // Local din ki boundaries — "to" wala poora din shamil
      final start = DateTime(from.year, from.month, from.day);
      final end   = DateTime(to.year, to.month, to.day + 1);
      result = result.where((o) {
        final d = o.orderDate.toLocal();
        return !d.isBefore(start) && d.isBefore(end);
      }).toList();
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

  static Map<String, int> _computeCounts(List<PurchaseOrderModel> list) {
    final counts = <String, int>{'all': list.length};
    for (final o in list) {
      counts[o.status] = (counts[o.status] ?? 0) + 1;
    }
    return counts;
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
      state = state.copyWith(searchQuery: query, page: 0);

  void onFilterChanged(String status) =>
      state = state.copyWith(filterStatus: status, page: 0);

  void onTypeChanged(String type) =>
      state = state.copyWith(filterType: type, page: 0);

  void onSupplierChanged(String? supplierId) => state = supplierId == null
      ? state.copyWith(clearSupplier: true, page: 0)
      : state.copyWith(filterSupplierId: supplierId, page: 0);

  void onDateRangeChanged(DateTime? from, DateTime? to) =>
      state = (from == null || to == null)
          ? state.copyWith(clearDates: true, page: 0)
          : state.copyWith(fromDate: from, toDate: to, page: 0);

  void onPageChanged(int page) => state = state.copyWith(page: page);

  void onPageSizeChanged(int size) =>
      state = state.copyWith(pageSize: size, page: 0);

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
          poType:                o.poType,
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