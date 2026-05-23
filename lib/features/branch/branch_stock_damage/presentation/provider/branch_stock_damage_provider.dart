// lib/features/branch/branch_stock_damage/presentation/provider/branch_stock_damage_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';
import '../../data/datasource/branch_stock_damage_datascorce.dart';
import '../../data/model/branch_stock_damage_model.dart';

const int kDamagePageSize = 50;

class BranchStockDamageState {
  final List<BranchStockDamageModel> rows;
  final int     currentPage;
  final int     totalCount;
  final int     pageSize;
  final bool    isLoading;
  final bool    isMutating;
  final String  searchQuery;
  final String  filterStatus;
  final String? errorMessage;
  final String? successMessage;
  final int     totalRecords;
  final double  totalQtyDamaged;
  final double  totalLossValue;

  const BranchStockDamageState({
    this.rows            = const [],
    this.currentPage     = 0,
    this.totalCount      = 0,
    this.pageSize        = kDamagePageSize,
    this.isLoading       = false,
    this.isMutating      = false,
    this.searchQuery     = '',
    this.filterStatus    = 'all',
    this.errorMessage,
    this.successMessage,
    this.totalRecords    = 0,
    this.totalQtyDamaged = 0,
    this.totalLossValue  = 0,
  });

  int  get totalPages  => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();
  int  get displayPage => currentPage + 1;
  bool get hasPrev     => currentPage > 0;
  bool get hasNext     => currentPage < totalPages - 1;
  int  get fromRow     => totalCount == 0 ? 0 : currentPage * pageSize + 1;
  int  get toRow       => (fromRow + rows.length - 1).clamp(0, totalCount);

  BranchStockDamageState copyWith({
    List<BranchStockDamageModel>? rows,
    int?    currentPage,
    int?    totalCount,
    int?    pageSize,
    bool?   isLoading,
    bool?   isMutating,
    String? searchQuery,
    String? filterStatus,
    String? errorMessage,
    String? successMessage,
    int?    totalRecords,
    double? totalQtyDamaged,
    double? totalLossValue,
  }) => BranchStockDamageState(
    rows:            rows            ?? this.rows,
    currentPage:     currentPage     ?? this.currentPage,
    totalCount:      totalCount      ?? this.totalCount,
    pageSize:        pageSize        ?? this.pageSize,
    isLoading:       isLoading       ?? this.isLoading,
    isMutating:      isMutating      ?? this.isMutating,
    searchQuery:     searchQuery     ?? this.searchQuery,
    filterStatus:    filterStatus    ?? this.filterStatus,
    errorMessage:    errorMessage,
    successMessage:  successMessage,
    totalRecords:    totalRecords    ?? this.totalRecords,
    totalQtyDamaged: totalQtyDamaged ?? this.totalQtyDamaged,
    totalLossValue:  totalLossValue  ?? this.totalLossValue,
  );
}

class BranchStockDamageNotifier extends StateNotifier<BranchStockDamageState> {
  final BranchStockDamageDataSource _ds;
  final Ref _ref;
  Timer? _debounce;

  BranchStockDamageNotifier(this._ref)
      : _ds  = BranchStockDamageDataSource(),
        super(const BranchStockDamageState()) {
    _load();
  }

