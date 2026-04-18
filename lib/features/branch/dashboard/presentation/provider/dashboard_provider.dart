import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/dashboard_datasource.dart';
import '../../data/model/dashboard_model.dart';

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

  // Manager/Owner → null (all counters), Cashier → specific counter
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
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) => DashboardNotifier(ref),);