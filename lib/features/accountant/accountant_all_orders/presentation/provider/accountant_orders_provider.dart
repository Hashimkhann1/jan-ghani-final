import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/accountant_orders_remote_datasource.dart';
import '../../data/model/accountant_order_model.dart';
import '../../data/repositories/accountant_orders_repository_impl.dart';
import '../../domain/repositories/accountant_orders_repository.dart';

// ── Datasource ───────────────────────────────────────────────────────────────
final accOrdersDatasourceProvider =
    Provider<AccountantOrdersRemoteDatasource>((ref) {
  return AccountantOrdersRemoteDatasourceImpl(Supabase.instance.client);
});

// ── Repository ───────────────────────────────────────────────────────────────
final accOrdersRepositoryProvider =
    Provider<AccountantOrdersRepository>((ref) {
  return AccountantOrdersRepositoryImpl(
    ref.watch(accOrdersDatasourceProvider),
  );
});

// ── All orders (selected warehouse) ──────────────────────────────────────────
final accAllOrdersProvider =
    FutureProvider.family<List<AccOrderModel>, String>((ref, warehouseId) async {
  return ref.watch(accOrdersRepositoryProvider).getAllOrders(warehouseId);
});

// ── Order items (expand) ─────────────────────────────────────────────────────
final accOrderItemsProvider =
    FutureProvider.family<List<AccOrderItemModel>, String>((ref, poId) async {
  return ref.watch(accOrdersRepositoryProvider).getOrderItems(poId);
});
