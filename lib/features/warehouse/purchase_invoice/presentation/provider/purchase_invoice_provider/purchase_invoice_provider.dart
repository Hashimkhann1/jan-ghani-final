// =============================================================
// purchase_invoice_provider.dart
// UPDATED: Edit mode support — existingOrderId track karta hai
// loadFromExistingOrder() → pending PO ka data load karo
// saveInvoice()           → create ya update decide karta hai
// =============================================================

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/auth/local/auth_local_storage.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/datasource/purchase_order_remote_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/purchase_invoice_model.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/provider/supplier_provider/supplier_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/data/warehouse_finance_repository.dart';
import 'package:uuid/uuid.dart';

// ── Helper: SupplierModel → PoSupplier ───────────────────────
PoSupplier _toPoSupplier(SupplierModel s) => PoSupplier(
  id:           s.id,
  name:         s.name,
  company:      s.companyName  ?? '',
  phone:        s.phone,
  paymentTerms: s.paymentTerms ?? 30,
);

// ── Provider ──────────────────────────────────────────────────
final purchaseInvoiceProvider = StateNotifierProvider<
    PurchaseInvoiceNotifier, PurchaseInvoiceState>(
      (ref) {
    final notifier = PurchaseInvoiceNotifier();

    ref.listen<SupplierState>(
      supplierProvider,
          (_, next) {
        final poSuppliers = next.allSuppliers
            .where((s) => s.deletedAt == null && s.isActive)
            .map(_toPoSupplier)
            .toList();
        notifier.updateSuppliers(poSuppliers);
      },
      fireImmediately: true,
    );

    return notifier;
  },
);

