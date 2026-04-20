import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/service/session/accountant_session.dart';
import '../../data/datasources/investment_remote_datasource.dart';
import '../../data/model/investment_model.dart';
import '../../data/repositories/investment_repository_impl.dart';
import '../../domain/repositories/investment_repository.dart';

// ── Datasource ────────────────────────────────────────────────────────────────
final investmentDatasourceProvider = Provider<InvestmentRemoteDatasource>((ref) {
  return InvestmentRemoteDatasourceImpl(Supabase.instance.client);
});

// ── Repository ────────────────────────────────────────────────────────────────
final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  return InvestmentRepositoryImpl(ref.watch(investmentDatasourceProvider));
});

// ── Investments list ──────────────────────────────────────────────────────────
final investmentsProvider = FutureProvider<List<InvestmentModel>>((ref) async {
  final id = await AccountantSession.getId();
  if (id == null) return [];
  return ref
      .watch(investmentRepositoryProvider)
      .getInvestments(accountantId: id);
});

// ── Add investment notifier ───────────────────────────────────────────────────
class AddInvestmentNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> add({
    required String name,
    required double amount,
    String? note,
  }) async {
    state = const AsyncLoading();
    try {
      final id = await AccountantSession.getId();
      if (id == null) return false;

      await ref.read(investmentRepositoryProvider).addInvestment(
        accountantId: id,
        name:         name,
        amount:       amount,
        note:         note,
      );

      // List refresh karo
      ref.invalidate(investmentsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

final addInvestmentProvider =
AsyncNotifierProvider<AddInvestmentNotifier, void>(
  AddInvestmentNotifier.new,
);