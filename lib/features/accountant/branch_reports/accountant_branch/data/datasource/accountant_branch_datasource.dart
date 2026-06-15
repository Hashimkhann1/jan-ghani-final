import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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

  // ── NEW: Create branch ──────────────────────────────────
  Future<BranchModel> createBranch({
    required String code,
    required String name,
    required String address,
    required String phone,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final row = await _client
        .from('branch')
        .insert({
      'id':         const Uuid().v4(),
      'code':       code,
      'name':       name,
      'address':    address,
      'phone':      phone,
      'is_active':  true,
      'created_at': now,
      'updated_at': now,
    })
        .select('id, code, name, address, phone, is_active, created_at')
        .single();

    return BranchModel.fromMap(row);
  }
}