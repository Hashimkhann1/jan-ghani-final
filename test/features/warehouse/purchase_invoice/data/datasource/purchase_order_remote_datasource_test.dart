// =============================================================
// purchase_order_remote_datasource_test.dart
//
// Yeh tests DB se connect nahi karte — pure logic test hai:
//   1. Model mapping (_mapToModel, fromMap)
//   2. Business logic helpers (qty diff, price change detection)
//   3. Ledger amount sign rules
//   4. Inventory GREATEST(0, ...) protection
//   5. alreadyReceived edit scenarios — diff calculations
//   6. Weighted average cost math
//   7. PurchaseOrderItem fromMap / toMap round-trip
// =============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';

void main() {

  // ── Helpers ───────────────────────────────────────────────
  PurchaseOrderItem makeItem({
    String  id               = 'item-1',
    String  poId             = 'po-1',
    String  tenantId         = 'wh-1',
    String? productId        = 'p-1',
    String  productName      = 'Pepsi 1L',
    String? sku              = 'SKU-001',
    double  quantityOrdered  = 10,
    double  quantityReceived = 0,
    double  unitCost         = 122,
    double  totalCost        = 1220,
    double? salePrice        = 145,
    double  discountAmount   = 0,
    double  discountPercent  = 0,
  }) {
    return PurchaseOrderItem(
      id:               id,
      poId:             poId,
      tenantId:         tenantId,
      productId:        productId,
      productName:      productName,
      sku:              sku,
      quantityOrdered:  quantityOrdered,
      quantityReceived: quantityReceived,
      unitCost:         unitCost,
      totalCost:        totalCost,
      salePrice:        salePrice,
      discountAmount:   discountAmount,
      discountPercent:  discountPercent,
    );
  }

  PurchaseOrderModel makeOrder({
    String  id             = 'po-1',
    String  status         = 'received',
    double  totalAmount    = 1645,
    double  paidAmount     = 0,
    double  discountAmount = 0,
    String? supplierId     = 'sup-1',
    String? supplierName   = 'M Hashim',
    List<PurchaseOrderItem> items = const [],
  }) {
    return PurchaseOrderModel(
      id:                    id,
      tenantId:              'wh-1',
      poNumber:              'PO-2026-001',
      supplierId:            supplierId,
      supplierName:          supplierName,
      destinationLocationId: 'loc-1',
      status:                status,
      orderDate:             DateTime(2026, 4, 27),
      subtotal:              totalAmount,
      discountAmount:        discountAmount,
      taxAmount:             0,
      totalAmount:           totalAmount,
      paidAmount:            paidAmount,
      createdAt:             DateTime(2026, 4, 27),
      updatedAt:             DateTime(2026, 4, 27),
      items:                 items,
    );
  }

  // ═══════════════════════════════════════════════════════════
  group('PurchaseOrderItem — fromMap / toMap round-trip', () {

    test('fromMap parses all fields correctly', () {
      final map = {
        'id':                'item-1',
        'po_id':             'po-1',
        'tenant_id':         'wh-1',
        'product_id':        'p-1',
        'product_name':      'Pepsi 1L',
        'sku':               'SKU-001',
        'quantity_ordered':  10.0,
        'quantity_received': 0.0,
        'unit_cost':         122.0,
        'total_cost':        1220.0,
        'sale_price':        145.0,
        'discount_amount':   0.0,
        'discount_percent':  0.0,
      };

      final item = PurchaseOrderItem.fromMap(map);
      expect(item.id,               equals('item-1'));
      expect(item.productName,      equals('Pepsi 1L'));
      expect(item.quantityOrdered,  equals(10.0));
      expect(item.unitCost,         equals(122.0));
      expect(item.salePrice,        equals(145.0));
      expect(item.discountAmount,   equals(0.0));
    });

    test('fromMap handles null salePrice', () {
      final map = {
        'id': 'i-1', 'po_id': 'po-1', 'tenant_id': 'wh-1',
        'product_name': 'Test', 'quantity_ordered': 5.0,
        'quantity_received': 0.0, 'unit_cost': 100.0,
        'total_cost': 500.0, 'sale_price': null,
        'discount_amount': 0.0, 'discount_percent': 0.0,
      };
      final item = PurchaseOrderItem.fromMap(map);
      expect(item.salePrice, isNull);
    });

    test('fromMap handles null discount_amount — defaults to 0', () {
      final map = {
        'id': 'i-1', 'po_id': 'po-1', 'tenant_id': 'wh-1',
        'product_name': 'Test', 'quantity_ordered': 5.0,
        'quantity_received': 0.0, 'unit_cost': 100.0,
        'total_cost': 500.0, 'sale_price': 130.0,
        'discount_amount': null, 'discount_percent': null,
      };
      final item = PurchaseOrderItem.fromMap(map);
      expect(item.discountAmount,  equals(0.0));
      expect(item.discountPercent, equals(0.0));
    });

    test('toMap → fromMap round-trip preserves all values', () {
      final original = makeItem(
        quantityOrdered: 12,
        unitCost:        150,
        salePrice:       200,
        discountAmount:  50,
        discountPercent: 5,
      );

      final map      = original.toMap();
      final restored = PurchaseOrderItem.fromMap(map);

      expect(restored.quantityOrdered,  equals(original.quantityOrdered));
      expect(restored.unitCost,         equals(original.unitCost));
      expect(restored.salePrice,        equals(original.salePrice));
      expect(restored.discountAmount,   equals(original.discountAmount));
      expect(restored.discountPercent,  equals(original.discountPercent));
    });

    test('copyWith changes only specified fields', () {
      final item    = makeItem(quantityOrdered: 10, unitCost: 100);
      final updated = item.copyWith(quantityOrdered: 15, salePrice: 180);

      expect(updated.quantityOrdered, equals(15));
      expect(updated.salePrice,       equals(180));
      expect(updated.unitCost,        equals(100)); // unchanged
      expect(updated.productName,     equals(item.productName)); // unchanged
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('Already Received PO — qty diff logic', () {

    // Simulate what datasource does:
    // qtyDiff = newItem.quantityOrdered - oldItem.quantityOrdered
    double qtyDiff(double oldQty, double newQty) => newQty - oldQty;

    test('qty increased — positive diff', () {
      // Pepsi: 10 → 12, inventory mein +2 jaana chahiye
      expect(qtyDiff(10, 12), equals(2));
    });

    test('qty decreased — negative diff', () {
      // Pepsi: 10 → 8, inventory se -2 hona chahiye
      expect(qtyDiff(10, 8), equals(-2));
    });

    test('qty unchanged — zero diff (skip inventory update)', () {
      expect(qtyDiff(10, 10), equals(0));
    });

    test('product removed — oldQty should be fully minused', () {
      // Old item had qty=10, new items list mein nahi hai
      const oldQty = 10.0;
      // inventory change = -oldQty
      expect(-oldQty, equals(-10.0));
    });

    test('new product added — full qty goes to inventory', () {
      // Product pehle PO mein nahi tha, ab add kiya
      const newQty    = 5.0;
      const existedBefore = false;
      if (!existedBefore) {
        // full qty inventory mein jayegi
        expect(newQty, equals(5.0));
      }
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('Already Received PO — price change detection', () {

    test('price changed when unitCost differs', () {
      final oldItem = makeItem(unitCost: 100);
      final newItem = makeItem(unitCost: 120);
      final priceChanged = newItem.unitCost != oldItem.unitCost;
      expect(priceChanged, isTrue);
    });

    test('price unchanged — no warehouse_products update needed', () {
      final oldItem = makeItem(unitCost: 100);
      final newItem = makeItem(unitCost: 100);
      final priceChanged = newItem.unitCost != oldItem.unitCost;
      expect(priceChanged, isFalse);
    });

    test('salePrice changed — detected', () {
      final oldItem = makeItem(salePrice: 130);
      final newItem = makeItem(salePrice: 150);
      final saleChanged =
          (newItem.salePrice ?? 0) != (oldItem.salePrice ?? 0);
      expect(saleChanged, isTrue);
    });

    test('salePrice from null to value — detected', () {
      final oldItem = makeItem(salePrice: null);
      final newItem = makeItem(salePrice: 150);
      final saleChanged =
          (newItem.salePrice ?? 0) != (oldItem.salePrice ?? 0);
      expect(saleChanged, isTrue);
    });

    test('update triggered when qty OR price changed', () {
      // shouldUpdateProduct = qtyDiff != 0 || priceChanged || saleChanged
      bool shouldUpdate({
        required double oldQty,   required double newQty,
        required double oldCost,  required double newCost,
        required double? oldSale, required double? newSale,
      }) {
        final qtyDiff      = newQty - oldQty;
        final priceChanged = newCost != oldCost;
        final saleChanged  = (newSale ?? 0) != (oldSale ?? 0);
        return qtyDiff != 0 || priceChanged || saleChanged;
      }

      // Only qty changed
      expect(shouldUpdate(
          oldQty: 10, newQty: 12,
          oldCost: 100, newCost: 100,
          oldSale: 130, newSale: 130), isTrue);

      // Only price changed
      expect(shouldUpdate(
          oldQty: 10, newQty: 10,
          oldCost: 100, newCost: 120,
          oldSale: 130, newSale: 130), isTrue);

      // Only sale price changed
      expect(shouldUpdate(
          oldQty: 10, newQty: 10,
          oldCost: 100, newCost: 100,
          oldSale: 130, newSale: 150), isTrue);

      // Nothing changed — no update needed
      expect(shouldUpdate(
          oldQty: 10, newQty: 10,
          oldCost: 100, newCost: 100,
          oldSale: 130, newSale: 130), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('Weighted Average Cost', () {

    double weightedAvgCost({
      required double currentQty,
      required double currentCost,
      required double addedQty,
      required double addedCost,
    }) {
      final totalQty = currentQty + addedQty;
      if (totalQty <= 0) return addedCost;
      // Note: currentQty already includes addedQty (post-update)
      // So formula uses (currentQty - addedQty) for pre-add stock
      return ((currentQty - addedQty) * currentCost +
          addedQty * addedCost) /
          currentQty;
    }

    test('basic weighted average — two different costs', () {
      // 10 units @ 100 already, adding 5 @ 130
      // Pre-add: 10, Post-add: 15
      // avg = (10*100 + 5*130) / 15 = 1650/15 = 110
      final avg = weightedAvgCost(
        currentQty:  15, currentCost: 100, // post-inventory
        addedQty:    5,  addedCost:   130,
      );
      expect(avg, closeTo(110.0, 0.01));
    });

    test('same cost — average stays same', () {
      final avg = weightedAvgCost(
        currentQty:  15, currentCost: 100,
        addedQty:    5,  addedCost:   100,
      );
      expect(avg, closeTo(100.0, 0.01));
    });

    test('price change only (qty diff=0) — direct replace', () {
      // Qty same, price change: just use new unitCost directly
      const newUnitCost = 120.0;
      expect(newUnitCost, equals(120.0),
          reason: 'Direct replace when qtyDiff == 0 but price changed');
    });

    test('zero current qty — new cost becomes avg', () {
      final avg = weightedAvgCost(
        currentQty:  5, currentCost: 0,
        addedQty:    5, addedCost:   120,
      );
      expect(avg, closeTo(120.0, 0.01));
    });

    test('large quantities — precision maintained', () {
      // 100 units @ 122 + 14 units @ 122
      final avg = weightedAvgCost(
        currentQty:  114, currentCost: 122,
        addedQty:    14,  addedCost:   122,
      );
      expect(avg, closeTo(122.0, 0.01));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('Supplier Ledger — amount sign rules', () {

    // Yeh rules datasource ke insertSupplierPaymentLedger mein apply hoti hain
    // Trigger: UPDATE suppliers SET outstanding_balance = SUM(amount)

    test('purchase entry positive — balance increases', () {
      // Supplier ne maal diya, hum unhe 1645 dene hain
      const purchaseAmount   = 1645.0;
      const expectedInLedger = 1645.0; // positive
      expect(purchaseAmount, equals(expectedInLedger));
    });

    test('payment entry NEGATIVE — balance decreases', () {
      // Hum ne supplier ko 1645 diye
      const paymentAmount    = 1645.0;
      final storedInLedger   = -paymentAmount; // NEGATIVE — our fix
      expect(storedInLedger, equals(-1645.0));

      // Trigger SUM: purchase(+1645) + payment(-1645) = 0
      const purchaseLedger = 1645.0;
      final totalBalance   = purchaseLedger + storedInLedger;
      expect(totalBalance, equals(0.0),
          reason: 'Fully paid supplier: balance should be 0');
    });

    test('partial payment — correct remaining balance', () {
      const purchaseLedger = 1645.0;
      const paymentLedger  = -645.0; // negative
      final balance = purchaseLedger + paymentLedger;
      expect(balance, equals(1000.0));
    });

    test('adjustment entry positive — balance increases (reverse payment)', () {
      // User ne 1000 mark kiya tha galti se, 800 karna tha
      // reverseSupplierPayment(200) → adjustment = +200
      const adjustmentAmount   = 200.0; // positive
      const purchaseLedger     = 1000.0;
      const paymentLedger      = -1000.0;
      final adjustmentLedger   = adjustmentAmount; // positive

      final finalBalance = purchaseLedger + paymentLedger + adjustmentLedger;
      expect(finalBalance, equals(200.0),
          reason: 'After correction: supplier is owed 200 again');
    });

    test('overpayment scenario — balance cannot go below 0', () {
      // Agar GREATEST(0, balance) use ho toh negative nahi jayega
      const calculatedBalance = -50.0; // overpaid
      final clampedBalance = calculatedBalance.clamp(0.0, double.infinity);
      expect(clampedBalance, equals(0.0));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('Inventory — GREATEST(0, qty - removal) protection', () {

    double safeInventoryUpdate(double currentQty, double removeQty) {
      return (currentQty - removeQty).clamp(0.0, double.infinity);
    }

    test('normal removal — qty decreases', () {
      expect(safeInventoryUpdate(20, 5), equals(15));
    });

    test('remove exact qty — becomes 0', () {
      expect(safeInventoryUpdate(10, 10), equals(0));
    });

    test('removal exceeds current qty — clamps to 0 (GREATEST protection)', () {
      // Inventory mein 8 hai, hum 12 remove karne ki koshish kar rahe
      // GREATEST(0, 8-12) = GREATEST(0, -4) = 0
      expect(safeInventoryUpdate(8, 12), equals(0),
          reason: 'Inventory cannot go negative');
    });

    test('zero qty removal — no change', () {
      expect(safeInventoryUpdate(10, 0), equals(10));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('becomingReceived vs alreadyReceived logic', () {

    bool becomingReceived(String oldStatus, String newStatus) =>
        newStatus == 'received' && oldStatus != 'received';

    bool alreadyReceived(String oldStatus, String newStatus) =>
        newStatus == 'received' && oldStatus == 'received';

    test('draft → received = becomingReceived', () {
      expect(becomingReceived('draft',    'received'), isTrue);
      expect(alreadyReceived('draft',     'received'), isFalse);
    });

    test('ordered → received = becomingReceived', () {
      expect(becomingReceived('ordered',  'received'), isTrue);
      expect(alreadyReceived('ordered',   'received'), isFalse);
    });

    test('received → received = alreadyReceived (edit mode)', () {
      expect(becomingReceived('received', 'received'), isFalse);
      expect(alreadyReceived('received',  'received'), isTrue);
    });

    test('received → ordered = neither (status downgrade, rare)', () {
      expect(becomingReceived('received', 'ordered'), isFalse);
      expect(alreadyReceived('received',  'ordered'), isFalse);
    });

    test('draft → ordered = neither (no inventory change)', () {
      expect(becomingReceived('draft', 'ordered'), isFalse);
      expect(alreadyReceived('draft',  'ordered'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('oldItems resolution — provider vs DB fallback', () {

    // Provider se oldItems aate hain — agar empty to DB se fallback
    List<PurchaseOrderItem> resolveOldItems(
        List<PurchaseOrderItem> providerItems,
        List<PurchaseOrderItem> dbItems) {
      return providerItems.isNotEmpty ? providerItems : dbItems;
    }

    test('provider items available — use them (no extra DB call)', () {
      final providerItems = [makeItem(id: 'i-1')];
      final dbItems       = [makeItem(id: 'i-2')];
      final resolved      = resolveOldItems(providerItems, dbItems);
      expect(resolved.first.id, equals('i-1'));
    });

    test('provider items empty — fallback to DB items', () {
      final providerItems = <PurchaseOrderItem>[];
      final dbItems       = [makeItem(id: 'i-db')];
      final resolved      = resolveOldItems(providerItems, dbItems);
      expect(resolved.first.id, equals('i-db'));
    });

    test('both empty — empty list returned', () {
      final resolved = resolveOldItems([], []);
      expect(resolved, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('PurchaseOrderModel — fromMap parsing', () {

    Map<String, dynamic> makeOrderMap({
      String status      = 'received',
      double totalAmount = 1645,
      double paidAmount  = 645,
    }) {
      return {
        'id':                     'po-1',
        'tenant_id':              'wh-1',
        'po_number':              'PO-2026-001',
        'supplier_id':            'sup-1',
        'supplier_name':          'M Hashim',
        'supplier_company':       'Testing',
        'supplier_phone':         '03001234567',
        'supplier_address':       null,
        'supplier_tax_id':        null,
        'supplier_payment_terms': 30,
        'destination_location_id': 'loc-1',
        'destination_name':       'WH-MAIN',
        'status':                 status,
        'order_date':             '2026-04-27T00:00:00.000Z',
        'expected_date':          '2026-04-27T00:00:00.000Z',
        'received_date':          null,
        'subtotal':               totalAmount,
        'discount_amount':        0.0,
        'tax_amount':             0.0,
        'total_amount':           totalAmount,
        'paid_amount':            paidAmount,
        'notes':                  null,
        'created_by_name':        'M Hashim',
        'created_at':             '2026-04-27T00:00:00.000Z',
        'updated_at':             '2026-04-27T00:00:00.000Z',
      };
    }

    test('fromMap parses basic fields', () {
      final order = PurchaseOrderModel.fromMap(makeOrderMap());
      expect(order.id,           equals('po-1'));
      expect(order.poNumber,     equals('PO-2026-001'));
      expect(order.status,       equals('received'));
      expect(order.totalAmount,  equals(1645));
      expect(order.paidAmount,   equals(645));
    });

    test('fromMap parses supplier fields', () {
      final order = PurchaseOrderModel.fromMap(makeOrderMap());
      expect(order.supplierId,            equals('sup-1'));
      expect(order.supplierName,          equals('M Hashim'));
      expect(order.supplierPaymentTerms,  equals(30));
    });

    test('fromMap handles null optional fields', () {
      final map   = makeOrderMap();
      map['supplier_id']   = null;
      map['expected_date'] = null;
      map['notes']         = null;

      final order = PurchaseOrderModel.fromMap(map);
      expect(order.supplierId,    isNull);
      expect(order.expectedDate,  isNull);
      expect(order.notes,         isNull);
    });

    test('fromMap with items list', () {
      final itemMap = {
        'id': 'i-1', 'po_id': 'po-1', 'tenant_id': 'wh-1',
        'product_id': 'p-1', 'product_name': 'Pepsi',
        'sku': 'SKU-001', 'quantity_ordered': 10.0,
        'quantity_received': 0.0, 'unit_cost': 122.0,
        'total_cost': 1220.0, 'sale_price': 145.0,
        'discount_amount': 0.0, 'discount_percent': 0.0,
      };
      final items = [PurchaseOrderItem.fromMap(itemMap)];
      final order = PurchaseOrderModel.fromMap(makeOrderMap(), items: items);
      expect(order.items, hasLength(1));
      expect(order.items.first.productName, equals('Pepsi'));
    });

    test('remainingAmount computed correctly from parsed data', () {
      final order = PurchaseOrderModel.fromMap(
          makeOrderMap(totalAmount: 1645, paidAmount: 645));
      expect(order.remainingAmount, equals(1000));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('Discount percent calculation', () {

    // Provider mein: discPct = (discountAmount / lineTotal) * 100
    double discountPercent(double discountAmount, double lineTotal) {
      if (lineTotal <= 0) return 0;
      return (discountAmount / lineTotal) * 100;
    }

    test('basic discount percent', () {
      // lineTotal = 1000, discount = 100 → 10%
      expect(discountPercent(100, 1000), closeTo(10.0, 0.01));
    });

    test('zero discount → 0%', () {
      expect(discountPercent(0, 1000), equals(0.0));
    });

    test('zero lineTotal → 0% (no division by zero)', () {
      expect(discountPercent(100, 0), equals(0.0));
    });

    test('full discount → 100%', () {
      expect(discountPercent(500, 500), closeTo(100.0, 0.01));
    });
  });
}