// ── Notifier ──────────────────────────────────────────────────
class PurchaseInvoiceNotifier
    extends StateNotifier<PurchaseInvoiceState> {

  final PurchaseOrderRemoteDataSource _ds =
  PurchaseOrderRemoteDataSource();

  // Edit mode tracking
  String? _existingOrderId;   // null = new PO, set = edit mode
  String  _existingStatus = 'draft'; // pehla status save karo

  bool get isEditMode => _existingOrderId != null;

  bool get isReceivedLocked =>
      isEditMode && _existingStatus == 'received';

  PurchaseInvoiceNotifier()
      : super(PurchaseInvoiceState(
    poNumber:         _generatePoNo(),
    orderDate:        DateTime.now(),
    deliveryDate:     null,
    selectedSupplier: null,
    poType:           PoType.purchase,
    invoiceStatus:    InvoiceStatus.completed,
    paidAmount:       0,
    cartItems:        [],
    suppliers:        [],
    products:         dummyPoProducts,
  ));

  /// Test ke liye — supplierProvider dependency nahi hogi
  /// DB config initialize nahi hogi isliye tests crash karte the
  factory PurchaseInvoiceNotifier.forTesting() =>
      PurchaseInvoiceNotifier();

  // static String _generatePoNo() {
  //   final now = DateTime.now();
  //   return 'PO-${now.year}'
  //       '${now.month.toString().padLeft(2, '0')}'
  //       '${now.day.toString().padLeft(2, '0')}'
  //       '-${now.millisecondsSinceEpoch.toString().substring(7)}';
  // }

  // generate PO more better and no risk of the same po number in all warehouses
  static String _generatePoNo() {
    final now = DateTime.now();
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    final epoch = now.millisecondsSinceEpoch.toString().substring(7);
    return 'PO-${AppConfig.warehouseCode.substring(3)}-${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '-$epoch$random';
    // PO-LHE-20260428-00382174
  }

  // ── Edit mode: existing PO ka data load karo ─────────────
  // PurchaseOrderScreen se call hoga jab user Edit press kare
  void loadFromExistingOrder(
      PurchaseOrderModel order, List<PoSupplier> availableSuppliers) {
    _existingOrderId = order.id;
    _existingStatus  = order.status;

    // supplier match karo available list se
    PoSupplier? matchedSupplier;
    if (order.supplierId != null) {
      try {
        matchedSupplier = availableSuppliers
            .firstWhere((s) => s.id == order.supplierId);
      } catch (_) {
        // supplier list mein nahi mila — naam se bana lo
        if (order.supplierName != null) {
          matchedSupplier = PoSupplier(
            id:           order.supplierId!,
            name:         order.supplierName!,
            company:      order.supplierCompany ?? '',
            phone:        order.supplierPhone   ?? '',
            paymentTerms: order.supplierPaymentTerms ?? 30,
          );
        }
      }
    }

    // Cart items: existing PurchaseOrderItems → PoCartItem
    final cartItems = order.items.map((item) {
      // product ko PoProduct ki tarah reconstruct karo
      final product = PoProduct(
        id:            item.productId ?? item.id,
        name:          item.productName,
        category:      '',
        sku:           item.sku ?? '',
        purchasePrice: item.unitCost,
        salePrice:     item.salePrice ?? 0,
        stock:         0,
      );

      return PoCartItem(
        cartId:        const Uuid().v4(),
        product:       product,
        quantity:      item.quantityOrdered,
        purchasePrice: item.unitCost,
        salePrice:     item.salePrice ?? 0,
        taxAmount:     0,
        discountAmount: item.discountAmount,
      );
    }).toList();

    // InvoiceStatus map karo
    InvoiceStatus invoiceStatus;
    switch (order.status) {
      case 'received':
        invoiceStatus = InvoiceStatus.completed;
        break;
      case 'ordered':
      case 'partial':
        invoiceStatus = InvoiceStatus.pending;
        break;
      default:
        invoiceStatus = InvoiceStatus.draft;
    }

    state = state.copyWith(
      poNumber:         order.poNumber,
      orderDate:        order.orderDate,
      deliveryDate:     order.expectedDate,
      selectedSupplier: matchedSupplier,
      invoiceStatus:    invoiceStatus,
      paidAmount:       order.paidAmount,
      cartItems:        cartItems,
    );
  }

  // ── Supplier listener ─────────────────────────────────────
  void updateSuppliers(List<PoSupplier> suppliers) {
    if (!mounted) return;
    state = state.copyWith(suppliers: suppliers);
  }

  // ── Supplier & Type ───────────────────────────────────────
  void selectSupplier(PoSupplier supplier) =>
      state = state.copyWith(selectedSupplier: supplier);

  void setPoType(PoType type) => state = state.copyWith(poType: type);

  // purchase_invoice_provider.dart mein
  void setInvoiceStatus(InvoiceStatus status) {
    state = state.copyWith(
      invoiceStatus: status,
      paidAmount: status != InvoiceStatus.completed ? 0 : state.paidAmount,
    );
  }

  // ── Paid Amount ───────────────────────────────────────────
  void setPaidAmount(double amount) {
    final clamped = amount.clamp(0.0, state.grandTotal);
    state = state.copyWith(paidAmount: clamped);
  }

  // ── Dates ─────────────────────────────────────────────────
  void setOrderDate(DateTime date) =>
      state = state.copyWith(orderDate: date);

  void setDeliveryDate(DateTime date) =>
      state = state.copyWith(deliveryDate: date);

  // ── Cart ──────────────────────────────────────────────────
  void addToCart(PoProduct product) {
    final idx = state.cartItems
        .indexWhere((i) => i.product.id == product.id);
    if (idx != -1) {
      final items = [...state.cartItems];
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
      state = state.copyWith(cartItems: items);
    } else {
      state = state.copyWith(
        cartItems: [
          ...state.cartItems,
          PoCartItem(
            cartId:        const Uuid().v4(),
            product:       product,
            quantity:      1,
            purchasePrice: product.purchasePrice,
            salePrice:     product.salePrice,
          ),
        ],
      );
    }
  }

  void removeFromCart(String cartId) => state = state.copyWith(
    cartItems:
    state.cartItems.where((i) => i.cartId != cartId).toList(),
  );

  void updateQuantity(String cartId, double qty) {
    if (qty <= 0) return;
    _update(cartId, (i) => i.copyWith(quantity: qty));
  }

  void updatePurchasePrice(String cartId, double price) {
    if (price < 0) return;
    _update(cartId, (i) => i.copyWith(purchasePrice: price));
  }

  void updateSalePrice(String cartId, double price) {
    if (price < 0) return;
    _update(cartId, (i) => i.copyWith(salePrice: price));
  }

  void updateTax(String cartId, double tax) {
    if (tax < 0) return;
    _update(cartId, (i) => i.copyWith(taxAmount: tax));
  }

  void updateDiscount(String cartId, double discount) {
    if (discount < 0) return;
    _update(cartId, (i) => i.copyWith(discountAmount: discount));
  }

  void updateSubTotal(String cartId, double newSubTotal) {
    if (newSubTotal < 0) return;
    final item =
    state.cartItems.firstWhere((i) => i.cartId == cartId);
    if (item.purchasePrice <= 0) return;
    final newQty =
        (newSubTotal - item.taxAmount + item.discountAmount) /
            item.purchasePrice;
    if (newQty <= 0) return;
    _update(cartId, (i) => i.copyWith(quantity: newQty));
  }

  void _update(String cartId, PoCartItem Function(PoCartItem) fn) {
    state = state.copyWith(
      cartItems: state.cartItems
          .map((i) => i.cartId == cartId ? fn(i) : i)
          .toList(),
    );
  }

  void updateSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void clearCart() {
    _existingOrderId = null;
    _existingStatus  = 'draft';

    state = state.copyWith(
      cartItems:             [],
      poNumber:              _generatePoNo(),
      poType:                PoType.purchase,
      invoiceStatus:         InvoiceStatus.completed,
      paidAmount:            0,
      orderDate:             DateTime.now(),
      clearDeliveryDate:     true,
      clearSelectedSupplier: true,
    );
  }

  // ── SAVE INVOICE — Create ya Update decide karta hai ──────
  Future<String?> saveInvoice() async {
    if (state.cartItems.isEmpty)        return 'Cart khali hai';
    if (state.selectedSupplier == null) return 'Supplier select karo';
    if (state.deliveryDate == null)     return 'Delivery date set karo';
    if (!state.cartItems.every((i) => i.salePrice > 0))
      return 'Sab items ki sale price set karo';
    if (state.hasPriceError)
      return 'Kuch items mein purchase price sale price se zyada hai';

    try {
      final userData  = await AuthLocalStorage.loadUser();
      final userId    = userData?['id']        as String? ?? '';
      final userName  = userData?['full_name'] as String? ?? '';
      final remaining = (state.grandTotal - state.paidAmount)
          .clamp(0.0, double.infinity);

      final items = state.cartItems
          .map((i) {
        final lineTotal = i.purchasePrice * i.quantity;
        final discPct = lineTotal > 0
            ? (i.discountAmount / lineTotal) * 100
            : 0.0;

        return PurchaseOrderItem(
          id:               const Uuid().v4(),
          poId:             _existingOrderId ?? '',
          tenantId:         AppConfig.warehouseId,
          productId:        i.product.id,
          productName:      i.product.name,
          sku:              i.product.sku,
          quantityOrdered:  i.quantity,
          quantityReceived: 0,
          unitCost:         i.purchasePrice,
          totalCost:        i.subTotal,
          salePrice:        i.salePrice,
          discountAmount:   i.discountAmount,
          discountPercent:  double.parse(discPct.toStringAsFixed(2)),
        );
      }).toList();

      // ── EDIT MODE: update karo ────────────────────────────
      if (isEditMode) {
        // ── Old PO data lao — diff calculations ke liye ─────
        final oldPo         = await _ds.getById(_existingOrderId!);
        final oldPaidAmount = oldPo?.paidAmount ?? 0.0;
        final oldItems      = oldPo?.items      ?? [];

        final becomingReceived =
            state.invoiceStatus.dbValue == 'received' &&
                _existingStatus        != 'received';

        await _ds.updatePO(
          poId:            _existingOrderId!,
          warehouseId:     AppConfig.warehouseId,
          oldStatus:       _existingStatus,
          supplierId:      state.selectedSupplier!.id,
          status:          state.invoiceStatus.dbValue,
          expectedDate:    state.deliveryDate,
          subtotal:        state.totalBeforeTax,
          discountAmount:  state.totalDiscount,
          taxAmount:       state.totalTax,
          totalAmount:     state.grandTotal,
          paidAmount:      state.paidAmount,
          remainingAmount: remaining,
          updatedBy:       userId,
          updatedByName:   userName,
          oldItems:        oldItems,   // datasource ko diff ke liye chahiye
          items:           items,
        );

        // ── Payment diff handle karo ───────────────────────
        // Sirf received PO pe — draft/ordered pe payment nahi hoti
        final isReceivedNow = state.invoiceStatus.dbValue == 'received';

        if (isReceivedNow) {
          final paidDiff = state.paidAmount - oldPaidAmount;

          if (paidDiff > 0) {
            final poNum    = state.poNumber;
            final oldPaidS = oldPaidAmount.toStringAsFixed(0);
            final newPaidS = state.paidAmount.toStringAsFixed(0);

            // ── Cash transaction (cash out) ───────────────
            await WarehouseFinanceRepository.instance.addSupplierPayment(
              amount:        paidDiff,
              supplierId:    state.selectedSupplier!.id,
              notes:         'PO $poNum — payment: Rs $oldPaidS → Rs $newPaidS',
              createdBy:     userId,
              createdByName: userName,
            );

            // ── Supplier ledger mein payment entry ────────
            // FIX: addSupplierPayment sirf cash karta hai
            // supplier outstanding balance ke liye alag ledger entry chahiye
            await _ds.insertSupplierPaymentLedger(
              warehouseId:   AppConfig.warehouseId,
              supplierId:    state.selectedSupplier!.id,
              poId:          _existingOrderId!,
              amount:        paidDiff,
              notes:         'PO $poNum — payment: Rs $oldPaidS → Rs $newPaidS',
              createdBy:     userId,
            );

          } else if (paidDiff < 0) {
            final poNum    = state.poNumber;
            final oldPaidS = oldPaidAmount.toStringAsFixed(0);
            final newPaidS = state.paidAmount.toStringAsFixed(0);

            // Kam payment — sirf supplier ledger correction
            // Cash wapas nahi aata physically
            await WarehouseFinanceRepository.instance.reverseSupplierPayment(
              amount:        paidDiff.abs(),
              supplierId:    state.selectedSupplier!.id,
              notes:         'PO $poNum — payment correction: Rs $oldPaidS → Rs $newPaidS',
              createdBy:     userId,
              createdByName: userName,
            );
          }
          // paidDiff == 0 — kuch nahi karna
        }
      }
      // ── NEW MODE: create karo ─────────────────────────────
      else {
        await _ds.create(
          warehouseId:           AppConfig.warehouseId,
          poNumber:              state.poNumber,
          destinationLocationId: null,
          supplierId:            state.selectedSupplier!.id,
          status:                state.invoiceStatus.dbValue,
          expectedDate:          state.deliveryDate,
          subtotal:              state.totalBeforeTax,
          discountAmount:        state.totalDiscount,
          taxAmount:             state.totalTax,
          totalAmount:           state.grandTotal,
          paidAmount:            state.paidAmount,
          remainingAmount:       remaining,
          createdBy:             userId,
          createdByName:         userName,
          items:                 items,
        );

        if (state.paidAmount > 0) {
          final poNum  = state.poNumber;
          final supName = state.selectedSupplier!.name;

          // Cash transaction
          await WarehouseFinanceRepository.instance.addSupplierPayment(
            amount:        state.paidAmount,
            supplierId:    state.selectedSupplier!.id,
            notes:         'PO $poNum — $supName ko payment',
            createdBy:     userId,
            createdByName: userName,
          );

          // Supplier ledger payment entry — outstanding balance katega
          await _ds.insertSupplierPaymentLedger(
            warehouseId:   AppConfig.warehouseId,
            supplierId:    state.selectedSupplier!.id,
            poId:          _existingOrderId ?? '',
            amount:        state.paidAmount,
            notes:         'PO $poNum — $supName ko payment',
            createdBy:     userId,
          );
        }
      }

      clearCart();
      return null; // null = success
    } catch (e, stack) {
      print('❌ saveInvoice error: $e');
      print(stack);
      return e.toString();
    }
  }
}


