// =============================================================
// warehouse_expense_provider.dart
// State + Notifier + Provider
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_expense/data/warehouse_expense_repository.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_expense/domain/warehouse_expense_model.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────
class WarehouseExpenseState {
  final List<WarehouseExpenseModel> expenses;
  final ExpenseStats                stats;
  final bool                        isLoading;
  final String?                     errorMessage;
  final String                      activeFilter;  // all / today / this_week / this_month
  final String                      searchQuery;

  const WarehouseExpenseState({
    this.expenses     = const [],
    this.stats        = const ExpenseStats(),
    this.isLoading    = false,
    this.errorMessage,
    this.activeFilter = 'all',
    this.searchQuery  = '',
  });

  // Filter ke hisaab se total
  double get filteredTotal =>
      expenses.fold(0.0, (sum, e) => sum + e.amount);

  WarehouseExpenseState copyWith({
    List<WarehouseExpenseModel>? expenses,
    ExpenseStats?                stats,
    bool?                        isLoading,
    String?                      errorMessage,
    String?                      activeFilter,
    String?                      searchQuery,
  }) {
    return WarehouseExpenseState(
      expenses:     expenses     ?? this.expenses,
      stats:        stats        ?? this.stats,
      isLoading:    isLoading    ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery:  searchQuery  ?? this.searchQuery,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────
class WarehouseExpenseNotifier
    extends StateNotifier<WarehouseExpenseState> {
  final WarehouseExpenseRepository _repo;

  WarehouseExpenseNotifier(this._repo)
      : super(const WarehouseExpenseState()) {
    loadData();
  }

  // ── Sab data load karo ───────────────────────────────────
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _repo.getAll(
          filter: state.activeFilter == 'all' ? null : state.activeFilter,
          search: state.searchQuery.isEmpty ? null : state.searchQuery,
        ),
        _repo.getStats(),
      ]);

      state = state.copyWith(
        expenses:  results[0] as List<WarehouseExpenseModel>,
        stats:     results[1] as ExpenseStats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Data load karne mein masla: $e',
      );
    }
  }

  // ── Filter change ────────────────────────────────────────
  void onFilterChanged(String filter) {
    state = state.copyWith(activeFilter: filter);
    loadData();
  }

  // ── Search change ────────────────────────────────────────
  void onSearchChanged(String query) {
    state = state.copyWith(searchQuery: query);
    loadData();
  }

  // ── Expense add karo ─────────────────────────────────────
  Future<void> addExpense({
    required String expenseHead,
    required double amount,
    String?         description,
    DateTime?       expenseDate,
    String?         userId,
    String?         userName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newExpense = await _repo.addExpense(
        expenseHead:   expenseHead,
        amount:        amount,
        description:   description,
        expenseDate:   expenseDate,
        createdBy:     userId,
        createdByName: userName,
      );

      // Stats refresh karo
      final updatedStats = await _repo.getStats();

      state = state.copyWith(
        expenses:  [newExpense, ...state.expenses],
        stats:     updatedStats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Expense save karne mein masla: $e',
      );
    }
  }

  // ── Expense delete karo ───────────────────────────────────
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _repo.deleteExpense(expenseId);
      final updatedList  = state.expenses
          .where((e) => e.id != expenseId)
          .toList();
      final updatedStats = await _repo.getStats();
      state = state.copyWith(
        expenses: updatedList,
        stats:    updatedStats,
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Delete karne mein masla: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────
final warehouseExpenseProvider = StateNotifierProvider<
    WarehouseExpenseNotifier,
    WarehouseExpenseState>(
      (ref) => WarehouseExpenseNotifier(WarehouseExpenseRepository.instance),
);