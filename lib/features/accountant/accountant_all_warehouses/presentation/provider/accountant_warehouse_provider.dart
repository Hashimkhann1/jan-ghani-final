import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/accountant_warehouse_remote_datasource.dart';
import '../../data/model/accountant_warehouse_model.dart';
import '../../data/repositories/accountant_warehouse_repository_impl.dart';
import '../../domain/repositories/accountant_warehouse_repository.dart';

final accWarehouseDatasourceProvider =
    Provider<AccountantWarehouseRemoteDatasource>((ref) {
  return AccountantWarehouseRemoteDatasourceImpl(Supabase.instance.client);
});

final accWarehouseRepositoryProvider =
    Provider<AccountantWarehouseRepository>((ref) {
  return AccountantWarehouseRepositoryImpl(
    ref.watch(accWarehouseDatasourceProvider),
  );
});

final accAllWarehousesProvider =
    FutureProvider<List<AccountantWarehouseModel>>((ref) async {
  return ref.watch(accWarehouseRepositoryProvider).getAllWarehouses();
});
