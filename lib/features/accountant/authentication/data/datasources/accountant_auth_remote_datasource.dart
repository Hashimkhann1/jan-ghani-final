import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_user_model.dart';

abstract class AccountantAuthRemoteDatasource {
  Future<AccountantUserModel?> login({
    required String username,
    required String password,
  });
}

class AccountantAuthRemoteDatasourceImpl
    implements AccountantAuthRemoteDatasource {
  final SupabaseClient _client;
  AccountantAuthRemoteDatasourceImpl(this._client);

  @override
  Future<AccountantUserModel?> login({
    required String username,
    required String password,
  }) async {
    final response = await _client
        .from('accountant_users')
        .select()
        .eq('username', username)
        .eq('password', password)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return AccountantUserModel.fromMap(response);
  }
}