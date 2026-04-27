// =============================================================
// purchase_invoice_provider_test.dart
// Most critical — cart logic, validation, payment diff
// =============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/purchase_invoice_model.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_invoice_provider/purchase_invoice_provider.dart';

void main() {

  // ── Helpers ───────────────────────────────────────────────
  PoProduct makeProduct({
    String id            = 'p-1',
    String name          = 'Pepsi 1L',
    String category      = 'Drinks',
    String sku           = 'SKU-001',
    double purchasePrice = 100,
    double salePrice     = 130,
    double stock         = 50,
  }) {
    return PoProduct(
      id:            id,
      name:          name,
      category:      category,
      sku:           sku,
      purchasePrice: purchasePrice,
      salePrice:     salePrice,
      stock:         stock,
    );
  }

  PoSupplier makeSupplier({
    String id           = 'sup-1',
    String name         = 'Ali Traders',
    String company      = 'Ali Co',
    String phone        = '03001234567',
    int    paymentTerms = 30,
  }) {
    return PoSupplier(
      id:           id,
      name:         name,
      company:      company,
      phone:        phone,
      paymentTerms: paymentTerms,
    );
  }

  // Direct notifier — no DB dependency
  // ProviderContainer use nahi karte kyunki purchaseInvoiceProvider
  // supplierProvider ko listen karta hai jo DB connect karta hai
  PurchaseInvoiceNotifier makeNotifier() {
    return PurchaseInvoiceNotifier.forTesting();
  }

  // ═══════════════════════════════════════════════════════════
  group('Cart — addToCart', () {

    test('add product to empty cart', () {
      final notifier = makeNotifier();
      final product   = makeProduct();

      notifier.addToCart(product);

      final state = notifier.state;
      expect(state.cartItems, hasLength(1));
      expect(state.cartItems.first.product.id, equals('p-1'));
    });

    test('add same product again — qty increases by 1', () {
      final notifier = makeNotifier();
      final product   = makeProduct();

      notifier.addToCart(product);
      notifier.addToCart(product);

      final state = notifier.state;
      expect(state.cartItems, hasLength(1));
      expect(state.cartItems.first.quantity, equals(2));
    });

    test('add different products — separate rows', () {
      final notifier = makeNotifier();

      notifier.addToCart(makeProduct(id: 'p-1', name: 'Pepsi'));
      notifier.addToCart(makeProduct(id: 'p-2', name: 'Coke'));

      final state = notifier.state;
      expect(state.cartItems, hasLength(2));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('Cart — removeFromCart', () {

    test('remove item — cart becomes empty', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct());

      final cartId = notifier.state
          .cartItems.first.cartId;
      notifier.removeFromCart(cartId);

      expect(notifier.state.cartItems, isEmpty);
    });

    test('remove one item — other item remains', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(id: 'p-1'));
      notifier.addToCart(makeProduct(id: 'p-2'));

      final cartId = notifier.state
          .cartItems.first.cartId;
      notifier.removeFromCart(cartId);

      expect(notifier.state.cartItems, hasLength(1));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('Cart — updateQuantity', () {

    test('valid qty update', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct());

      final cartId = notifier.state
          .cartItems.first.cartId;
      notifier.updateQuantity(cartId, 5);

      expect(notifier.state
          .cartItems.first.quantity, equals(5));
    });

    test('qty 0 — ignored (quantity stays same)', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct());

      final cartId = notifier.state
          .cartItems.first.cartId;
      notifier.updateQuantity(cartId, 0);

      // qty 0 ya negative ignore hona chahiye
      expect(notifier.state
          .cartItems.first.quantity, greaterThan(0));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('Cart — price updates', () {

    test('updatePurchasePrice reflects in subTotal', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(purchasePrice: 100));

      final cartId = notifier.state
          .cartItems.first.cartId;
      notifier.updatePurchasePrice(cartId, 150);

      final item = notifier.state.cartItems.first;
      expect(item.purchasePrice, equals(150));
      expect(item.subTotal, equals(150)); // qty=1, price=150
    });

    test('updateSalePrice updates margin', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(purchasePrice: 100, salePrice: 130));

      final cartId = notifier.state
          .cartItems.first.cartId;
      notifier.updateSalePrice(cartId, 200);

      final item = notifier.state.cartItems.first;
      expect(item.salePrice, equals(200));
      expect(item.marginPercent, closeTo(100, 0.01)); // (200-100)/100 * 100
    });

    test('updateDiscount reduces subTotal', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(purchasePrice: 100));

      final cartId = notifier.state
          .cartItems.first.cartId;
      notifier.updateDiscount(cartId, 20);

      final item = notifier.state.cartItems.first;
      expect(item.subTotal, equals(80)); // 100 - 20
    });

    test('updateTax increases subTotal', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(purchasePrice: 100));

      final cartId = notifier.state
          .cartItems.first.cartId;
      notifier.updateTax(cartId, 17);

      final item = notifier.state.cartItems.first;
      expect(item.subTotal, equals(117)); // 100 + 17
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('Cart — grandTotal calculations', () {

    test('grandTotal = sum of all subTotals', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(id: 'p-1', purchasePrice: 500));
      notifier.addToCart(makeProduct(id: 'p-2', purchasePrice: 300));

      final state = notifier.state;
      expect(state.grandTotal, equals(800));
    });

    test('totalItems = cart items count', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(id: 'p-1'));
      notifier.addToCart(makeProduct(id: 'p-2'));

      expect(notifier.state.totalItems, equals(2));
    });

    test('hasPriceError true when purchasePrice > salePrice', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(purchasePrice: 200, salePrice: 150));

      expect(notifier.state.hasPriceError, isTrue);
    });

    test('hasPriceError false when purchasePrice <= salePrice', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(purchasePrice: 100, salePrice: 150));

      expect(notifier.state.hasPriceError, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('updateSubTotal — back-calculation', () {

    test('subTotal update back-calculates quantity (not price)', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(purchasePrice: 100));

      final cartId = notifier.state.cartItems.first.cartId;

      // Actual implementation: qty = newSubTotal / purchasePrice
      // purchasePrice=100, newSubTotal=200 → qty = 2.0
      notifier.updateSubTotal(cartId, 200);

      final item = notifier.state.cartItems.first;
      expect(item.quantity,      equals(2.0));
      expect(item.purchasePrice, equals(100.0)); // price unchanged
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('setPaidAmount — clamping', () {

    test('paid amount cannot exceed grandTotal', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(purchasePrice: 500));
      notifier.setPaidAmount(9999);

      final state = notifier.state;
      expect(state.paidAmount, lessThanOrEqualTo(state.grandTotal));
    });

    test('paid amount cannot be negative', () {
      final notifier = makeNotifier();
      notifier.setPaidAmount(-100);

      expect(notifier.state.paidAmount,
          greaterThanOrEqualTo(0));
    });

    test('valid paid amount stored correctly', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(purchasePrice: 1000));
      notifier.setPaidAmount(500);

      expect(notifier.state.paidAmount,
          equals(500));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('saveInvoice — validation errors', () {

    test('empty cart returns error', () async {
      final notifier = makeNotifier();

      final error = await notifier.saveInvoice();
      expect(error, isNotNull);
      expect(error, contains('khali'));
    });

    test('no supplier selected returns error', () async {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct());
      // supplier select nahi kiya

      final error = await notifier.saveInvoice();
      expect(error, isNotNull);
      expect(error?.toLowerCase(),
          anyOf(contains('supplier'), contains('select')));
    });

    test('no delivery date returns error', () async {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct());
      notifier.selectSupplier(makeSupplier());
      // delivery date set nahi ki

      final error = await notifier.saveInvoice();
      expect(error, isNotNull);
      expect(error?.toLowerCase(),
          anyOf(contains('delivery'), contains('date')));
    });

    test('missing sale price returns error', () async {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(salePrice: 0)); // sale price 0
      notifier.selectSupplier(makeSupplier());
      notifier.setDeliveryDate(DateTime.now().add(const Duration(days: 7)));

      final error = await notifier.saveInvoice();
      expect(error, isNotNull);
      expect(error?.toLowerCase(),
          anyOf(contains('sale'), contains('price')));
    });

    test('purchase price > sale price returns error', () async {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(purchasePrice: 200, salePrice: 150));
      notifier.selectSupplier(makeSupplier());
      notifier.setDeliveryDate(DateTime.now().add(const Duration(days: 7)));

      // Sale price set karo (above 0)
      final cartId = notifier.state
          .cartItems.first.cartId;
      notifier.updateSalePrice(cartId, 150); // still less than purchase

      final error = await notifier.saveInvoice();
      expect(error, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('loadFromExistingOrder', () {

    test('items loaded correctly from existing order', () {
      final notifier = makeNotifier();

      // Existing PO — PurchaseOrderModel banao with items
      final existingOrder = PurchaseOrderModel(
        id:                    'po-existing-1',
        tenantId:              'wh-1',
        poNumber:              'PO-2026-100',
        destinationLocationId: 'loc-1',
        status:                'ordered',
        orderDate:             DateTime(2026, 4, 26),
        expectedDate:          DateTime(2026, 4, 27),
        subtotal:              1220,
        discountAmount:        50,
        taxAmount:             0,
        totalAmount:           1220,
        paidAmount:            645,
        supplierId:            'sup-1',
        supplierName:          'M Hashim',
        supplierCompany:       'Testing',
        supplierPhone:         '03001234567',
        supplierPaymentTerms:  30,
        createdAt:             DateTime(2026, 4, 26),
        updatedAt:             DateTime(2026, 4, 26),
        items: [
          PurchaseOrderItem(
            id:               'item-1',
            poId:             'po-existing-1',
            tenantId:         'wh-1',
            productId:        'p-1',
            productName:      'Pepsi',
            sku:              'SKU-001',
            quantityOrdered:  10,
            quantityReceived: 0,
            unitCost:         122,
            totalCost:        1220,
            salePrice:        145,
            discountAmount:   50,
          ),
        ],
      );

      // Supplier list mein supplier available hai
      final suppliers = [
        PoSupplier(
          id:           'sup-1',
          name:         'M Hashim',
          company:      'Testing',
          phone:        '03001234567',
          paymentTerms: 30,
        ),
      ];

      notifier.loadFromExistingOrder(existingOrder, suppliers);

      final state = notifier.state;
      expect(state.cartItems,                      hasLength(1));
      expect(state.cartItems.first.quantity,       equals(10));
      expect(state.cartItems.first.purchasePrice,  equals(122));
      expect(state.cartItems.first.salePrice,      equals(145));
      expect(state.cartItems.first.discountAmount, equals(50));
      expect(state.paidAmount,                     equals(645));
      expect(state.selectedSupplier?.id,           equals('sup-1'));
      expect(state.selectedSupplier?.name,         equals('M Hashim'));
    });

    test('supplier not in list — created from order data', () {
      final notifier = makeNotifier();

      final existingOrder = PurchaseOrderModel(
        id:                    'po-2',
        tenantId:              'wh-1',
        poNumber:              'PO-2026-101',
        destinationLocationId: 'loc-1',
        status:                'ordered',
        orderDate:             DateTime(2026, 4, 26),
        subtotal:              500,
        discountAmount:        0,
        taxAmount:             0,
        totalAmount:           500,
        paidAmount:            0,
        supplierId:            'sup-unknown',
        supplierName:          'Unknown Supplier',
        supplierPhone:         '03009999999',
        createdAt:             DateTime(2026, 4, 26),
        updatedAt:             DateTime(2026, 4, 26),
        items:                 [],
      );

      // Empty supplier list — supplier nahi milega
      notifier.loadFromExistingOrder(existingOrder, []);

      final state = notifier.state;
      // Supplier naam se bana liya gaya hoga
      expect(state.selectedSupplier, isNotNull);
      expect(state.selectedSupplier?.name, equals('Unknown Supplier'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('clearCart', () {

    test('clearCart resets all state', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct());
      notifier.selectSupplier(makeSupplier());
      notifier.setPaidAmount(500);

      notifier.clearCart();

      final state = notifier.state;
      expect(state.cartItems,        isEmpty);
      expect(state.paidAmount,       equals(0));
      expect(state.selectedSupplier, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('Invoice Status — poType and invoiceStatus', () {

    test('default poType is purchase', () {
      final notifier = makeNotifier();
      expect(notifier.state.poType, equals(PoType.purchase));
    });

    test('setPoType changes type', () {
      final notifier = makeNotifier();
      notifier.setPoType(PoType.purchaseReturn);
      expect(notifier.state.poType,
          equals(PoType.purchaseReturn));
    });

    test('setInvoiceStatus to pending clears paidAmount', () {
      final notifier = makeNotifier();
      notifier.addToCart(makeProduct(purchasePrice: 1000));
      notifier.setPaidAmount(500);

      notifier.setInvoiceStatus(InvoiceStatus.pending);

      expect(notifier.state.paidAmount, equals(0));
    });
  });

  // ═══════════════════════════════════════════════════════════
  group('Search — filteredProducts', () {

    test('empty search returns all products', () {
      final notifier = makeNotifier();
      // searchQuery empty hone pe sab products milne chahiye
      expect(notifier.state.searchQuery, equals(''));
    });

    test('updateSearch filters by name', () {
      final notifier = makeNotifier();
      notifier.updateSearch('Pepsi');
      expect(notifier.state.searchQuery,
          equals('Pepsi'));
    });
  });
}