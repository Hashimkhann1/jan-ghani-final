import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/accountant_transfer_remote_datasource.dart';
import '../../data/model/accountant_transfer_model.dart';
import '../../data/repositories/accountant_transfer_repository_impl.dart';
import '../../domain/repositories/accountant_transfer_repository.dart';

// ── Datasource ───────────────────────────────────────────────────────────────
final accTransferDatasourceProvider =
    Provider<AccountantTransferRemoteDatasource>((ref) {
  return AccountantTransferRemoteDatasourceImpl(Supabase.instance.client);
});

// ── Repository ───────────────────────────────────────────────────────────────
final accTransferRepositoryProvider =
    Provider<AccountantTransferRepository>((ref) {
  return AccountantTransferRepositoryImpl(
    ref.watch(accTransferDatasourceProvider),
  );
});

// ── All transfers (selected warehouse) ───────────────────────────────────────
final accAllTransfersProvider = FutureProvider.family<
    List<AccTransferModel>, String>((ref, warehouseId) async {
  return ref.watch(accTransferRepositoryProvider).getAllTransfers(warehouseId);
});

// ── Transfer items (expand) ──────────────────────────────────────────────────
final accTransferItemsProvider =
    FutureProvider.family<List<AccTransferItemModel>, String>(
        (ref, transferId) async {
  return ref.watch(accTransferRepositoryProvider).getTransferItems(transferId);
});
