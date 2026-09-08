import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';
import '../../data/datasource/stock_transfer_remote_datasource.dart';
import '../../data/model/stock_transfer_model.dart';

const kTransferPageSize = 20;

// DataSource provider
final stockTransferDataSourceProvider = Provider((ref) {
  return StockTransferRemoteDataSource(Supabase.instance.client);
});

// ✅ BUG 6 FIX: storeId already non-nullable String — ?? '' removed
final currentStoreIdProvider = Provider<String>((ref) {
  return ref.watch(authProvider).storeId;
});

/// Server-side paged view of one store's transfers.
///  - `rows`  : sirf `status` tab ke, sirf `page` ke transfers.
///  - `agg`   : har status ka count + totals (tab badges + summary bar).
class TransferPageData {
  final String status;   // current tab: pending | accepted | rejected
  final int    page;     // 0-based
  final List<StockTransfer>           rows;
  final Map<String, TransferStatusAgg> agg;

  const TransferPageData({
    this.status = 'pending',
    this.page   = 0,
    this.rows   = const [],
    this.agg    = const {},
  });

  TransferStatusAgg aggFor(String s) =>
      agg[s] ?? const TransferStatusAgg();

  int get total     => aggFor(status).count;
  int get pageCount =>
      total == 0 ? 1 : ((total + kTransferPageSize - 1) ~/ kTransferPageSize);

  TransferPageData copyWith({
    String? status,
    int?    page,
    List<StockTransfer>? rows,
    Map<String, TransferStatusAgg>? agg,
  }) =>
      TransferPageData(
        status: status ?? this.status,
        page:   page   ?? this.page,
        rows:   rows   ?? this.rows,
        agg:    agg    ?? this.agg,
      );
}

// Transfers provider — AsyncNotifier
final stockTransferProvider =
    AsyncNotifierProvider<StockTransferNotifier, TransferPageData>(
  StockTransferNotifier.new,
);

class StockTransferNotifier extends AsyncNotifier<TransferPageData> {
  late StockTransferRemoteDataSource _dataSource;
  late String _storeId;

  // Single-flight guard: same transfer par ek waqt mein sirf ek
  // accept/reject in-flight ho sakta hai (double-tap / retry-while-loading
  // se double stock-credit na ho).
  final Set<String> _inFlightIds = {};

  @override
  Future<TransferPageData> build() async {
    _dataSource = ref.read(stockTransferDataSourceProvider);
    _storeId    = ref.watch(currentStoreIdProvider);

    if (_storeId.isEmpty) {
      return const TransferPageData(agg: {});
    }
    return _load(status: 'pending', page: 0);
  }

  /// Aggregates + ek status/page ke rows dono fetch karke state banao.
  Future<TransferPageData> _load({
    required String status,
    required int page,
  }) async {
    final results = await Future.wait([
      _dataSource.fetchStatusAggregates(_storeId),
      _dataSource.fetchTransfersPage(
        _storeId,
        status: status,
        offset: page * kTransferPageSize,
        limit:  kTransferPageSize,
      ),
    ]);

    final agg  = results[0] as Map<String, TransferStatusAgg>;
    var   rows = results[1] as List<StockTransfer>;

    // Page range se bahar (delete/accept ke baad) — pichle valid page par.
    final total   = (agg[status]?.count ?? 0);
    final maxPage =
        total == 0 ? 0 : (total - 1) ~/ kTransferPageSize;
    if (page > maxPage) {
      rows = await _dataSource.fetchTransfersPage(
        _storeId,
        status: status,
        offset: maxPage * kTransferPageSize,
        limit:  kTransferPageSize,
      );
      return TransferPageData(
          status: status, page: maxPage, rows: rows, agg: agg);
    }

    return TransferPageData(
        status: status, page: page, rows: rows, agg: agg);
  }

  Future<void> _reload({String? status, int? page}) async {
    final cur = state.value;
    final s = status ?? cur?.status ?? 'pending';
    final p = page   ?? cur?.page   ?? 0;
    state = const AsyncLoading<TransferPageData>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _load(status: s, page: p));
  }

  /// Tab change — status set karo, page 0 par jao.
  Future<void> setStatus(String status) async {
    if (state.value?.status == status) return;
    await _reload(status: status, page: 0);
  }

  Future<void> setPage(int page) async {
    if (state.value?.page == page) return;
    await _reload(page: page);
  }

  Future<void> refresh() => _reload();

  // Accept flow — atomic + idempotent + self-healing (pehle jaisa),
  // ab success ke baad current page + aggregates dobara fetch hote hain.
  Future<bool> acceptTransfer(String transferId) async {
    if (_inFlightIds.contains(transferId)) return false;
    _inFlightIds.add(transferId);
    try {
      final rows = state.value?.rows ?? const <StockTransfer>[];
      final idx  = rows.indexWhere((t) => t.id == transferId);
      if (idx < 0) return false;
      final transfer = rows[idx];

      final wonClaim = await _dataSource.acceptTransfer(transferId);

      if (wonClaim) {
        try {
          await _dataSource.upsertLocalBranchStock(
            storeId: _storeId,
            items:   transfer.items,
          );
        } catch (e, stack) {
          debugPrint('❌ local stock upsert failed, reverting status: $e');
          debugPrint('❌ Stack: $stack');
          try {
            await _dataSource.revertToPending(transferId);
          } catch (revertError) {
            debugPrint('❌ revertToPending also failed: $revertError');
          }
          rethrow;
        }
      }

      await ref.read(branchStockProvider.notifier).load();
      await _reload();
      return true;
    } catch (e, stack) {
      debugPrint('❌ acceptTransfer error: $e');
      debugPrint('❌ Stack: $stack');
      return false;
    } finally {
      _inFlightIds.remove(transferId);
    }
  }

  Future<bool> rejectTransfer(String transferId) async {
    try {
      await _dataSource.rejectTransfer(transferId);
      await _reload();
      return true;
    } catch (e) {
      debugPrint('❌ rejectTransfer error: $e');
      return false;
    }
  }
}
