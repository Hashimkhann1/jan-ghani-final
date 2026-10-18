import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/inventory_counting_datasource.dart';
import '../../data/model/inventory_counting_report_model.dart';

const _sentinel = Object();
const int _pageSize = InventoryCountingReportRemoteDatasource.pageSize;

// ─── State ───────────────────────────────────────────────────────────────────

class InventoryCountingReportState {
  /// Sirf current page ki rows (server-side pagination).
  final List<InventoryCountingRecord> records;
  final int                           totalCount;
  final int                           surplusCount;
  final int                           shortageCount;
  final int                           matchedCount;
  final String                        searchQuery;
  final DateTime?                     startDate;
  final DateTime?                     endDate;
  final int                           currentPage; // 1-indexed
  final bool                          isLoading;
  final String?                       errorMessage;

  const InventoryCountingReportState({
    this.records       = const [],
    this.totalCount    = 0,
    this.surplusCount  = 0,
    this.shortageCount = 0,
    this.matchedCount  = 0,
    this.searchQuery   = '',
    this.startDate,
    this.endDate,
    this.currentPage   = 1,
    this.isLoading     = false,
    this.errorMessage,
  });

  int get pageSize   => _pageSize;
  int get totalPages => totalCount == 0 ? 1 : (totalCount / _pageSize).ceil();

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPrevPage => currentPage > 1;

  InventoryCountingReportState copyWith({
    List<InventoryCountingRecord>? records,
    int?                           totalCount,
    int?                           surplusCount,
    int?                           shortageCount,
    int?                           matchedCount,
    String?                        searchQuery,
    Object?                        startDate    = _sentinel,
    Object?                        endDate      = _sentinel,
    int?                           currentPage,
    bool?                          isLoading,
    Object?                        errorMessage = _sentinel,
  }) {
    return InventoryCountingReportState(
      records:       records       ?? this.records,
      totalCount:    totalCount    ?? this.totalCount,
      surplusCount:  surplusCount  ?? this.surplusCount,
      shortageCount: shortageCount ?? this.shortageCount,
      matchedCount:  matchedCount  ?? this.matchedCount,
      searchQuery:   searchQuery   ?? this.searchQuery,
      startDate:     startDate == _sentinel
          ? this.startDate
          : startDate as DateTime?,
      endDate:       endDate == _sentinel
          ? this.endDate
          : endDate as DateTime?,
      currentPage:   currentPage   ?? this.currentPage,
      isLoading:     isLoading     ?? this.isLoading,
      errorMessage:  errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class InventoryCountingReportNotifier extends StateNotifier<InventoryCountingReportState> {
  final InventoryCountingReportRemoteDatasource _datasource;
  final String storeId;

  Timer? _searchDebounce;
  // Purane (late) response ko ignore karne ke liye.
  int _requestId = 0;

  InventoryCountingReportNotifier({
    required InventoryCountingReportRemoteDatasource datasource,
    required this.storeId,
  })  : _datasource = datasource,
        super(const InventoryCountingReportState()) {
    loadReport();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// [page] 1-indexed. Filters state se aate hain.
  Future<void> _load(int page) async {
    final id = ++_requestId;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _datasource.fetchPage(
        storeId: storeId,
        page:    page - 1,
        from:    state.startDate,
        to:      state.endDate,
        search:  state.searchQuery,
      );
      if (id != _requestId || !mounted) return;
      state = state.copyWith(
        records:       result.records,
        totalCount:    result.totalCount,
        surplusCount:  result.surplusCount,
        shortageCount: result.shortageCount,
        matchedCount:  result.matchedCount,
        currentPage:   page,
        isLoading:     false,
      );
    } catch (e) {
      if (id != _requestId || !mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadReport() => _load(1);

  /// Poora filtered data (export ke liye) — screen par load nahi hota.
  Future<List<InventoryCountingRecord>> fetchAllForExport() =>
      _datasource.fetchAll(
        storeId: storeId,
        from:    state.startDate,
        to:      state.endDate,
        search:  state.searchQuery,
      );

  /// Har keystroke par nahi — typing ruknay ke 400ms baad server se.
  void search(String q) {
    state = state.copyWith(searchQuery: q);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _load(1));
  }

  /// Set start date (pass null to clear)
  void setStartDate(DateTime? date) {
    state = state.copyWith(startDate: date);
    _load(1);
  }

  /// Set end date (pass null to clear)
  void setEndDate(DateTime? date) {
    state = state.copyWith(endDate: date);
    _load(1);
  }

  /// Set both dates together (useful for range pickers)
  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
    _load(1);
  }

  void clearDateFilter() {
    state = state.copyWith(startDate: null, endDate: null);
    _load(1);
  }

  // ─── Pagination controls ────────────────────────────────────────────────

  void nextPage() {
    if (state.hasNextPage && !state.isLoading) _load(state.currentPage + 1);
  }

  void prevPage() {
    if (state.hasPrevPage && !state.isLoading) _load(state.currentPage - 1);
  }

  void goToPage(int page) {
    if (page < 1 || page > state.totalPages || state.isLoading) return;
    _load(page);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final inventoryCountingReportProvider = StateNotifierProvider.autoDispose
    .family<InventoryCountingReportNotifier, InventoryCountingReportState, String>(
      (ref, storeId) => InventoryCountingReportNotifier(
    datasource: InventoryCountingReportRemoteDatasource(),
    storeId: storeId,
  ),
);
