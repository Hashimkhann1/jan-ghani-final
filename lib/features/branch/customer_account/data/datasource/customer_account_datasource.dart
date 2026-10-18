import 'package:postgres/postgres.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/service/db/db_service.dart';
import '../../../customer/data/model/customer_model.dart';
import '../model/customer_account_model.dart';


class CustomerAccountDatasource {
  final _supabase = Supabase.instance.client;

  // ── GET CUSTOMERS FOR DROPDOWN (PostgreSQL) ────────────────
  // store_id se filter, aur jo account ban chuke hain wo nahi aayenge
  Future<List<CustomerModel>> getCustomers(String storeId) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, code, name, phone, address,
          customer_type, credit_limit, is_active, notes,
          created_at, updated_at, deleted_at, synced_at,
          balance
        FROM public.customer
        WHERE store_id  = @storeId
          AND deleted_at IS NULL
        ORDER BY name ASC
      '''),
      parameters: {'storeId': storeId},
    );

    if (result.isEmpty) return [];

    final allCustomers =
    result.map((row) => CustomerModel.fromMap(_pgToMap(row))).toList();

    // Jo customers ka Supabase mein account already hai unke IDs lo
    final allIds = allCustomers.map((c) => c.id).toList();

    final existingAccounts = await _supabase
        .from('users')
        .select('customer_token')
        .eq('role', 'customer')
        .inFilter('customer_token', allIds);

    final existingTokens = (existingAccounts as List)
        .map((row) => row['customer_token']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    // Account ban chuke customers ko dropdown se hatao
    return allCustomers
        .where((c) => !existingTokens.contains(c.id))
        .toList();
  }

  // ── GET STORE CUSTOMER ACCOUNTS (Supabase) ────────────────
  Future<List<CustomerAccountModel>> getStoreAccounts(String storeId) async {
    final conn     = await DataBaseService.getConnection();
    final pgResult = await conn.execute(
      Sql.named('''
        SELECT id FROM public.customer
        WHERE store_id  = @storeId
          AND deleted_at IS NULL
      '''),
      parameters: {'storeId': storeId},
    );

    if (pgResult.isEmpty) return [];

    final customerIds = pgResult
        .map((row) => row.toColumnMap()['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final sbResult = await _supabase
        .from('users')
        .select('id, full_name, email, password, customer_token, created_at, updated_at')
        .eq('role', 'customer')
        .inFilter('customer_token', customerIds)
        .order('created_at', ascending: false);

    return (sbResult as List)
        .map((row) => CustomerAccountModel.fromMap(row))
        .toList();
  }

  // ── CHECK IF ACCOUNT ALREADY EXISTS (Supabase) ───────────
  Future<bool> accountExists(String customerId) async {
    final result = await _supabase
        .from('users')
        .select('id')
        .eq('customer_token', customerId)
        .eq('role', 'customer')
        .maybeSingle();

    return result != null;
  }

  // ── CREATE CUSTOMER ACCOUNT (Supabase) ───────────────────
  Future<void> createAccount({
    required String customerId,
    required String fullName,
    required String email,
    required String password,
  }) async {
    // Asli Supabase Auth user banta hai (auth.users) aur customer se link hota hai
    await _supabase.rpc('create_customer_account', params: {
      'p_customer_id': customerId,
      'p_full_name':   fullName,
      'p_email':       email,
      'p_password':    password,
    });
  }

  // ── UPDATE PASSWORD (Supabase) ────────────────────────────
  Future<void> updatePassword({
    required String userId,
    required String newPassword,
  }) async {
    await _supabase.rpc('update_customer_account_password', params: {
      'p_user_id':      userId,
      'p_new_password': newPassword,
    });
  }

  // ── UPDATE NAME / EMAIL (Supabase Auth + users) ──────────
  Future<void> updateAccount({
    required String userId,
    required String fullName,
    required String email,
  }) async {
    await _supabase.rpc('update_customer_account', params: {
      'p_user_id':   userId,
      'p_full_name': fullName,
      'p_email':     email,
    });
  }

  // ── DELETE ACCOUNT (Supabase Auth + users) ────────────────
  Future<void> deleteAccount(String userId) async {
    await _supabase.rpc('delete_customer_account', params: {
      'p_user_id': userId,
    });
  }

  // ── PostgreSQL ROW → MAP ──────────────────────────────────
  Map<String, dynamic> _pgToMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':            m['id']?.toString()            ?? '',
      'store_id':      m['store_id']?.toString()      ?? '',
      'code':          m['code']?.toString()           ?? '',
      'name':          m['name']?.toString()           ?? '',
      'phone':         m['phone']?.toString()          ?? '',
      'address':       m['address']?.toString(),
      'customer_type': m['customer_type']?.toString() ?? 'walkin',
      'credit_limit':  m['credit_limit'],
      'is_active':     m['is_active']                 ?? true,
      'notes':         m['notes']?.toString(),
      'created_at':    m['created_at']?.toString()    ?? DateTime.now().toIso8601String(),
      'updated_at':    m['updated_at']?.toString()    ?? DateTime.now().toIso8601String(),
      'deleted_at':    m['deleted_at']?.toString(),
      'synced_at':     m['synced_at']?.toString(),
      'balance':       m['balance'],
    };
  }
}