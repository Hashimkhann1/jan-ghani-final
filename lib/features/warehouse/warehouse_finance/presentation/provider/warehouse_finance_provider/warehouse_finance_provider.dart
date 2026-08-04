// =============================================================
// warehouse_finance_provider.dart
// State + Notifier + Provider — supplier_provider.dart jaisa pattern
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/data/warehouse_finance_repository.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/domain/warehouse_finance_model.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────
class WarehouseFinanceState {
  final WarehouseFinanceModel?    finance;
  final List<CashTransactionModel> transactions;
  final WarehouseFinanceSummary?  summary;
  final bool                      isLoading;
  final String?                   errorMessage;
  final String                    activeFilter;  // all / cash_in / purchase / supplier_payment / expense
  final DateTime?                 fromDate;      // date filter — start (inclusive)
  final DateTime?                 toDate;        // date filter — end (inclusive din)

  const WarehouseFinanceState({
    this.finance,
    this.transactions  = const [],
    this.summary,
    this.isLoading     = false,
    this.errorMessage,
    this.activeFilter  = 'all',
    this.fromDate,
    this.toDate,
  });

  // Filter apply karo
  List<CashTransactionModel> get filteredTransactions {
    if (activeFilter == 'all') return transactions;
    return transactions
        .where((t) => t.entryType == activeFilter)
        .toList();
  }

  WarehouseFinanceState copyWith({
    WarehouseFinanceModel?    finance,
    List<CashTransactionModel>? transactions,
    WarehouseFinanceSummary?  summary,
    bool?                     isLoading,
    String?                   errorMessage,
    String?                   activeFilter,
    DateTime?                 fromDate,
    DateTime?                 toDate,
  }) {
    return WarehouseFinanceState(
      finance:      finance      ?? this.finance,
      transactions: transactions ?? this.transactions,
      summary:      summary      ?? this.summary,
      isLoading:    isLoading    ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      activeFilter: activeFilter ?? this.activeFilter,
      fromDate:     fromDate     ?? this.fromDate,
      toDate:       toDate       ?? this.toDate,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────
class WarehouseFinanceNotifier
    extends StateNotifier<WarehouseFinanceState> {
  final WarehouseFinanceRepository _repo;

  WarehouseFinanceNotifier(this._repo)
      : super(WarehouseFinanceState(
          fromDate: _defaultFrom(), // default: last 30 din
          toDate:   _today(),
        )) {
    loadData();
  }

  // Date helpers (date-only, midnight)
  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _defaultFrom() =>
      _today().subtract(const Duration(days: 29)); // last 30 din (inclusive)

  // ── Sab data load karo (date range ke saath) ─────────────
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final from = state.fromDate ?? _defaultFrom();
      final to   = state.toDate   ?? _today();

      final results = await Future.wait([
        _repo.getOrCreate(),
        _repo.getTransactions(
          fromDate: DateTime(from.year, from.month, from.day),
          // pura "to" din shamil → agle din ki midnight se pehle
          toDate: DateTime(to.year, to.month, to.day)
              .add(const Duration(days: 1)),
          limit: 1000,
        ),
        _repo.getSummary(),
      ]);

      state = state.copyWith(
        finance:      results[0] as WarehouseFinanceModel,
        transactions: results[1] as List<CashTransactionModel>,
        summary:      results[2] as WarehouseFinanceSummary,
        isLoading:    false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Data load karne mein masla: $e',
      );
    }
  }

  // ── Filter change karo ───────────────────────────────────
  void onFilterChanged(String filter) =>
      state = state.copyWith(activeFilter: filter);

  // ── Date range change → reload ───────────────────────────
  void onDateRangeChanged(DateTime from, DateTime to) {
    state = state.copyWith(fromDate: from, toDate: to);
    loadData();
  }

  // ── Cash In entry ────────────────────────────────────────
  Future<void> addCashIn({
    required double amount,
    String?         notes,
    String?         userId,
    String?         userName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newTx = await _repo.addCashIn(
        amount:        amount,
        notes:         notes,
        createdBy:     userId,
        createdByName: userName,
      );

      // Transactions list mein add karo
      // Finance reload karo updated balance ke liye
      final updatedFinance = await _repo.getOrCreate();

      state = state.copyWith(
        finance:      updatedFinance,
        transactions: [newTx, ...state.transactions],
        summary:      state.summary == null ? null : WarehouseFinanceSummary(
          cashInHand:       updatedFinance.cashInHand,
          todayCashIn:      (state.summary?.todayCashIn ?? 0) + amount,
          todayCashOut:     state.summary?.todayCashOut ?? 0,
          thisMonthCashIn:  (state.summary?.thisMonthCashIn ?? 0) + amount,
          thisMonthCashOut: state.summary?.thisMonthCashOut ?? 0,
          totalSupplierDue: state.summary?.totalSupplierDue ?? 0,
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Cash in entry mein masla: $e',
      );
    }
  }

  // ── Supplier Payment entry ───────────────────────────────
  Future<void> addSupplierPayment({
    required double amount,
    required String supplierId,
    String?         notes,
    String?         userId,
    String?         userName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newTx = await _repo.addSupplierPayment(
        amount:        amount,
        supplierId:    supplierId,
        notes:         notes,
        createdBy:     userId,
        createdByName: userName,
      );

      final updatedFinance = await _repo.getOrCreate();

      state = state.copyWith(
        finance:      updatedFinance,
        transactions: [newTx, ...state.transactions],
        isLoading:    false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Supplier payment entry mein masla: $e',
      );
    }
  }

  // ── Purchase entry (PO se call hoga) ────────────────────
  Future<void> addPurchaseEntry({
    required double amount,
    required String poId,
    String?         notes,
    String?         userId,
    String?         userName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newTx = await _repo.addPurchaseEntry(
        amount:        amount,
        poId:          poId,
        notes:         notes,
        createdBy:     userId,
        createdByName: userName,
      );

      final updatedFinance = await _repo.getOrCreate();

      state = state.copyWith(
        finance:      updatedFinance,
        transactions: [newTx, ...state.transactions],
        isLoading:    false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Purchase entry mein masla: $e',
      );
    }
  }

  // ── Expense entry ────────────────────────────────────────
  Future<void> addExpenseEntry({
    required double amount,
    required String expenseId,
    String?         notes,
    String?         userId,
    String?         userName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newTx = await _repo.addExpenseEntry(
        amount:        amount,
        expenseId:     expenseId,
        notes:         notes,
        createdBy:     userId,
        createdByName: userName,
      );

      final updatedFinance = await _repo.getOrCreate();

      state = state.copyWith(
        finance:      updatedFinance,
        transactions: [newTx, ...state.transactions],
        isLoading:    false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Expense entry mein masla: $e',
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────
final warehouseFinanceProvider = StateNotifierProvider<
    WarehouseFinanceNotifier,
    WarehouseFinanceState>(
      (ref) => WarehouseFinanceNotifier(WarehouseFinanceRepository.instance),
);