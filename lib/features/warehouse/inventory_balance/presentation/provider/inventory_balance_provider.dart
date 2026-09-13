// Updated on 2026-09-12 12:50 PM
// =============================================================
// inventory_balance_provider.dart
// Warehouse-side providers for Inventory Balance feature.
//
//   • pendingCountsProvider  — FutureProvider.family<String storeId>
//   • createBatchProvider    — StateNotifier for Create Batch UI
//   • balanceReportProvider  — StateNotifier for Report/History tab
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/provider/auth_provider.dart';

import '../../data/model/balance_batch_model.dart';
import '../../data/model/balance_item_model.dart';
import '../../data/repository/inventory_balance_repository.dart';
import '../../domain/balance_status.dart';
export '../../data/model/balance_batch_model.dart';

// ─────────────────────────────────────────────────────────────
// 1. Pending counts (per store) — Create Batch panel ke liye
// ─────────────────────────────────────────────────────────────
final pendingCountsProvider = FutureProvider.autoDispose
    .family<List<PendingCountRow>, String>((ref, storeId) async {
  return InventoryBalanceRepository.instance
      .fetchPendingCounts(storeId: storeId, daysBack: 7);
});

// ─────────────────────────────────────────────────────────────
// View filter + sort mode (client-side filter of pending counts)
// ─────────────────────────────────────────────────────────────
enum CreateViewFilter { all, redFlag, missing, extra }
enum CreateSortMode   { impactDesc, impactAsc, productName, recent }

// ─────────────────────────────────────────────────────────────
// 2. Create Batch — state
// ─────────────────────────────────────────────────────────────
class CreateBatchState {
  final String?              selectedStoreId;
  final Set<String>          selectedCountingIds;
  // countingId → user-entered DELTA (physical - system). Physical is treated
  // as branch's read-only evidence; warehouse decides the adjustment amount.
  // Removing an entry restores the row's original delta (physical - system).
  final Map<String, double>  overrides;
  final String               notes;
  final bool                 isSaving;
  final String?              errorMessage;
  final String?              successBatchNumber; // set on success (for snackbar)

  final CreateViewFilter     viewFilter;
  final CreateSortMode       sortMode;
  final String               searchQuery;

  const CreateBatchState({
    this.selectedStoreId,
    this.selectedCountingIds = const {},
    this.overrides           = const {},
    this.notes               = '',
    this.isSaving            = false,
    this.errorMessage,
    this.successBatchNumber,
    this.viewFilter          = CreateViewFilter.all,
    this.sortMode            = CreateSortMode.impactDesc,
    this.searchQuery         = '',
  });

  CreateBatchState copyWith({
    String?              selectedStoreId,
    Set<String>?         selectedCountingIds,
    Map<String, double>? overrides,
    String?              notes,
    bool?                isSaving,
    String?              errorMessage,
    String?              successBatchNumber,
    CreateViewFilter?    viewFilter,
    CreateSortMode?      sortMode,
    String?              searchQuery,
    bool                 clearError    = false,
    bool                 clearSuccess  = false,
    bool                 clearOverride = false,
    bool                 clearStore    = false,
  }) => CreateBatchState(
    selectedStoreId:     clearStore ? null : (selectedStoreId ?? this.selectedStoreId),
    selectedCountingIds: selectedCountingIds ?? this.selectedCountingIds,
    overrides:           clearOverride ? {} : (overrides ?? this.overrides),
    notes:               notes ?? this.notes,
    isSaving:            isSaving ?? this.isSaving,
    errorMessage:        clearError   ? null : (errorMessage ?? this.errorMessage),
    successBatchNumber:  clearSuccess ? null : (successBatchNumber ?? this.successBatchNumber),
    viewFilter:          viewFilter  ?? this.viewFilter,
    sortMode:            sortMode    ?? this.sortMode,
    searchQuery:         searchQuery ?? this.searchQuery,
  );
}

class CreateBatchNotifier extends StateNotifier<CreateBatchState> {
  final Ref _ref;
  CreateBatchNotifier(this._ref) : super(const CreateBatchState());

