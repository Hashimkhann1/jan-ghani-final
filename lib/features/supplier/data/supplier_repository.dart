// =============================================================
// supplier_repository.dart
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/features/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/warehouse_finance/data/warehouse_finance_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

class SupplierRepository {
  static final SupplierRepository instance = SupplierRepository._();
  SupplierRepository._();

  Future<Connection> get _db => DatabaseService.getConnection();
  String get _wid => AppConfig.warehouseId;

  // ── Shared SELECT query ───────────────────────────────────
  // Ek jagah likha — getAll aur getById dono use karte hain
  static const String _selectQuery = '''
    SELECT
      s.id,
      s.warehouse_id,
      s.name,
      s.company_name,
      s.contact_person,
      s.email,
      s.phone,
      s.address,
      s.code,
      s.tax_id,
      s.payment_terms,
      s.is_active,
      s.notes,
      s.created_at,
      s.updated_at,
      s.deleted_at,
      s.outstanding_balance,
      s.created_by,
      u.full_name AS created_by_name,
      COALESCE(po_agg.total_orders,    0) AS total_orders,
      COALESCE(po_agg.total_purchased, 0) AS total_purchase_amount
    FROM suppliers s
    LEFT JOIN users u ON u.id = s.created_by
    LEFT JOIN (
      SELECT
        supplier_id,
        COUNT(*)          AS total_orders,
        SUM(total_amount) AS total_purchased
      FROM purchase_orders
      WHERE warehouse_id = @wid
        AND deleted_at   IS NULL
        AND status       = 'received'
      GROUP BY supplier_id
    ) po_agg ON po_agg.supplier_id = s.id
  ''';

