import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/inventory_counting_datasource.dart';
import '../../data/model/inventory_counting_report_model.dart';

const _sentinel = Object();
const int _pageSize = 100;

// ─── State ───────────────────────────────────────────────────────────────────

class InventoryCountingReportState {
  final List<InventoryCountingRecord> records;
  final List<InventoryCountingRecord> filtered;
  final String                        searchQuery;
  final DateTime?                     startDate;
  final DateTime?                     endDate;
  final int                           currentPage; // 1-indexed
  final bool                          isLoading;
  final String?                       errorMessage;

  const InventoryCountingReportState({
    this.records     = const [],
    this.filtered    = const [],
    this.searchQuery = '',
    this.startDate,
    this.endDate,
    this.currentPage = 1,
    this.isLoading   = false,
    this.errorMessage,
  });

  int get totalPages =>
      filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();

  /// Current page ka data — hamesha 100 (ya kam, last page par) items
  List<InventoryCountingRecord> get paginated {
    if (filtered.isEmpty) return const [];
    final start = (currentPage - 1) * _pageSize;
    if (start >= filtered.length) return const [];
    final end = (start + _pageSize) > filtered.length ? filtered.length : start + _pageSize;
    return filtered.sublist(start, end);
  }

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPrevPage => currentPage > 1;

  InventoryCountingReportState copyWith({
    List<InventoryCountingRecord>? records,
    List<InventoryCountingRecord>? filtered,
    String?                        searchQuery,
    Object?                        startDate    = _sentinel,
    Object?                        endDate      = _sentinel,
    int?                           currentPage,
    bool?                          isLoading,
    Object?                        errorMessage = _sentinel,
  }) {
    return InventoryCountingReportState(
      records:      records     ?? this.records,
      filtered:     filtered    ?? this.filtered,
      searchQuery:  searchQuery ?? this.searchQuery,
      startDate:    startDate == _sentinel
          ? this.startDate
          : startDate as DateTime?,
      endDate:      endDate == _sentinel
          ? this.endDate
          : endDate as DateTime?,
      currentPage:  currentPage ?? this.currentPage,
      isLoading:    isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class InventoryCountingReportNotifier extends StateNotifier<InventoryCountingReportState> {
  final InventoryCountingReportRemoteDatasource _datasource;
  final String storeId;

  InventoryCountingReportNotifier({
    required InventoryCountingReportRemoteDatasource datasource,
    required this.storeId,
  })  : _datasource = datasource,
        super(const InventoryCountingReportState()) {
    loadReport();
  }

  Future<void> loadReport() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final records = await _datasource.fetchAllRecords(storeId: storeId);
      final filtered = _applyFilters(
        records,
        state.searchQuery,
        state.startDate,
        state.endDate,
      );
      state = state.copyWith(
        records:     records,
        filtered:    filtered,
        currentPage: 1, // fresh load par page 1 par reset
        isLoading:   false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void search(String q) {
    final filtered = _applyFilters(
      state.records,
      q,
      state.startDate,
      state.endDate,
    );
    state = state.copyWith(searchQuery: q, filtered: filtered, currentPage: 1);
  }

  /// Set start date (pass null to clear)
  void setStartDate(DateTime? date) {
    final filtered = _applyFilters(
      state.records,
      state.searchQuery,
      date,
      state.endDate,
    );
    state = state.copyWith(startDate: date, filtered: filtered, currentPage: 1);
  }

  /// Set end date (pass null to clear)
  void setEndDate(DateTime? date) {
    final filtered = _applyFilters(
      state.records,
      state.searchQuery,
      state.startDate,
      date,
    );
    state = state.copyWith(endDate: date, filtered: filtered, currentPage: 1);
  }

  /// Set both dates together (useful for range pickers)
  void setDateRange(DateTime? start, DateTime? end) {
    final filtered = _applyFilters(
      state.records,
      state.searchQuery,
      start,
      end,
    );
    state = state.copyWith(startDate: start, endDate: end, filtered: filtered, currentPage: 1);
  }

  void clearDateFilter() {
    final filtered = _applyFilters(
      state.records,
      state.searchQuery,
      null,
      null,
    );
    state = state.copyWith(startDate: null, endDate: null, filtered: filtered, currentPage: 1);
  }

  // ─── Pagination controls ────────────────────────────────────────────────

  void nextPage() {
    if (state.hasNextPage) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void prevPage() {
    if (state.hasPrevPage) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void goToPage(int page) {
    if (page < 1 || page > state.totalPages) return;
    state = state.copyWith(currentPage: page);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  List<InventoryCountingRecord> _applyFilters(
      List<InventoryCountingRecord> all,
      String    q,
      DateTime? start,
      DateTime? end,
      ) {
    var list = all;

    if (q.isNotEmpty) {
      final lower = q.toLowerCase();
      list = list.where((r) {
        final nameMatch = r.productName.toLowerCase().contains(lower);
        final barcodeMatch = r.barcodes.any((b) => b.toLowerCase().contains(lower));
        return nameMatch || barcodeMatch;
      }).toList();
    }

    if (start != null) {
      final s = DateTime(start.year, start.month, start.day);
      list = list.where((r) => !r.countedDate.isBefore(s)).toList();
    }

    if (end != null) {
      // include the whole end day
      final e = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      list = list.where((r) => !r.countedDate.isAfter(e)).toList();
    }

    return list;
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