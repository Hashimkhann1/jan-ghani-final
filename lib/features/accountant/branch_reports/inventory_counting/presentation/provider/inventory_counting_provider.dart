import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/inventory_counting_datasource.dart';
import '../../data/model/inventory_counting_report_model.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class InventoryCountingReportState {
  final List<InventoryCountingRecord> records;
  final bool isLoading;
  final String? errorMessage;

  const InventoryCountingReportState({
    this.records = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  InventoryCountingReportState copyWith({
    List<InventoryCountingRecord>? records,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InventoryCountingReportState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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
      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
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