import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_warehouse_model.dart';

abstract class AccountantWarehouseRemoteDatasource {
  Future<List<AccountantWarehouseModel>> getAllWarehouses();
}

class AccountantWarehouseRemoteDatasourceImpl
    implements AccountantWarehouseRemoteDatasource {
  final SupabaseClient _client;
  const AccountantWarehouseRemoteDatasourceImpl(this._client);

  @override
  Future<List<AccountantWarehouseModel>> getAllWarehouses() async {
    try {
      final res = await _client
          .from('warehouses')
          .select('id, name, code, address, phone, is_active')
          .filter('deleted_at', 'is', null)
          .order('name', ascending: true);

      return (res as List)
          .map((e) =>
              AccountantWarehouseModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getAllWarehouses error: $e');
      rethrow;
    }
  }
}
