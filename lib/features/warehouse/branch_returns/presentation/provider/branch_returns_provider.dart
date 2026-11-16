// Updated on 2026-11-16 09:59 AM
// =============================================================
// branch_returns_provider.dart — Branch Returns (warehouse side)
//
//   • branchReturnsProvider   — tabs (Pending/Accepted/Rejected) +
//                               search + pagination (server-side, 20)
//   • accept()                — fresh fetch → product check → RPC claim
//                               → LOCAL stock add → fail par RPC revert
//   • reject()                — sirf RPC (stock ko haath nahi; branch
//                               apna stock khud wapas leti hai)
//   • branchReturnsWatcherProvider — realtime INSERT/UPDATE (toast +
//                               list refresh) + app start par safety net
//   • Badge NAHI (user ka faisla)
// =============================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/provider/product_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/branch_return_local_datasource.dart';
import '../../data/branch_return_remote_datasource.dart';
import '../../domain/branch_return_model.dart';

final branchReturnRemoteProvider = Provider<BranchReturnRemoteDatasource>(
  (ref) => BranchReturnRemoteDatasource(
      Supabase.instance.client, AppConfig.warehouseId),
);

// ─────────────────────────────────────────────────────────────
// ACTIONS (accept / reject) — notifier aur safety net dono use karte
// ─────────────────────────────────────────────────────────────
class BranchReturnActions {
  final BranchReturnRemoteDatasource _remote;
  final BranchReturnLocalDatasource  _local;
  final String                       _wid;

  BranchReturnActions(this._remote, this._local, this._wid);

  /// Detail screen ke liye: har product ki local halat.
  Future<Map<String, ReturnProductStatus>> productStatus(BranchReturn r) =>
      _local.checkProducts(_wid, r.items.map((e) => e.productId).toList());

  Future<ReturnActionResult> accept(BranchReturn ret,
      {String? userId, String? userName}) async {
    // 1) Taaza data (list purani ho sakti hai)
    final fresh = await _remote.fetchById(ret.id);
    if (fresh == null) {
      return const ReturnActionResult(
          false, 'Ye return ab mojood nahi (branch ne hata diya)');
    }
    if (!fresh.isPending) {
      return const ReturnActionResult(
          false, 'Ye return pehle hi handle ho chuka hai');
    }
    if (!fresh.itemsComplete) {
      return const ReturnActionResult(false,
          'Return ke items abhi poore nahi aaye — thori der baad refresh karein');
    }

    // 2) Products local mein theek hain? (deleted / missing → accept band)
    final status = await productStatus(fresh);
    if (status.values.any((s) => s != ReturnProductStatus.ok)) {
      return const ReturnActionResult(false,
          'Kuch products delete hain ya warehouse mein nahi — sirf Reject ho sakta hai');
    }

    // 3) Supabase par claim (pending → accepted, atomic)
    final claimed =
        await _remote.accept(fresh.id, userId: userId, userName: userName);
    if (!claimed) {
      return const ReturnActionResult(
          false, 'Ye return pehle hi handle ho chuka hai');
    }

    // 4) Local stock add — fail ho to status wapas pending
    try {
      final r = await _local.applyReturn(
          warehouseId: _wid, ret: fresh, userId: userId);
      return ReturnActionResult(
          true,
          r == ApplyResult.applied
              ? 'Return accept ho gaya — ${_qty(fresh.itemsQty)} qty stock mein add'
              : 'Return accept ho gaya (stock pehle se add tha)');
    } catch (e) {
      debugPrint('❌ return local apply failed: $e');
      var reverted = false;
      try {
        reverted = await _remote.revertAccept(fresh.id);
      } catch (re) {
        debugPrint('❌ return revert failed: $re');
      }
      final why = e.toString().replaceFirst('Exception: ', '');
      return ReturnActionResult(
          false,
          reverted
              ? 'Stock add nahi hua ($why) — return wapas Pending kar diya'
              : 'Stock add nahi hua ($why). Status wapas nahi hua — app '
                'dobara kholne par stock khud add ho jayega');
    }
  }

  Future<ReturnActionResult> reject(BranchReturn ret, String reason,
      {String? userId, String? userName}) async {
    final ok = await _remote.reject(ret.id,
        userId: userId, userName: userName, reason: reason.trim());
    return ok
        ? const ReturnActionResult(
            true, 'Return reject ho gaya — branch ko stock wapas mil jayega')
        : const ReturnActionResult(
            false, 'Ye return pehle hi handle ho chuka hai');
  }

