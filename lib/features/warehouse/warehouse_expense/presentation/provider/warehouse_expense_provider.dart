// =============================================================
// warehouse_expense_provider.dart
// State + Notifier + Provider
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final DateTime?                   fromDate;    // inclusive
  final DateTime?                   toDate;      // inclusive (query converts +1 din)
  final String                      searchQuery;

  const WarehouseExpenseState({
    this.expenses     = const [],
    this.stats        = const ExpenseStats(),
    this.isLoading    = false,
    this.errorMessage,
    this.fromDate,
    this.toDate,
    this.searchQuery  = '',
  });

  // Loaded rows ka total (date filter + search ke andar)
  double get filteredTotal =>
      expenses.fold(0.0, (sum, e) => sum + e.amount);

  WarehouseExpenseState copyWith({
    List<WarehouseExpenseModel>? expenses,
    ExpenseStats?                stats,
    bool?                        isLoading,
    String?                      errorMessage,
    DateTime?                    fromDate,
    DateTime?                    toDate,
    String?                      searchQuery,
  }) {
    return WarehouseExpenseState(
      expenses:     expenses     ?? this.expenses,
      stats:        stats        ?? this.stats,
      isLoading:    isLoading    ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      fromDate:     fromDate     ?? this.fromDate,
      toDate:       toDate       ?? this.toDate,
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
      : super(WarehouseExpenseState(
    // Default: last 30 din (today-29 → today)
    fromDate: _defaultFrom(),
    toDate:   _defaultTo(),
  )) {
    loadData();
  }

  static DateTime _defaultFrom() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(const Duration(days: 29));
  }

  static DateTime _defaultTo() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Repo ke liye exclusive upper bound (to + 1 din — pura `to` din include ho).
  DateTime? get _toExclusive =>
      state.toDate == null ? null : state.toDate!.add(const Duration(days: 1));

  // ── Sab data load karo ───────────────────────────────────
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _repo.getAll(
          fromDate: state.fromDate,
          toDate:   _toExclusive,
          search:   state.searchQuery.isEmpty ? null : state.searchQuery,
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

  // ── Date range change ────────────────────────────────────
  void onDateRangeChanged(DateTime from, DateTime to) {
    state = state.copyWith(fromDate: from, toDate: to);
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

  // ── Expense edit karo ─────────────────────────────────────
  Future<void> updateExpense({
    required String id,
    String?         cashTransactionId,
    required String expenseHead,
    required double amount,
    String?         description,
    String?         userId,
    String?         userName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.updateExpense(
        id:                id,
        cashTransactionId: cashTransactionId,
        expenseHead:       expenseHead,
        amount:            amount,
        description:       description,
        createdBy:         userId,
        createdByName:     userName,
      );

      // List + stats fresh karo (date range/search respect karte hue)
      final results = await Future.wait([
        _repo.getAll(
          fromDate: state.fromDate,
          toDate:   _toExclusive,
          search:   state.searchQuery.isEmpty ? null : state.searchQuery,
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
        errorMessage: 'Expense update karne mein masla: $e',
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