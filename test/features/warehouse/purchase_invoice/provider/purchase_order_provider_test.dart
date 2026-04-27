// =============================================================
// purchase_order_provider_test.dart
// =============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_order_provider.dart';

void main() {

  // ── Helpers ───────────────────────────────────────────────
  PurchaseOrderModel makeOrder({
    String id          = 'po-1',
    String poNumber    = 'PO-2026-001',
    String status      = 'ordered',
    double totalAmount = 1000,
    double paidAmount  = 0,
    String? supplierName,
    String? supplierCompany,
  }) {
    return PurchaseOrderModel(
      id:                    id,
      tenantId:              'wh-1',
      poNumber:              poNumber,
      destinationLocationId: 'loc-1',
      status:                status,
      orderDate:             DateTime(2026, 4, 27),
      subtotal:              totalAmount,
      discountAmount:        0,
      taxAmount:             0,
      totalAmount:           totalAmount,
      paidAmount:            paidAmount,
      createdAt:             DateTime(2026, 4, 27),
      updatedAt:             DateTime(2026, 4, 27),
      supplierName:          supplierName,
      supplierCompany:       supplierCompany,
    );
  }

  // ═══════════════════════════════════════════════════════════
  group('PurchaseOrderState — filtering', () {

    PurchaseOrderState makeStateWithOrders(
        List<PurchaseOrderModel> orders) {
      return PurchaseOrderState(
        allOrders: orders,
        filteredOrders: orders,
      );
    }

    test('filter by status — only matching orders returned', () {
      final orders = [
        makeOrder(id: '1', status: 'draft'),
        makeOrder(id: '2', status: 'ordered'),
        makeOrder(id: '3', status: 'received'),
      ];
      final state = makeStateWithOrders(orders);
      final filtered = state.copyWith(filterStatus: 'draft');
      expect(filtered.filteredOrders, hasLength(1));
      expect(filtered.filteredOrders.first.status, equals('draft'));
    });

    test('filter all — returns all orders', () {
      final orders = [
        makeOrder(id: '1', status: 'draft'),
        makeOrder(id: '2', status: 'received'),
      ];
      final state = makeStateWithOrders(orders).copyWith(filterStatus: 'all');
      expect(state.filteredOrders, hasLength(2));
    });

    test('search by PO number', () {
      final orders = [
        makeOrder(id: '1', poNumber: 'PO-2026-001'),
        makeOrder(id: '2', poNumber: 'PO-2026-999'),
      ];
      final state = makeStateWithOrders(orders)
          .copyWith(searchQuery: 'PO-2026-001');
      expect(state.filteredOrders, hasLength(1));
      expect(state.filteredOrders.first.poNumber, equals('PO-2026-001'));
    });

    test('search by supplier name', () {
      final orders = [
        makeOrder(id: '1', supplierName: 'Ali Traders'),
        makeOrder(id: '2', supplierName: 'M Hashim'),
      ];
      final state = makeStateWithOrders(orders)
          .copyWith(searchQuery: 'ali');
      expect(state.filteredOrders, hasLength(1));
      expect(state.filteredOrders.first.supplierName, equals('Ali Traders'));
    });

    test('search by supplier company', () {
      final orders = [
        makeOrder(id: '1', supplierCompany: 'Coka Cola'),
        makeOrder(id: '2', supplierCompany: 'Pepsi Co'),
      ];
      final state = makeStateWithOrders(orders)
          .copyWith(searchQuery: 'pepsi');
      expect(state.filteredOrders, hasLength(1));
    });

    test('search case insensitive', () {
      final orders = [
        makeOrder(id: '1', supplierName: 'Ali Traders'),
      ];
      final state = makeStateWithOrders(orders)
          .copyWith(searchQuery: 'ALI TRADERS');
      expect(state.filteredOrders, hasLength(1));
    });

    test('search no match — empty list', () {
      final orders = [
        makeOrder(id: '1', supplierName: 'Ali Traders'),
      ];
      final state = makeStateWithOrders(orders)
          .copyWith(searchQuery: 'xyz-not-found');
      expect(state.filteredOrders, isEmpty);
    });

    test('filter + search combined', () {
      final orders = [
        makeOrder(id: '1', status: 'draft',    supplierName: 'Ali'),
        makeOrder(id: '2', status: 'ordered',  supplierName: 'Ali'),
        makeOrder(id: '3', status: 'received', supplierName: 'Ali'),
      ];
      final state = makeStateWithOrders(orders)
          .copyWith(filterStatus: 'draft', searchQuery: 'ali');
      expect(state.filteredOrders, hasLength(1));
      expect(state.filteredOrders.first.status, equals('draft'));
    });

    test('filteredOrders not recomputed when unrelated field changes', () {
      final orders = [makeOrder()];
      final state1 = makeStateWithOrders(orders);
      // Only isLoading changes — filteredOrders same object hona chahiye
      final state2 = state1.copyWith(isLoading: true);
      expect(identical(state1.filteredOrders, state2.filteredOrders), isTrue,
          reason: 'filteredOrders should not be recomputed '
              'when only isLoading changes');
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PurchaseOrderState — copyWith', () {

    test('copyWith preserves unspecified fields', () {
      const state = PurchaseOrderState(
        searchQuery:  'test',
        filterStatus: 'draft',
      );
      final updated = state.copyWith(isLoading: true);

      expect(updated.searchQuery,  equals('test'));
      expect(updated.filterStatus, equals('draft'));
      expect(updated.isLoading,    isTrue);
    });

    test('errorMessage can be set to null', () {
      const state = PurchaseOrderState(errorMessage: 'some error');
      final cleared = state.copyWith(errorMessage: null);
      expect(cleared.errorMessage, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PurchaseOrderStats', () {

    test('stats model stores all fields', () {
      const stats = PurchaseOrderStats(
        totalPOs:         41,
        pendingCount:     1,
        receivedCount:    40,
        thisMonthTotal:   595796.07,
        totalOutstanding: 43992.5,
      );
      expect(stats.totalPOs,         equals(41));
      expect(stats.pendingCount,     equals(1));
      expect(stats.receivedCount,    equals(40));
      expect(stats.thisMonthTotal,   closeTo(595796.07, 0.01));
      expect(stats.totalOutstanding, closeTo(43992.5,   0.01));
    });
  });
}