  /// Safety net: accepted returns jin ka local stock add nahi hua
  /// (accept ke beech app band). Return: kitne apply hue.
  Future<int> applyMissingAccepted() async {
    final accepted = await _remote.fetchRecentAccepted();
    if (accepted.isEmpty) return 0;
    final done = await _local.appliedReturnIds(
        _wid, accepted.map((e) => e.id).toList());
    var applied = 0;
    for (final r in accepted) {
      if (done.contains(r.id) || !r.itemsComplete) continue;
      try {
        final res = await _local.applyReturn(
            warehouseId: _wid, ret: r, userId: r.respondedById);
        if (res == ApplyResult.applied) applied++;
      } catch (e) {
        debugPrint('❌ return safety-net ${r.returnNumber}: $e');
      }
    }
    return applied;
  }

  static String _qty(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

final branchReturnActionsProvider = Provider<BranchReturnActions>(
  (ref) => BranchReturnActions(
    ref.watch(branchReturnRemoteProvider),
    BranchReturnLocalDatasource.instance,
    AppConfig.warehouseId,
  ),
);

/// Detail screen: return ke products ki local halat.
final returnProductStatusProvider = FutureProvider.autoDispose
    .family<Map<String, ReturnProductStatus>, BranchReturn>((ref, r) {
  return ref.read(branchReturnActionsProvider).productStatus(r);
});

// ─────────────────────────────────────────────────────────────
// LIST STATE
// ─────────────────────────────────────────────────────────────
class BranchReturnsState {
  final String              tab;        // pending | accepted | rejected
  final String              search;
  final int                 page;       // 0-based
  final int                 pageSize;
  final List<BranchReturn>  returns;
  final Map<String, int>    counts;
  final bool                isLoading;
  final String?             error;
  final Set<String>         busyIds;    // accept/reject chal raha

  const BranchReturnsState({
    this.tab       = 'pending',
    this.search    = '',
    this.page      = 0,
    this.pageSize  = 20,
    this.returns   = const [],
    this.counts    = const {'pending': 0, 'accepted': 0, 'rejected': 0},
    this.isLoading = false,
    this.error,
    this.busyIds   = const {},
  });

  int get totalInTab => counts[tab] ?? 0;
  int get pageCount =>
      totalInTab == 0 ? 1 : ((totalInTab + pageSize - 1) ~/ pageSize);

  BranchReturnsState copyWith({
    String?             tab,
    String?             search,
    int?                page,
    int?                pageSize,
    List<BranchReturn>? returns,
    Map<String, int>?   counts,
    bool?               isLoading,
    String?             error,
    bool                clearError = false,
    Set<String>?        busyIds,
  }) =>
      BranchReturnsState(
        tab:       tab       ?? this.tab,
        search:    search    ?? this.search,
        page:      page      ?? this.page,
        pageSize:  pageSize  ?? this.pageSize,
        returns:   returns   ?? this.returns,
        counts:    counts    ?? this.counts,
        isLoading: isLoading ?? this.isLoading,
        error:     clearError ? null : (error ?? this.error),
        busyIds:   busyIds   ?? this.busyIds,
      );
}

class BranchReturnsNotifier extends StateNotifier<BranchReturnsState> {
  final Ref _ref;
  BranchReturnsNotifier(this._ref) : super(const BranchReturnsState());

  bool _loadedOnce = false;
  int  _seq        = 0;   // purani request ka jawab nayi ko overwrite na kare

  BranchReturnRemoteDatasource get _remote =>
      _ref.read(branchReturnRemoteProvider);

  Future<void> load() async {
    final seq = ++_seq;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await Future.wait([
        _remote.fetchPage(
          status:   state.tab,
          page:     state.page,
          pageSize: state.pageSize,
          search:   state.search,
        ),
        _remote.fetchCounts(search: state.search),
      ]);
      if (!mounted || seq != _seq) return;
      _loadedOnce = true;
      state = state.copyWith(
        returns:   res[0] as List<BranchReturn>,
        counts:    res[1] as Map<String, int>,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('❌ branch returns load: $e');
      if (!mounted || seq != _seq) return;
      state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Realtime se — sirf tab jab screen ek dafa load ho chuki ho.
  Future<void> refreshIfLoaded() async {
    if (_loadedOnce) await load();
  }

  void onTab(String tab) {
    if (tab == state.tab) return;
    state = state.copyWith(tab: tab, page: 0, returns: const []);
    load();
  }

  void onSearch(String q) {
    state = state.copyWith(search: q, page: 0);
    load();
  }

  void onPage(int p) {
    if (p < 0 || p >= state.pageCount || p == state.page) return;
    state = state.copyWith(page: p);
    load();
  }

  bool isBusy(String id) => state.busyIds.contains(id);

  Future<ReturnActionResult> accept(BranchReturn ret) =>
      _run(ret.id, (a, uid, uname) =>
          a.accept(ret, userId: uid, userName: uname), refreshStock: true);

  Future<ReturnActionResult> reject(BranchReturn ret, String reason) =>
      _run(ret.id, (a, uid, uname) =>
          a.reject(ret, reason, userId: uid, userName: uname));

  // Single-flight: ek return par ek waqt mein ek hi action
  Future<ReturnActionResult> _run(
    String id,
    Future<ReturnActionResult> Function(
            BranchReturnActions a, String? uid, String? uname)
        action, {
    bool refreshStock = false,
  }) async {
    if (state.busyIds.contains(id)) {
      return const ReturnActionResult(false, 'Kaam chal raha hai…');
    }
    state = state.copyWith(busyIds: {...state.busyIds, id});
    final user = _ref.read(authProvider).user;
    final uid  = (user?.id.isNotEmpty ?? false) ? user!.id : null;
    ReturnActionResult result;
    try {
      result = await action(
          _ref.read(branchReturnActionsProvider), uid, user?.fullName);
    } catch (e) {
      debugPrint('❌ branch return action: $e');
      result = ReturnActionResult(
          false, e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) {
      state = state.copyWith(busyIds: {...state.busyIds}..remove(id));
    }
    if (refreshStock && result.ok) {
      _ref.read(productProvider.notifier).loadProducts();
    }
    await load();
    return result;
  }
}

final branchReturnsProvider =
    StateNotifierProvider<BranchReturnsNotifier, BranchReturnsState>(
  (ref) => BranchReturnsNotifier(ref),
);

// ─────────────────────────────────────────────────────────────
// REALTIME + SAFETY NET (SideBar initState se ek dafa start)
// ─────────────────────────────────────────────────────────────

/// Naya return aaya — SideBar toast dikhati hai.
class BranchReturnNotice {
  final String storeName;
  final String returnNumber;
  final DateTime at;
  BranchReturnNotice(this.storeName, this.returnNumber) : at = DateTime.now();
}

final branchReturnNoticeProvider =
    StateProvider<BranchReturnNotice?>((ref) => null);

class BranchReturnsWatcher {
  final Ref    _ref;
  final String _wid;
  RealtimeChannel? _channel;
  Timer?           _reconnect;
  bool             _disposed = false;

  BranchReturnsWatcher(this._ref, this._wid);

  void start() {
    _listen();
    // DB connect hone ka thora waqt — phir safety net
    Future.delayed(const Duration(seconds: 3), _runSafetyNet);
  }

  Future<void> _runSafetyNet() async {
    if (_disposed) return;
    try {
      final n =
          await _ref.read(branchReturnActionsProvider).applyMissingAccepted();
      if (n > 0) {
        debugPrint('↩️ return safety-net: $n accepted returns ka stock add');
        _ref.read(productProvider.notifier).loadProducts();
      }
    } catch (e) {
      debugPrint('⚠️ return safety-net skip: $e');
    }
  }

  void _listen() {
    if (_disposed) return;
    final old = _channel;
    _channel = null;
    old?.unsubscribe();

    final filter = PostgresChangeFilter(
      type:   PostgresChangeFilterType.eq,
      column: 'warehouse_id',
      value:  _wid,
    );

    _channel = Supabase.instance.client
        .channel('stock_returns_wh_${_wid}_${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'stock_returns',
          filter: filter,
          callback: (p) {
            final row = p.newRecord;
            if ((row['status'] ?? 'pending').toString() == 'pending') {
              _ref.read(branchReturnNoticeProvider.notifier).state =
                  BranchReturnNotice(
                (row['from_store_name'] ?? 'Branch').toString(),
                (row['return_number'] ?? '').toString(),
              );
            }
            // Items header ke baad aate hain — thora ruk kar refresh
            Future.delayed(const Duration(seconds: 2), () {
              if (!_disposed) {
                _ref.read(branchReturnsProvider.notifier).refreshIfLoaded();
              }
            });
          },
        )
        .onPostgresChanges(
          event:  PostgresChangeEvent.update,
          schema: 'public',
          table:  'stock_returns',
          filter: filter,
          callback: (_) {
            _ref.read(branchReturnsProvider.notifier).refreshIfLoaded();
          },
        )
        .subscribe((status, [error]) {
          if (error != null) debugPrint('⚠️ stock_returns realtime: $error');
          if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            _scheduleReconnect();
          }
        });
  }

  void _scheduleReconnect() {
    if (_disposed || (_reconnect?.isActive ?? false)) return;
    _reconnect = Timer(const Duration(seconds: 10), _listen);
  }

  void dispose() {
    _disposed = true;
    _reconnect?.cancel();
    _channel?.unsubscribe();
  }
}

final branchReturnsWatcherProvider = Provider<BranchReturnsWatcher>((ref) {
  final w = BranchReturnsWatcher(ref, AppConfig.warehouseId)..start();
  ref.onDispose(w.dispose);
  return w;
});
