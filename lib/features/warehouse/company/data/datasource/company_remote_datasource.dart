// =============================================================
// company_remote_datasource.dart
// =============================================================

import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:postgres/postgres.dart';

import '../model/company_model.dart';

class CompanyRemoteDataSource {

  Future<Connection> get _db => DatabaseService.getConnection();

  // ── GET ALL ───────────────────────────────────────────────
  Future<List<CompanyModel>> getAll(String warehouseId) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, warehouse_id, name, is_active,
          created_at, updated_at, deleted_at
        FROM warehouse_companies
        WHERE warehouse_id = @warehouseId
          AND deleted_at   IS NULL
        ORDER BY name ASC
      '''),
      parameters: {'warehouseId': warehouseId},
    );

    return result.map((row) => CompanyModel.fromMap(_toMap(row))).toList();
  }

  // ── GET BY ID ─────────────────────────────────────────────
  Future<CompanyModel?> getById(String id) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, warehouse_id, name, is_active,
          created_at, updated_at, deleted_at
        FROM warehouse_companies
        WHERE id         = @id
          AND deleted_at IS NULL
        LIMIT 1
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return CompanyModel.fromMap(_toMap(result.first));
  }

  // ── ADD ───────────────────────────────────────────────────
  Future<CompanyModel> add(CompanyModel company) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        INSERT INTO warehouse_companies (
          id, warehouse_id, name, is_active
        ) VALUES (
          @id, @warehouseId, @name, @isActive
        )
        RETURNING *
      '''),
      parameters: {
        'id':          company.id,
        'warehouseId': company.warehouseId,
        'name':        company.name,
        'isActive':    company.isActive,
      },
    );

    return CompanyModel.fromMap(_toMap(result.first));
  }

  // ── UPDATE ────────────────────────────────────────────────
  Future<CompanyModel> update(CompanyModel company) async {
    final conn = await _db;

    await conn.execute(
      Sql.named('''
        UPDATE warehouse_companies SET
          name      = @name,
          is_active = @isActive,
          is_synced = false
        WHERE id           = @id
          AND warehouse_id = @warehouseId
      '''),
      parameters: {
        'id':          company.id,
        'warehouseId': company.warehouseId,
        'name':        company.name,
        'isActive':    company.isActive,
      },
    );

    return (await getById(company.id))!;
  }

  // ── SOFT DELETE ───────────────────────────────────────────
  Future<void> delete(String id) async {
    final conn = await _db;

    await conn.execute(
      Sql.named('''
        UPDATE warehouse_companies
        SET deleted_at = NOW(), is_synced = false
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );
  }

  // ── NAME EXISTS CHECK ─────────────────────────────────────
  Future<bool> nameExists(String name, String warehouseId,
      {String? excludeId}) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT 1 FROM warehouse_companies
        WHERE LOWER(name)  = LOWER(@name)
          AND warehouse_id = @warehouseId
          AND deleted_at   IS NULL
          ${excludeId != null ? 'AND id != @excludeId' : ''}
        LIMIT 1
      '''),
      parameters: {
        'name':        name,
        'warehouseId': warehouseId,
        if (excludeId != null) 'excludeId': excludeId,
      },
    );

    return result.isNotEmpty;
  }

  // ── ROW → MAP ─────────────────────────────────────────────
  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':           m['id'],
      'warehouse_id': m['warehouse_id'],
      'name':         m['name']?.toString() ?? '',
      'is_active':    m['is_active']        ?? true,
      'created_at':   m['created_at'],
      'updated_at':   m['updated_at'],
      'deleted_at':   m['deleted_at'],
    };
  }
}
