import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/customer_model.dart';

class CustomerRemoteDataSource {

  // ── GET ALL ───────────────────────────────────────────────
  Future<List<CustomerModel>> getAll(String storeId) async {
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
        ORDER BY created_at DESC
      '''),
      parameters: {'storeId': storeId},
    );

    return result.map((row) => CustomerModel.fromMap(_toMap(row))).toList();
  }

  // ── GET BY ID ─────────────────────────────────────────────
  Future<CustomerModel?> getById(String id) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, store_id, code, name, phone, address,
          customer_type, credit_limit, is_active, notes,
          created_at, updated_at, deleted_at, synced_at,
          balance
        FROM public.customer
        WHERE id = @id
          AND deleted_at IS NULL
        LIMIT 1
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return CustomerModel.fromMap(_toMap(result.first));
  }

  // ── ADD ───────────────────────────────────────────────────
  Future<CustomerModel> add(CustomerModel customer) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        INSERT INTO public.customer (
          store_id, code, name, phone, address,
          customer_type, credit_limit, is_active, notes
        )
        VALUES (
          @storeId, @code, @name, @phone, @address,
          @customerType, @creditLimit, @isActive, @notes
        )
        RETURNING *
      '''),
      parameters: {
        'storeId':      customer.storeId,
        'code':         customer.code,
        'name':         customer.name,
        'phone':        customer.phone,
        'address':      customer.address,
        'customerType': customer.customerType,
        'creditLimit':  customer.creditLimit,
        'isActive':     customer.isActive,
        'notes':        customer.notes,
      },
    );

    return CustomerModel.fromMap(_toMap(result.first));
  }

  // ── UPDATE ────────────────────────────────────────────────
  Future<CustomerModel> update(CustomerModel customer) async {
    final conn = await DataBaseService.getConnection();

    await conn.execute(
      Sql.named('''
        UPDATE public.customer SET
          name          = @name,
          phone         = @phone,
          address       = @address,
          customer_type = @customerType,
          credit_limit  = @creditLimit,
          is_active     = @isActive,
          notes         = @notes,
          updated_at    = NOW()
        WHERE id = @id
      '''),
      parameters: {
        'id':           customer.id,
        'name':         customer.name,
        'phone':        customer.phone,
        'address':      customer.address,
        'customerType': customer.customerType,
        'creditLimit':  customer.creditLimit,
        'isActive':     customer.isActive,
        'notes':        customer.notes,
      },
    );

    return (await getById(customer.id))!;
  }

  // ── SOFT DELETE ───────────────────────────────────────────
  Future<void> delete(String id) async {
    final conn = await DataBaseService.getConnection();

    await conn.execute(
      Sql.named('''
        UPDATE public.customer
        SET deleted_at = NOW(),
            updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );
  }

  // ── GENERATE NEXT CODE ────────────────────────────────────
  Future<String> generateCode(String storeId) async {
    final conn = await DataBaseService.getConnection();

    final result = await conn.execute(
      Sql.named('''
        SELECT COALESCE(
          MAX(CAST(SUBSTRING(code FROM 6) AS INTEGER)), 0
        ) + 1 AS next_num
        FROM public.customer
        WHERE store_id = @storeId
          AND code LIKE 'CUST-%'
      '''),
      parameters: {'storeId': storeId},
    );

    final nextNum = result.first[0] as int? ?? 1;
    return 'CUST-${nextNum.toString().padLeft(4, '0')}';
  }

  // ── ROW → MAP ─────────────────────────────────────────────
  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':           m['id']?.toString()            ?? '',
      'store_id':     m['store_id']?.toString()      ?? '',
      'code':         m['code']?.toString()           ?? '',
      'name':         m['name']?.toString()           ?? '',
      'phone':        m['phone']?.toString()          ?? '',
      'address':      m['address']?.toString(),
      'customer_type': m['customer_type']?.toString() ?? 'walkin',
      'credit_limit': m['credit_limit'],
      'is_active':    m['is_active']                 ?? true,
      'notes':        m['notes']?.toString(),
      'created_at':   m['created_at']?.toString()    ?? DateTime.now().toIso8601String(),
      'updated_at':   m['updated_at']?.toString()    ?? DateTime.now().toIso8601String(),
      'deleted_at':   m['deleted_at']?.toString(),
      'synced_at':    m['synced_at']?.toString(),
      'balance':      m['balance'],
    };
  }
}