  void selectStore(String storeId) {
    // Store change → selection + overrides reset.
    state = CreateBatchState(selectedStoreId: storeId);
  }

  void toggleItem(String countingId, bool selected) {
    final s = {...state.selectedCountingIds};
    if (selected) {
      s.add(countingId);
    } else {
      s.remove(countingId);
    }
    state = state.copyWith(selectedCountingIds: s);
  }

  void toggleAll(Iterable<String> countingIds, bool selectAll) {
    if (selectAll) {
      state = state.copyWith(selectedCountingIds: countingIds.toSet());
    } else {
      state = state.copyWith(selectedCountingIds: {});
    }
  }

  /// [delta] null = original delta (physical - system) restore ho jayega.
  /// Delta free-range hai — negative bhi ho sakta hai.
  void setOverride(String countingId, double? delta) {
    final map = {...state.overrides};
    if (delta == null) {
      map.remove(countingId);
    } else {
      map[countingId] = delta;
    }
    state = state.copyWith(overrides: map);
  }

  void setNotes(String v) => state = state.copyWith(notes: v);

  void setViewFilter(CreateViewFilter f) =>
      state = state.copyWith(viewFilter: f);

  void setSortMode(CreateSortMode m) =>
      state = state.copyWith(sortMode: m);

  void setSearchQuery(String q) =>
      state = state.copyWith(searchQuery: q);

  Future<bool> submit(List<PendingCountRow> allRows) async {
    if (state.isSaving) return false;
    if (state.selectedStoreId == null) {
      state = state.copyWith(errorMessage: 'Store select karein');
      return false;
    }
    if (state.selectedCountingIds.isEmpty) {
      state = state.copyWith(errorMessage: 'Kam se kam ek item select karein');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      final user = _ref.read(authProvider).user;
      final picked = allRows
          .where((r) => state.selectedCountingIds.contains(r.countingId))
          .toList();

      final items = picked.map((r) {
        // Delta — warehouse ka adjustment amount. Override na ho to row ka
        // original delta (physical - system).
        // Physical stock IMMUTABLE hai — branch ne jo gina wahi record hoga.
        final delta    = state.overrides[r.countingId] ?? (r.physicalStock - r.systemStock);
        final physical = r.physicalStock;
        return BalanceItemModel(
          id:                 '', // datasource generate karega
          batchId:            '', // datasource set karega
          warehouseId:        '', // datasource _wid use karega
          storeId:            state.selectedStoreId!,
          productId:          r.productId,
          productName:        r.productName,
          productSku:         r.productSku,
          countingId:         r.countingId,
          systemStockAtCount: r.systemStock,
          physicalStock:      physical,
          delta:              delta,
          unitPrice:          r.unitPrice,
          isHighVariance:     isHighVariance(delta, r.unitPrice),
          status:             BalanceStatus.reviewPending,
          createdAt:          DateTime.now(),
        );
      }).toList();

      final batch = await InventoryBalanceRepository.instance.createBatch(
        storeId:       state.selectedStoreId!,
        items:         items,
        notes:         state.notes.trim().isEmpty ? null : state.notes.trim(),
        createdBy:     user?.id,
        createdByName: user?.fullName,
      );

      state = CreateBatchState(successBatchNumber: batch.batchNumber);
      // Consumed IDs invalidate — pending list refresh ho jaye.
      _ref.invalidate(pendingCountsProvider(state.selectedStoreId ?? ''));
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Save nahi hui: $e',
      );
      return false;
    }
  }

  void ackSuccess() => state = state.copyWith(clearSuccess: true);
  void ackError()   => state = state.copyWith(clearError:   true);
}

final createBatchProvider =
    StateNotifierProvider.autoDispose<CreateBatchNotifier, CreateBatchState>(
        (ref) => CreateBatchNotifier(ref));

// ─────────────────────────────────────────────────────────────
// 3. Balance Report (history + status) — cloud-first read
// ─────────────────────────────────────────────────────────────
enum ReportDateMode { last7, last30, custom }

