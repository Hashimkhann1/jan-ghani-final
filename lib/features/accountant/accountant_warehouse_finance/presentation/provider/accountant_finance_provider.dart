import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/accountant_finance_remote_datasource.dart';
import '../../data/model/accountant_finance_model.dart';
import '../../data/repositories/accountant_finance_repository_impl.dart';
import '../../domain/repositories/accountant_finance_repository.dart';

final accFinanceDatasourceProvider =
    Provider<AccountantFinanceRemoteDatasource>((ref) {
  return AccountantFinanceRemoteDatasourceImpl(Supabase.instance.client);
});

final accFinanceRepositoryProvider =
    Provider<AccountantFinanceRepository>((ref) {
  return AccountantFinanceRepositoryImpl(
    ref.watch(accFinanceDatasourceProvider),
  );
});

// ── Summary (selected warehouse) ─────────────────────────────────────────────
final accFinanceSummaryProvider =
    FutureProvider.family<AccFinanceSummary, String>((ref, warehouseId) async {
  return ref.watch(accFinanceRepositoryProvider).getSummary(warehouseId);
});

// ── Cash transactions (selected warehouse) ───────────────────────────────────
final accFinanceTransactionsProvider = FutureProvider.family<
    List<AccCashTransactionModel>, String>((ref, warehouseId) async {
  return ref.watch(accFinanceRepositoryProvider).getTransactions(warehouseId);
});
