import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/counter_remote_datasource.dart';
import '../../data/model/counter_model.dart';

// ── State ─────────────────────────────────────────────────────
class CounterState {
  final List<CounterModel> counters;
  final bool    isLoading;
  final String? errorMessage;

  const CounterState({
    this.counters     = const [],
    this.isLoading    = false,
    this.errorMessage,
  });

  CounterState copyWith({
    List<CounterModel>? counters,
    bool?               isLoading,
    String?             errorMessage,
  }) => CounterState(
    counters:     counters     ?? this.counters,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,
  );
}

// ── Notifier ──────────────────────────────────────────────────
class CounterNotifier extends StateNotifier<CounterState> {
  final CounterRemoteDataSource _ds;
  final Ref _ref;
  String get _storeId => _ref.read(authProvider).storeId;

  CounterNotifier(this._ref): _ds = CounterRemoteDataSource(), super(const CounterState()) {
    loadCounters();
  }

  Future<void> loadCounters() async {
    state = state.copyWith(isLoading: true);
    try {
      final counters = await _ds.getAll(_storeId);
      state = state.copyWith(counters: counters, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  Future<void> addCounter(String counterName) async {
    state = state.copyWith(isLoading: true);
    try {
      final saved = await _ds.add(_storeId, counterName);
      state = state.copyWith(
        counters:  [saved, ...state.counters],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Add error: $e');
    }
  }

  Future<void> updateCounter(String id, String counterName) async {
    state = state.copyWith(isLoading: true);
    try {
      final fresh = await _ds.update(id, counterName);
      final list  = state.counters
          .map((c) => c.id == fresh.id ? fresh : c)
          .toList();
      state = state.copyWith(counters: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Update error: $e');
    }
  }

  Future<void> deleteCounter(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _ds.delete(id);
      final list = state.counters.where((c) => c.id != id).toList();
      state = state.copyWith(counters: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Delete error: $e');
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ── Provider ──────────────────────────────────────────────────
final counterProvider =
StateNotifierProvider<CounterNotifier, CounterState>(
      (ref) => CounterNotifier(ref),
);