  String get _storeId => _ref.read(authProvider).storeId;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _ds.getPaginated(
          storeId:      _storeId,
          page:         state.currentPage,
          pageSize:     state.pageSize,
          search:       state.searchQuery,
          filterStatus: state.filterStatus,
        ),
        _ds.getStats(_storeId),
      ]);

      final paged = results[0] as ({List<BranchStockDamageModel> rows, int totalCount});
      final stats = results[1] as Map<String, dynamic>;

      state = state.copyWith(
        rows:            paged.rows,
        totalCount:      paged.totalCount,
        isLoading:       false,
        totalRecords:    stats['total_records']     as int,
        totalQtyDamaged: stats['total_qty_damaged'] as double,
        totalLossValue:  stats['total_loss_value']  as double,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void refresh() => _load();

  // ── ADD ───────────────────────────────────────────────────────
  Future<bool> addDamage({
    required String productId,
    required String productName,
    required double salePrice,
    required double purchasePrice,
    required double stockDamage,   // ✅ double
  }) async {
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      final record = await _ds.addDamage(
        storeId:       _storeId,
        productId:     productId,
        productName:   productName,
        salePrice:     salePrice,
        purchasePrice: purchasePrice,
        stockDamage:   stockDamage,
      );

      _ref.read(branchStockProvider.notifier).load();

      state = state.copyWith(
        rows:            [record, ...state.rows],
        totalCount:      state.totalCount + 1,
        totalRecords:    state.totalRecords + 1,
        totalQtyDamaged: state.totalQtyDamaged + stockDamage,
        totalLossValue:  state.totalLossValue + (purchasePrice * stockDamage),
        isMutating:      false,
        successMessage:  '$productName damage record add ho gaya',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: 'Error: $e');
      return false;
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────
  Future<bool> updateDamage({
    required BranchStockDamageModel original,
    required double                 newStockDamage,  // ✅ int → double
  }) async {
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      final updated = await _ds.updateDamage(
        id:             original.id,
        newStockDamage: newStockDamage,
      );

      _ref.read(branchStockProvider.notifier).load();

      final updatedRows = state.rows
          .map((r) => r.id == updated.id ? updated : r)
          .toList();

      state = state.copyWith(
        rows:           updatedRows,
        isMutating:     false,
        successMessage: '${updated.productName} updated successfully',
      );

      _reloadStats();
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: 'Update error: $e');
      return false;
    }
  }

  // ── DELETE ────────────────────────────────────────────────────
  Future<bool> deleteDamage(BranchStockDamageModel record) async {
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      await _ds.deleteDamage(record.id);

      _ref.read(branchStockProvider.notifier).load();

      state = state.copyWith(
        rows:            state.rows.where((r) => r.id != record.id).toList(),
        totalCount:      state.totalCount - 1,
        totalRecords:    state.totalRecords - 1,
        totalQtyDamaged: state.totalQtyDamaged - record.stockDamage,
        totalLossValue:  (state.totalLossValue - record.totalLoss).clamp(0, double.infinity),
        isMutating:      false,
        successMessage:  '${record.stockDamage} units stock restore ho gaya',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: 'Delete error: $e');
      return false;
    }
  }

  void nextPage()    { if (state.hasNext) { state = state.copyWith(currentPage: state.currentPage + 1); _load(); } }
  void prevPage()    { if (state.hasPrev) { state = state.copyWith(currentPage: state.currentPage - 1); _load(); } }
  void goToPage(int p) { if (p >= 0 && p < state.totalPages) { state = state.copyWith(currentPage: p); _load(); } }

  void onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(searchQuery: q, currentPage: 0);
      _load();
    });
  }

  void onFilterChanged(String f) {
    state = state.copyWith(filterStatus: f, currentPage: 0);
    _load();
  }

  void clearError()   => state = state.copyWith(errorMessage: null);
  void clearSuccess() => state = state.copyWith(successMessage: null);

  Future<void> _reloadStats() async {
    try {
      final stats = await _ds.getStats(_storeId);
      state = state.copyWith(
        totalRecords:    stats['total_records']     as int,
        totalQtyDamaged: stats['total_qty_damaged'] as double,
        totalLossValue:  stats['total_loss_value']  as double,
      );
    } catch (_) {}
  }

  @override
  void dispose() { _debounce?.cancel(); super.dispose(); }
}

final branchStockDamageProvider =
StateNotifierProvider.autoDispose<BranchStockDamageNotifier, BranchStockDamageState>(
      (ref) => BranchStockDamageNotifier(ref),
);