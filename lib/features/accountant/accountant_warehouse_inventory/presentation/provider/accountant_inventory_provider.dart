import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/accountant_inventory_remote_datasource.dart';
import '../../data/model/accountant_inventory_model.dart';
import '../../data/repositories/accountant_inventory_repository_impl.dart';
import '../../domain/repositories/accountant_inventory_repository.dart';

// ── Datasource ───────────────────────────────────────────────────────────────
final accInventoryDatasourceProvider =
    Provider<AccountantInventoryRemoteDatasource>((ref) {
  return AccountantInventoryRemoteDatasourceImpl(Supabase.instance.client);
});

// ── Repository ───────────────────────────────────────────────────────────────
final accInventoryRepositoryProvider =
    Provider<AccountantInventoryRepository>((ref) {
  return AccountantInventoryRepositoryImpl(
    ref.watch(accInventoryDatasourceProvider),
  );
});

// ── Inventory list (selected warehouse) ──────────────────────────────────────
final accInventoryProvider = FutureProvider.family<
    List<AccountantInventoryModel>, String>((ref, warehouseId) async {
  return ref.watch(accInventoryRepositoryProvider).getInventory(warehouseId);
});