class BalanceReportState {
  final bool                    isLoading;
  final String?                 errorMessage;
  final List<BalanceItemModel>  items;
  final Map<String, BalanceBatchModel> batchesById;
  final String                  searchQuery;
  final ReportDateMode          dateMode;
  final DateTime?               fromDate;
  final DateTime?               toDate;
  final BalanceStatus?          statusFilter;
  final String?                 storeFilter;

  const BalanceReportState({
    this.isLoading    = false,
    this.errorMessage,
    this.items        = const [],
    this.batchesById  = const {},
    this.searchQuery  = '',
    this.dateMode     = ReportDateMode.last30,
    this.fromDate,
    this.toDate,
    this.statusFilter,
    this.storeFilter,
  });

  BalanceReportState copyWith({
    bool?                    isLoading,
    String?                  errorMessage,
    List<BalanceItemModel>?  items,
    Map<String, BalanceBatchModel>? batchesById,
    String?                  searchQuery,
    ReportDateMode?          dateMode,
    DateTime?                fromDate,
    DateTime?                toDate,
    BalanceStatus?           statusFilter,
    String?                  storeFilter,
    bool                     clearError  = false,
    bool                     clearStatus = false,
    bool                     clearStore  = false,
  }) => BalanceReportState(
    isLoading:    isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    items:        items     ?? this.items,
    batchesById:  batchesById ?? this.batchesById,
    searchQuery:  searchQuery ?? this.searchQuery,
    dateMode:     dateMode  ?? this.dateMode,
    fromDate:     fromDate  ?? this.fromDate,
    toDate:       toDate    ?? this.toDate,
    statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
    storeFilter:  clearStore  ? null : (storeFilter  ?? this.storeFilter),
  );
}

class BalanceReportNotifier extends StateNotifier<BalanceReportState> {
  BalanceReportNotifier() : super(_initialState()) {
    load();
  }

  static BalanceReportState _initialState() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return BalanceReportState(
      fromDate: today.subtract(const Duration(days: 29)),
      toDate:   today,
    );
  }

  DateTime? get _toExclusive =>
      state.toDate == null ? null : state.toDate!.add(const Duration(days: 1));

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await InventoryBalanceRepository.instance
          .fetchItemsFromCloud(
            fromDate: state.fromDate,
            toDate:   _toExclusive,
            status:   state.statusFilter,
            storeId:  state.storeFilter,
          );
      final batchIds = items.map((i) => i.batchId).toSet();
      final batches = await InventoryBalanceRepository.instance
          .fetchBatchesByIds(batchIds);
      final byId = {for (final b in batches) b.id: b};
      state = state.copyWith(
        isLoading: false, items: items, batchesById: byId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Cloud se load nahi hui: $e',
      );
    }
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  void setDateMode(ReportDateMode m) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime from = state.fromDate ?? today;
    DateTime to   = state.toDate   ?? today;
    switch (m) {
      case ReportDateMode.last7:
        from = today.subtract(const Duration(days: 6));
        to   = today;
        break;
      case ReportDateMode.last30:
        from = today.subtract(const Duration(days: 29));
        to   = today;
        break;
      case ReportDateMode.custom:
        break; // caller `setCustomRange` bhejta
    }
    state = state.copyWith(dateMode: m, fromDate: from, toDate: to);
    load();
  }

  void setCustomRange(DateTime from, DateTime to) {
    state = state.copyWith(
      dateMode: ReportDateMode.custom,
      fromDate: from,
      toDate:   to,
    );
    load();
  }

  void setStatus(BalanceStatus? status) {
    state = status == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(statusFilter: status);
    load();
  }

  void setStore(String? storeId) {
    state = storeId == null
        ? state.copyWith(clearStore: true)
        : state.copyWith(storeFilter: storeId);
    load();
  }

  Future<void> refresh() => load();
}

final balanceReportProvider =
    StateNotifierProvider.autoDispose<BalanceReportNotifier, BalanceReportState>(
        (ref) => BalanceReportNotifier());
