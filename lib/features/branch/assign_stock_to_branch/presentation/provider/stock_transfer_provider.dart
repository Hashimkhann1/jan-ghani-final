import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';
import '../../data/datasource/stock_transfer_remote_datasource.dart';
import '../../data/model/stock_transfer_model.dart';

// DataSource provider
final stockTransferDataSourceProvider = Provider((ref) {
  return StockTransferRemoteDataSource(Supabase.instance.client);
});

// ✅ BUG 6 FIX: storeId already non-nullable String — ?? '' removed
final currentStoreIdProvider = Provider<String>((ref) {
  return ref.watch(authProvider).storeId;
});

// Transfers provider — AsyncNotifier
final stockTransferProvider =
    AsyncNotifierProvider<StockTransferNotifier, List<StockTransfer>>(
  StockTransferNotifier.new,
);

class StockTransferNotifier extends AsyncNotifier<List<StockTransfer>> {
  late StockTransferRemoteDataSource _dataSource;
  late String _storeId;

  // Single-flight guard: same transfer par ek waqt mein sirf ek
  // accept/reject in-flight ho sakta hai (double-tap / retry-while-loading
  // se double stock-credit na ho).
  final Set<String> _inFlightIds = {};

  @override
  Future<List<StockTransfer>> build() async {
    _dataSource = ref.read(stockTransferDataSourceProvider);
    _storeId    = ref.watch(currentStoreIdProvider);

    if (_storeId.isEmpty) return [];
    return _dataSource.fetchTransfersByStore(_storeId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _dataSource.fetchTransfersByStore(_storeId),
    );
  }

  // Accept flow — ab fully atomic + idempotent + self-healing:
  //  1. Supabase status ko GUARDED tareeqe se pending→accepted flip karo
  //     (`WHERE status='pending'`). Agar 0 rows update hui to iska matlab
  //     transfer already kisi aur call/device ne accept/reject kar diya —
  //     idempotent no-op, local stock DOBARA add nahi karte.
  //  2. Jeetne wala call hi local stock upsert karta hai (ek transaction
  //     mein — sab items ya to poore apply hote hain ya koi nahi).
  //  3. Agar step 2 fail ho jaye, Supabase status wapas 'pending' par
  //     revert karte hain (compensation) — taake transfer safely retry ho
  //     sake aur stock permanently "gum" na ho (purana silent-failure bug).
  Future<bool> acceptTransfer(String transferId) async {
    if (_inFlightIds.contains(transferId)) return false;
    _inFlightIds.add(transferId);
    try {
      final currentList = state.value ?? [];
      final transfer    = currentList.firstWhere((t) => t.id == transferId);

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
      // wonClaim == false → already accepted (elsewhere) → treat as
      // success, just reflect status locally.

      // Local state update
      state = AsyncData(
        currentList
            .map((t) => t.id == transferId
                ? _rebuildWithStatus(t, 'accepted')
                : t)
            .toList(),
      );

      // POS provider refresh karo
      await ref.read(branchStockProvider.notifier).load();

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

      final currentList = state.value ?? [];
      state = AsyncData(
        currentList.map((t) {
          if (t.id == transferId) return _rebuildWithStatus(t, 'rejected');
          return t;
        }).toList(),
      );

      return true;
    } catch (e) {
      debugPrint('❌ rejectTransfer error: $e');
      return false;
    }
  }

  // Local state ke liye helper
  StockTransfer _rebuildWithStatus(StockTransfer t, String status) {
    return StockTransfer(
      id:             t.id,
      transferNumber: t.transferNumber,
      toStoreId:      t.toStoreId,
      toStoreName:    t.toStoreName,
      warehouseId:    t.warehouseId,
      assignedByName: t.assignedByName,
      assignedAt:     t.assignedAt,
      notes:          t.notes,
      totalItems:     t.totalItems,
      totalCost:      t.totalCost,
      totalSalePrice: t.totalSalePrice,
      status:         status,
      items:          t.items,
    );
  }
}
