import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/provider/auth_provider.dart';
import '../../../cash_store/presentation/provider/store_summary_provider.dart';
import '../../data/model/expense_model.dart';
import '../../data/repository/expense_repository_impl.dart';
import '../../domian/usecase/add_expense_usecase.dart';
import '../../domian/usecase/delete_expense_usecase.dart';
import '../../domian/usecase/get_expenses_usecase.dart';
import '../../domian/usecase/update_expense_usecase.dart';

// ── State ─────────────────────────────────────────────────────
class ExpenseState {
  final List<ExpenseModel> allExpenses;
  final String  searchQuery;
  final String  filterPeriod; // all | today | week | month
  final bool    isLoading;
  final String? errorMessage;

  const ExpenseState({
    this.allExpenses  = const [],
    this.searchQuery  = '',
    this.filterPeriod = 'all',
    this.isLoading    = false,
    this.errorMessage,
  });

  // ── Filtered List ─────────────────────────────────────────
  List<ExpenseModel> get filteredExpenses {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return allExpenses.where((e) {
      if (e.deletedAt != null) return false;

      // Period filter
      if (filterPeriod == 'today') {
        if (e.createdAt.isBefore(today)) return false;
      } else if (filterPeriod == 'week') {
        if (e.createdAt.isBefore(
            today.subtract(const Duration(days: 7)))) return false;
      } else if (filterPeriod == 'month') {
        if (e.createdAt.isBefore(
            DateTime(now.year, now.month, 1))) return false;
      }

      // Search filter
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return e.expenseHead.toLowerCase().contains(q) ||
            (e.description?.toLowerCase().contains(q) ?? false);
      }

      return true;
    }).toList();
  }

  // ── Stats ─────────────────────────────────────────────────
  int    get totalCount  => filteredExpenses.length;
  double get totalAmount =>
      filteredExpenses.fold(0, (sum, e) => sum + e.amount);

  double get todayAmount {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return allExpenses
        .where((e) => e.deletedAt == null && e.createdAt.isAfter(start))
        .fold(0, (sum, e) => sum + e.amount);
  }

  double get monthAmount {
    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return allExpenses
        .where((e) => e.deletedAt == null && e.createdAt.isAfter(start))
        .fold(0, (sum, e) => sum + e.amount);
  }

  ExpenseState copyWith({
    List<ExpenseModel>? allExpenses,
    String?             searchQuery,
    String?             filterPeriod,
    bool?               isLoading,
    String?             errorMessage,
  }) => ExpenseState(
    allExpenses:  allExpenses  ?? this.allExpenses,
    searchQuery:  searchQuery  ?? this.searchQuery,
    filterPeriod: filterPeriod ?? this.filterPeriod,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,
  );
}

// ── Notifier ──────────────────────────────────────────────────
class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ExpenseRepositoryImpl _repo;
  final GetExpensesUseCase    _getAll;
  final AddExpenseUseCase     _add;
  final UpdateExpenseUseCase  _update;
  final DeleteExpenseUseCase  _delete;
  final Ref _ref;


  ExpenseNotifier(this._ref)
      : _repo   = ExpenseRepositoryImpl(),
        _getAll  = GetExpensesUseCase(ExpenseRepositoryImpl()),
        _add     = AddExpenseUseCase(ExpenseRepositoryImpl()),
        _update  = UpdateExpenseUseCase(ExpenseRepositoryImpl()),
        _delete  = DeleteExpenseUseCase(ExpenseRepositoryImpl()),
        super(const ExpenseState()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = state.copyWith(isLoading: true);
    try {
      final String _storeId = _ref.watch(authProvider).storeId;
      final expenses = await _getAll(_storeId);
      state = state.copyWith(allExpenses: expenses, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  Future<void> addExpense({
    required String expenseHead,
    required double amount,
    String?         description,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final String _storeId = _ref.watch(authProvider).storeId;
      final saved = await _add(ExpenseModel(
        id:          '',
        storeId:     _storeId,
        expenseHead: expenseHead,
        amount:      amount,
        description: description,
        createdAt:   DateTime.now(),
        updatedAt:   DateTime.now(),
      ));
      state = state.copyWith(
        allExpenses: [saved, ...state.allExpenses],
        isLoading:   false,
      );
      _ref.read(storeSummaryProvider.notifier).load();

    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Add error: $e');
    }
  }

  Future<void> updateExpense(ExpenseModel updated) async {
    state = state.copyWith(isLoading: true);
    try {
      final fresh = await _update(updated);
      final list  = state.allExpenses
          .map((e) => e.id == fresh.id ? fresh : e)
          .toList();
      state = state.copyWith(allExpenses: list, isLoading: false);
      _ref.read(storeSummaryProvider.notifier).load();
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Update error: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _delete(id);
      final list = state.allExpenses.where((e) => e.id != id).toList();
      state = state.copyWith(allExpenses: list, isLoading: false);
      _ref.read(storeSummaryProvider.notifier).load();
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Delete error: $e');
    }
  }

  void onSearchChanged(String q)       => state = state.copyWith(searchQuery: q);
  void onFilterPeriodChanged(String p) => state = state.copyWith(filterPeriod: p);
  void clearError()                    => state = state.copyWith(errorMessage: null);
}

// ── Provider ──────────────────────────────────────────────────
final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) => ExpenseNotifier(ref),);