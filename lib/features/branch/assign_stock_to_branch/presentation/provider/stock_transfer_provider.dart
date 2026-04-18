import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/stock_transfer_remote_datasource.dart';
import '../../data/model/stock_transfer_model.dart';

// DataSource provider
final stockTransferDataSourceProvider = Provider((ref) {
  return StockTransferRemoteDataSource(Supabase.instance.client);
});

final currentStoreIdProvider = Provider<String>((ref) {
  return ref.watch(authProvider).storeId ?? '';
});

// Transfers provider — AsyncNotifier
final stockTransferProvider =
AsyncNotifierProvider<StockTransferNotifier, List<StockTransfer>>(
  StockTransferNotifier.new,
);

class StockTransferNotifier extends AsyncNotifier<List<StockTransfer>> {
  late StockTransferRemoteDataSource _dataSource;
  late String _storeId;

  @override
  Future<List<StockTransfer>> build() async {
    _dataSource = ref.read(stockTransferDataSourceProvider);
    _storeId = ref.watch(currentStoreIdProvider);

    if (_storeId.isEmpty) return [];
    return _dataSource.fetchTransfersByStore(_storeId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _dataSource.fetchTransfersByStore(_storeId),
    );
  }

  Future<bool> acceptTransfer(String transferId) async {
    try {
      final currentList = state.value ?? [];
      final transfer = currentList.firstWhere((t) => t.id == transferId);

      // 1. Local PostgreSQL mein save karo
      await _dataSource.upsertLocalBranchStock(
        storeId: _storeId,
        items: transfer.items,
      );

      // 2. Supabase mein sirf status = accepted karo
      await _dataSource.acceptTransfer(transferId);

      state = AsyncData(
        currentList.map((t) => t.id == transferId
            ? _rebuildWithStatus(t, 'accepted')
            : t).toList(),
      );

      return true;
    } catch (e, stack) {
      debugPrint('❌ acceptTransfer error: $e');
      debugPrint('❌ Stack: $stack');
      return false;
    }
  }

  Future<bool> rejectTransfer(String transferId) async {
    try {
      await _dataSource.rejectTransfer(transferId);

      final currentList = state.value ?? [];
      state = AsyncData(
        currentList.map((t) {
          if (t.id == transferId) {
            return _rebuildWithStatus(t, 'rejected');
          }
          return t;
        }).toList(),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Local state ke liye helper
  StockTransfer _rebuildWithStatus(StockTransfer t, String status) {
    return StockTransfer(
      id: t.id,
      transferNumber: t.transferNumber,
      toStoreId: t.toStoreId,
      toStoreName: t.toStoreName,
      warehouseId: t.warehouseId,
      assignedByName: t.assignedByName,
      assignedAt: t.assignedAt,
      notes: t.notes,
      totalItems: t.totalItems,
      totalCost: t.totalCost,
      totalSalePrice: t.totalSalePrice,
      status: status,
      items: t.items,
    );
  }
}