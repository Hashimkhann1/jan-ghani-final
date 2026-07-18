import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/inventory_counting_datasource.dart';
import '../../data/model/inventory_counting_report_model.dart';

const _sentinel = Object();

// ─── State ───────────────────────────────────────────────────────────────────

class InventoryCountingReportState {
  final List<InventoryCountingRecord> records;
  final List<InventoryCountingRecord> filtered;
  final String                        searchQuery;
  final DateTime?                     startDate;
  final DateTime?                     endDate;
  final bool                          isLoading;
  final String?                       errorMessage;

  const InventoryCountingReportState({
    this.records     = const [],
    this.filtered    = const [],
    this.searchQuery = '',
    this.startDate,
    this.endDate,
    this.isLoading   = false,
    this.errorMessage,
  });

  InventoryCountingReportState copyWith({
    List<InventoryCountingRecord>? records,
    List<InventoryCountingRecord>? filtered,
    String?                        searchQuery,
    Object?                        startDate    = _sentinel,
    Object?                        endDate      = _sentinel,
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
        records:   records,
        filtered:  filtered,
        isLoading: false,
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
    state = state.copyWith(searchQuery: q, filtered: filtered);
  }

  /// Set start date (pass null to clear)
  void setStartDate(DateTime? date) {
    final filtered = _applyFilters(
      state.records,
      state.searchQuery,
      date,
      state.endDate,
    );
    state = state.copyWith(startDate: date, filtered: filtered);
  }

  /// Set end date (pass null to clear)
  void setEndDate(DateTime? date) {
    final filtered = _applyFilters(
      state.records,
      state.searchQuery,
      state.startDate,
      date,
    );
    state = state.copyWith(endDate: date, filtered: filtered);
  }

  /// Set both dates together (useful for range pickers)
  void setDateRange(DateTime? start, DateTime? end) {
    final filtered = _applyFilters(
      state.records,
      state.searchQuery,
      start,
      end,
    );
    state = state.copyWith(startDate: start, endDate: end, filtered: filtered);
  }

  void clearDateFilter() {
    final filtered = _applyFilters(
      state.records,
      state.searchQuery,
      null,
      null,
    );
    state = state.copyWith(startDate: null, endDate: null, filtered: filtered);
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
