// =============================================================
// employee_provider.dart — employee master list + CRUD
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/employee_repository.dart';
import '../../domain/employee_model.dart';

class EmployeeState {
  final List<EmployeeModel> all;
  final String              searchQuery;
  final bool                isLoading;
  final String?             errorMessage;

  const EmployeeState({
    this.all          = const [],
    this.searchQuery  = '',
    this.isLoading    = false,
    this.errorMessage,
  });

  List<EmployeeModel> get filtered {
    if (searchQuery.isEmpty) return all;
    final q = searchQuery.toLowerCase();
    return all.where((e) =>
        e.name.toLowerCase().contains(q) ||
        (e.phone?.toLowerCase().contains(q) ?? false)).toList();
  }

  int    get totalCount     => all.length;
  int    get activeCount    => all.where((e) => e.isActive).length;
  double get totalMonthly   =>
      all.where((e) => e.isActive).fold(0.0, (s, e) => s + e.monthlySalary);

  EmployeeState copyWith({
    List<EmployeeModel>? all,
    String?              searchQuery,
    bool?                isLoading,
    String?              errorMessage,
  }) {
    return EmployeeState(
      all:          all          ?? this.all,
      searchQuery:  searchQuery  ?? this.searchQuery,
      isLoading:    isLoading    ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class EmployeeNotifier extends StateNotifier<EmployeeState> {
  final EmployeeRepository _repo = EmployeeRepository.instance;

  EmployeeNotifier() : super(const EmployeeState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repo.getAllEmployees();
      state = state.copyWith(all: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Employees load masla: $e');
    }
  }

  Future<void> addEmployee(EmployeeModel e) async {
    state = state.copyWith(isLoading: true);
    try {
      final saved = await _repo.addEmployee(e);
      state = state.copyWith(all: [...state.all, saved], isLoading: false);
    } catch (err) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Employee add masla: $err');
    }
  }

  Future<void> updateEmployee(EmployeeModel e) async {
    state = state.copyWith(isLoading: true);
    try {
      final saved = await _repo.updateEmployee(e);
      final list = state.all.map((x) => x.id == saved.id ? saved : x).toList();
      state = state.copyWith(all: list, isLoading: false);
    } catch (err) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Employee update masla: $err');
    }
  }

  Future<void> deleteEmployee(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.deleteEmployee(id);
      state = state.copyWith(
          all: state.all.where((e) => e.id != id).toList(), isLoading: false);
    } catch (err) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Employee delete masla: $err');
    }
  }

  void onSearch(String q) => state = state.copyWith(searchQuery: q);
  void clearError()       => state = state.copyWith(errorMessage: null);
}

final employeeProvider =
    StateNotifierProvider<EmployeeNotifier, EmployeeState>(
        (ref) => EmployeeNotifier());
