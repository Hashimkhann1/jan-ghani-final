import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/dashboard_datasource.dart';
import '../../data/model/dashboard_model.dart';

// ─── Dashboard State & Notifier ───────────────────────────────────────────

class DashboardState {
  final DashboardData data;
  final bool          isLoading;
  final String?       errorMessage;

  const DashboardState({
    required this.data,
    this.isLoading    = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardData? data,
    bool?          isLoading,
    String?        errorMessage,
  }) => DashboardState(
    data:         data         ?? this.data,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,
  );
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardDatasource _ds;
  final Ref                 _ref;

  DashboardNotifier(this._ref)
      : _ds = DashboardDatasource(),
        super(DashboardState(data: DashboardData.empty())) {
    load();
  }

  String  get _storeId   => _ref.read(authProvider).storeId;
  String? get _counterId => _ref.read(authProvider).counterId;
  String  get _role      => _ref.read(authProvider).role;

  String? get _filterCounterId {
    if (_role == 'store_owner' || _role == 'store_manager') return null;
    return _counterId;
  }

  int _reqId = 0;

  Future<void> load() async {
    final storeId = _storeId;
    if (storeId.isEmpty) return; // user/session not ready yet

    final req = ++_reqId;
    state = state.copyWith(isLoading: true);
    try {
      final data = await _ds.load(
        storeId:   storeId,
        counterId: _filterCounterId,
      );
      if (req != _reqId) return; // a newer load() superseded this one
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      if (kDebugMode) debugPrint('Dashboard load error: $e');
      if (req != _reqId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Dashboard load nahi ho saka',
      );
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final dashboardProvider =
StateNotifierProvider<DashboardNotifier, DashboardState>(
      (ref) => DashboardNotifier(ref),
);

// ─── Low Stock State & Notifier ───────────────────────────────────────────

class LowStockState {
  final List<LowStockItem> items;
  final bool               isLoading;
  final String?            errorMessage;

  const LowStockState({
    this.items        = const [],
    this.isLoading    = false,
    this.errorMessage,
  });

  LowStockState copyWith({
    List<LowStockItem>? items,
    bool?               isLoading,
    String?             errorMessage,
  }) => LowStockState(
    items:        items        ?? this.items,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,
  );

  int get outOfStockCount =>
      items.where((i) => i.status == StockStatus.outOfStock).length;
  int get lowStockCount =>
      items.where((i) => i.status == StockStatus.low).length;
}

class LowStockNotifier extends StateNotifier<LowStockState> {
  final LowStockDatasource _ds;
  final Ref                _ref;

  LowStockNotifier(this._ref)
      : _ds = LowStockDatasource(),
        super(const LowStockState()) {
    load();
  }

  String get _storeId => _ref.read(authProvider).storeId;

  int _reqId = 0;

  Future<void> load() async {
    final storeId = _storeId;
    if (storeId.isEmpty) return;

    final req = ++_reqId;
    state = state.copyWith(isLoading: true);
    try {
      final items = await _ds.getAll(storeId: storeId);
      if (req != _reqId) return;
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      if (kDebugMode) debugPrint('LowStock load error: $e');
      if (req != _reqId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Low stock load nahi ho saka',
      );
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final lowStockProvider =
StateNotifierProvider<LowStockNotifier, LowStockState>(
      (ref) => LowStockNotifier(ref),
);