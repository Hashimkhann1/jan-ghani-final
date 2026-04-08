// =============================================================
// purchase_order_provider.dart
// Purchase Order list screen ka Riverpod State + Notifier
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/features/purchase_invoice/domain/purchase_order_model.dart';
import 'package:jan_ghani_final/features/purchase_invoice/data/purchase_order_dummy_data.dart';

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

  const PurchaseOrderState({
    this.allOrders    = const [],
    this.stats,
    this.searchQuery  = '',
    this.filterStatus = 'all',
    this.isLoading    = false,
    this.errorMessage,
  });

  List<PurchaseOrderModel> get filteredOrders {
    var result = allOrders;

    if (filterStatus != 'all') {
      result = result
          .where((o) => o.status == filterStatus)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((o) {
        return o.poNumber.toLowerCase().contains(q) ||
            (o.supplierName?.toLowerCase().contains(q) ?? false) ||
            (o.supplierCompany?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }

  PurchaseOrderState copyWith({
    List<PurchaseOrderModel>? allOrders,
    PurchaseOrderStats?       stats,
    String?                   searchQuery,
    String?                   filterStatus,
    bool?                     isLoading,
    String?                   errorMessage,
  }) {
    return PurchaseOrderState(
      allOrders:    allOrders    ?? this.allOrders,
      stats:        stats        ?? this.stats,
      searchQuery:  searchQuery  ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      isLoading:    isLoading    ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class PurchaseOrderNotifier
    extends StateNotifier<PurchaseOrderState> {
  PurchaseOrderNotifier() : super(const PurchaseOrderState());

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // TODO: Drift se real data
      await Future.delayed(const Duration(milliseconds: 250));
      state = state.copyWith(
        allOrders: dummyPurchaseOrders,
        stats:     dummyPoStats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Orders load karne mein masla: $e',
      );
    }
  }

  void onSearchChanged(String query) =>
      state = state.copyWith(searchQuery: query);

  void onFilterChanged(String status) =>
      state = state.copyWith(filterStatus: status);

  Future<void> deleteOrder(String id) async {
    state = state.copyWith(
      allOrders: state.allOrders.where((o) => o.id != id).toList(),
    );
  }

  Future<void> addOrder(PurchaseOrderModel order) async {
    state = state.copyWith(
      allOrders: [order, ...state.allOrders],
    );
  }

  Future<void> updateOrder(PurchaseOrderModel updated) async {
    state = state.copyWith(
      allOrders: state.allOrders
          .map((o) => o.id == updated.id ? updated : o)
          .toList(),
    );
  }

  Future<void> refresh() => loadOrders();
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

final purchaseOrderProvider = StateNotifierProvider<
    PurchaseOrderNotifier, PurchaseOrderState>(
      (ref) => PurchaseOrderNotifier(),
);