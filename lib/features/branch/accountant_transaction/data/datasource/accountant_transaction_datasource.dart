import 'package:postgres/postgres.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/account_transaction_model.dart';
import '../model/accountant_user_model.dart';

class AccountantDataSource {
  final SupabaseClient _supabase;
  const AccountantDataSource(this._supabase);

  // ── Branch total ──────────────────────────────────────────────────────────

  Future<double> getBranchTotalAmount(String branchId) async {
    try {
      final conn = await DataBaseService.getConnection();
      final result = await conn.execute(
        Sql.named('''
          SELECT total_amount FROM public.branch_summary
          WHERE store_id = @storeId AND counter_date = CURRENT_DATE
          LIMIT 1
        '''),
        parameters: {'storeId': branchId},
      );
      if (result.isEmpty) return 0.0;
      final raw = result.first.toColumnMap()['total_amount'];
      if (raw == null) return 0.0;
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString()) ?? 0.0;
    } catch (e) {
      print('❌ getBranchTotalAmount error: $e');
      rethrow;
    }
  }

  // ── Active accountants ────────────────────────────────────────────────────

  Future<List<AccountantUserModel>> getActiveAccountants() async {
    final res = await _supabase
        .from('accountant_users')
        .select('id, name, phone, username, is_active, created_at')
        .eq('is_active', true)
        .order('name');

    return (res as List).map((u) => AccountantUserModel(
      id:          u['id']        as String,
      name:        u['name']      as String,
      phone:       u['phone']     as String?,
      username:    u['username']  as String,
      isActive:    u['is_active'] as bool? ?? true,
      createdAt:   DateTime.parse(u['created_at'] as String),
      totalAmount: 0.0,
    )).toList();
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<List<AccountantTransactionModel>> getTransactions(
      String branchId) async {
    final conn = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT
          id::text, accountant_id, accountant_name, branch_id::text,
          transaction_type, amount, description, is_synced,
          created_at, updated_at
        FROM public.accountant_transactions
        WHERE branch_id = @branchId::uuid
        ORDER BY created_at DESC
      '''),
      parameters: {'branchId': branchId},
    );

    return result
        .map((row) =>
        AccountantTransactionModel.fromRowMap(row.toColumnMap()))
        .toList();
  }

  // ── Cash Out: branch → accountant ────────────────────────────────────────

  Future<AccountantTransactionModel> cashOut({
    required String accountantId,
    required String accountantName,
    required String branchId,
    required double amount,
    required double previousAmount,
    required double remainingAmount,
    String? description,
  }) async {
    final conn = await DataBaseService.getConnection();

    // 1. Local insert (works offline)
    await conn.execute(
      Sql.named('''
        INSERT INTO accountant_transactions
          (accountant_id, accountant_name, branch_id,
           transaction_type, amount, description, is_synced)
        VALUES
          (@accId, @accName, @branchId, 'cash_in', @amount, @desc, false)
      '''),
      parameters: {
        'accId':    accountantId,
        'accName':  accountantName,
        'branchId': branchId,
        'amount':   amount,
        'desc':     description,
      },
    );

    final localRows = await conn.execute(
      Sql.named('''
        SELECT * FROM accountant_transactions
        WHERE accountant_id = @accId AND branch_id = @branchId
        ORDER BY created_at DESC LIMIT 1
      '''),
      parameters: {'accId': accountantId, 'branchId': branchId},
    );
    final localMap = localRows.first.toColumnMap();

    // 2. Supabase sync (skip if offline)
    try {
      final branchRows = await conn.execute(
        Sql.named('SELECT name FROM public.branch WHERE id = @id LIMIT 1'),
        parameters: {'id': branchId},
      );
      final branchName = branchRows.isNotEmpty
          ? (branchRows.first.toColumnMap()['name'] as String? ?? branchId)
          : branchId;

      await _supabase.from('accountant_transactions').insert({
        'accountant_id':    accountantId,
        'accountant_name':  accountantName,
        'branch_id':        branchId,
        'branch_name':      branchName,
        'transaction_type': 'cash_in',
        'amount':           amount,
        'previous_amount':  previousAmount,
        'remaining_amount': remainingAmount,
        if (description != null && description.isNotEmpty)
          'description': description,
      });

      await _supabase.rpc('update_accountant_counter', params: {
        'p_accountant_id':   accountantId,
        'p_accountant_name': accountantName,
        'p_amount':          amount,
        'p_type':            'cash_in',
      });

      await conn.execute(
        Sql.named(
            'UPDATE accountant_transactions SET is_synced = true WHERE id = @id'),
        parameters: {'id': localMap['id'].toString()},
      );

      print('✅ Supabase sync successful');
    } catch (e) {
      print('⚠️ Offline — local save hua, Supabase sync pending: $e');
    }

    return AccountantTransactionModel.fromRowMap({
      ...localMap,
      'branch_name':      '',
      'previous_amount':  previousAmount,
      'remaining_amount': remainingAmount,
    });
  }

  // ── Cash In: accountant → branch ─────────────────────────────────────────

  Future<AccountantTransactionModel> cashIn({
    required String accountantId,
    required String accountantName,
    required String branchId,
    required double amount,
    required double previousAmount,
    required double remainingAmount,
    String? description,
  }) async {
    final conn = await DataBaseService.getConnection();

    await conn.execute(
      Sql.named('''
        INSERT INTO accountant_transactions
          (accountant_id, accountant_name, branch_id,
           transaction_type, amount, description)
        VALUES
          (@accId, @accName, @branchId, 'cash_out', @amount, @desc)
      '''),
      parameters: {
        'accId':    accountantId,
        'accName':  accountantName,
        'branchId': branchId,
        'amount':   amount,
        'desc':     description,
      },
    );

    final branchRows = await conn.execute(
      Sql.named('SELECT name FROM public.branch WHERE id = @id LIMIT 1'),
      parameters: {'id': branchId},
    );
    final branchName = branchRows.isNotEmpty
        ? (branchRows.first.toColumnMap()['name'] as String? ?? branchId)
        : branchId;

    final res = await _supabase
        .from('accountant_transactions')
        .insert({
      'accountant_id':    accountantId,
      'accountant_name':  accountantName,
      'branch_id':        branchId,
      'branch_name':      branchName,
      'transaction_type': 'cash_out',
      'amount':           amount,
      'previous_amount':  previousAmount,
      'remaining_amount': remainingAmount,
      if (description != null && description.isNotEmpty)
        'description': description,
    })
        .select()
        .single();

    await _supabase.rpc('update_accountant_counter', params: {
      'p_accountant_id':   accountantId,
      'p_accountant_name': accountantName,
      'p_amount':          amount,
      'p_type':            'cash_out',
    });

    return AccountantTransactionModel.fromJson(res as Map<String, dynamic>);
  }

  // ── Sync pending ──────────────────────────────────────────────────────────

  Future<void> syncPendingTransactions() async {
    try {
      final conn = await DataBaseService.getConnection();

      final pending = await conn.execute(
        Sql.named('''
          SELECT at.*, b.name as branch_name
          FROM accountant_transactions at
          LEFT JOIN branch b ON b.id = at.branch_id
          WHERE at.is_synced = false
          ORDER BY at.created_at ASC
        '''),
      );

      if (pending.isEmpty) {
        print('✅ Koi pending sync nahi');
        return;
      }

      print('🔄 ${pending.length} transactions sync ho rahi hain...');

      for (final row in pending) {
        final m = row.toColumnMap();
        try {
          await _supabase.from('accountant_transactions').insert({
            'accountant_id':    m['accountant_id'].toString(),
            'accountant_name':  m['accountant_name'].toString(),
            'branch_id':        m['branch_id'].toString(),
            'branch_name':      m['branch_name']?.toString() ?? '',
            'transaction_type': m['transaction_type'].toString(),
            'amount':           double.tryParse(m['amount'].toString()) ?? 0,
            'description':      m['description']?.toString(),
          });

          await _supabase.rpc('update_accountant_counter', params: {
            'p_accountant_id':   m['accountant_id'].toString(),
            'p_accountant_name': m['accountant_name'].toString(),
            'p_amount':          double.tryParse(m['amount'].toString()) ?? 0,
            'p_type':            m['transaction_type'].toString(),
          });

          await conn.execute(
            Sql.named(
                'UPDATE accountant_transactions SET is_synced = true WHERE id = @id'),
            parameters: {'id': m['id'].toString()},
          );

          print('✅ Synced: ${m['id']}');
        } catch (e) {
          print('❌ Sync fail for ${m['id']}: $e');
        }
      }
    } catch (e) {
      print('❌ syncPendingTransactions error: $e');
    }
  }
}