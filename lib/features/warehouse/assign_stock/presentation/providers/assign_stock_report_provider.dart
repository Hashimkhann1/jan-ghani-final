import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class TransferReportItem {
  final String id;
  final String transferNumber;
  final String toStoreId;
  final String toStoreName;
  final String status;
  final String? assignedById;
  final String? assignedByName;
  final DateTime assignedAt;
  final String? notes;
  final int totalItems;
  final double totalCost;
  final double totalSalePrice;
  final DateTime createdAt;

  const TransferReportItem({
    required this.id,
    required this.transferNumber,
    required this.toStoreId,
    required this.toStoreName,
    required this.status,
    this.assignedById,
    this.assignedByName,
    required this.assignedAt,
    this.notes,
    required this.totalItems,
    required this.totalCost,
    required this.totalSalePrice,
    required this.createdAt,
  });

  factory TransferReportItem.fromMap(Map<String, dynamic> map) {
    return TransferReportItem(
      id: map['id'] as String,
      transferNumber: map['transfer_number'] as String,
      toStoreId: map['to_store_id'] as String,
      toStoreName: map['to_store_name'] as String,
      status: map['status'] as String,
      assignedById: map['assigned_by_id'] as String?,
      assignedByName: map['assigned_by_name'] as String?,
      assignedAt: map['assigned_at'] is DateTime
          ? map['assigned_at'] as DateTime
          : DateTime.parse(map['assigned_at'].toString()),
      notes: map['notes'] as String?,
      totalItems: _parseInt(map['total_items']),
      totalCost: _parseDouble(map['total_cost']),
      totalSalePrice: _parseDouble(map['total_sale_price']),
      createdAt: map['created_at'] is DateTime
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at'].toString()),
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class TransferDetailItem {
  final String id;
  final String productId;
  final String productName;
  final String sku;
  final String unitOfMeasure;
  final double quantityRequested;
  final double quantitySent;
  final double purchasePrice;
  final double salePrice;
  final double wholesalePrice;
  final double taxAmount;
  final double discountAmount;
  final double totalCost;
  final String? categoryId;

  const TransferDetailItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unitOfMeasure,
    required this.quantityRequested,
    required this.quantitySent,
    required this.purchasePrice,
    required this.salePrice,
    required this.wholesalePrice,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalCost,
    this.categoryId,
  });

  factory TransferDetailItem.fromMap(Map<String, dynamic> map) {
    return TransferDetailItem(
      id: map['id'] as String,
      productId: map['product_id'] as String? ?? '',
      productName: map['product_name'] as String,
      sku: map['sku'] as String? ?? '',
      unitOfMeasure: map['unit_of_measure'] as String? ?? 'pcs',
      quantityRequested: _parseDouble(map['quantity_requested']),
      quantitySent: _parseDouble(map['quantity_sent']),
      purchasePrice: _parseDouble(map['purchase_price']),
      salePrice: _parseDouble(map['sale_price']),
      wholesalePrice: _parseDouble(map['wholesale_price']),
      taxAmount: _parseDouble(map['tax_amount']),
      discountAmount: _parseDouble(map['discount_amount']),
      totalCost: _parseDouble(map['total_cost']),
      categoryId: map['category_id'] as String?,
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  double get totalSalePrice => salePrice * quantitySent;
}

// ─── Filter State ─────────────────────────────────────────────────────────────

class TransferReportFilter {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? selectedStoreId;
  final String? selectedStatus; // null = all
  final String searchQuery;

  const TransferReportFilter({
    this.fromDate,
    this.toDate,
    this.selectedStoreId,
    this.selectedStatus,
    this.searchQuery = '',
  });

  TransferReportFilter copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String? selectedStoreId,
    String? selectedStatus,
    String? searchQuery,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearStore = false,
    bool clearStatus = false,
  }) {
    return TransferReportFilter(
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      selectedStoreId:
      clearStore ? null : (selectedStoreId ?? this.selectedStoreId),
      selectedStatus:
      clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ─── Report State ─────────────────────────────────────────────────────────────

class TransferReportState {
  final List<TransferReportItem> transfers;
  final List<TransferReportItem> filteredTransfers;
  final List<Map<String, dynamic>> linkedStores; // [{storeId, storeName}]
  final TransferReportFilter filter;
  final bool isLoading;
  final String? errorMessage;

  // Detail dialog
  final TransferReportItem? selectedTransfer;
  final List<TransferDetailItem> selectedItems;
  final bool isLoadingDetail;

  const TransferReportState({
    required this.transfers,
    required this.filteredTransfers,
    required this.linkedStores,
    required this.filter,
    this.isLoading = false,
    this.errorMessage,
    this.selectedTransfer,
    this.selectedItems = const [],
    this.isLoadingDetail = false,
  });

  // Summary stats
  int get totalTransfers => filteredTransfers.length;
  int get pendingCount =>
      filteredTransfers.where((t) => t.status == 'pending').length;
  int get acceptedCount =>
      filteredTransfers.where((t) => t.status == 'accepted').length;
  double get thisMonthCost {
    final now = DateTime.now();
    return filteredTransfers
        .where((t) =>
    t.assignedAt.year == now.year && t.assignedAt.month == now.month)
        .fold(0.0, (sum, t) => sum + t.totalCost);
  }

  double get grandTotalCost =>
      filteredTransfers.fold(0.0, (sum, t) => sum + t.totalCost);

  TransferReportState copyWith({
    List<TransferReportItem>? transfers,
    List<TransferReportItem>? filteredTransfers,
    List<Map<String, dynamic>>? linkedStores,
    TransferReportFilter? filter,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    TransferReportItem? selectedTransfer,
    bool clearSelectedTransfer = false,
    List<TransferDetailItem>? selectedItems,
    bool? isLoadingDetail,
  }) {
    return TransferReportState(
      transfers: transfers ?? this.transfers,
      filteredTransfers: filteredTransfers ?? this.filteredTransfers,
      linkedStores: linkedStores ?? this.linkedStores,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedTransfer: clearSelectedTransfer
          ? null
          : (selectedTransfer ?? this.selectedTransfer),
      selectedItems: selectedItems ?? this.selectedItems,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class TransferReportNotifier extends StateNotifier<TransferReportState> {
  final String _warehouseId;
  final Connection _db;

  TransferReportNotifier(this._warehouseId, this._db)
      : super(TransferReportState(
    transfers: const [],
    filteredTransfers: const [],
    linkedStores: const [],
    filter: const TransferReportFilter(),
  )) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.wait([_loadTransfers(), _loadLinkedStores()]);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> _loadLinkedStores() async {
    final result = await _db.execute(
      Sql.named('''
        SELECT store_id, store_name, store_code
        FROM public.linked_stores
        WHERE warehouse_id = @warehouseId
          AND is_active = true
          AND deleted_at IS NULL
        ORDER BY store_name ASC
      '''),
      parameters: {'warehouseId': _warehouseId},
    );
    final stores =
    result.map((r) => Map<String, dynamic>.from(r.toColumnMap())).toList();
    state = state.copyWith(linkedStores: stores);
  }

  Future<void> _loadTransfers() async {
    final result = await _db.execute(
      Sql.named('''
        SELECT
          id, transfer_number, to_store_id, to_store_name,
          status, assigned_by_id, assigned_by_name,
          assigned_at, notes, total_items, total_cost, total_sale_price,
          created_at
        FROM public.stock_transfers
        WHERE warehouse_id = @warehouseId
          AND deleted_at IS NULL
        ORDER BY assigned_at DESC
      '''),
      parameters: {'warehouseId': _warehouseId},
    );

    final transfers = result
        .map((r) => TransferReportItem.fromMap(Map<String, dynamic>.from(r.toColumnMap())))
        .toList();

    state = state.copyWith(
      transfers: transfers,
      filteredTransfers: transfers,
      isLoading: false,
    );
  }

  void applyFilters({
    DateTime? fromDate,
    DateTime? toDate,
    String? storeId,
    String? status,
    String? search,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearStore = false,
    bool clearStatus = false,
  }) {
    final newFilter = state.filter.copyWith(
      fromDate: fromDate,
      toDate: toDate,
      selectedStoreId: storeId,
      selectedStatus: status,
      searchQuery: search,
      clearFromDate: clearFromDate,
      clearToDate: clearToDate,
      clearStore: clearStore,
      clearStatus: clearStatus,
    );
    _applyFilter(newFilter);
  }

  void _applyFilter(TransferReportFilter f) {
    var list = state.transfers;

    if (f.fromDate != null) {
      list = list
          .where((t) =>
          t.assignedAt.isAfter(f.fromDate!.subtract(const Duration(days: 1))))
          .toList();
    }
    if (f.toDate != null) {
      final end = f.toDate!.add(const Duration(days: 1));
      list = list.where((t) => t.assignedAt.isBefore(end)).toList();
    }
    if (f.selectedStoreId != null) {
      list = list.where((t) => t.toStoreId == f.selectedStoreId).toList();
    }
    if (f.selectedStatus != null) {
      list = list.where((t) => t.status == f.selectedStatus).toList();
    }
    if (f.searchQuery.isNotEmpty) {
      final q = f.searchQuery.toLowerCase();
      list = list
          .where((t) =>
      t.transferNumber.toLowerCase().contains(q) ||
          t.toStoreName.toLowerCase().contains(q) ||
          (t.assignedByName?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    state = state.copyWith(filter: f, filteredTransfers: list);
  }

  void resetFilters() {
    state = state.copyWith(
      filter: const TransferReportFilter(),
      filteredTransfers: state.transfers,
    );
  }

  // ─── Detail Dialog ──────────────────────────────────────────────────────────

  Future<void> openTransferDetail(TransferReportItem transfer) async {
    state = state.copyWith(
      selectedTransfer: transfer,
      selectedItems: [],
      isLoadingDetail: true,
    );

    try {
      final result = await _db.execute(
        Sql.named('''
          SELECT
            id, product_id, product_name, sku, unit_of_measure,
            quantity_requested, quantity_sent,
            purchase_price, sale_price, wholesale_price,
            tax_amount, discount_amount, total_cost, category_id
          FROM public.stock_transfer_items
          WHERE transfer_id = @transferId
            AND deleted_at IS NULL
          ORDER BY product_name ASC
        '''),
        parameters: {'transferId': transfer.id},
      );

      final items = result
          .map((r) =>
          TransferDetailItem.fromMap(Map<String, dynamic>.from(r.toColumnMap())))
          .toList();

      state = state.copyWith(selectedItems: items, isLoadingDetail: false);
    } catch (e) {
      state = state.copyWith(
          isLoadingDetail: false, errorMessage: e.toString());
    }
  }

  void closeDetail() {
    state = state.copyWith(
      clearSelectedTransfer: true,
      selectedItems: [],
    );
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> refresh() => _loadTransfers();
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final transferReportProvider =
StateNotifierProvider<TransferReportNotifier, TransferReportState>((ref) {
  return TransferReportNotifier(
    AppConfig.warehouseId,
    DatabaseService.connection,
  );
});