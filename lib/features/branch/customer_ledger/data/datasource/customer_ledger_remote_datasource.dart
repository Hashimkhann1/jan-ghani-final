import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/customer_ledger_model.dart';

class CustomerLedgerRemoteDataSource {

  // ── GET ALL ───────────────────────────────────────────────
  Future<List<CustomerLedgerModel>> getAll(String storeId) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, customer_id, customer_name,
          counter_id, previous_amount, pay_amount,
          new_amount, notes, created_at, updated_at, deleted_at
        FROM public.customer_ledger
        WHERE store_id  = @storeId
          AND deleted_at IS NULL
        ORDER BY created_at DESC
      '''),
      parameters: {'storeId': storeId},
    );

    return result.map((r) => CustomerLedgerModel.fromMap(_toMap(r))).toList();
  }

  // ── GET BY CUSTOMER ───────────────────────────────────────
  Future<List<CustomerLedgerModel>> getByCustomer(String customerId) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, customer_id, customer_name,
          counter_id, previous_amount, pay_amount,
          new_amount, notes, created_at, updated_at, deleted_at
        FROM public.customer_ledger
        WHERE customer_id = @customerId
          AND deleted_at  IS NULL
        ORDER BY created_at DESC
      '''),
      parameters: {'customerId': customerId},
    );

    return result.map((r) => CustomerLedgerModel.fromMap(_toMap(r))).toList();
  }

  // ── ADD ───────────────────────────────────────────────────
  Future<CustomerLedgerModel> add(CustomerLedgerModel ledger) async {
    final conn = await DataBaseService.getConnection();

    await conn.runTx((tx) async {
      // 1. Ledger insert
      await tx.execute(
        Sql.named('''
          INSERT INTO public.customer_ledger (
            store_id, customer_id, customer_name,
            counter_id, previous_amount, pay_amount,
            new_amount, notes
          )
          VALUES (
            @storeId, @customerId, @customerName,
            @counterId, @previousAmount, @payAmount,
            @newAmount, @notes
          )
        '''),
        parameters: {
          'storeId':        ledger.storeId,
          'customerId':     ledger.customerId,
          'customerName':   ledger.customerName,
          'counterId':      ledger.counterId,    // ← new
          'previousAmount': ledger.previousAmount,
          'payAmount':      ledger.payAmount,
          'newAmount':      ledger.newAmount,
          'notes':          ledger.notes,
        },
      );

      // 2. Customer balance update
      await tx.execute(
        Sql.named('''
          UPDATE public.customer
          SET balance    = @newAmount,
              updated_at = NOW()
          WHERE id = @customerId
        '''),
        parameters: {
          'customerId': ledger.customerId,
          'newAmount':  ledger.newAmount,
        },
      );
    });

    // Fresh record fetch
    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, customer_id, customer_name,
          counter_id, previous_amount, pay_amount,
          new_amount, notes, created_at, updated_at, deleted_at
        FROM public.customer_ledger
        WHERE customer_id = @customerId
          AND deleted_at  IS NULL
        ORDER BY created_at DESC
        LIMIT 1
      '''),
      parameters: {'customerId': ledger.customerId},
    );

    return CustomerLedgerModel.fromMap(_toMap(result.first));
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

    // Fresh record
    final result = await conn.execute(
      Sql.named('''
      SELECT
        id, store_id, customer_id, customer_name,
        counter_id, previous_amount, pay_amount,
        new_amount, notes, created_at, updated_at, deleted_at
      FROM public.customer_ledger
      WHERE id = @id
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
      'id':             m['id']?.toString()             ?? '',
      'store_id':       m['store_id']?.toString()       ?? '',
      'customer_id':    m['customer_id']?.toString()    ?? '',
      'customer_name':  m['customer_name']?.toString()  ?? '',
      'counter_id':     m['counter_id']?.toString(),    // ← new
      'previous_amount': m['previous_amount'],
      'pay_amount':     m['pay_amount'],
      'new_amount':     m['new_amount'],
      'notes':          m['notes']?.toString(),
      'created_at':     m['created_at']?.toString()     ?? DateTime.now().toIso8601String(),
      'updated_at':     m['updated_at']?.toString()     ?? DateTime.now().toIso8601String(),
      'deleted_at':     m['deleted_at']?.toString(),
    };
  }


}