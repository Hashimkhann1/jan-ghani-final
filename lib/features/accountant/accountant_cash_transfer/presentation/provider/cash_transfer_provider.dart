import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/cash_transfer_remote_datasource.dart';
import '../../data/model/cash_transfer_model.dart';
import '../../data/repositories/cash_transfer_repository_impl.dart';
import '../../domain/repositories/cash_transfer_repository.dart';

final cashTransferDatasourceProvider =
    Provider<CashTransferRemoteDatasource>((ref) {
  return CashTransferRemoteDatasourceImpl(Supabase.instance.client);
});

final cashTransferRepositoryProvider =
    Provider<CashTransferRepository>((ref) {
  return CashTransferRepositoryImpl(ref.watch(cashTransferDatasourceProvider));
});

// Accountant ke saare bheje hue transfers (status ke saath)
final myCashTransfersProvider =
    FutureProvider<List<CashTransferModel>>((ref) async {
  return ref.watch(cashTransferRepositoryProvider).getMyTransfers();
});

// Selected warehouse ke transfers
final warehouseCashTransfersProvider =
    FutureProvider.family<List<CashTransferModel>, String>(
        (ref, warehouseId) async {
  return ref
      .watch(cashTransferRepositoryProvider)
      .getTransfersByWarehouse(warehouseId);
});
