import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/link_stores_local_datasource.dart';
import '../../data/datasources/link_stores_remote_datasource.dart';
import '../../data/models/linked_store_model/linked_store_model.dart';
import '../../data/models/store_model/store_model.dart';
import '../../data/repositories/link_stores_repository.dart';

final linkStoresRepositoryProvider = Provider<LinkStoresRepository>((ref) {
  return LinkStoresRepository(
    localDatasource: LinkStoresLocalDatasource(
      db: DatabaseService.connection,
    ),
    remoteDatasource: LinkStoresRemoteDatasource(
      supabase: Supabase.instance.client,
    ),
  );
});

final linkedStoresProvider =
FutureProvider.family<List<LinkedStoreModel>, String>(
      (ref, warehouseId) async {
    final repo = ref.watch(linkStoresRepositoryProvider);
    return await repo.getLinkedStoresFromLocal(warehouseId);
  },
);

final allStoresProvider = FutureProvider<List<StoreModel>>((ref) async {
  final repo = ref.watch(linkStoresRepositoryProvider);
  return await repo.getAllStores();
});

final linkedStoreIdsProvider =
FutureProvider.family<List<String>, String>(
      (ref, warehouseId) async {
    final repo = ref.watch(linkStoresRepositoryProvider);
    return await repo.getLinkedStoreIds(warehouseId);
  },
);

typedef LinkStoreFn = Future<void> Function({
required String warehouseId,
required String warehouseName,
required StoreModel store,
required String? linkedByName,
required String? linkedById,
});

final linkStoreProvider = Provider<LinkStoreFn>((ref) {
  final repo = ref.watch(linkStoresRepositoryProvider);

  return ({
    required String warehouseId,
    required String warehouseName,
    required StoreModel store,
    required String? linkedByName,
    required String? linkedById,
  }) async {
    await repo.linkStore(
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      store: store,
      linkedByName: linkedByName,
      linkedById: linkedById,
    );
  };
});