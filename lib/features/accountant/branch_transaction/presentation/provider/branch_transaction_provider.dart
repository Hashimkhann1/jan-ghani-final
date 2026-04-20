import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/service/session/accountant_session.dart';
import '../../data/datasource/branch_transaction_datasource.dart';
import '../../data/model/branch_transaction_model.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────
final branchTransactionDataSourceProvider =
Provider<BranchTransactionDataSource>(
      (ref) => BranchTransactionDataSource(Supabase.instance.client),
);

// ── Filter Params ────────────────────────────────────────────────────────────
class BranchTransactionParams {
  final String    accountantId;
  final DateTime? startDate;
  final DateTime? endDate;

  const BranchTransactionParams({
    required this.accountantId,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      other is BranchTransactionParams &&
          other.accountantId == accountantId &&
          other.startDate    == startDate &&
          other.endDate      == endDate;

  @override
  int get hashCode =>
      accountantId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}

// ── State ────────────────────────────────────────────────────────────────────
class BranchTransactionState {
  final List<BranchTransactionModel> transactions;
  final bool    isLoading;
  final String? error;

  const BranchTransactionState({
    this.transactions = const [],
    this.isLoading    = false,
    this.error,
  });

  double get totalAmount =>
      transactions.fold(0, (s, t) => s + t.amount);

  BranchTransactionState copyWith({
    List<BranchTransactionModel>? transactions,
    bool?   isLoading,
    String? error,
  }) =>
      BranchTransactionState(
        transactions: transactions ?? this.transactions,
        isLoading:    isLoading    ?? this.isLoading,
        error:        error,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────
class BranchTransactionNotifier
    extends StateNotifier<BranchTransactionState> {
  final BranchTransactionDataSource _ds;
  final BranchTransactionParams _params;

  BranchTransactionNotifier(this._ds, this._params)
      : super(const BranchTransactionState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _ds.getTransactions(
        accountantId: _params.accountantId,
        startDate:    _params.startDate,
        endDate:      _params.endDate,
      );
      state = state.copyWith(transactions: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Load error: $e');
    }
  }
}

final accountantSessionDataProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  return AccountantSession.getAll();
});

final accountantCounterProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final session = await ref.watch(accountantSessionDataProvider.future);
  if (session == null) return null;

  final response = await Supabase.instance.client.from('accountant_counter').select().limit(1).maybeSingle();
  return response;
});

// ── Provider Family ───────────────────────────────────────────────────────────
final branchTransactionProvider = StateNotifierProvider.family
<BranchTransactionNotifier,
    BranchTransactionState,
    BranchTransactionParams>(
      (ref, params) => BranchTransactionNotifier(
    ref.read(branchTransactionDataSourceProvider),
    params,
  ),
);