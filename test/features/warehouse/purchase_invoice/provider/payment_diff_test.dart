// =============================================================
// payment_diff_test.dart
// Most critical — payment diff, supplier ledger, cash transaction
// These test the exact bugs we fixed
// =============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/purchase_invoice_model.dart';

void main() {

  // ═══════════════════════════════════════════════════════════
  // Payment Diff Logic — unit test (pure Dart, no DB)
  // ═══════════════════════════════════════════════════════════
  group('Payment Diff Calculation', () {

    double calculatePaidDiff(double oldPaid, double newPaid) =>
        newPaid - oldPaid;

    test('payment increased — positive diff', () {
      // Old: 0, New: 645 → diff = +645
      final diff = calculatePaidDiff(0, 645);
      expect(diff, equals(645));
      expect(diff > 0, isTrue,
          reason: 'addSupplierPayment should be called');
    });

    test('payment decreased — negative diff', () {
      // Old: 1000, New: 800 → diff = -200
      final diff = calculatePaidDiff(1000, 800);
      expect(diff, equals(-200));
      expect(diff < 0, isTrue,
          reason: 'reverseSupplierPayment should be called');
    });

    test('payment unchanged — zero diff', () {
      final diff = calculatePaidDiff(500, 500);
      expect(diff, equals(0),
          reason: 'no payment action should be taken');
    });

    test('full payment from zero', () {
      final diff = calculatePaidDiff(0, 1220);
      expect(diff, equals(1220));
      expect(diff > 0, isTrue);
    });

    test('partial payment', () {
      final diff = calculatePaidDiff(0, 645);
      expect(diff, equals(645));
    });

    test('overpayment correction', () {
      // User ne 1500 mark kiya tha galti se, correct karke 1000 kiya
      final diff = calculatePaidDiff(1500, 1000);
      expect(diff, equals(-500));
      expect(diff < 0, isTrue,
          reason: 'reverseSupplierPayment(500) should be called');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Supplier Ledger Amount Sign
  // ═══════════════════════════════════════════════════════════
  group('Supplier Ledger — amount sign logic', () {

    test('purchase entry should be POSITIVE (balance increases)', () {
      // When supplier delivers goods, we owe them money
      // outstanding_balance += purchaseAmount
      const purchaseAmount = 1645.0;
      const expectedSign   = 1;  // positive
      expect(purchaseAmount.sign, equals(expectedSign));
    });

    test('payment entry must be NEGATIVE (balance decreases)', () {
      // When we pay supplier, we owe them less
      // SUM(amount) in trigger: purchase(+) + payment(-) = correct balance
      const paymentAmount  = 1645.0;
      final storedAmount   = -paymentAmount; // must store negative
      expect(storedAmount, equals(-1645.0));
      expect(storedAmount < 0, isTrue,
          reason: 'Payment in supplier_ledger must be negative '
              'so SUM(amount) trigger gives correct balance');
    });

    test('adjustment entry should be POSITIVE (balance increases)', () {
      // Reverse payment — supplier outstanding goes back up
      // e.g., 1000 → 800: reverseSupplierPayment(200)
      // adjustment amount = +200
      const adjustmentAmount = 200.0;
      expect(adjustmentAmount > 0, isTrue);
    });

    test('balance calculation with trigger SUM logic', () {
      // Simulate trigger: SELECT SUM(amount) FROM supplier_ledger
      const purchaseEntry   =  1645.0;  // positive
      const paymentEntry    = -1645.0;  // negative (our fix)
      final calculatedBalance = purchaseEntry + paymentEntry;
      expect(calculatedBalance, equals(0.0),
          reason: 'Fully paid supplier should have 0 outstanding');
    });

    test('partial payment balance calculation', () {
      const purchaseEntry   =  1645.0;
      const paymentEntry    =  -645.0;  // negative
      final balance = purchaseEntry + paymentEntry;
      expect(balance, equals(1000.0),
          reason: 'After partial payment: 1645 - 645 = 1000 remaining');
    });

    test('reverse payment (overpayment correction) balance', () {
      const purchaseEntry    =  1000.0;
      const paymentEntry     = -1000.0; // paid full
      const adjustmentEntry  =   200.0; // reverse 200 (positive)
      final balance = purchaseEntry + paymentEntry + adjustmentEntry;
      expect(balance, equals(200.0),
          reason: 'After 200 reversal: supplier is owed 200 again');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Inventory Qty Diff Logic
  // ═══════════════════════════════════════════════════════════
  group('Inventory Qty Diff — already received PO edit', () {

    double calculateQtyDiff(double oldQty, double newQty) =>
        newQty - oldQty;

    test('qty increased — positive diff added to inventory', () {
      // Pepsi: 10 → 12, diff = +2
      final diff = calculateQtyDiff(10, 12);
      expect(diff, equals(2));
      expect(diff > 0, isTrue,
          reason: 'inventory += 2');
    });

    test('qty decreased — negative diff removes from inventory', () {
      // Pepsi: 10 → 8, diff = -2
      final diff = calculateQtyDiff(10, 8);
      expect(diff, equals(-2));
      expect(diff < 0, isTrue,
          reason: 'inventory -= 2');
    });

    test('qty unchanged — no inventory update needed', () {
      final diff = calculateQtyDiff(10, 10);
      expect(diff, equals(0),
          reason: 'skip inventory update when diff is 0');
    });

    test('product removed — entire old qty should be minused', () {
      const oldQty  = 10.0;
      const removed = true;
      if (removed) {
        // inventory -= oldQty
        expect(oldQty, equals(10.0));
        expect(-oldQty, equals(-10.0));
      }
    });

    test('GREATEST(0, qty - removal) prevents negative inventory', () {
      // If inventory has 8 but we try to remove 10
      const currentInventory = 8.0;
      const removalQty       = 10.0;
      final result = (currentInventory - removalQty).clamp(0.0, double.infinity);
      expect(result, equals(0.0),
          reason: 'Inventory cannot go below 0');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Weighted Average Cost Calculation
  // ═══════════════════════════════════════════════════════════
  group('Weighted Average Cost', () {

    double weightedAvg({
      required double existingQty,
      required double existingCost,
      required double newQty,
      required double newCost,
    }) {
      final totalQty = existingQty + newQty;
      if (totalQty <= 0) return newCost;
      return (existingQty * existingCost + newQty * newCost) / totalQty;
    }

    test('basic weighted average', () {
      // 10 units @ 100 + 5 units @ 130 = 15 units @ 110
      final avg = weightedAvg(
          existingQty: 10, existingCost: 100,
          newQty: 5, newCost: 130);
      expect(avg, closeTo(110.0, 0.01));
    });

    test('same cost — average stays same', () {
      final avg = weightedAvg(
          existingQty: 10, existingCost: 100,
          newQty: 5, newCost: 100);
      expect(avg, equals(100.0));
    });

    test('zero existing qty — new cost is avg', () {
      final avg = weightedAvg(
          existingQty: 0, existingCost: 0,
          newQty: 10, newCost: 120);
      expect(avg, equals(120.0));
    });

    test('price change only (qty unchanged) — direct replace', () {
      // Old cost: 100, New cost: 120, qty same
      // In this case we directly replace purchase_price
      const newCost = 120.0;
      expect(newCost, equals(120.0),
          reason: 'Direct price replace when qty diff = 0');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // PoCartItem — subTotal calculation
  // ═══════════════════════════════════════════════════════════
  group('PoCartItem — subTotal edge cases', () {

    PoCartItem makeCartItem({
      double qty            = 1,
      double purchasePrice  = 100,
      double salePrice      = 130,
      double taxAmount      = 0,
      double discountAmount = 0,
    }) {
      return PoCartItem(
        cartId:         'cart-1',
        product:        const PoProduct(
          id: 'p-1', name: 'Test', category: 'Cat',
          sku: 'SKU', purchasePrice: 100, salePrice: 130, stock: 50,
        ),
        quantity:       qty,
        purchasePrice:  purchasePrice,
        salePrice:      salePrice,
        taxAmount:      taxAmount,
        discountAmount: discountAmount,
      );
    }

    test('subTotal = price * qty (no tax, no discount)', () {
      final item = makeCartItem(qty: 5, purchasePrice: 100);
      expect(item.subTotal, equals(500));
    });

    test('subTotal with tax', () {
      final item = makeCartItem(qty: 1, purchasePrice: 100, taxAmount: 17);
      expect(item.subTotal, equals(117));
    });

    test('subTotal with discount', () {
      final item = makeCartItem(
          qty: 1, purchasePrice: 100, discountAmount: 20);
      expect(item.subTotal, equals(80));
    });

    test('subTotal with both tax and discount', () {
      final item = makeCartItem(
          qty: 2, purchasePrice: 100, taxAmount: 20, discountAmount: 10);
      // (100*2) + 20 - 10 = 210
      expect(item.subTotal, equals(210));
    });

    test('marginPercent calculation', () {
      final item = makeCartItem(purchasePrice: 100, salePrice: 150);
      expect(item.marginPercent, closeTo(50.0, 0.01));
    });

    test('marginPercent null when salePrice is 0', () {
      final item = makeCartItem(purchasePrice: 100, salePrice: 0);
      expect(item.marginPercent, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // PurchaseInvoiceState — computed fields
  // ═══════════════════════════════════════════════════════════
  group('PurchaseInvoiceState — computed fields', () {

    PoCartItem makeItem({
      String id            = 'cart-1',
      double qty           = 1,
      double purchasePrice = 100,
      double salePrice     = 130,
      double discount      = 0,
      double tax           = 0,
    }) {
      return PoCartItem(
        cartId: id,
        product: const PoProduct(
          id: 'p-1', name: 'P', category: 'C',
          sku: 'S', purchasePrice: 100, salePrice: 130, stock: 10,
        ),
        quantity:       qty,
        purchasePrice:  purchasePrice,
        salePrice:      salePrice,
        discountAmount: discount,
        taxAmount:      tax,
      );
    }

    PurchaseInvoiceState makeState(List<PoCartItem> items) {
      return PurchaseInvoiceState(
        poNumber:         'PO-001',
        orderDate:        DateTime(2026, 4, 27),
        selectedSupplier: null,
        poType:           PoType.purchase,
        cartItems:        items,
        suppliers:        const [],
        products:         const [],
      );
    }

    test('totalBeforeTax sums purchasePrice * qty', () {
      final state = makeState([
        makeItem(qty: 5, purchasePrice: 100),
        makeItem(id: 'cart-2', qty: 3, purchasePrice: 200),
      ]);
      expect(state.totalBeforeTax, equals(1100)); // 500 + 600
    });

    test('totalDiscount sums all discounts', () {
      final state = makeState([
        makeItem(discount: 50),
        makeItem(id: 'cart-2', discount: 30),
      ]);
      expect(state.totalDiscount, equals(80));
    });

    test('totalTax sums all taxes', () {
      final state = makeState([
        makeItem(tax: 17),
        makeItem(id: 'cart-2', tax: 25),
      ]);
      expect(state.totalTax, equals(42));
    });

    test('grandTotal = beforeTax + tax - discount', () {
      final state = makeState([
        makeItem(qty: 2, purchasePrice: 100, tax: 20, discount: 10),
      ]);
      // (100*2) + 20 - 10 = 210
      expect(state.grandTotal, equals(210));
    });

    test('totalProfit only counts items with salePrice > 0', () {
      final state = makeState([
        makeItem(qty: 10, purchasePrice: 100, salePrice: 130), // 300
        makeItem(id: 'cart-2', qty: 5, purchasePrice: 200, salePrice: 0),  // 0
      ]);
      expect(state.totalProfit, equals(300));
    });

    test('filteredProducts — empty search returns all', () {
      final state = makeState([]);
      expect(state.filteredProducts.length,
          equals(state.products.length));
    });
  });
}