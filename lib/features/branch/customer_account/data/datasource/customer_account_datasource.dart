import 'dart:math';
import 'package:postgres/postgres.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/service/db/db_service.dart';
import '../../../customer/data/model/customer_model.dart';
import '../model/customer_account_model.dart';


class CustomerAccountDatasource {
  final _supabase = Supabase.instance.client;

  // ── GET ALL CUSTOMERS (PostgreSQL) ────────────────────────
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

    return result.map((row) => CustomerModel.fromMap(_pgToMap(row))).toList();
  }

  // ── GET STORE CUSTOMER ACCOUNTS (Supabase) ────────────────
  Future<List<CustomerAccountModel>> getStoreAccounts(String storeId) async {
    // Step 1: PostgreSQL se is store ke saare customer IDs lo
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

    // Step 2: Supabase se customer_token IN customerIds wale users lo
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
    await _supabase.from('users').insert({
      'id':             _uuid(),       // manually generate karo
      'full_name':      fullName,
      'email':          email,
      'role':           'customer',
      'branch_id':      null,
      'warehouse_id':   null,
      'customer_token': customerId,    // customer.id yahan store hoga
      'password':       password,
    });
  }

  // ── UPDATE PASSWORD (Supabase) ────────────────────────────
  Future<void> updatePassword({
    required String userId,
    required String newPassword,
  }) async {
    await _supabase
        .from('users')
        .update({
      'password':   newPassword,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', userId);
  }

  // ── UUID v4 generator (dart:math) ─────────────────────────
  String _uuid() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).toList();
    return '${b[0]}${b[1]}${b[2]}${b[3]}-'
        '${b[4]}${b[5]}-'
        '${b[6]}${b[7]}-'
        '${b[8]}${b[9]}-'
        '${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
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
