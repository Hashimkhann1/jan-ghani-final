import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/branch_model.dart';

class BranchDatasource {
  final SupabaseClient _client;

  BranchDatasource(this._client);

  Future<BranchModel?> getBranchById(String branchId) async {
    final res = await _client
        .from('branch')
        .select()
        .eq('id', branchId)
        .maybeSingle();

    if (res == null) return null;
    return BranchModel.fromMap(res);
  }
}