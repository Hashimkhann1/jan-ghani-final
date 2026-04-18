
import 'package:jan_ghani_final/features/warehouse/link_stores/data/models/linked_store_model/linked_store_model.dart';
import 'package:postgres/postgres.dart';

class LinkStoresLocalDatasource {
  final Connection db;

  LinkStoresLocalDatasource({required this.db});

  Future<List<LinkedStoreModel>> getLinkedStores(String warehouseId) async {
    final result = await db.execute(
      Sql.named('''
        SELECT * FROM public.linked_stores
        WHERE warehouse_id = @warehouseId
        AND deleted_at IS NULL
        AND is_active = true
        ORDER BY linked_at DESC
      '''),
      parameters: {'warehouseId': warehouseId},
    );
    return result
        .map((row) => LinkedStoreModel.fromMap(row.toColumnMap()))
        .toList();
  }

  Future<void> insertLinkedStore(LinkedStoreModel store) async {
    await db.execute(
      Sql.named('''
        INSERT INTO public.linked_stores (
          id,
          warehouse_id,
          store_id,
          store_code,
          store_name,
          store_address,
          store_phone,
          manager_name,
          linked_by_id,
          linked_by_name,
          is_active,
          linked_at
        ) VALUES (
          @id,
          @warehouseId,
          @storeId,
          @storeCode,
          @storeName,
          @storeAddress,
          @storePhone,
          @managerName,
          @linkedById,
          @linkedByName,
          @isActive,
          @linkedAt
        )
      '''),
      parameters: {
        'id': store.id,
        'warehouseId': store.warehouseId,
        'storeId': store.storeId,
        'storeCode': store.storeCode,
        'storeName': store.storeName,
        'storeAddress': store.storeAddress,
        'storePhone': store.storePhone,
        'managerName': store.managerName,
        'linkedById': store.linkedById,
        'linkedByName': store.linkedByName,
        'isActive': store.isActive,
        'linkedAt': store.linkedAt.toIso8601String(),
      },
    );
  }

  Future<bool> isStoreAlreadyLinked(
      String warehouseId, String storeId) async {
    final result = await db.execute(
      Sql.named('''
        SELECT id FROM public.linked_stores
        WHERE warehouse_id = @warehouseId
        AND store_id = @storeId
        AND deleted_at IS NULL
      '''),
      parameters: {
        'warehouseId': warehouseId,
        'storeId': storeId,
      },
    );
    return result.isNotEmpty;
  }

  Future<void> unlinkStore(String warehouseId, String storeId) async {
    await db.execute(
      Sql.named('''
        UPDATE public.linked_stores
        SET is_active = false,
            deleted_at = NOW()
        WHERE warehouse_id = @warehouseId
        AND store_id = @storeId
      '''),
      parameters: {
        'warehouseId': warehouseId,
        'storeId': storeId,
      },
    );
  }
}