// =============================================================
// inventory_review_provider.dart
// Reviewer's providers:
//   • reviewQueueProvider   — StateNotifier for pending items (Tab 1)
//   • reviewHistoryProvider — StateNotifier for history (Tab 2)
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/providers/accoutant_session_provider.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_batch_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_item_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/domain/balance_status.dart';

import '../../data/repository/inventory_review_repository.dart';

// ─────────────────────────────────────────────────────────────
// 1. REVIEW QUEUE (pending items → grouped by batch)
// ─────────────────────────────────────────────────────────────
class ReviewQueueState {
  final bool                    isLoading;
  final String?                 errorMessage;
  final List<BalanceItemModel>  items;
  final Map<String, BalanceBatchModel> batchById;
  final Set<String>             actingItemIds; // ongoing per-item action (accept/reject spinner)

  const ReviewQueueState({
    this.isLoading    = false,
    this.errorMessage,
    this.items        = const [],
    this.batchById    = const {},
    this.actingItemIds = const {},
  });

  ReviewQueueState copyWith({
    bool?                    isLoading,
    String?                  errorMessage,
    List<BalanceItemModel>?  items,
    Map<String, BalanceBatchModel>? batchById,
    Set<String>?             actingItemIds,
    bool                     clearError = false,
  }) => ReviewQueueState(
    isLoading:    isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    items:        items ?? this.items,
    batchById:    batchById ?? this.batchById,
    actingItemIds: actingItemIds ?? this.actingItemIds,
  );
}

class ReviewQueueNotifier extends StateNotifier<ReviewQueueState> {
  final Ref _ref;
  ReviewQueueNotifier(this._ref) : super(const ReviewQueueState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await InventoryReviewRepository.instance.getPendingItems();
      final batchIds = items.map((i) => i.batchId).toSet();
      final batches = await InventoryReviewRepository.instance
          .getBatchesByIds(batchIds);
      final byId = {for (final b in batches) b.id: b};
      state = state.copyWith(
        isLoading: false, items: items, batchById: byId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load nahi hui: $e');
    }
  }

  Future<void> refresh() => load();

  Future<bool> acceptItem(BalanceItemModel item) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(errorMessage: 'User session mojood nahi');
      return false;
    }
    return _doAction(item, () async {
      await InventoryReviewRepository.instance.accept(
        itemId:       item.id,
        batchId:      item.batchId,
        reviewerId:   user.id,
        reviewerName: user.fullName,
      );
    });
  }

  Future<bool> rejectItem(BalanceItemModel item, String reason) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(errorMessage: 'User session mojood nahi');
      return false;
    }
    if (reason.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Reject reason lazmi');
      return false;
    }
    return _doAction(item, () async {
      await InventoryReviewRepository.instance.reject(
        itemId:       item.id,
        batchId:      item.batchId,
        reason:       reason.trim(),
        reviewerId:   user.id,
        reviewerName: user.fullName,
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
      // Remove from local list (action complete)
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

final reviewQueueProvider = StateNotifierProvider.autoDispose<
    ReviewQueueNotifier, ReviewQueueState>(
  (ref) => ReviewQueueNotifier(ref),
);

// ─────────────────────────────────────────────────────────────
// 2. HISTORY / REPORT
// ─────────────────────────────────────────────────────────────
class ReviewHistoryState {
  final bool                    isLoading;
  final String?                 errorMessage;
  final List<BalanceItemModel>  items;
  final DateTime?               fromDate;
  final DateTime?               toDate;
  final BalanceStatus?          statusFilter;

  const ReviewHistoryState({
    this.isLoading = false,
    this.errorMessage,
    this.items = const [],
    this.fromDate,
    this.toDate,
    this.statusFilter,
  });

  ReviewHistoryState copyWith({
    bool?                   isLoading,
    String?                 errorMessage,
    List<BalanceItemModel>? items,
    DateTime?               fromDate,
    DateTime?               toDate,
    BalanceStatus?          statusFilter,
    bool                    clearError  = false,
    bool                    clearStatus = false,
  }) => ReviewHistoryState(
    isLoading:    isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    items:        items ?? this.items,
    fromDate:     fromDate ?? this.fromDate,
    toDate:       toDate ?? this.toDate,
    statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
  );
}

class ReviewHistoryNotifier extends StateNotifier<ReviewHistoryState> {
  ReviewHistoryNotifier() : super(_initial()) {
    load();
  }

  static ReviewHistoryState _initial() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return ReviewHistoryState(
      fromDate: today.subtract(const Duration(days: 29)),
      toDate:   today,
    );
  }

  DateTime? get _toExclusive =>
      state.toDate == null ? null : state.toDate!.add(const Duration(days: 1));

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await InventoryReviewRepository.instance.getItems(
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

final reviewHistoryProvider = StateNotifierProvider.autoDispose<
    ReviewHistoryNotifier, ReviewHistoryState>(
  (ref) => ReviewHistoryNotifier(),
);
