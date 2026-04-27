// =============================================================
// purchase_order_model_test.dart
// =============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';

void main() {

  // ── Helpers ───────────────────────────────────────────────
  PurchaseOrderModel makeOrder({
    String status      = 'draft',
    double totalAmount = 1000,
    double paidAmount  = 0,
    List<PurchaseOrderItem> items = const [],
    String? supplierName,
  }) {
    return PurchaseOrderModel(
      id:                    'po-1',
      tenantId:              'wh-1',
      poNumber:              'PO-2026-001',
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
      items:                 items,
    );
  }

  PurchaseOrderItem makeItem({
    String  id              = 'item-1',
    String  productName     = 'Test Product',
    double  quantityOrdered = 10,
    double  unitCost        = 100,
    double? salePrice,
    double  discountAmount  = 0,
  }) {
    return PurchaseOrderItem(
      id:               id,
      poId:             'po-1',
      tenantId:         'wh-1',
      productName:      productName,
      quantityOrdered:  quantityOrdered,
      quantityReceived: 0,
      unitCost:         unitCost,
      totalCost:        quantityOrdered * unitCost,
      salePrice:        salePrice,
      discountAmount:   discountAmount,
    );
  }

  // ═══════════════════════════════════════════════════════════
  group('PurchaseOrderModel — canEdit', () {

    test('draft status — canEdit true', () {
      expect(makeOrder(status: 'draft').canEdit, isTrue);
    });

    test('ordered status — canEdit true', () {
      expect(makeOrder(status: 'ordered').canEdit, isTrue);
    });

    test('partial status — canEdit true', () {
      expect(makeOrder(status: 'partial').canEdit, isTrue);
    });

    test('received status — canEdit true (edit mode enabled for received POs)', () {
      // purchase_order_model.dart mein received bhi canEdit mein hai
      // received POs bhi edit ho sakti hain (qty, price, paid amount)
      expect(makeOrder(status: 'received').canEdit, isTrue);
    });

    test('cancelled status — canEdit false', () {
      expect(makeOrder(status: 'cancelled').canEdit, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PurchaseOrderModel — remainingAmount', () {

    test('remaining = total - paid', () {
      final o = makeOrder(totalAmount: 1000, paidAmount: 400);
      expect(o.remainingAmount, equals(600));
    });

    test('remaining never goes negative — fully paid', () {
      final o = makeOrder(totalAmount: 1000, paidAmount: 1000);
      expect(o.remainingAmount, equals(0));
    });

    test('remaining never goes negative — overpaid edge case', () {
      final o = makeOrder(totalAmount: 1000, paidAmount: 1200);
      expect(o.remainingAmount, equals(0));
    });

    test('isFullyPaid true when remaining is 0', () {
      final o = makeOrder(totalAmount: 500, paidAmount: 500);
      expect(o.isFullyPaid, isTrue);
    });

    test('isFullyPaid false when remaining > 0', () {
      final o = makeOrder(totalAmount: 500, paidAmount: 200);
      expect(o.isFullyPaid, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PurchaseOrderModel — paidPercent', () {

    test('50% paid', () {
      final o = makeOrder(totalAmount: 1000, paidAmount: 500);
      expect(o.paidPercent, closeTo(0.5, 0.001));
    });

    test('fully paid = 1.0', () {
      final o = makeOrder(totalAmount: 1000, paidAmount: 1000);
      expect(o.paidPercent, equals(1.0));
    });

    test('zero total = 0.0 (no division by zero)', () {
      final o = makeOrder(totalAmount: 0, paidAmount: 0);
      expect(o.paidPercent, equals(0.0));
    });

    test('overpaid clamps to 1.0', () {
      final o = makeOrder(totalAmount: 1000, paidAmount: 1500);
      expect(o.paidPercent, equals(1.0));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PurchaseOrderModel — supplierInitials', () {

    test('two word name → first letters uppercase', () {
      final o = makeOrder(supplierName: 'Ali Traders');
      expect(o.supplierInitials, equals('AT'));
    });

    test('single word name → first two letters', () {
      final o = makeOrder(supplierName: 'Google');
      expect(o.supplierInitials, equals('GO'));
    });

    test('null supplier name → ??', () {
      final o = makeOrder(supplierName: null);
      expect(o.supplierInitials, equals('??'));
    });

    test('three word name → first two words initials', () {
      final o = makeOrder(supplierName: 'M Hashim Khan');
      expect(o.supplierInitials, equals('MH'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PurchaseOrderModel — totalProfit', () {

    test('profit calculated only for items with salePrice', () {
      final items = [
        makeItem(productName: 'A', quantityOrdered: 10,
            unitCost: 100, salePrice: 150),   // profit = 500
        makeItem(productName: 'B', quantityOrdered: 5,
            unitCost: 200, salePrice: null),  // no profit
      ];
      final o = makeOrder(items: items);
      expect(o.totalProfit, equals(500));
    });

    test('no items with salePrice → profit 0', () {
      final items = [
        makeItem(salePrice: null),
      ];
      final o = makeOrder(items: items);
      expect(o.totalProfit, equals(0));
    });

    test('multiple items with salePrice', () {
      final items = [
        makeItem(productName: 'A', quantityOrdered: 10,
            unitCost: 100, salePrice: 120),   // profit = 200
        makeItem(productName: 'B', quantityOrdered: 5,
            unitCost: 50, salePrice: 80),     // profit = 150
      ];
      final o = makeOrder(items: items);
      expect(o.totalProfit, equals(350));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PurchaseOrderItem — helpers', () {

    test('receivedPercent = received / ordered', () {
      final item = makeItem(quantityOrdered: 10).copyWith(
          quantityReceived: 7);
      expect(item.receivedPercent, closeTo(0.7, 0.001));
    });

    test('receivedPercent clamps to 1.0 max', () {
      final item = makeItem(quantityOrdered: 10).copyWith(
          quantityReceived: 15);
      expect(item.receivedPercent, equals(1.0));
    });

    test('quantityPending = ordered - received', () {
      final item = makeItem(quantityOrdered: 10).copyWith(
          quantityReceived: 3);
      expect(item.quantityPending, equals(7));
    });

    test('quantityPending never negative', () {
      final item = makeItem(quantityOrdered: 5).copyWith(
          quantityReceived: 8);
      expect(item.quantityPending, equals(0));
    });

    test('isFullyReceived true', () {
      final item = makeItem(quantityOrdered: 10).copyWith(
          quantityReceived: 10);
      expect(item.isFullyReceived, isTrue);
    });

    test('marginPercent calculation', () {
      final item = makeItem(unitCost: 100, salePrice: 150);
      expect(item.marginPercent, closeTo(50.0, 0.001));
    });

    test('marginPercent null when salePrice null', () {
      final item = makeItem(unitCost: 100, salePrice: null);
      expect(item.marginPercent, isNull);
    });

    test('profitPerUnit = salePrice - unitCost', () {
      final item = makeItem(unitCost: 100, salePrice: 140);
      expect(item.profitPerUnit, equals(40));
    });
  });
}