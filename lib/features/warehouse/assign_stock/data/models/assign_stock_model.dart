import 'assign_stock_item_model.dart';

class AssignStockState {
  final String transferNumber;
  final DateTime assignedAt;
  final String? selectedStoreId;
  final String? selectedStoreName;
  final String? assignedById;
  final String? assignedByName;
  final String? notes;
  final List<AssignStockCartItem> cartItems;
  final List<LinkedStoreItem> linkedStores;
  final String searchQuery;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const AssignStockState({
    required this.transferNumber,
    required this.assignedAt,
    this.selectedStoreId,
    this.selectedStoreName,
    this.assignedById,
    this.assignedByName,
    this.notes,
    required this.cartItems,
    required this.linkedStores,
    this.searchQuery = '',
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  int get totalItems => cartItems.length;

  double get grandTotal =>
      cartItems.fold(0.0, (sum, i) => sum + i.totalCost);

  double get grandTotalSalePrice =>
      cartItems.fold(0.0, (sum, i) => sum + i.totalSalePrice);

  double get totalQty =>
      cartItems.fold(0.0, (sum, i) => sum + i.quantity);

  bool get canSave =>
      selectedStoreId != null && cartItems.isNotEmpty;

  AssignStockState copyWith({
    String? transferNumber,
    DateTime? assignedAt,
    String? selectedStoreId,
    String? selectedStoreName,
    String? assignedById,
    String? assignedByName,
    String? notes,
    List<AssignStockCartItem>? cartItems,
    List<LinkedStoreItem>? linkedStores,
    String? searchQuery,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearStore = false,
    bool clearError = false,
  }) {
    return AssignStockState(
      transferNumber: transferNumber ?? this.transferNumber,
      assignedAt: assignedAt ?? this.assignedAt,
      selectedStoreId:
      clearStore ? null : (selectedStoreId ?? this.selectedStoreId),
      selectedStoreName:
      clearStore ? null : (selectedStoreName ?? this.selectedStoreName),
      assignedById: assignedById ?? this.assignedById,
      assignedByName: assignedByName ?? this.assignedByName,
      notes: notes ?? this.notes,
      cartItems: cartItems ?? this.cartItems,
      linkedStores: linkedStores ?? this.linkedStores,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LinkedStoreItem {
  final String storeId;
  final String storeName;
  final String storeCode;
  final String? storePhone;
  final String? storeAddress;

  const LinkedStoreItem({
    required this.storeId,
    required this.storeName,
    required this.storeCode,
    this.storePhone,
    this.storeAddress,
  });

  factory LinkedStoreItem.fromMap(Map<String, dynamic> map) {
    return LinkedStoreItem(
      storeId: map['store_id'] as String,
      storeName: map['store_name'] as String,
      storeCode: map['store_code'] as String,
      storePhone: map['store_phone'] as String?,
      storeAddress: map['store_address'] as String?,
    );
  }
}