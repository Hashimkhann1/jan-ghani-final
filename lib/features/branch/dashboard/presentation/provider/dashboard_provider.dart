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

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _ds.load(
        storeId:   _storeId,
        counterId: _filterCounterId,
      );
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      print('❌ Dashboard load error: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
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

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _ds.getAll(storeId: _storeId);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      print('❌ LowStock load error: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final lowStockProvider =
StateNotifierProvider<LowStockNotifier, LowStockState>(
      (ref) => LowStockNotifier(ref),
);