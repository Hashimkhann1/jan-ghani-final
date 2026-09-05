// customer_ledger_remote_datasource.dart
import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';
import '../model/customer_ledger_model.dart';

class CustomerLedgerRemoteDataSource {

  /// `from`/`to` diye jayein to sirf usi date range ka data DB se load
  /// hota hai (poori history nahi) — screen default current month
  /// bhejta hai taake load fast rahe.
  Future<List<CustomerLedgerModel>> getAll(
    String storeId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          cl.id, cl.store_id, cl.customer_id, cl.customer_name,
          cl.counter_id, cl.user_id, cl.previous_amount, cl.pay_amount,
          cl.new_amount, cl.notes, cl.created_at, cl.updated_at, cl.deleted_at,
          bu.full_name AS user_full_name
        FROM public.customer_ledger cl
        LEFT JOIN public.branch_users bu ON bu.id = cl.user_id
        WHERE cl.store_id  = @storeId
          AND cl.deleted_at IS NULL
          ${from != null ? 'AND cl.created_at::date >= @fromDate' : ''}
          ${to   != null ? 'AND cl.created_at::date <= @toDate'   : ''}
        ORDER BY cl.created_at DESC
      '''),
      parameters: {
        'storeId': storeId,
        if (from != null) 'fromDate': _dateOnly(from),
        if (to   != null) 'toDate':   _dateOnly(to),
      },
    );

    return result.map((r) => CustomerLedgerModel.fromMap(_toMap(r))).toList();
  }

  static String _dateOnly(DateTime d) => d.toIso8601String().substring(0, 10);

  // ── GET BY CUSTOMER ───────────────────────────────────────
  Future<List<CustomerLedgerModel>> getByCustomer(String customerId) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          cl.id, cl.store_id, cl.customer_id, cl.customer_name,
          cl.counter_id, cl.user_id, cl.previous_amount, cl.pay_amount,
          cl.new_amount, cl.notes, cl.created_at, cl.updated_at, cl.deleted_at,
          bu.full_name AS user_full_name
        FROM public.customer_ledger cl
        LEFT JOIN public.branch_users bu ON bu.id = cl.user_id
        WHERE cl.customer_id = @customerId
          AND cl.deleted_at  IS NULL
        ORDER BY cl.created_at DESC
      '''),
      parameters: {'customerId': customerId},
    );

    return result.map((r) => CustomerLedgerModel.fromMap(_toMap(r))).toList();
  }

  // ── ADD ───────────────────────────────────────────────────
  Future<CustomerLedgerModel> add(CustomerLedgerModel ledger) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
      INSERT INTO public.customer_ledger (
        store_id, customer_id, customer_name,
        counter_id, user_id, pay_amount, notes
      )
      VALUES (
        @storeId, @customerId, @customerName,
        @counterId, @userId, @payAmount, @notes
      )
      RETURNING id
    '''),
      parameters: {
        'storeId':      ledger.storeId,
        'customerId':   ledger.customerId,
        'customerName': ledger.customerName,
        'counterId':    ledger.counterId,
        'userId':       ledger.userId,
        'payAmount':    ledger.payAmount,
        'notes':        ledger.notes,
      },
    );

    final newId = result.first.toColumnMap()['id'].toString();

    // user_full_name ke saath fresh record fetch karo
    final fresh = await conn.execute(
      Sql.named('''
        SELECT
          cl.id, cl.store_id, cl.customer_id, cl.customer_name,
          cl.counter_id, cl.user_id, cl.previous_amount, cl.pay_amount,
          cl.new_amount, cl.notes, cl.created_at, cl.updated_at, cl.deleted_at,
          bu.full_name AS user_full_name
        FROM public.customer_ledger cl
        LEFT JOIN public.branch_users bu ON bu.id = cl.user_id
        WHERE cl.id = @id
      '''),
      parameters: {'id': newId},
    );

    return CustomerLedgerModel.fromMap(_toMap(fresh.first));
  }

  Future<CustomerLedgerModel> update({
    required String  id,
    required double  payAmount,
    required double  newAmount,
    String?          notes,
  }) async {
    final conn = await DataBaseService.getConnection();

    await conn.runTx((tx) async {
      // 1. Ledger update
      await tx.execute(
        Sql.named('''
        UPDATE public.customer_ledger
        SET pay_amount  = @payAmount,
            new_amount  = @newAmount,
            notes       = @notes,
            updated_at  = NOW()
        WHERE id = @id
      '''),
        parameters: {
          'id':        id,
          'payAmount': payAmount,
          'newAmount': newAmount,
          'notes':     notes,
        },
      );

      // 2. Customer balance update
      final ledgerResult = await tx.execute(
        Sql.named('''
        SELECT customer_id FROM public.customer_ledger WHERE id = @id
      '''),
        parameters: {'id': id},
      );

      final customerId =
      ledgerResult.first.toColumnMap()['customer_id'].toString();

      await tx.execute(
        Sql.named('''
        UPDATE public.customer
        SET balance    = @newAmount,
            updated_at = NOW()
        WHERE id = @customerId
      '''),
        parameters: {
          'customerId': customerId,
          'newAmount':  newAmount,
        },
      );
    });

    // Fresh record (joined)
    final result = await conn.execute(
      Sql.named('''
      SELECT
        cl.id, cl.store_id, cl.customer_id, cl.customer_name,
        cl.counter_id, cl.user_id, cl.previous_amount, cl.pay_amount,
        cl.new_amount, cl.notes, cl.created_at, cl.updated_at, cl.deleted_at,
        bu.full_name AS user_full_name
      FROM public.customer_ledger cl
      LEFT JOIN public.branch_users bu ON bu.id = cl.user_id
      WHERE cl.id = @id
    '''),
      parameters: {'id': id},
    );

    return CustomerLedgerModel.fromMap(_toMap(result.first));
  }

  // ── SOFT DELETE ───────────────────────────────────────────
  Future<void> delete(String id) async {
    final conn = await DataBaseService.getConnection();

    await conn.execute(
      Sql.named('''
        UPDATE public.customer_ledger
        SET deleted_at = NOW(), updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );
  }

  // ── ROW → MAP ─────────────────────────────────────────────
  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':              m['id']?.toString()              ?? '',
      'store_id':        m['store_id']?.toString()        ?? '',
      'customer_id':     m['customer_id']?.toString()     ?? '',
      'customer_name':   m['customer_name']?.toString()   ?? '',
      'counter_id':      m['counter_id']?.toString(),
      'user_id':         m['user_id']?.toString(),
      'user_full_name':  m['user_full_name']?.toString(),   // ← new
      'previous_amount': m['previous_amount'],
      'pay_amount':      m['pay_amount'],
      'new_amount':      m['new_amount'],
      'notes':           m['notes']?.toString(),
      'created_at':      m['created_at']?.toString()     ?? DateTime.now().toIso8601String(),
      'updated_at':      m['updated_at']?.toString()     ?? DateTime.now().toIso8601String(),
      'deleted_at':      m['deleted_at']?.toString(),
    };
  }
}