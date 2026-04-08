// =============================================================
// new_po_provider.dart
// NewPurchaseOrderScreen ka Riverpod State + Notifier
// =============================================================

import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/features/purchase_invoice/domain/new_po_form_item/new_po_form_item.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class NewPoState {
  // Section 1 — Basic Info
  final String?   supplierId;
  final String?   supplierName;
  final String?   supplierCompany;
  final int       supplierPaymentTerms;
  final String    destinationId;
  final String    destinationName;
  final DateTime  orderDate;
  final DateTime? expectedDate;
  final String    notes;

  // Section 2 — Products
  final List<NewPoFormItem> items;

  // Section 3 — Financials
  final double discount;
  final double tax;

  // UI state
  final bool    isSaving;
  final String? errorMessage;

  const NewPoState({
    this.supplierId,
    this.supplierName,
    this.supplierCompany,
    this.supplierPaymentTerms = 30,
    this.destinationId        = 'loc-001',
    this.destinationName      = 'WH-MAIN — Main Warehouse',
    required this.orderDate,
    this.expectedDate,
    this.notes                = '',
    this.items                = const [],
    this.discount             = 0,
    this.tax                  = 0,
    this.isSaving             = false,
    this.errorMessage,
  });

  // ── Computed ──────────────────────────────────────────────

  double get subtotal =>
      items.fold(0.0, (sum, i) => sum + i.totalCost);

  double get totalAmount =>
      (subtotal - discount + tax).clamp(0, double.infinity);

  double get totalProfit {
    double p = 0;
    for (final item in items) {
      if (item.salePrice > 0 && item.unitCost > 0) {
        p += (item.salePrice - item.unitCost) * item.qty;
      }
    }
    return p;
  }

  double? get avgMargin {
    final withPrice = items
        .where((i) => i.salePrice > 0 && i.unitCost > 0)
        .toList();
    if (withPrice.isEmpty) return null;
    final total = withPrice.fold(
        0.0, (sum, i) => sum + (i.marginPercent ?? 0));
    return total / withPrice.length;
  }

  int get itemsWithSalePrice =>
      items.where((i) => i.salePrice > 0).length;

  double get expectedRevenue => items.fold(
      0.0,
          (sum, i) =>
      sum + (i.salePrice > 0 ? i.salePrice * i.qty : 0));

  bool get isValid =>
      supplierId != null &&
          items.isNotEmpty &&
          items.every((i) => i.isValid);

  NewPoState copyWith({
    String?             supplierId,
    String?             supplierName,
    String?             supplierCompany,
    int?                supplierPaymentTerms,
    String?             destinationId,
    String?             destinationName,
    DateTime?           orderDate,
    DateTime?           expectedDate,
    String?             notes,
    List<NewPoFormItem>? items,
    double?             discount,
    double?             tax,
    bool?               isSaving,
    String?             errorMessage,
  }) {
    return NewPoState(
      supplierId:           supplierId           ?? this.supplierId,
      supplierName:         supplierName         ?? this.supplierName,
      supplierCompany:      supplierCompany      ?? this.supplierCompany,
      supplierPaymentTerms: supplierPaymentTerms ?? this.supplierPaymentTerms,
      destinationId:        destinationId        ?? this.destinationId,
      destinationName:      destinationName      ?? this.destinationName,
      orderDate:            orderDate            ?? this.orderDate,
      expectedDate:         expectedDate         ?? this.expectedDate,
      notes:                notes                ?? this.notes,
      items:                items                ?? this.items,
      discount:             discount             ?? this.discount,
      tax:                  tax                  ?? this.tax,
      isSaving:             isSaving             ?? this.isSaving,
      errorMessage:         errorMessage         ?? this.errorMessage,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class NewPoNotifier extends StateNotifier<NewPoState> {
  NewPoNotifier()
      : super(NewPoState(orderDate: DateTime.now())) {
    // Pehle se ek empty row add karo
    addItem();
  }

  // ── Section 1 actions ─────────────────────────────────────

  void selectSupplier({
    required String id,
    required String name,
    required String company,
    required int    paymentTerms,
  }) {
    state = state.copyWith(
      supplierId:           id,
      supplierName:         name,
      supplierCompany:      company,
      supplierPaymentTerms: paymentTerms,
    );
  }

  void setDestination(String id, String name) =>
      state = state.copyWith(
          destinationId: id, destinationName: name);

  void setOrderDate(DateTime date) =>
      state = state.copyWith(orderDate: date);

  void setExpectedDate(DateTime date) =>
      state = state.copyWith(expectedDate: date);

  void setNotes(String notes) =>
      state = state.copyWith(notes: notes);

  // ── Section 2 actions ─────────────────────────────────────

  void addItem() {
    final newItems = [...state.items, NewPoFormItem()];
    state = state.copyWith(items: newItems);
  }

  void removeItem(String id) {
    final item = state.items.firstWhere((i) => i.id == id);
    item.dispose();
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
    );
  }

  void updateItemName(String id, String name) {
    for (final item in state.items) {
      if (item.id == id) item.productName = name;
    }
    // Trigger rebuild
    state = state.copyWith(items: [...state.items]);
  }

  /// Controllers change hone pe UI rebuild karo
  void onItemChanged() =>
      state = state.copyWith(items: [...state.items]);

  // ── Section 3 actions ─────────────────────────────────────

  void setDiscount(String val) =>
      state = state.copyWith(
          discount: double.tryParse(val) ?? 0);

  void setTax(String val) =>
      state = state.copyWith(tax: double.tryParse(val) ?? 0);

  // ── Cleanup ───────────────────────────────────────────────

  @override
  void dispose() {
    for (final item in state.items) {
      item.dispose();
    }
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

// autoDispose — screen close hone pe automatically dispose
final newPoProvider =
StateNotifierProvider.autoDispose<NewPoNotifier, NewPoState>(
      (ref) => NewPoNotifier(),
);