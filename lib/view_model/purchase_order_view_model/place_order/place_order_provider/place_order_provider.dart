import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/model/purchase_order_model.dart';
import 'package:jan_ghani_final/res/dummy/dummy_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PLACE ORDER FORM STATE
// ─────────────────────────────────────────────────────────────────────────────

class PlaceOrderState {
  final PoSupplierModel? selectedSupplier;
  final LocationModel? selectedDestination;
  final DateTime orderDate;
  final DateTime? expectedDate;
  final List<DraftOrderItem> items;
  final double taxPercent;
  final String notes;
  final PurchaseOrderStatus initialStatus; // draft or ordered
  final bool isSubmitting;
  final String? errorMessage;

  const PlaceOrderState({
    this.selectedSupplier,
    this.selectedDestination,
    required this.orderDate,
    this.expectedDate,
    this.items = const [],
    this.taxPercent = 0,
    this.notes = '',
    this.initialStatus = PurchaseOrderStatus.ordered,
    this.isSubmitting = false,
    this.errorMessage,
  });

  // ── Computed ──────────────────────────────────────────────────────────────
  double get subtotal => items.fold(0, (s, i) => s + i.total);
  double get taxAmount => subtotal * taxPercent / 100;
  double get totalAmount => subtotal + taxAmount;

  bool get canSubmit =>
      selectedSupplier != null &&
          selectedDestination != null &&
          items.isNotEmpty &&
          items.every((i) =>
          i.productName.trim().isNotEmpty &&
              i.quantity > 0 &&
              i.unitCost >= 0);

  PlaceOrderState copyWith({
    PoSupplierModel? selectedSupplier,
    LocationModel? selectedDestination,
    DateTime? orderDate,
    DateTime? expectedDate,
    List<DraftOrderItem>? items,
    double? taxPercent,
    String? notes,
    PurchaseOrderStatus? initialStatus,
    bool? isSubmitting,
    String? errorMessage,
    bool clearExpectedDate = false,
    bool clearError = false,
    bool clearSupplier = false,
    bool clearDestination = false,
  }) {
    return PlaceOrderState(
      selectedSupplier:
      clearSupplier ? null : (selectedSupplier ?? this.selectedSupplier),
      selectedDestination: clearDestination
          ? null
          : (selectedDestination ?? this.selectedDestination),
      orderDate: orderDate ?? this.orderDate,
      expectedDate: clearExpectedDate
          ? null
          : (expectedDate ?? this.expectedDate),
      items: items ?? this.items,
      taxPercent: taxPercent ?? this.taxPercent,
      notes: notes ?? this.notes,
      initialStatus: initialStatus ?? this.initialStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACE ORDER NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class PlaceOrderNotifier extends StateNotifier<PlaceOrderState> {
  PlaceOrderNotifier()
      : super(PlaceOrderState(orderDate: DateTime.now()));

  // ── Header fields ─────────────────────────────────────────────────────────

  void setSupplier(PoSupplierModel? s) =>
      state = state.copyWith(selectedSupplier: s, clearSupplier: s == null);

  void setDestination(LocationModel? l) =>
      state = state.copyWith(
          selectedDestination: l, clearDestination: l == null);

  void setOrderDate(DateTime d) => state = state.copyWith(orderDate: d);

  void setExpectedDate(DateTime? d) => d == null
      ? state = state.copyWith(clearExpectedDate: true)
      : state = state.copyWith(expectedDate: d);

  void setTaxPercent(double t) =>
      state = state.copyWith(taxPercent: t.clamp(0, 100));

  void setNotes(String n) => state = state.copyWith(notes: n);

  void setInitialStatus(PurchaseOrderStatus s) =>
      state = state.copyWith(initialStatus: s);

  // ── Items management ──────────────────────────────────────────────────────

  void addItem() {
    final newItem = DraftOrderItem(
      productName: '',
      quantity: 1,
      unitCost: 0,
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  void removeItem(int index) {
    final items = [...state.items];
    items.removeAt(index);
    state = state.copyWith(items: items);
  }

  void updateItemProduct(int index, PoProductSnapshot product) {
    final items = [...state.items];
    items[index] = items[index].copyWith(
      product: product,
      productName: product.name,
      sku: product.sku,
      unitCost: product.costPrice,
    );
    state = state.copyWith(items: items);
  }

  void updateItemName(int index, String name) {
    final items = [...state.items];
    items[index] = items[index].copyWith(productName: name);
    state = state.copyWith(items: items);
  }

  void updateItemQty(int index, double qty) {
    final items = [...state.items];
    items[index] = items[index].copyWith(quantity: qty < 0 ? 0 : qty);
    state = state.copyWith(items: items);
  }

  void updateItemCost(int index, double cost) {
    final items = [...state.items];
    items[index] = items[index].copyWith(unitCost: cost < 0 ? 0 : cost);
    state = state.copyWith(items: items);
  }

  void duplicateItem(int index) {
    final items = [...state.items];
    final copy = items[index].copyWith();
    items.insert(index + 1, copy);
    state = state.copyWith(items: items);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  /// Returns the created [PurchaseOrderModel] on success, null on failure.
  PurchaseOrderModel? submit() {
    if (!state.canSubmit) {
      state = state.copyWith(
          errorMessage: 'Please fill supplier, destination and all items.');
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    final now = DateTime.now();
    final poNumber = _generatePoNumber(state.selectedDestination!);

    final poItems = state.items.asMap().entries.map((e) {
      final i = e.key;
      final d = e.value;
      return PurchaseOrderItem(
        id: i + 1,
        poId: 0, // assigned by DB in real app
        productId: d.product?.id,
        productName: d.productName,
        sku: d.sku ?? d.product?.sku,
        quantityOrdered: d.quantity,
        quantityReceived: 0,
        unitCost: d.unitCost,
        totalCost: d.total,
      );
    }).toList();

    final po = PurchaseOrderModel(
      id: DateTime.now().millisecondsSinceEpoch,
      poNumber: poNumber,
      supplier: state.selectedSupplier,
      destinationLocation: state.selectedDestination,
      destinationLocationName: state.selectedDestination!.name,
      status: state.initialStatus,
      orderDate: state.orderDate,
      expectedDate: state.expectedDate,
      subtotal: state.subtotal,
      taxAmount: state.taxAmount,
      totalAmount: state.totalAmount,
      notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
      items: poItems,
    );

    // Reset form after success
    state = PlaceOrderState(orderDate: DateTime.now());

    return po;
  }

  void reset() {
    state = PlaceOrderState(orderDate: DateTime.now());
  }

  String _generatePoNumber(LocationModel dest) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final prefix = dest.type == LocationType.warehouse ? 'WH' : dest.code;
    final seq = (DateTime.now().millisecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    return 'PO-$prefix-$dateStr-$seq';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final placeOrderProvider =
StateNotifierProvider<PlaceOrderNotifier, PlaceOrderState>(
      (ref) => PlaceOrderNotifier(),
);

/// Available suppliers from dummy data
final availableSuppliersProvider = Provider<List<PoSupplierModel>>(
      (ref) => DummyData.dummyPoSuppliers,
);

/// Available locations (warehouses + stores) from dummy data
final availableLocationsProvider = Provider<List<LocationModel>>(
      (ref) => DummyData.dummyLocations,
);

/// Available products for selection inside PO items
final availablePoProductsProvider = Provider<List<PoProductSnapshot>>(
      (ref) => DummyData.dummyPoProducts,
);