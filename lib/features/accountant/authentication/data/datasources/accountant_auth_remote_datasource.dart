import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/accountant_user_entity.dart';
import '../model/accountant_user_model.dart';

abstract class AccountantAuthRemoteDatasource {
  Future<AccountantUserEntity?> login({
    required String email,
    required String password,
  });
}

class AccountantAuthRemoteDatasourceImpl
    implements AccountantAuthRemoteDatasource {
  final SupabaseClient _client;
  const AccountantAuthRemoteDatasourceImpl(this._client);

  @override
  Future<AccountantUserEntity?> login({
    required String email,
    required String password,
  }) async {
    final data = await _client
        .from('users')
        .select()
        .eq('email', email)
        .eq('password', password)
        .maybeSingle();

    if (data == null) return null;

    return AccountantUserModel.fromMap(data);
  }
}