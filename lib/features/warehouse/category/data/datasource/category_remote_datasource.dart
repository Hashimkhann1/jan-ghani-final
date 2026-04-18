// =============================================================
// category_remote_datasource.dart
// =============================================================

import 'package:postgres/postgres.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import '../model/category_model.dart';

class CategoryRemoteDataSource {

  Future<Connection> get _db => DatabaseService.getConnection();

  // ── GET ALL ───────────────────────────────────────────────
  Future<List<CategoryModel>> getAll(String warehouseId) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, warehouse_id, name, description,
          color_code, is_active,
          created_at, updated_at, deleted_at
        FROM warehouse_categories
        WHERE warehouse_id = @warehouseId
          AND deleted_at   IS NULL
        ORDER BY name ASC
      '''),
      parameters: {'warehouseId': warehouseId},
    );

    return result
        .map((row) => CategoryModel.fromMap(_toMap(row)))
        .toList();
  }

  // ── GET BY ID ─────────────────────────────────────────────
  Future<CategoryModel?> getById(String id) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id, warehouse_id, name, description,
          color_code, is_active,
          created_at, updated_at, deleted_at
        FROM warehouse_categories
        WHERE id         = @id
          AND deleted_at IS NULL
        LIMIT 1
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return CategoryModel.fromMap(_toMap(result.first));
  }

  // ── ADD ───────────────────────────────────────────────────
  Future<CategoryModel> add(CategoryModel category) async {
    final conn = await _db;

    final result = await conn.execute(
      Sql.named('''
        INSERT INTO warehouse_categories (
          warehouse_id, name, description,
          color_code, is_active
        ) VALUES (
          @warehouseId, @name, @description,
          @colorCode, @isActive
        )
        RETURNING *
      '''),
      parameters: {
        'warehouseId': category.warehouseId,
        'name':        category.name,
        'description': category.description,
        'colorCode':   category.colorCode,
        'isActive':    category.isActive,
      },
    );

    return CategoryModel.fromMap(_toMap(result.first));
  }

  // ── UPDATE ────────────────────────────────────────────────
  Future<CategoryModel> update(CategoryModel category) async {
    final conn = await _db;

    await conn.execute(
      Sql.named('''
        UPDATE warehouse_categories SET
          name        = @name,
          description = @description,
          color_code  = @colorCode,
          is_active   = @isActive
        WHERE id           = @id
          AND warehouse_id = @warehouseId
      '''),
      parameters: {
        'id':          category.id,
        'warehouseId': category.warehouseId,
        'name':        category.name,
        'description': category.description,
        'colorCode':   category.colorCode,
        'isActive':    category.isActive,
      },
    );

    return (await getById(category.id))!;
  }

  // ── SOFT DELETE ───────────────────────────────────────────
  Future<void> delete(String id) async {
    final conn = await _db;

    await conn.execute(
      Sql.named('''
        UPDATE warehouse_categories
        SET deleted_at = NOW()
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
        SELECT 1 FROM warehouse_categories
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
      'name':         m['name']?.toString()        ?? '',
      'description':  m['description']?.toString(),
      'color_code':   m['color_code']?.toString(),
      'is_active':    m['is_active']               ?? true,
      'created_at':   m['created_at'],
      'updated_at':   m['updated_at'],
      'deleted_at':   m['deleted_at'],
    };
  }
}