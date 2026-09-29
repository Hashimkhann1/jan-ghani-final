// Updated on 2026-09-28 11:49 AM
// =============================================================
// supplier_repository.dart
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/data/warehouse_finance_repository.dart';
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
    LEFT JOIN warehouse_users u ON u.id = s.created_by
    LEFT JOIN (
      SELECT
        supplier_id,
        COUNT(*)          AS total_orders,
        SUM(total_amount) AS total_purchased
      FROM purchase_orders
      WHERE warehouse_id = @wid
        AND deleted_at   IS NULL
        AND status       = 'received'
        -- Purchase Return bhi status='received' se save hota hai → exclude
        AND po_type      = 'purchase'
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
          notes          = @notes,
          is_synced      = false 
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
        // 'createdBy':     supplier.createdById,
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
// 8. ADJUST BALANCE — ledger mein adjustment entry dalo
// trigger automatically outstanding_balance update karega
// ==========================================================
  Future<SupplierModel> adjustBalance({
    required String supplierId,
    required double newBalance,
    String?         userId,
  }) async {
    final conn = await _db;

    // Step 1: Current balance lo
    final supplier = await getById(supplierId);
    if (supplier == null) throw Exception('Supplier nahi mila');

    final currentBalance = supplier.outstandingBalance;

    // Agar same hai toh kuch mat karo
    if (currentBalance == newBalance) return supplier;

    // Difference: positive = increase, negative = decrease
    final difference = newBalance - currentBalance;

    // Step 2: Ledger mein adjustment entry insert karo
    await conn.execute(
      Sql.named('''
      INSERT INTO supplier_ledger (
        id,            warehouse_id,  supplier_id,
        entry_type,    amount,        balance_before,
        balance_after, notes,         created_by
      ) VALUES (
        @id,           @wid,          @supplierId,
        'adjustment',  @amount,       @balanceBefore,
        @balanceAfter, @notes,        @userId
      )
    '''),
      parameters: {
        'id':            const Uuid().v4(),
        'wid':           _wid,
        'supplierId':    supplierId,
        'amount':        difference,
        'balanceBefore': currentBalance,
        'balanceAfter':  newBalance,
        'notes':         'Manual balance adjustment via edit',
        'userId':        userId,
      },
    );

    // Step 3: Fresh data wapas lo (trigger ne balance update kar diya hoga)
    return (await getById(supplierId))!;
  }


  // ==========================================================
  // 7. PAY TO SUPPLIER — payment record karo
  // Ek hi DB transaction mein:
  //   1. supplier row FOR UPDATE lock + fresh balance
  //   2. supplier_ledger 'payment' entry (trigger balance update karega)
  //   3. warehouse_cash_transactions 'supplier_payment' (cash out)
  // Koi step fail ho to sab rollback — ledger aur cash hamesha saath
  // ==========================================================
  Future<SupplierModel> payToSupplier({
    required String supplierId,
    required double amount,
    String?         notes,
    String?         userId,
    String?         userName,
  }) async {
    if (amount <= 0) throw Exception('Amount 0 se zyada honi chahiye');

    final conn = await _db;

    await conn.runTx((tx) async {
      // Step 1: Fresh balance lo — lock ke saath (UI ka balance stale ho sakta hai)
      final sup = await _lockSupplier(tx, supplierId);

      // Step 2 + 3: ledger payment + cash out (SAME transaction)
      await _insertPaymentTx(
        tx,
        supplierId:    supplierId,
        supplierName:  sup.name,
        amount:        amount,
        balanceBefore: sup.balance,
        notes:         notes,
        userId:        userId,
        userName:      userName,
      );
    });

    // Step 4: Fresh data wapas lo (commit ke baad)
    return (await getById(supplierId))!;
  }

  // ==========================================================
  // 7b. REVERSE PAYMENT — galat manual payment ki ULTI entry
  //
  // Purani payment rows (ledger + cash) KABHI update nahi hoti —
  // before/after snapshot chain safe rehti hai. Ek hi transaction mein:
  //   1. original ledger row lock + validate (sirf manual 'payment',
  //      po_id NULL, pehle se reversed nahi)
  //   2. supplier lock → ledger 'payment_reversal' (+amount, reversal_of)
  //      → trigger se outstanding balance wapas barhega
  //   3. cash 'supplier_payment_reversal' (+amount) → cash wapas
  //   4. [correctAmount] > 0 ho to sahi amount ki nayi payment
  //      (ledger + cash) — user ke liye "edit" jaisa
  // PO wali payment (po_id set) yahan se reverse NAHI — uska paid_amount
  // PO par hai, woh Purchase Invoice edit se theek hoti hai.
  // ==========================================================
  Future<SupplierModel> reversePayment({
    required String ledgerId,
    required String reason,
    double          correctAmount = 0,
    String?         userId,
    String?         userName,
  }) async {
    final why = reason.trim();
    if (why.isEmpty)       throw Exception('Reverse ki wajah likhna zaroori hai');
    if (correctAmount < 0) throw Exception('Sahi amount minus nahi ho sakti');

    final conn = await _db;
    String? supplierId;

    await conn.runTx((tx) async {
      // Step 1: Original payment row lock + validate
      final origResult = await tx.execute(
        Sql.named('''
          SELECT id, supplier_id, entry_type, amount, po_id
          FROM supplier_ledger
          WHERE id           = @id
            AND warehouse_id = @wid
          FOR UPDATE
        '''),
        parameters: {'id': ledgerId, 'wid': _wid},
      );
      if (origResult.isEmpty) throw Exception('Ledger entry nahi mili');

      final orig = origResult.first.toColumnMap();
      if (orig['entry_type']?.toString() != 'payment') {
        throw Exception('Sirf payment entry reverse ho sakti hai');
      }
      if (orig['po_id'] != null) {
        throw Exception('Yeh PO ki payment hai — Purchase Invoice edit '
            'karke theek karein');
      }

      final already = await tx.execute(
        Sql.named('''
          SELECT 1 FROM supplier_ledger
          WHERE reversal_of = @id
          LIMIT 1
        '''),
        parameters: {'id': ledgerId},
      );
      if (already.isNotEmpty) {
        throw Exception('Yeh payment pehle se reverse ho chuki hai');
      }

      final sid        = orig['supplier_id'].toString();
      final paidAmount = _parseDouble(orig['amount']).abs();
      supplierId = sid;

      // Step 2: Supplier lock + ledger reversal (+amount)
      final sup               = await _lockSupplier(tx, sid);
      final balanceAfterRev   = sup.balance + paidAmount;

      await tx.execute(
        Sql.named('''
          INSERT INTO supplier_ledger (
            id,            warehouse_id,  supplier_id,
            entry_type,    amount,        balance_before, balance_after,
            notes,         created_by,    reversal_of,    created_at
          ) VALUES (
            @id,           @wid,          @supplierId,
            'payment_reversal', @amount,  @balanceBefore, @balanceAfter,
            @notes,        @userId,       @reversalOf,    clock_timestamp()
          )
        '''),
        parameters: {
          'id':            const Uuid().v4(),
          'wid':           _wid,
          'supplierId':    sid,
          'amount':        paidAmount,
          'balanceBefore': sup.balance,
          'balanceAfter':  balanceAfterRev,
          'notes':         'Reversal: $why',
          'userId':        userId,
          'reversalOf':    ledgerId,
        },
      );

      // Step 3: Cash wapas — SAME transaction
      await WarehouseFinanceRepository.instance.addSupplierPaymentReversal(
        amount:        paidAmount,
        supplierId:    sid,
        notes:         'Payment reversal — ${sup.name} ($why)',
        createdBy:     userId,
        createdByName: userName,
        session:       tx,
      );

      // Step 4: Sahi amount ki nayi payment (optional)
      if (correctAmount > 0) {
        await _insertPaymentTx(
          tx,
          supplierId:    sid,
          supplierName:  sup.name,
          amount:        correctAmount,
          balanceBefore: balanceAfterRev,
          notes:         'Sahi payment (galat Rs '
              '${paidAmount.toStringAsFixed(0)} ki jagah)',
          userId:        userId,
          userName:      userName,
        );
      }
    });

    return (await getById(supplierId!))!;
  }

  // ── PRIVATE: supplier row FOR UPDATE lock + fresh balance ──
  Future<({String name, double balance})> _lockSupplier(
      TxSession tx, String supplierId) async {
    final result = await tx.execute(
      Sql.named('''
        SELECT name, outstanding_balance FROM suppliers
        WHERE id           = @supplierId
          AND warehouse_id = @wid
          AND deleted_at   IS NULL
        FOR UPDATE
      '''),
      parameters: {'supplierId': supplierId, 'wid': _wid},
    );
    if (result.isEmpty) throw Exception('Supplier nahi mila');

    final row = result.first.toColumnMap();
    return (
      name:    row['name']?.toString() ?? '',
      balance: _parseDouble(row['outstanding_balance']),
    );
  }

  // ── PRIVATE: ledger 'payment' + cash 'supplier_payment' (caller ka tx) ──
  // Overpay guard [balanceBefore] (DB ka fresh, locked balance) par
  Future<void> _insertPaymentTx(
    TxSession tx, {
    required String supplierId,
    required String supplierName,
    required double amount,
    required double balanceBefore,
    String?         notes,
    String?         userId,
    String?         userName,
  }) async {
    if (amount <= 0) throw Exception('Amount 0 se zyada honi chahiye');
    if (amount > balanceBefore + 0.001) {
      throw Exception('Amount outstanding '
          '(Rs ${balanceBefore.toStringAsFixed(2)}) se zyada hai');
    }
    final balanceAfter = balanceBefore - amount;

    // created_at = clock_timestamp() — reversal ke baad wali payment ka
    // time reversal se alag (now() transaction mein same rehta)
    await tx.execute(
      Sql.named('''
        INSERT INTO supplier_ledger (
          id,          warehouse_id, supplier_id,
          entry_type,  amount,       balance_before, balance_after,
          notes,       created_by,   created_at
        ) VALUES (
          @id,         @wid,         @supplierId,
          'payment',   @amount,      @balanceBefore, @balanceAfter,
          @notes,      @userId,      clock_timestamp()
        )
      '''),
      parameters: {
        'id':            const Uuid().v4(),
        'wid':           _wid,
        'supplierId':    supplierId,
        'amount':        -amount,
        'balanceBefore': balanceBefore,
        'balanceAfter':  balanceAfter,
        'notes':         notes ?? 'Manual payment',
        'userId':        userId,
      },
    );

    await WarehouseFinanceRepository.instance.addSupplierPayment(
      amount:        amount,
      supplierId:    supplierId,
      notes:         notes ?? 'Supplier payment — $supplierName',
      createdBy:     userId,
      createdByName: userName,
      session:       tx,
    );
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

  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int)  return v;
    if (v is num)  return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}