  // ==========================================================
  // 1. GET ALL SUPPLIERS
  // ==========================================================
  Future<List<SupplierModel>> getAll() async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        $_selectQuery
        WHERE s.warehouse_id = @wid
          AND s.deleted_at   IS NULL
        ORDER BY s.created_at DESC
      '''),
      parameters: {'wid': _wid},
    );

    return result
        .map((row) => SupplierModel.fromMap(row.toColumnMap()))
        .toList();
  }

  // ==========================================================
  // 2. GET SINGLE SUPPLIER BY ID
  // ==========================================================
  Future<SupplierModel?> getById(String supplierId) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        $_selectQuery
        WHERE s.id           = @id
          AND s.warehouse_id = @wid
          AND s.deleted_at   IS NULL
        LIMIT 1
      '''),
      parameters: {'id': supplierId, 'wid': _wid},
    );

    if (result.isEmpty) return null;
    return SupplierModel.fromMap(result.first.toColumnMap());
  }

  // ==========================================================
  // 3. INSERT — naya supplier add karo
  // Agar opening balance > 0 ho toh ledger mein entry bhi dalo
  // ==========================================================
  Future<SupplierModel> insert(SupplierModel supplier,
      {double openingBalance = 0}) async {
    final conn = await _db;

    final code = await _generateCode();

    // Step 1: Supplier save karo
    await conn.execute(
      Sql.named('''
        INSERT INTO suppliers (
          id,           warehouse_id,   name,
          company_name, contact_person, email,
          phone,        address,        code,
          tax_id,       payment_terms,  is_active,
          notes,        created_by
        ) VALUES (
          @id,          @wid,           @name,
          @companyName, @contactPerson, @email,
          @phone,       @address,       @code,
          @taxId,       @paymentTerms,  @isActive,
          @notes,       @createdBy
        )
      '''),
      parameters: {
        'id':            supplier.id,
        'wid':           _wid,
        'name':          supplier.name,
        'companyName':   supplier.companyName,
        'contactPerson': supplier.contactPerson,
        'email':         supplier.email,
        'phone':         supplier.phone,
        'address':       supplier.address,
        'code':          code,
        'taxId':         supplier.taxId,
        'paymentTerms':  supplier.paymentTerms,
        'isActive':      supplier.isActive,
        'notes':         supplier.notes,
        'createdBy':     supplier.createdById,
      },
    );

    // Step 2: Agar opening balance > 0 toh ledger mein entry dalo
    // Trigger outstanding_balance apne aap update karega
    if (openingBalance > 0) {
      await conn.execute(
        Sql.named('''
          INSERT INTO supplier_ledger (
            id,         warehouse_id, supplier_id,
            entry_type, amount,       balance_before, balance_after,
            notes
          ) VALUES (
            @id,        @wid,         @supplierId,
            'opening',  @amount,      0,              @amount,
            'System se pehle ka balance'
          )
        '''),
        parameters: {
          'id':         const Uuid().v4(),
          'wid':        _wid,
          'supplierId': supplier.id,
          'amount':     openingBalance,
        },
      );
    }

    // Step 3: DB se fresh data wapas lo
    return (await getById(supplier.id))!;
  }

  // ==========================================================
  // 4. UPDATE — existing supplier update karo
  // ==========================================================
  Future<SupplierModel> update(SupplierModel supplier) async {
    final conn = await _db;

    await conn.execute(
      Sql.named('''
        UPDATE suppliers SET
          name           = @name,
          company_name   = @companyName,
          contact_person = @contactPerson,
          email          = @email,
          phone          = @phone,
          address        = @address,
          tax_id         = @taxId,
          payment_terms  = @paymentTerms,
          is_active      = @isActive,
          notes          = @notes
        WHERE id           = @id
          AND warehouse_id = @wid
      '''),
      parameters: {
        'id':            supplier.id,
        'wid':           _wid,
        'name':          supplier.name,
        'companyName':   supplier.companyName,
        'contactPerson': supplier.contactPerson,
        'email':         supplier.email,
        'phone':         supplier.phone,
        'address':       supplier.address,
        'taxId':         supplier.taxId,
        'paymentTerms':  supplier.paymentTerms,
        'isActive':      supplier.isActive,
        'notes':         supplier.notes,
        'createdBy':     supplier.createdById,
      },
    );

    return (await getById(supplier.id))!;
  }

  // ==========================================================
  // 5. SOFT DELETE
  // ==========================================================
  Future<void> softDelete(String supplierId) async {
    final conn = await _db;

    await conn.execute(
      Sql.named('''
        UPDATE suppliers
        SET deleted_at = NOW()
        WHERE id           = @id
          AND warehouse_id = @wid
      '''),
      parameters: {'id': supplierId, 'wid': _wid},
    );
  }


  // ==========================================================
  // 7. PAY TO SUPPLIER — payment record karo
  // supplier_ledger mein 'payment' entry insert hogi
  // trigger automatically outstanding_balance update karega
  // ==========================================================
  Future<SupplierModel> payToSupplier({
    required String supplierId,
    required double amount,
    String?         notes,
    String?         userId,
    String?         userName,
  }) async {
    final conn = await _db;

    // Step 1: Current balance lo
    final supplier = await getById(supplierId);
    if (supplier == null) throw Exception('Supplier nahi mila');

    final newBalance = supplier.outstandingBalance - amount;

    // Step 2: Supplier ledger mein payment entry karo
    await conn.execute(
      Sql.named('''
      INSERT INTO supplier_ledger (
        id,          warehouse_id, supplier_id,
        entry_type,  amount,       balance_before, balance_after,
        notes,       created_by
      ) VALUES (
        @id,         @wid,         @supplierId,
        'payment',   @amount,      @balanceBefore, @balanceAfter,
        @notes,      @userId
      )
    '''),
      parameters: {
        'id':            const Uuid().v4(),
        'wid':           _wid,
        'supplierId':    supplierId,
        'amount':        -amount,
        'balanceBefore': supplier.outstandingBalance,
        'balanceAfter':  newBalance,
        'notes':         notes ?? 'Manual payment',
        'userId':        userId,
      },
    );

    // Step 3: Warehouse finance mein cash out entry karo
    await WarehouseFinanceRepository.instance.addSupplierPayment(
      amount:        amount,
      supplierId:    supplierId,
      notes:         notes ?? 'Supplier payment — ${supplier.name}',
      createdBy:     userId,
      createdByName: userName,
    );

    // Step 4: Fresh data wapas lo
    return (await getById(supplierId))!;
  }

  // ==========================================================
  // 6. TOGGLE STATUS
  // ==========================================================
  Future<void> toggleStatus(String supplierId, bool isActive) async {
    final conn = await _db;

    await conn.execute(
      Sql.named('''
        UPDATE suppliers
        SET is_active = @isActive
        WHERE id           = @id
          AND warehouse_id = @wid
      '''),
      parameters: {
        'id':       supplierId,
        'wid':      _wid,
        'isActive': isActive,
      },
    );
  }

  // ==========================================================
  // PRIVATE: Auto code — SUPP-0001, SUPP-0002 ...
  // ==========================================================
  Future<String> _generateCode() async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT COUNT(*) FROM suppliers
        WHERE warehouse_id = @wid
      '''),
      parameters: {'wid': _wid},
    );

    final count = _parseInt(result.first[0]) + 1;
    return 'SUPP-${count.toString().padLeft(4, '0')}';
  }

  int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int)  return v;
    if (v is num)  return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}