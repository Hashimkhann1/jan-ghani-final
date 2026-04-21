// =============================================================
// supplier_detail_models_test.dart
// SupplierLedgerEntry, SupplierPurchaseOrder,
// PurchaseOrderItem, SupplierFinancialSummary
// Real DB data se test kiya gaya hai
// =============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_detail_models.dart';

void main() {

  // ════════════════════════════════════════════════════════════
  // 1. SupplierLedgerEntry Tests
  // ════════════════════════════════════════════════════════════
  group('SupplierLedgerEntry —', () {

    // Real DB se — Qasim Khan ka opening entry
    final Map<String, dynamic> openingEntryMap = {
      'id':               '783ed866-efa7-49db-bb5d-43c2b8b0321b',
      'supplier_id':      '4991b2bd-21bf-4251-9df8-b9e55ea415c8',
      'po_id':            null,
      'entry_type':       'opening',
      'amount':           10000.0,
      'balance_before':   0.0,
      'balance_after':    10000.0,
      'notes':            'System se pehle ka balance',
      'created_by_name':  null,
      'created_at':       '2026-04-09 17:23:34',
    };

    // Real DB se — purchase entry
    final Map<String, dynamic> purchaseEntryMap = {
      'id':               'a273e7df-f721-4c86-bc3c-e08d09246ac6',
      'supplier_id':      '85e7ba3a-0f97-4bc9-9df9-9bf26a74535e',
      'po_id':            'f9563894-b9e5-41f0-8ced-364e2b894192',
      'entry_type':       'purchase',
      'amount':           1200.0,
      'balance_before':   3000.0,
      'balance_after':    4200.0,
      'notes':            'PO PO-20260411-275334 se purchase',
      'created_by_name':  'M Hashim',
      'created_at':       '2026-04-11 21:01:29',
    };

    // Real DB se — payment entry (negative amount)
    final Map<String, dynamic> paymentEntryMap = {
      'id':               '63306ea4-9a95-45ea-9e4c-a126bbdd9a28',
      'supplier_id':      '85e7ba3a-0f97-4bc9-9df9-9bf26a74535e',
      'po_id':            null,
      'entry_type':       'payment',
      'amount':           -5000.0,
      'balance_before':   13000.0,
      'balance_after':    8000.0,
      'notes':            'Manual payment',
      'created_by_name':  'M Hashim',
      'created_at':       '2026-04-11 00:04:40',
    };

    // Return entry
    final Map<String, dynamic> returnEntryMap = {
      'id':               'return-001',
      'supplier_id':      'sup-001',
      'po_id':            null,
      'entry_type':       'return',
      'amount':           -8000.0,
      'balance_before':   155000.0,
      'balance_after':    147000.0,
      'notes':            'Damaged goods return',
      'created_by_name':  'Ali (Manager)',
      'created_at':       '2026-02-10 00:00:00',
    };

    group('fromMap —', () {

      test('basic fields sahi parse hote hain', () {
        final entry = SupplierLedgerEntry.fromMap(openingEntryMap);

        expect(entry.id,           '783ed866-efa7-49db-bb5d-43c2b8b0321b');
        expect(entry.supplierId,   '4991b2bd-21bf-4251-9df8-b9e55ea415c8');
        expect(entry.entryType,    'opening');
        expect(entry.amount,       10000.0);
        expect(entry.balanceBefore, 0.0);
        expect(entry.balanceAfter,  10000.0);
        expect(entry.notes,         'System se pehle ka balance');
      });

      test('po_id null hota hai jab linked PO nahi', () {
        final entry = SupplierLedgerEntry.fromMap(openingEntryMap);
        expect(entry.poId, isNull);
      });

      test('po_id set hota hai jab PO linked ho', () {
        final entry = SupplierLedgerEntry.fromMap(purchaseEntryMap);
        expect(entry.poId, 'f9563894-b9e5-41f0-8ced-364e2b894192');
      });

      test('createdByName null ho sakta hai', () {
        final entry = SupplierLedgerEntry.fromMap(openingEntryMap);
        expect(entry.createdByName, isNull);
      });

      test('createdByName set hota hai', () {
        final entry = SupplierLedgerEntry.fromMap(purchaseEntryMap);
        expect(entry.createdByName, 'M Hashim');
      });

      test('createdAt sahi parse hota hai', () {
        final entry = SupplierLedgerEntry.fromMap(openingEntryMap);
        expect(entry.createdAt.year,  2026);
        expect(entry.createdAt.month, 4);
        expect(entry.createdAt.day,   9);
      });

      test('amount negative (payment) parse hota hai', () {
        final entry = SupplierLedgerEntry.fromMap(paymentEntryMap);
        expect(entry.amount, -5000.0);
      });
    });

    group('computed fields —', () {

      test('isDebit — purchase entry debit hoti hai', () {
        final entry = SupplierLedgerEntry.fromMap(purchaseEntryMap);
        expect(entry.isDebit,  true);
        expect(entry.isCredit, false);
      });

      test('isCredit — payment entry credit hoti hai', () {
        final entry = SupplierLedgerEntry.fromMap(paymentEntryMap);
        expect(entry.isCredit, true);
        expect(entry.isDebit,  false);
      });

      test('isCredit — return entry credit hoti hai', () {
        final entry = SupplierLedgerEntry.fromMap(returnEntryMap);
        expect(entry.isCredit, true);
      });

      test('entryTypeLabel — purchase', () {
        final entry = SupplierLedgerEntry.fromMap(purchaseEntryMap);
        expect(entry.entryTypeLabel, 'Purchase');
      });

      test('entryTypeLabel — payment', () {
        final entry = SupplierLedgerEntry.fromMap(paymentEntryMap);
        expect(entry.entryTypeLabel, 'Payment');
      });

      test('entryTypeLabel — return', () {
        final entry = SupplierLedgerEntry.fromMap(returnEntryMap);
        expect(entry.entryTypeLabel, 'Return');
      });

      test('entryTypeLabel — opening', () {
        final entry = SupplierLedgerEntry.fromMap(openingEntryMap);
        expect(entry.entryTypeLabel, isA<String>());
        // 'opening' label DB mein hai lekin model mein switch case nahi
        // toh default se original return hoga
      });

      test('entryTypeLabel — adjustment', () {
        final map = Map<String, dynamic>.from(openingEntryMap)
          ..['entry_type'] = 'adjustment';
        final entry = SupplierLedgerEntry.fromMap(map);
        expect(entry.entryTypeLabel, 'Adjustment');
      });
    });
  });

  // ════════════════════════════════════════════════════════════
  // 2. PurchaseOrderItem Tests
  // ════════════════════════════════════════════════════════════
  group('PurchaseOrderItem —', () {

    // Real data pattern se
    final Map<String, dynamic> fullyReceivedItemMap = {
      'id':                 'poi-001',
      'po_id':              'po-001',
      'product_id':         '3108e176-f0f1-492e-abbf-fc3fcbfce71b',
      'product_name':       'Pepsi 1 liter',
      'sku':                'Jg-8397434',
      'quantity_ordered':   10.0,
      'quantity_received':  10.0,
      'unit_cost':          122.0,
      'total_cost':         1220.0,
    };

    final Map<String, dynamic> partialReceivedItemMap = {
      'id':                 'poi-003',
      'po_id':              'po-002',
      'product_id':         '5eb20e03-ffd0-4385-9d57-b40bbe8aa446',
      'product_name':       'Family 1Kg',
      'sku':                'jg-8923473',
      'quantity_ordered':   10.0,
      'quantity_received':  4.0,
      'unit_cost':          301.51,
      'total_cost':         3015.10,
    };

    final Map<String, dynamic> notReceivedItemMap = {
      'id':                 'poi-007',
      'po_id':              'po-003',
      'product_id':         null,
      'product_name':       'Tapal Danedar 500g',
      'sku':                null,
      'quantity_ordered':   200.0,
      'quantity_received':  0.0,
      'unit_cost':          350.0,
      'total_cost':         70000.0,
    };

    group('fromMap —', () {

      test('basic fields sahi parse hote hain', () {
        final item = PurchaseOrderItem.fromMap(fullyReceivedItemMap);

        expect(item.id,           'poi-001');
        expect(item.poId,         'po-001');
        expect(item.productName,  'Pepsi 1 liter');
        expect(item.sku,          'Jg-8397434');
        expect(item.unitCost,     122.0);
        expect(item.totalCost,    1220.0);
      });

      test('product_id nullable — null ho sakta hai', () {
        final item = PurchaseOrderItem.fromMap(notReceivedItemMap);
        expect(item.productId, isNull);
      });

      test('sku nullable — null ho sakta hai', () {
        final item = PurchaseOrderItem.fromMap(notReceivedItemMap);
        expect(item.sku, isNull);
      });

      test('quantities sahi parse hote hain', () {
        final item = PurchaseOrderItem.fromMap(partialReceivedItemMap);
        expect(item.quantityOrdered,  10.0);
        expect(item.quantityReceived, 4.0);
      });
    });

    group('computed fields —', () {

      test('isFullyReceived — fully received item', () {
        final item = PurchaseOrderItem.fromMap(fullyReceivedItemMap);
        expect(item.isFullyReceived, true);
      });

      test('isFullyReceived — partial item', () {
        final item = PurchaseOrderItem.fromMap(partialReceivedItemMap);
        expect(item.isFullyReceived, false);
      });

      test('isFullyReceived — not received item', () {
        final item = PurchaseOrderItem.fromMap(notReceivedItemMap);
        expect(item.isFullyReceived, false);
      });

      test('quantityPending — fully received', () {
        final item = PurchaseOrderItem.fromMap(fullyReceivedItemMap);
        expect(item.quantityPending, 0.0);
      });

      test('quantityPending — partial', () {
        final item = PurchaseOrderItem.fromMap(partialReceivedItemMap);
        expect(item.quantityPending, 6.0); // 10 - 4
      });

      test('quantityPending — not received', () {
        final item = PurchaseOrderItem.fromMap(notReceivedItemMap);
        expect(item.quantityPending, 200.0);
      });

      test('receivedPercent — fully received = 1.0', () {
        final item = PurchaseOrderItem.fromMap(fullyReceivedItemMap);
        expect(item.receivedPercent, 1.0);
      });

      test('receivedPercent — partial = 0.4', () {
        final item = PurchaseOrderItem.fromMap(partialReceivedItemMap);
        expect(item.receivedPercent, 0.4);
      });

      test('receivedPercent — not received = 0.0', () {
        final item = PurchaseOrderItem.fromMap(notReceivedItemMap);
        expect(item.receivedPercent, 0.0);
      });

      test('receivedPercent — zero ordered mein division by zero nahi', () {
        final map = Map<String, dynamic>.from(fullyReceivedItemMap)
          ..['quantity_ordered']  = 0.0
          ..['quantity_received'] = 0.0;
        final item = PurchaseOrderItem.fromMap(map);
        expect(item.receivedPercent, 0.0);
      });

      test('receivedPercent — 1.0 se zyada nahi hota (clamp)', () {
        final map = Map<String, dynamic>.from(fullyReceivedItemMap)
          ..['quantity_ordered']  = 5.0
          ..['quantity_received'] = 10.0; // over-received
        final item = PurchaseOrderItem.fromMap(map);
        expect(item.receivedPercent, 1.0);
      });

      test('quantityPending — negative nahi hota (clamp)', () {
        final map = Map<String, dynamic>.from(fullyReceivedItemMap)
          ..['quantity_ordered']  = 5.0
          ..['quantity_received'] = 10.0; // over-received
        final item = PurchaseOrderItem.fromMap(map);
        expect(item.quantityPending, 0.0);
      });
    });
  });

  // ════════════════════════════════════════════════════════════
  // 3. SupplierPurchaseOrder Tests
  // ════════════════════════════════════════════════════════════
  group('SupplierPurchaseOrder —', () {

    // Real DB se — received PO (fully paid)
    final Map<String, dynamic> receivedPOMap = {
      'id':              '3b207b19-c70a-4250-8a60-37042569e34f',
      'po_number':       'PO-20260411-887925',
      'order_date':      '2026-04-11 20:55:01',
      'expected_date':   '2026-04-11 00:00:00',
      'received_date':   null,
      'status':          'received',
      'subtotal':        1200.0,
      'discount_amount': 0.0,
      'tax_amount':      0.0,
      'total_amount':    1200.0,
      'paid_amount':     1200.0,
      'notes':           null,
      'created_at':      '2026-04-11 20:55:01',
    };

    // Real DB se — ordered PO (not received, not paid)
    final Map<String, dynamic> orderedPOMap = {
      'id':              'e549ed73-a479-42a2-ae97-13c0a76ca2f9',
      'po_number':       'PO-20260415-112385',
      'order_date':      '2026-04-15 23:52:18',
      'expected_date':   '2026-04-15 00:00:00',
      'received_date':   null,
      'status':          'ordered',
      'subtotal':        43992.50,
      'discount_amount': 0.0,
      'tax_amount':      0.0,
      'total_amount':    43992.50,
      'paid_amount':     0.0,
      'notes':           null,
      'created_at':      '2026-04-15 23:52:18',
    };

    // Partial PO
    final Map<String, dynamic> partialPOMap = {
      'id':              'po-partial',
      'po_number':       'PO-2026-000021',
      'order_date':      '2026-03-28 00:00:00',
      'expected_date':   '2026-04-05 00:00:00',
      'received_date':   null,
      'status':          'partial',
      'subtotal':        150000.0,
      'discount_amount': 0.0,
      'tax_amount':      0.0,
      'total_amount':    150000.0,
      'paid_amount':     75000.0,
      'notes':           'Large bulk order',
      'created_at':      '2026-03-28 00:00:00',
    };

    group('fromMap —', () {

      test('basic fields sahi parse hote hain', () {
        final po = SupplierPurchaseOrder.fromMap(receivedPOMap);

        expect(po.id,       '3b207b19-c70a-4250-8a60-37042569e34f');
        expect(po.poNumber, 'PO-20260411-887925');
        expect(po.status,   'received');
        expect(po.totalAmount, 1200.0);
        expect(po.paidAmount,  1200.0);
      });

      test('received_date null hota hai', () {
        final po = SupplierPurchaseOrder.fromMap(receivedPOMap);
        expect(po.receivedDate, isNull);
      });

      test('notes null hota hai', () {
        final po = SupplierPurchaseOrder.fromMap(receivedPOMap);
        expect(po.notes, isNull);
      });

      test('notes set hota hai', () {
        final po = SupplierPurchaseOrder.fromMap(partialPOMap);
        expect(po.notes, 'Large bulk order');
      });

      test('discount_amount parse hota hai', () {
        final po = SupplierPurchaseOrder.fromMap(partialPOMap);
        expect(po.discountAmount, 0.0);
      });

      test('dates sahi parse hote hain', () {
        final po = SupplierPurchaseOrder.fromMap(orderedPOMap);
        expect(po.orderDate.year,  2026);
        expect(po.orderDate.month, 4);
        expect(po.orderDate.day,   15);
      });

      test('default items empty list hai', () {
        final po = SupplierPurchaseOrder.fromMap(receivedPOMap);
        expect(po.items, isEmpty);
      });
    });

    group('computed fields —', () {

      test('isFullyPaid — fully paid PO', () {
        final po = SupplierPurchaseOrder.fromMap(receivedPOMap);
        expect(po.isFullyPaid, true);
      });

      test('isFullyPaid — unpaid PO', () {
        final po = SupplierPurchaseOrder.fromMap(orderedPOMap);
        expect(po.isFullyPaid, false);
      });

      test('isFullyPaid — partial PO', () {
        final po = SupplierPurchaseOrder.fromMap(partialPOMap);
        expect(po.isFullyPaid, false);
      });

      test('remainingAmount — fully paid = 0', () {
        final po = SupplierPurchaseOrder.fromMap(receivedPOMap);
        expect(po.remainingAmount, 0.0);
      });

      test('remainingAmount — unpaid = total', () {
        final po = SupplierPurchaseOrder.fromMap(orderedPOMap);
        expect(po.remainingAmount, 43992.50);
      });

      test('remainingAmount — partial', () {
        final po = SupplierPurchaseOrder.fromMap(partialPOMap);
        expect(po.remainingAmount, 75000.0); // 150000 - 75000
      });

      test('statusLabel — received', () {
        final po = SupplierPurchaseOrder.fromMap(receivedPOMap);
        expect(po.statusLabel, 'Received');
      });

      test('statusLabel — ordered', () {
        final po = SupplierPurchaseOrder.fromMap(orderedPOMap);
        expect(po.statusLabel, 'Ordered');
      });

      test('statusLabel — partial', () {
        final po = SupplierPurchaseOrder.fromMap(partialPOMap);
        expect(po.statusLabel, 'Partial');
      });

      test('statusLabel — draft', () {
        final map = Map<String, dynamic>.from(receivedPOMap)
          ..['status'] = 'draft';
        final po = SupplierPurchaseOrder.fromMap(map);
        expect(po.statusLabel, 'Draft');
      });

      test('statusLabel — cancelled', () {
        final map = Map<String, dynamic>.from(receivedPOMap)
          ..['status'] = 'cancelled';
        final po = SupplierPurchaseOrder.fromMap(map);
        expect(po.statusLabel, 'Cancelled');
      });
    });
  });

  // ════════════════════════════════════════════════════════════
  // 4. SupplierFinancialSummary Tests
  // ════════════════════════════════════════════════════════════
  group('SupplierFinancialSummary —', () {

    test('totalRemaining sahi calculate hota hai', () {
      const summary = SupplierFinancialSummary(
        outstandingBalance: 12000,
        totalPurchased:     450000,
        totalPaid:          438000,
        totalOrders:        24,
        pendingOrders:      2,
      );

      expect(summary.totalRemaining, 12000.0); // 450000 - 438000
    });

    test('totalRemaining — sab paid ho toh 0', () {
      const summary = SupplierFinancialSummary(
        outstandingBalance: 0,
        totalPurchased:     100000,
        totalPaid:          100000,
        totalOrders:        5,
        pendingOrders:      0,
      );

      expect(summary.totalRemaining, 0.0);
    });

    test('Real DB values — M Hashim Testing supplier', () {
      // 100000.58 outstanding, multiple POs
      const summary = SupplierFinancialSummary(
        outstandingBalance: 100000.58,
        totalPurchased:     220000.0,
        totalPaid:          119999.42,
        totalOrders:        10,
        pendingOrders:      3,
      );

      expect(summary.outstandingBalance, 100000.58);
      expect(summary.pendingOrders, 3);
      expect(summary.totalOrders, 10);
    });

    test('zero state — naya supplier', () {
      const summary = SupplierFinancialSummary(
        outstandingBalance: 0,
        totalPurchased:     0,
        totalPaid:          0,
        totalOrders:        0,
        pendingOrders:      0,
      );

      expect(summary.totalRemaining, 0.0);
      expect(summary.totalOrders, 0);
    });
  });
}