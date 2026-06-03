import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_branch_model.dart';

class BranchDatasource {
  final SupabaseClient _client;

  BranchDatasource({required SupabaseClient client}) : _client = client;

  Future<List<BranchModel>> fetchBranches() async {
    final rows = await _client
        .from('branch')
        .select('id, code, name, address, phone, is_active, created_at')
        .isFilter('deleted_at', null)
        .eq('is_active', true)
        .order('name', ascending: true);

    return (rows as List)
        .map((r) => BranchModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}