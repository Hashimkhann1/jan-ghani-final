// =============================================================
// branch_inventory_balance_provider.dart
// Branch's providers:
//   • branchBalanceQueueProvider   — StateNotifier for
//     branch_pending items (Tab 1 — accept applies live stock)
//   • branchBalanceHistoryProvider — history (Tab 2)
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_batch_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_item_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/domain/balance_status.dart';

import '../../data/repository/branch_inventory_balance_repository.dart';

// ─────────────────────────────────────────────────────────────
// 1. BALANCE QUEUE (branch_pending items → grouped by batch)
// ─────────────────────────────────────────────────────────────
class BranchBalanceQueueState {
  final bool                    isLoading;
  final String?                 errorMessage;
  final List<BalanceItemModel>  items;
  final Map<String, BalanceBatchModel> batchById;
  final Set<String>             actingItemIds; // ongoing per-item action

  const BranchBalanceQueueState({
    this.isLoading     = false,
    this.errorMessage,
    this.items         = const [],
    this.batchById     = const {},
    this.actingItemIds = const {},
  });

  BranchBalanceQueueState copyWith({
    bool?                    isLoading,
    String?                  errorMessage,
    List<BalanceItemModel>?  items,
    Map<String, BalanceBatchModel>? batchById,
    Set<String>?             actingItemIds,
    bool                     clearError = false,
  }) => BranchBalanceQueueState(
    isLoading:     isLoading ?? this.isLoading,
    errorMessage:  clearError ? null : (errorMessage ?? this.errorMessage),
    items:         items ?? this.items,
    batchById:     batchById ?? this.batchById,
    actingItemIds: actingItemIds ?? this.actingItemIds,
  );
}

class BranchBalanceQueueNotifier extends StateNotifier<BranchBalanceQueueState> {
  final Ref _ref;
  BranchBalanceQueueNotifier(this._ref) : super(const BranchBalanceQueueState()) {
    load();
  }

  Future<void> load() async {
    final storeId = _ref.read(authProvider).storeId;
    if (storeId.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await BranchInventoryBalanceRepository.instance
          .getPendingItems(storeId);
      final batchIds = items.map((i) => i.batchId).toSet();
      final batches = await BranchInventoryBalanceRepository.instance
          .getBatchesByIds(batchIds);
      final byId = {for (final b in batches) b.id: b};
      state = state.copyWith(isLoading: false, items: items, batchById: byId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load nahi hui: $e');
    }
  }

  Future<void> refresh() => load();

  Future<bool> acceptItem(BalanceItemModel item) async {
    final auth = _ref.read(authProvider);
    if (auth.userId.isEmpty) {
      state = state.copyWith(errorMessage: 'User session mojood nahi');
      return false;
    }
    return _doAction(item, () async {
      await BranchInventoryBalanceRepository.instance.acceptAndApply(
        itemId:         item.id,
        branchUserId:   auth.userId,
        branchUserName: auth.fullName,
      );
    });
  }

  Future<bool> rejectItem(BalanceItemModel item, String reason) async {
    final auth = _ref.read(authProvider);
    if (auth.userId.isEmpty) {
      state = state.copyWith(errorMessage: 'User session mojood nahi');
      return false;
    }
    if (reason.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Reject reason lazmi');
      return false;
    }
    return _doAction(item, () async {
      await BranchInventoryBalanceRepository.instance.reject(
        itemId:         item.id,
        batchId:        item.batchId,
        reason:         reason.trim(),
        branchUserId:   auth.userId,
        branchUserName: auth.fullName,
      );
    });
  }

  Future<bool> _doAction(
      BalanceItemModel item, Future<void> Function() fn) async {
    if (state.actingItemIds.contains(item.id)) return false;
    final acting = {...state.actingItemIds, item.id};
    state = state.copyWith(actingItemIds: acting, clearError: true);
    try {
      await fn();
      final remaining = state.items.where((i) => i.id != item.id).toList();
      final done = {...state.actingItemIds}..remove(item.id);
      state = state.copyWith(items: remaining, actingItemIds: done);
      return true;
    } catch (e) {
      final done = {...state.actingItemIds}..remove(item.id);
      state = state.copyWith(
        actingItemIds: done,
        errorMessage: 'Action fail: $e',
      );
      return false;
    }
  }
}

final branchBalanceQueueProvider = StateNotifierProvider.autoDispose<
    BranchBalanceQueueNotifier, BranchBalanceQueueState>(
  (ref) => BranchBalanceQueueNotifier(ref),
);

// ─────────────────────────────────────────────────────────────
// 2. HISTORY / REPORT
// ─────────────────────────────────────────────────────────────
class BranchBalanceHistoryState {
  final bool                    isLoading;
  final String?                 errorMessage;
  final List<BalanceItemModel>  items;
  final DateTime?               fromDate;
  final DateTime?               toDate;
  final BalanceStatus?          statusFilter;

  const BranchBalanceHistoryState({
    this.isLoading = false,
    this.errorMessage,
    this.items     = const [],
    this.fromDate,
    this.toDate,
    this.statusFilter,
  });

  BranchBalanceHistoryState copyWith({
    bool?                   isLoading,
    String?                 errorMessage,
    List<BalanceItemModel>? items,
    DateTime?               fromDate,
    DateTime?               toDate,
    BalanceStatus?          statusFilter,
    bool                    clearError  = false,
    bool                    clearStatus = false,
  }) => BranchBalanceHistoryState(
    isLoading:    isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    items:        items ?? this.items,
    fromDate:     fromDate ?? this.fromDate,
    toDate:       toDate ?? this.toDate,
    statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
  );
}

class BranchBalanceHistoryNotifier extends StateNotifier<BranchBalanceHistoryState> {
  final Ref _ref;
  BranchBalanceHistoryNotifier(this._ref) : super(_initial()) {
    load();
  }

  static BranchBalanceHistoryState _initial() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return BranchBalanceHistoryState(
      fromDate: today.subtract(const Duration(days: 29)),
      toDate:   today,
    );
  }

  DateTime? get _toExclusive =>
      state.toDate == null ? null : state.toDate!.add(const Duration(days: 1));

  Future<void> load() async {
    final storeId = _ref.read(authProvider).storeId;
    if (storeId.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await BranchInventoryBalanceRepository.instance.getItems(
        storeId:  storeId,
        fromDate: state.fromDate,
        toDate:   _toExclusive,
        status:   state.statusFilter,
      );
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load nahi hui: $e');
    }
  }

  void setDateRange(DateTime from, DateTime to) {
    state = state.copyWith(fromDate: from, toDate: to);
    load();
  }

  void setStatus(BalanceStatus? status) {
    state = status == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(statusFilter: status);
    load();
  }

  Future<void> refresh() => load();
}

final branchBalanceHistoryProvider = StateNotifierProvider.autoDispose<
    BranchBalanceHistoryNotifier, BranchBalanceHistoryState>(
  (ref) => BranchBalanceHistoryNotifier(ref),
);
