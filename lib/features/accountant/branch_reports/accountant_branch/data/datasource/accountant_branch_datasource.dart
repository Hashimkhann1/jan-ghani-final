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

  /// Branch + us ka default manager user ek saath banata hai
  Future<BranchModel> createBranch({
    required String code,
    required String name,
    required String address,
    required String phone,
    // Manager user fields
    required String managerUsername,
    required String managerPassword,
    required String managerFullName,
    required String managerPhone,
  }) async {
    final now      = DateTime.now().toUtc().toIso8601String();
    final branchId = const Uuid().v4();
    final userId   = const Uuid().v4();

    // 1️⃣ Branch insert
    final row = await _client
        .from('branch')
        .insert({
      'id':         branchId,
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

    // 2️⃣ Branch user insert (store_manager)
    await _client.from('branch_users').insert({
      'id':            userId,
      'store_id':      branchId,
      'username':      managerUsername.trim(),
      'password_hash': managerPassword.trim(),
      'full_name':     managerFullName.trim(),
      'phone':         managerPhone.trim(),
      'role':          'store_manager',
      'is_active':     true,
      'counter_id':    null,
      'created_at':    now,
      'updated_at':    now,
    });

    return BranchModel.fromMap(row);
  }
}