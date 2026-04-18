import 'package:jan_ghani_final/features/warehouse/link_stores/data/models/linked_store_model/linked_store_model.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/data/models/store_model/store_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class LinkStoresRemoteDatasource {
  final SupabaseClient supabase;

  LinkStoresRemoteDatasource({required this.supabase});

  Future<List<StoreModel>> getAllStores() async {
    final response = await supabase
        .from('branch')
        .select()
        .eq('is_active', true)
        .isFilter('deleted_at', null)
        .order('name', ascending: true);

    return (response as List)
        .map((map) => StoreModel.fromMap(map))
        .toList();
  }

  Future<List<String>> getLinkedStoreIds(String warehouseId) async {
    final response = await supabase
        .from('warehouse_store_links')
        .select('store_id')
        .eq('warehouse_id', warehouseId)
        .eq('is_active', true);

    return (response as List)
        .map((map) => map['store_id'] as String)
        .toList();
  }

  Future<List<LinkedStoreModel>> getLinkedStores(String warehouseId) async {
    final response = await supabase
        .from('warehouse_store_links')
        .select('''
          id,
          warehouse_id,
          store_id,
          store_name,
          warehouse_name,
          is_active,
          linked_by_id,
          linked_by_name,
          linked_at,
          stores (
            code,
            phone,
            address
          )
        ''')
        .eq('warehouse_id', warehouseId)
        .eq('is_active', true)
        .order('linked_at', ascending: false);

    return (response as List).map((map) {
      final storeDetails = map['branch'] as Map<String, dynamic>?;
      return LinkedStoreModel.fromMap({
        'id': map['id'],
        'warehouse_id': map['warehouse_id'],
        'store_id': map['store_id'],
        'store_code': storeDetails?['code'] ?? '',
        'store_name': map['store_name'],
        'store_address': storeDetails?['address'],
        'store_phone': storeDetails?['phone'],
        'manager_name': null,
        'linked_by_name': map['linked_by_name'],
        'linked_by_id': map['linked_by_id'],
        'is_active': map['is_active'],
        'linked_at': map['linked_at'],
        'deleted_at': null,
      });
    }).toList();
  }

  Future<void> insertWarehouseStoreLink({
    required String warehouseId,
    required String warehouseName,
    required String storeId,
    required String storeName,
    required String? linkedByName,
    required String? linkedById,
  }) async {
    await supabase.from('warehouse_store_links').insert({
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'store_id': storeId,
      'store_name': storeName,
      'linked_by_name': linkedByName,
      'linked_by_id': linkedById,
      'is_active': true,
      'linked_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unlinkStore(String warehouseId, String storeId) async {
    await supabase
        .from('warehouse_store_links')
        .update({'is_active': false})
        .eq('warehouse_id', warehouseId)
        .eq('store_id', storeId);
  }
}