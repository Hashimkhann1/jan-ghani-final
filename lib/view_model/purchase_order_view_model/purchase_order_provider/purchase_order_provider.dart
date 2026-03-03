import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/model/purchase_order_model.dart';
import 'package:jan_ghani_final/res/dummy/dummy_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UI FILTER STATE
// ─────────────────────────────────────────────────────────────────────────────

class PurchaseOrderFilterState {
  final String searchQuery;
  final String statusFilter;   // 'All Statuses' or status label
  final String supplierFilter; // 'All Suppliers' or supplier name
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const PurchaseOrderFilterState({
    this.searchQuery = '',
    this.statusFilter = 'All Statuses',
    this.supplierFilter = 'All Suppliers',
    this.dateFrom,
    this.dateTo,
  });

  PurchaseOrderFilterState copyWith({
    String? searchQuery,
    String? statusFilter,
    String? supplierFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return PurchaseOrderFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      supplierFilter: supplierFilter ?? this.supplierFilter,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class PurchaseOrderFilterNotifier
    extends StateNotifier<PurchaseOrderFilterState> {
  PurchaseOrderFilterNotifier()
      : super(const PurchaseOrderFilterState());

  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setStatus(String s) => state = state.copyWith(statusFilter: s);
  void setSupplier(String s) => state = state.copyWith(supplierFilter: s);
  void setDateFrom(DateTime? d) =>
      d == null ? state = state.copyWith(clearDateFrom: true) : state = state.copyWith(dateFrom: d);
  void setDateTo(DateTime? d) =>
      d == null ? state = state.copyWith(clearDateTo: true) : state = state.copyWith(dateTo: d);
  void reset() => state = const PurchaseOrderFilterState();
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final purchaseOrderFilterProvider = StateNotifierProvider<
    PurchaseOrderFilterNotifier, PurchaseOrderFilterState>(
      (ref) => PurchaseOrderFilterNotifier(),
);

/// All POs — in a real app this would come from a repository/DB
final allPurchaseOrdersProvider = Provider<List<PurchaseOrderModel>>(
      (ref) => DummyData.dummyPurchaseOrders,
);

/// Filtered POs reacting to filter state
final filteredPurchaseOrdersProvider =
Provider<List<PurchaseOrderModel>>((ref) {
  final orders = ref.watch(allPurchaseOrdersProvider);
  final filters = ref.watch(purchaseOrderFilterProvider);

  return orders.where((po) {
    // Search
    final q = filters.searchQuery.toLowerCase();
    final matchSearch = q.isEmpty ||
        po.poNumber.toLowerCase().contains(q) ||
        (po.supplier?.name.toLowerCase().contains(q) ?? false) ||
        (po.supplier?.contactPerson?.toLowerCase().contains(q) ?? false);

    // Status filter
    final matchStatus = filters.statusFilter == 'All Statuses' ||
        po.status.label == filters.statusFilter;

    // Supplier filter
    final matchSupplier = filters.supplierFilter == 'All Suppliers' ||
        (po.supplier?.name == filters.supplierFilter);

    // Date from
    final matchDateFrom = filters.dateFrom == null ||
        !po.orderDate.isBefore(filters.dateFrom!);

    // Date to
    final matchDateTo = filters.dateTo == null ||
        !po.orderDate.isAfter(filters.dateTo!);

    return matchSearch && matchStatus && matchSupplier &&
        matchDateFrom && matchDateTo;
  }).toList();
});

/// Stats derived from ALL orders (not filtered)
final purchaseOrderStatsProvider = Provider<PurchaseOrderStats>((ref) {
  final orders = ref.watch(allPurchaseOrdersProvider);
  return PurchaseOrderStats(
    ordered: orders
        .where((o) => o.status == PurchaseOrderStatus.ordered)
        .length,
    received: orders
        .where((o) => o.status == PurchaseOrderStatus.received)
        .length,
    totalValue: orders.fold(0, (s, o) => s + o.totalAmount),
  );
});

/// Unique supplier names for dropdown
final supplierNamesProvider = Provider<List<String>>((ref) {
  final orders = ref.watch(allPurchaseOrdersProvider);
  final names = <String>{'All Suppliers'};
  for (final o in orders) {
    if (o.supplier != null) names.add(o.supplier!.name);
  }
  return names.toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// STATS MODEL
// ─────────────────────────────────────────────────────────────────────────────

class PurchaseOrderStats {
  final int ordered;
  final int received;
  final double totalValue;

  const PurchaseOrderStats({
    required this.ordered,
    required this.received,
    required this.totalValue,
  });
}