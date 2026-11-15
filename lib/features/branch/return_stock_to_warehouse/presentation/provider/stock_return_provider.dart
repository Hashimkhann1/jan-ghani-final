import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../branch_info/presentation/provider/branch_provider.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';
import '../../data/datasource/stock_return_datasource.dart';
import '../../data/model/stock_return_model.dart';

final stockReturnDsProvider = Provider<StockReturnDataSource>(
  (ref) => StockReturnDataSource(Supabase.instance.client),
);

// ── Rejected returns ka stock wapis (branch) ───────────────────
/// Screen khulne / refresh par chalta hai: warehouse ke reject kiye hue
/// returns ka stock branch mein wapis add hota hai.
final returnRestoreProvider = FutureProvider.autoDispose<int>((ref) async {
  final storeId = ref.watch(authProvider).storeId;
  if (storeId.isEmpty) return 0;
  final n =
      await ref.read(stockReturnDsProvider).restoreRejectedReturns(storeId);
  if (n > 0) await ref.read(branchStockProvider.notifier).load();
  return n;
});

final returnCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final storeId = ref.watch(authProvider).storeId;
  await ref.watch(returnRestoreProvider.future);
  return ref.read(stockReturnDsProvider).fetchCounts(storeId);
});

final returnListProvider = FutureProvider.autoDispose
    .family<List<StockReturn>, String>((ref, status) async {
  final storeId = ref.watch(authProvider).storeId;
  await ref.watch(returnRestoreProvider.future);
  return ref
      .read(stockReturnDsProvider)
      .fetchReturns(storeId, status: status);
});

// ── Cart ───────────────────────────────────────────────────────
class ReturnCartState {
  final List<ReturnCartLine> lines;
  final String  notes;
  final String  returnNo;
  final bool    isSending;
  final String? error;

  const ReturnCartState({
    this.lines = const [],
    this.notes = '',
    this.returnNo = '',
    this.isSending = false,
    this.error,
  });

  double get totalQty  => lines.fold(0, (s, l) => s + l.qty);
  double get totalCost => lines.fold(0, (s, l) => s + l.totalCost);
  double get totalSale => lines.fold(0, (s, l) => s + l.totalSale);

  ReturnCartState copyWith({
    List<ReturnCartLine>? lines,
    String? notes,
    String? returnNo,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) =>
      ReturnCartState(
        lines:     lines     ?? this.lines,
        notes:     notes     ?? this.notes,
        returnNo:  returnNo  ?? this.returnNo,
        isSending: isSending ?? this.isSending,
        error:     clearError ? null : (error ?? this.error),
      );
}

class ReturnCartNotifier extends StateNotifier<ReturnCartState> {
  final Ref _ref;
  ReturnCartNotifier(this._ref)
      : super(ReturnCartState(
            returnNo: _ref.read(stockReturnDsProvider).nextReturnNumber()));

  void add(BranchStockModel p, {double qty = 1}) {
    if (p.isDigital || p.quantity <= 0 || qty <= 0) return;
    final i = state.lines.indexWhere((l) => l.productId == p.productId);
    if (i >= 0) {
      final l = state.lines[i];
      setQty(l.productId, (l.qty + qty).clamp(0, l.available).toDouble());
      return;
    }
    state = state.copyWith(clearError: true, lines: [
      ...state.lines,
      ReturnCartLine(
        productId: p.productId,
        name:      p.name,
        sku:       p.sku,
        unit:      p.unitOfMeasure,
        costPrice: p.costPrice,
        salePrice: p.sellingPrice,
        available: p.quantity,
        qty:       qty.clamp(0, p.quantity).toDouble(),
      ),
    ]);
  }

  void setQty(String productId, double qty) {
    state = state.copyWith(
      clearError: true,
      lines: [
        for (final l in state.lines)
          if (l.productId == productId)
            l.withQty(qty.clamp(0, l.available).toDouble())
          else
            l,
      ],
    );
  }

  void remove(String productId) => state = state.copyWith(
      lines: state.lines.where((l) => l.productId != productId).toList());

  void setNotes(String n) => state = state.copyWith(notes: n);

  void clear() => state = ReturnCartState(
      returnNo: _ref.read(stockReturnDsProvider).nextReturnNumber());

  /// true = bhej diya gaya.
  Future<bool> send() async {
    if (state.isSending) return false;
    final lines = state.lines.where((l) => l.qty > 0).toList();
    if (lines.isEmpty) {
      state = state.copyWith(error: 'Koi item select nahi kiya');
      return false;
    }
    final auth = _ref.read(authProvider);
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final ds = _ref.read(stockReturnDsProvider);
      final warehouseId = await ds.getWarehouseId(auth.storeId);
      if (warehouseId == null) {
        throw Exception('Is branch ka warehouse link nahi hai');
      }
      final branch = await _ref.read(branchProvider(auth.storeId).future);
      await ds.sendReturn(
        storeId:     auth.storeId,
        storeName:   branch?.name ?? '',
        warehouseId: warehouseId,
        userId:      auth.userId,
        userName:    auth.fullName,
        notes:       state.notes,
        lines:       lines,
      );
      await _ref.read(branchStockProvider.notifier).load();
      _ref.invalidate(returnCountsProvider);
      _ref.invalidate(returnListProvider);
      clear();
      return true;
    } catch (e) {
      debugPrint('❌ send return error: $e');
      state = state.copyWith(
          isSending: false,
          error: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }
}

final returnCartProvider =
    StateNotifierProvider.autoDispose<ReturnCartNotifier, ReturnCartState>(
  (ref) => ReturnCartNotifier(ref),
);
