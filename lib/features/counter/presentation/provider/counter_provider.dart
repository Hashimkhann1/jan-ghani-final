import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/model/counter_model.dart';

final counterProvider = NotifierProvider<CounterNotifier, CounterState>(() => CounterNotifier());

class CounterState {
  final List<CounterModel> counters;
  final bool isLoading;

  CounterState({this.counters = const [], this.isLoading = false});

  CounterState copyWith({List<CounterModel>? counters, bool? isLoading}) {
    return CounterState(
      counters: counters ?? this.counters,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CounterNotifier extends Notifier<CounterState> {
  @override
  CounterState build() {
    // Mock Data
    return CounterState(
      counters: [
        CounterModel(
          id: '1',
          counterName: 'Main Counter',
          username: 'counter01',
          password: '123456',
          cashSale: 45200,
          cardSale: 12800,
          creditSale: 7500,
          installment: 3200,
        ),
        CounterModel(
          id: '2',
          counterName: 'Counter A',
          username: 'counter02',
          password: '654321',
          cashSale: 28900,
          cardSale: 6700,
          creditSale: 4500,
          installment: 1800,
        ),
      ],
    );
  }

  addCounter(CounterModel counter) {
    state = state.copyWith(
      counters: [...state.counters, counter],
    );
  }

  updateCounter(CounterModel updatedCounter) {
    state = state.copyWith(
      counters: state.counters
          .map((c) => c.id == updatedCounter.id ? updatedCounter : c)
          .toList(),
    );
  }

  void deleteCounter(String id) {
    state = state.copyWith(
      counters: state.counters.where((c) => c.id != id).toList(),
    );
  }
}