// Updated on 2026-11-16 09:59 AM
// =============================================================
// branch_return_local_datasource.dart — LOCAL Postgres
//
// Warehouse ka asal stock local `warehouse_inventory` mein hai aur
// wahan se Supabase ko sync hota hai. Isliye returned stock YAHAN add
// hota hai (is_synced = false) — Supabase par seedha kabhi nahi.
//
//   • checkProducts()  — har product: ok / deleted / missing
//   • isApplied()      — is return ki `return_in` movement bani hai?
//   • applyReturn()    — ek transaction: +qty inventory + return_in
//                        movement. Advisory lock + movement check →
//                        stock kabhi do baar add nahi hota.
//   • Price NAHI badalti (owner ka faisla) — sirf qty
//   • reserved_quantity ko haath nahi lagta
// =============================================================

import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';

import '../domain/branch_return_model.dart';

/// applyReturn ka nateeja.
enum ApplyResult { applied, alreadyApplied }

/// Product delete / missing — accept nahi ho sakta.
class ReturnProductException implements Exception {
  final Map<String, ReturnProductStatus> issues; // productId → status
  const ReturnProductException(this.issues);

  @override
  String toString() =>
      'Kuch products warehouse mein delete hain ya mojood nahi — '
      'ye return accept nahi ho sakta, sirf reject karein';
}

class BranchReturnLocalDatasource {
  BranchReturnLocalDatasource._();
  static final BranchReturnLocalDatasource instance =
      BranchReturnLocalDatasource._();

  Future<Connection> get _db => DatabaseService.getConnection();

  // ── Products ki halat ──────────────────────────────────────
  Future<Map<String, ReturnProductStatus>> checkProducts(
      String warehouseId, List<String> productIds,
      {Session? session}) async {
    final ids = productIds.toSet().toList();
    if (ids.isEmpty) return {};
    final exec = session ?? await _db;
    final res = await exec.execute(
      Sql.named('''
        SELECT id::text AS id, deleted_at IS NOT NULL AS is_deleted
        FROM warehouse_products
        WHERE warehouse_id = @wid AND id = ANY(@ids::uuid[])
      '''),
      parameters: {'wid': warehouseId, 'ids': ids},
    );
    final found = <String, bool>{
      for (final r in res)
        r.toColumnMap()['id'].toString():
            r.toColumnMap()['is_deleted'] == true,
    };
    return {
      for (final id in ids)
        id: !found.containsKey(id)
            ? ReturnProductStatus.missing
            : found[id]!
                ? ReturnProductStatus.deleted
                : ReturnProductStatus.ok,
    };
  }

  // ── Is return ka stock pehle add ho chuka? ─────────────────
  Future<bool> isApplied(String warehouseId, String returnId,
      {Session? session}) async {
    final exec = session ?? await _db;
    final res = await exec.execute(
      Sql.named('''
        SELECT 1 FROM warehouse_stock_movements
        WHERE warehouse_id = @wid
          AND reference_id = @rid
          AND movement_type = 'return_in'
        LIMIT 1
      '''),
      parameters: {'wid': warehouseId, 'rid': returnId},
    );
    return res.isNotEmpty;
  }

  /// Accepted returns mein se jin ka stock abhi local mein nahi aaya.
  Future<Set<String>> appliedReturnIds(
      String warehouseId, List<String> returnIds) async {
    if (returnIds.isEmpty) return {};
    final conn = await _db;
    final res = await conn.execute(
      Sql.named('''
        SELECT DISTINCT reference_id::text AS rid
        FROM warehouse_stock_movements
        WHERE warehouse_id = @wid
          AND movement_type = 'return_in'
          AND reference_id = ANY(@ids::uuid[])
      '''),
      parameters: {'wid': warehouseId, 'ids': returnIds},
    );
    return {for (final r in res) r.toColumnMap()['rid'].toString()};
  }

  // ── ACCEPT: stock add (ek transaction) ─────────────────────
  Future<ApplyResult> applyReturn({
    required String       warehouseId,
    required BranchReturn ret,
    String?               userId,
  }) async {
    final conn = await _db;
    return conn.runTx<ApplyResult>((tx) async {
      // Isi return par do jagah se ek saath apply (button + safety net)
      // → doosra yahin rukta hai, phir movement dekh kar skip karta hai.
      await tx.execute(
        Sql.named('SELECT pg_advisory_xact_lock(hashtext(@k))'),
        parameters: {'k': 'stock_return:${ret.id}'},
      );

      if (await isApplied(warehouseId, ret.id, session: tx)) {
        return ApplyResult.alreadyApplied;
      }

      // Products dobara check (transaction ke andar — beech mein delete
      // na hua ho). Koi masla → throw → rollback.
      final status = await checkProducts(
          warehouseId, ret.items.map((e) => e.productId).toList(),
          session: tx);
      final issues = Map<String, ReturnProductStatus>.fromEntries(
          status.entries.where((e) => e.value != ReturnProductStatus.ok));
      if (issues.isNotEmpty) throw ReturnProductException(issues);

      final notes = 'Return from ${ret.fromStoreName} (${ret.returnNumber})';

      for (final it in ret.items) {
        // 1) Inventory +qty (row na ho to nayi). Sync isi flag se uthati hai.
        await tx.execute(
          Sql.named('''
            INSERT INTO warehouse_inventory
              (warehouse_id, product_id, quantity, last_movement_at,
               updated_at, is_synced)
            VALUES (@wid, @pid, @qty, NOW(), NOW(), false)
            ON CONFLICT (warehouse_id, product_id) DO UPDATE SET
              quantity         = warehouse_inventory.quantity + EXCLUDED.quantity,
              last_movement_at = NOW(),
              updated_at       = NOW(),
              is_synced        = false
          '''),
          parameters: {
            'wid': warehouseId,
            'pid': it.productId,
            'qty': it.quantityReturned,
          },
        );

        // 2) Ledger: return_in (reference_type CHECK sirf
        //    purchase/transfer/adjustment allow karta hai → 'transfer')
        await tx.execute(
          Sql.named('''
            INSERT INTO warehouse_stock_movements
              (warehouse_id, product_id, movement_type, quantity, unit_cost,
               reference_type, reference_id, notes, created_by)
            VALUES
              (@wid, @pid, 'return_in', @qty, @cost,
               'transfer', @rid, @notes,
               (SELECT id FROM warehouse_users WHERE id::text = @uid))
          '''),
          parameters: {
            'wid':   warehouseId,
            'pid':   it.productId,
            'qty':   it.quantityReturned,
            'cost':  double.parse(it.purchasePrice.toStringAsFixed(2)),
            'rid':   ret.id,
            'notes': notes,
            'uid':   userId ?? '',
          },
        );
      }
      return ApplyResult.applied;
    });
  }
}
