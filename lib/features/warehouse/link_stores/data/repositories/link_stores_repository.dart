import 'package:uuid/uuid.dart';
import '../datasources/link_stores_local_datasource.dart';
import '../datasources/link_stores_remote_datasource.dart';
import '../models/linked_store_model/linked_store_model.dart';
import '../models/store_model/store_model.dart';

class LinkStoresRepository {
  final LinkStoresLocalDatasource localDatasource;
  final LinkStoresRemoteDatasource remoteDatasource;

  LinkStoresRepository({
    required this.localDatasource,
    required this.remoteDatasource,
  });

  // Supabase se linked stores fetch karo
  Future<List<LinkedStoreModel>> getLinkedStores(String warehouseId) async {
    return await remoteDatasource.getLinkedStores(warehouseId);
  }

  Future<List<StoreModel>> getAllStores() async {
    return await remoteDatasource.getAllStores();
  }

  Future<List<String>> getLinkedStoreIds(String warehouseId) async {
    return await remoteDatasource.getLinkedStoreIds(warehouseId);
  }

  Future<List<LinkedStoreModel>> getLinkedStoresFromLocal(
      String warehouseId) async {
    return await localDatasource.getLinkedStores(warehouseId);
  }

  Future<void> linkStore({
    required String warehouseId,
    required String warehouseName,
    required StoreModel store,
    required String? linkedByName,
    required String? linkedById,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    // Pehle Supabase mein save karo
    await remoteDatasource.insertWarehouseStoreLink(
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      storeId: store.storeId,
      storeName: store.storeName,
      linkedByName: linkedByName,
      linkedById: linkedById,
    );

    // Phir local mein save karo
    final linkedStore = LinkedStoreModel(
      id: id,
      warehouseId: warehouseId,
      storeId: store.storeId,
      storeCode: store.storeCode,
      storeName: store.storeName,
      storeAddress: store.storeAddress,
      storePhone: store.storePhone,
      linkedByName: linkedByName,
      linkedById: linkedById,
      isActive: true,
      linkedAt: now,
    );

    await localDatasource.insertLinkedStore(linkedStore);
  }
}