// // =============================================================
// // purchase_invoice_provider.dart  — UPDATED (real DB suppliers)
// // =============================================================
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';
// import 'package:jan_ghani_final/core/config/app_config.dart';
// import 'package:jan_ghani_final/features/auth/local/auth_local_storage.dart';
// import 'package:jan_ghani_final/features/purchase_invoice/data/purchase_invoice_model.dart';
// import 'package:jan_ghani_final/features/purchase_invoice/data/datasource/purchase_order_remote_datasource.dart';
// import 'package:jan_ghani_final/features/purchase_invoice/domain/purchase_order_model.dart';
// import 'package:jan_ghani_final/features/supplier/domian/supplier_model.dart';
// import 'package:jan_ghani_final/features/supplier/presentation/provider/supplier_provider/supplier_provider.dart';
// import 'package:jan_ghani_final/features/warehouse_finance/data/warehouse_finance_repository.dart';
// import 'package:uuid/uuid.dart';
//
// // ── Helper: SupplierModel  →  PoSupplier ─────────────────────
// PoSupplier _toPoSupplier(SupplierModel s) => PoSupplier(
//   id:           s.id,
//   name:         s.name,
//   company:      s.companyName    ?? '',
//   phone:        s.phone,
//   paymentTerms: s.paymentTerms   ?? 30,
// );
//
// // ── Provider ──────────────────────────────────────────────────
// final purchaseInvoiceProvider = StateNotifierProvider<
//     PurchaseInvoiceNotifier, PurchaseInvoiceState>(
//       (ref) {
//     final notifier = PurchaseInvoiceNotifier();
//
//     // supplierProvider ko listen karo.
//     // fireImmediately: true  →  pehli baar bhi foran chalega
//     ref.listen<SupplierState>(
//       supplierProvider,
//           (_, next) {
//         final poSuppliers = next.allSuppliers
//             .where((s) => s.deletedAt == null && s.isActive)
//             .map(_toPoSupplier)
//             .toList();
//         notifier.updateSuppliers(poSuppliers);
//       },
//       fireImmediately: true,
//     );
//
//     return notifier;
//   },
// );
//
// // ── Notifier ──────────────────────────────────────────────────
// class PurchaseInvoiceNotifier
//     extends StateNotifier<PurchaseInvoiceState> {
//
//   final PurchaseOrderRemoteDataSource _ds = PurchaseOrderRemoteDataSource();
//
//   PurchaseInvoiceNotifier()
//       : super(PurchaseInvoiceState(
//     poNumber:         _generatePoNo(),
//     orderDate:        DateTime.now(),
//     deliveryDate:     null,
//     selectedSupplier: null,
//     poType:           PoType.purchase,
//     invoiceStatus:    InvoiceStatus.completed,
//     paidAmount:       0,
//     cartItems:        [],
//     suppliers:        [],
//     products:         dummyPoProducts,
//   ));
//
//   static String _generatePoNo() {
//     final now = DateTime.now();
//     return 'PO-${now.year}'
//         '${now.month.toString().padLeft(2, '0')}'
//         '${now.day.toString().padLeft(2, '0')}'
//         '-${now.millisecondsSinceEpoch.toString().substring(7)}';
//   }
//
//   // ── Supplier listener ────────────────────────────────────────
//   void updateSuppliers(List<PoSupplier> suppliers) {
//     if (!mounted) return;
//     state = state.copyWith(suppliers: suppliers);
//   }
//
//   // ── Supplier & Type ──────────────────────────────────────────
//   void selectSupplier(PoSupplier supplier) =>
//       state = state.copyWith(selectedSupplier: supplier);
//
//   void setPoType(PoType type) =>
//       state = state.copyWith(poType: type);
//
//   void setInvoiceStatus(InvoiceStatus status) =>
//       state = state.copyWith(invoiceStatus: status);
//
//   // ── Paid Amount ───────────────────────────────────────────────
//   void setPaidAmount(double amount) {
//     final clamped = amount.clamp(0.0, state.grandTotal);
//     state = state.copyWith(paidAmount: clamped);
//   }
//
//   // ── Dates ─────────────────────────────────────────────────────
//   void setOrderDate(DateTime date) =>
//       state = state.copyWith(orderDate: date);
//
//   void setDeliveryDate(DateTime date) =>
//       state = state.copyWith(deliveryDate: date);
//
//   // ── Cart ──────────────────────────────────────────────────────
//   void addToCart(PoProduct product) {
//     final idx =
//     state.cartItems.indexWhere((i) => i.product.id == product.id);
//     if (idx != -1) {
//       final items = [...state.cartItems];
//       items[idx] =
//           items[idx].copyWith(quantity: items[idx].quantity + 1);
//       state = state.copyWith(cartItems: items);
//     } else {
//       state = state.copyWith(
//         cartItems: [
//           ...state.cartItems,
//           PoCartItem(
//             cartId:        const Uuid().v4(),
//             product:       product,
//             quantity:      1,
//             purchasePrice: product.purchasePrice,
//             salePrice:     product.salePrice,
//           ),
//         ],
//       );
//     }
//   }
//
//   void removeFromCart(String cartId) => state = state.copyWith(
//     cartItems:
//     state.cartItems.where((i) => i.cartId != cartId).toList(),
//   );
//
//   void updateQuantity(String cartId, double qty) {
//     if (qty <= 0) return;
//     _update(cartId, (i) => i.copyWith(quantity: qty));
//   }
//
//   void updatePurchasePrice(String cartId, double price) {
//     if (price < 0) return;
//     _update(cartId, (i) => i.copyWith(purchasePrice: price));
//   }
//
//   void updateSalePrice(String cartId, double price) {
//     if (price < 0) return;
//     _update(cartId, (i) => i.copyWith(salePrice: price));
//   }
//
//   void updateTax(String cartId, double tax) {
//     if (tax < 0) return;
//     _update(cartId, (i) => i.copyWith(taxAmount: tax));
//   }
//
//   void updateDiscount(String cartId, double discount) {
//     if (discount < 0) return;
//     _update(cartId, (i) => i.copyWith(discountAmount: discount));
//   }
//
//   void updateSubTotal(String cartId, double newSubTotal) {
//     if (newSubTotal < 0) return;
//     final item =
//     state.cartItems.firstWhere((i) => i.cartId == cartId);
//     if (item.purchasePrice <= 0) return;
//     final newQty =
//         (newSubTotal - item.taxAmount + item.discountAmount) /
//             item.purchasePrice;
//     if (newQty <= 0) return;
//     _update(cartId, (i) => i.copyWith(quantity: newQty));
//   }
//
//   void _update(String cartId, PoCartItem Function(PoCartItem) fn) {
//     state = state.copyWith(
//       cartItems: state.cartItems
//           .map((i) => i.cartId == cartId ? fn(i) : i)
//           .toList(),
//     );
//   }
//
//   void updateSearch(String query) =>
//       state = state.copyWith(searchQuery: query);
//
//   void clearCart() => state = state.copyWith(
//     cartItems:              [],
//     poNumber:               _generatePoNo(),
//     poType:                 PoType.purchase,
//     invoiceStatus:          InvoiceStatus.completed,
//     paidAmount:             0,
//     orderDate:              DateTime.now(),
//     clearDeliveryDate:      true,
//     clearSelectedSupplier:  true,
//   );
//
//   // ── SAVE INVOICE — Complete implementation ───────────────────
//   Future<String?> saveInvoice() async {
//     if (state.cartItems.isEmpty)        return 'Cart khali hai';
//     if (state.selectedSupplier == null) return 'Supplier select karo';
//     if (state.deliveryDate == null)     return 'Delivery date set karo';
//     if (!state.cartItems.every((i) => i.salePrice > 0)) return 'Sab items ki sale price set karo';
//     if (state.hasPriceError) return 'Kuch items mein purchase price sale price se zyada hai';
//
//
//     try {
//       // SharedPreferences se logged-in user ka data lo
//       final userData = await AuthLocalStorage.loadUser();
//       final userId   = userData?['id']        as String? ?? '';
//       final userName = userData?['full_name'] as String? ?? '';
//
//       final remaining = (state.grandTotal - state.paidAmount)
//           .clamp(0.0, double.infinity);
//
//       final items = state.cartItems.map((i) => PurchaseOrderItem(
//         id:               const Uuid().v4(),
//         poId:             '',
//         tenantId:         AppConfig.warehouseId,
//         productId:        i.product.id,
//         productName:      i.product.name,
//         sku:              i.product.sku,
//         quantityOrdered:  i.quantity,
//         quantityReceived: 0,
//         unitCost:         i.purchasePrice,
//         totalCost:        i.purchasePrice * i.quantity,
//         salePrice:        i.salePrice,
//       )).toList();
//
//       await _ds.create(
//         warehouseId:           AppConfig.warehouseId,
//         poNumber:              state.poNumber,
//         destinationLocationId: null,
//         supplierId:            state.selectedSupplier!.id,
//         status:                state.invoiceStatus.dbValue,
//         expectedDate:          state.deliveryDate,
//         subtotal:              state.totalBeforeTax,
//         discountAmount:        state.totalDiscount,
//         taxAmount:             state.totalTax,
//         totalAmount:           state.grandTotal,
//         paidAmount:            state.paidAmount,
//         remainingAmount:       remaining,
//         createdBy:             userId,
//         createdByName:         userName,
//         items:                 items,
//       );
//
//       if (state.paidAmount > 0) {
//         await WarehouseFinanceRepository.instance.addSupplierPayment(
//           amount:        state.paidAmount,
//           supplierId:    state.selectedSupplier!.id,
//           notes:         'PO ${state.poNumber} — ${state.selectedSupplier!.name} ko payment',
//           createdBy:     userId,
//           createdByName: userName,
//         );
//       }
//
//       clearCart();
//       return null; // null = success
//     } catch (e, stack) {
//       print('❌ saveInvoice error: $e');
//       print(stack);
//       return e.toString();
//     }
//   }
// }