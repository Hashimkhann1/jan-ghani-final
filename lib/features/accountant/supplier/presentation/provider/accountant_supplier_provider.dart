import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/accountant_supplier_remote_datasource.dart';
import '../../data/model/accountant_supplier_model.dart';
import '../../data/model/accountant_supplier_detail_models.dart';
import '../../data/repositories/accountant_supplier_repository_impl.dart';
import '../../domain/repositories/accountant_supplier_repository.dart';

// ── Datasource ───────────────────────────────────────────────────────────────
final accSupplierDatasourceProvider =
    Provider<AccountantSupplierRemoteDatasource>((ref) {
  return AccountantSupplierRemoteDatasourceImpl(Supabase.instance.client);
});

// ── Repository ───────────────────────────────────────────────────────────────
final accSupplierRepositoryProvider =
    Provider<AccountantSupplierRepository>((ref) {
  return AccountantSupplierRepositoryImpl(
    ref.watch(accSupplierDatasourceProvider),
  );
});

// ── All suppliers list (selected warehouse) ──────────────────────────────────
final accSuppliersProvider = FutureProvider.family<
    List<AccountantSupplierModel>, String>((ref, warehouseId) async {
  return ref.watch(accSupplierRepositoryProvider).getAllSuppliers(warehouseId);
});

// ── Ledger (Transactions) of a supplier ──────────────────────────────────────
final accSupplierLedgerProvider = FutureProvider.family<
    List<AccSupplierLedgerEntry>, String>((ref, supplierId) async {
  return ref.watch(accSupplierRepositoryProvider).getLedger(supplierId);
});

// ── Orders of a supplier ─────────────────────────────────────────────────────
final accSupplierOrdersProvider =
    FutureProvider.family<List<AccSupplierOrder>, String>(
        (ref, supplierId) async {
  return ref.watch(accSupplierRepositoryProvider).getOrders(supplierId);
});

// ── Order items (PO expand) ──────────────────────────────────────────────────
final accSupplierOrderItemsProvider =
    FutureProvider.family<List<AccSupplierOrderItem>, String>(
        (ref, poId) async {
  return ref.watch(accSupplierRepositoryProvider).getOrderItems(poId);
});
