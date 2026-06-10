// =============================================================
// linked_store_inventory_provider.dart
// Per-store inventory state — pagination, filter, search.
// =============================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/inventory/data/datasources/linked_store_inventory_remote_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/inventory/data/models/linked_store_product_model.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class LinkedStoreInventoryState {
  final bool isLoading;       // initial / filter reload
  final bool isLoadingMore;   // pagination append
  final String? error;
  final List<LinkedStoreProduct> products;
  final String status;        // all | ok | low | out
  final String search;
  final int allCount;
  final int lowCount;
  final int outCount;
  final bool hasMore;
  final int offset;

  const LinkedStoreInventoryState({
    this.isLoading     = true,
    this.isLoadingMore = false,
    this.error,
    this.products      = const [],
    this.status        = 'all',
    this.search        = '',
    this.allCount      = 0,
    this.lowCount      = 0,
    this.outCount      = 0,
    this.hasMore       = true,
    this.offset        = 0,
  });

  int get inStockCount => (allCount - lowCount - outCount).clamp(0, allCount);

  LinkedStoreInventoryState copyWith({
    bool?    isLoading,
    bool?    isLoadingMore,
    String?  error,
    List<LinkedStoreProduct>? products,
    String?  status,
    String?  search,
    int?     allCount,
    int?     lowCount,
    int?     outCount,
    bool?    hasMore,
    int?     offset,
    bool     clearError = false,
  }) {
    return LinkedStoreInventoryState(
      isLoading:     isLoading     ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error:         clearError    ? null : error ?? this.error,
      products:      products      ?? this.products,
      status:        status        ?? this.status,
      search:        search        ?? this.search,
      allCount:      allCount      ?? this.allCount,
      lowCount:      lowCount      ?? this.lowCount,
      outCount:      outCount      ?? this.outCount,
      hasMore:       hasMore       ?? this.hasMore,
      offset:        offset        ?? this.offset,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class LinkedStoreInventoryNotifier extends StateNotifier<LinkedStoreInventoryState> {
  final LinkedStoreInventoryRemoteDatasource _ds;
  final String storeId;

  static const int pageSize = 50;
  Timer? _debounce;

  LinkedStoreInventoryNotifier(this._ds, this.storeId)
      : super(const LinkedStoreInventoryState()) {
    load();
  }

  // First page + counts (filter/search change pe bhi yahi)
  Future<void> load() async {
    state = state.copyWith(
      isLoading: true, clearError: true, products: const [], offset: 0, hasMore: true,
    );
    try {
      final results = await Future.wait([
        _ds.fetchPage(
          storeId: storeId, status: state.status, search: state.search,
          offset: 0, limit: pageSize,
        ),
        _ds.counts(storeId: storeId, search: state.search),
      ]);

      final page = results[0] as List<LinkedStoreProduct>;
      final cnt  = results[1] as ({int all, int low, int out});

      state = state.copyWith(
        isLoading: false,
        products:  page,
        offset:    page.length,
        hasMore:   page.length == pageSize,
        allCount:  cnt.all,
        lowCount:  cnt.low,
        outCount:  cnt.out,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Agla page append (infinite scroll)
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _ds.fetchPage(
        storeId: storeId, status: state.status, search: state.search,
        offset: state.offset, limit: pageSize,
      );
      state = state.copyWith(
        isLoadingMore: false,
        products:      [...state.products, ...page],
        offset:        state.offset + page.length,
        hasMore:       page.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void setStatus(String s) {
    if (s == state.status) return;
    state = state.copyWith(status: s);
    load();
  }

  void setSearch(String q) {
    state = state.copyWith(search: q);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), load);
  }

  Future<void> refresh() => load();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDER (per storeId, auto-dispose for memory)
// ─────────────────────────────────────────────────────────────

final linkedStoreInventoryProvider = StateNotifierProvider.autoDispose
    .family<LinkedStoreInventoryNotifier, LinkedStoreInventoryState, String>(
  (ref, storeId) {
    return LinkedStoreInventoryNotifier(
      LinkedStoreInventoryRemoteDatasource(supabase: Supabase.instance.client),
      storeId,
    );
  },
);
