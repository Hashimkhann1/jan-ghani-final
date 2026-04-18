// =============================================================
// product_remote_datasource.dart
// UPDATED: barcode String? → barcodes List<String> (text[])
// UPDATED: cost_price → purchase_price
// =============================================================

import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import '../model/product_model.dart';

class ProductRemoteDataSource {

  Future<Connection> get _db => DatabaseService.getConnection();

  // ── GET ALL ───────────────────────────────────────────────
  Future<List<ProductModel>> getAll(String warehouseId) async {
    final conn = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT
          p.id, p.warehouse_id, p.sku, p.barcode,
          p.name, p.description,
          p.category_id, c.name AS category_name,
          p.unit_of_measure, p.purchase_price, p.selling_price,  -- ✅ cost_price → purchase_price
          p.wholesale_price, p.tax_rate,
          p.min_stock_level, p.max_stock_level, p.reorder_point,
          p.is_active, p.is_track_stock,
          p.created_at, p.updated_at, p.deleted_at,
          COALESCE(i.quantity, 0)          AS quantity,
          COALESCE(i.reserved_quantity, 0) AS reserved_quantity
        FROM warehouse_products p
        LEFT JOIN warehouse_categories c ON c.id = p.category_id
        LEFT JOIN warehouse_inventory  i ON i.product_id = p.id
          AND i.warehouse_id = p.warehouse_id
        WHERE p.warehouse_id = @warehouseId
          AND p.deleted_at   IS NULL
        ORDER BY p.created_at DESC
      '''),
      parameters: {'warehouseId': warehouseId},
    );
    return result.map((row) => ProductModel.fromMap(_toMap(row))).toList();
  }

  // ── GET BY ID ─────────────────────────────────────────────
  Future<ProductModel?> getById(String id) async {
    final conn = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT
          p.id, p.warehouse_id, p.sku, p.barcode,
          p.name, p.description,
          p.category_id, c.name AS category_name,
          p.unit_of_measure, p.purchase_price, p.selling_price,  -- ✅ cost_price → purchase_price
          p.wholesale_price, p.tax_rate,
          p.min_stock_level, p.max_stock_level, p.reorder_point,
          p.is_active, p.is_track_stock,
          p.created_at, p.updated_at, p.deleted_at,
          COALESCE(i.quantity, 0)          AS quantity,
          COALESCE(i.reserved_quantity, 0) AS reserved_quantity
        FROM warehouse_products p
        LEFT JOIN warehouse_categories c ON c.id = p.category_id
        LEFT JOIN warehouse_inventory  i ON i.product_id = p.id
          AND i.warehouse_id = p.warehouse_id
        WHERE p.id = @id AND p.deleted_at IS NULL
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return ProductModel.fromMap(_toMap(result.first));
  }

  // ── ADD ───────────────────────────────────────────────────
  Future<ProductModel> add({
    required ProductModel product,
    required double       initialQty,
    required String?      userId,
    required String?      userName,
  }) async {
    final conn = await _db;

    final productResult = await conn.execute(
      Sql.named('''
        INSERT INTO warehouse_products (
          warehouse_id, sku, barcode, name, description,
          category_id, unit_of_measure, purchase_price, selling_price,  -- ✅ cost_price → purchase_price
          wholesale_price, tax_rate, min_stock_level, max_stock_level,
          reorder_point, is_active, is_track_stock
        ) VALUES (
          @warehouseId, @sku, @barcode, @name, @description,
          @categoryId, @unitOfMeasure, @purchasePrice, @sellingPrice,  -- ✅ costPrice → purchasePrice
          @wholesalePrice, @taxRate, @minStockLevel, @maxStockLevel,
          @reorderPoint, @isActive, @isTrackStock
        )
        RETURNING id
      '''),
      parameters: {
        'warehouseId':    product.warehouseId,
        'sku':            product.sku,
        'barcode':        product.barcodes,
        'name':           product.name,
        'description':    product.description,
        'categoryId':     product.categoryId,
        'unitOfMeasure':  product.unitOfMeasure,
        'purchasePrice':  product.purchasePrice,   // ✅ costPrice → purchasePrice
        'sellingPrice':   product.sellingPrice,
        'wholesalePrice': product.wholesalePrice,
        'taxRate':        product.taxRate,
        'minStockLevel':  product.minStockLevel,
        'maxStockLevel':  product.maxStockLevel,
        'reorderPoint':   product.reorderPoint,
        'isActive':       product.isActive,
        'isTrackStock':   product.isTrackStock,
      },
    );

    final newId = productResult.first.toColumnMap()['id'].toString();

    await conn.execute(
      Sql.named('''
        INSERT INTO warehouse_inventory (
          warehouse_id, product_id, location_id, quantity, reserved_quantity
        ) VALUES (
          @warehouseId, @productId, NULL, @quantity, 0
        )
        ON CONFLICT (warehouse_id, product_id)
        DO UPDATE SET quantity = EXCLUDED.quantity
      '''),
      parameters: {
        'warehouseId': product.warehouseId,
        'productId':   newId,
        'quantity':    initialQty,
      },
    );

    await _insertAuditLog(
      conn: conn, productId: newId, userId: userId, userName: userName,
      changeType: 'create', oldData: null,
      newData: _productToAuditMap(product, initialQty),
    );

    return (await getById(newId))!;
  }

  // ── UPDATE ────────────────────────────────────────────────
  Future<ProductModel> update({
    required ProductModel oldProduct,
    required ProductModel newProduct,
    required double       newQty,
    required String?      userId,
    required String?      userName,
  }) async {
    final conn = await _db;

    await conn.execute(
      Sql.named('''
        UPDATE warehouse_inventory
        SET quantity = @quantity
        WHERE product_id   = @productId
          AND warehouse_id = @warehouseId
      '''),
      parameters: {
        'quantity':    newQty,
        'productId':   newProduct.id,
        'warehouseId': newProduct.warehouseId,
      },
    );

    await conn.execute(
      Sql.named('''
        UPDATE warehouse_products SET
          sku             = @sku,
          barcode         = @barcode,
          name            = @name,
          description     = @description,
          category_id     = @categoryId,
          unit_of_measure = @unitOfMeasure,
          purchase_price  = @purchasePrice,  -- ✅ cost_price → purchase_price
          selling_price   = @sellingPrice,
          wholesale_price = @wholesalePrice,
          tax_rate        = @taxRate,
          min_stock_level = @minStockLevel,
          max_stock_level = @maxStockLevel,
          reorder_point   = @reorderPoint,
          is_active       = @isActive,
          is_track_stock  = @isTrackStock
        WHERE id = @id
      '''),
      parameters: {
        'id':            newProduct.id,
        'sku':           newProduct.sku,
        'barcode':       newProduct.barcodes,
        'name':          newProduct.name,
        'description':   newProduct.description,
        'categoryId':    newProduct.categoryId,
        'unitOfMeasure': newProduct.unitOfMeasure,
        'purchasePrice': newProduct.purchasePrice,  // ✅ costPrice → purchasePrice
        'sellingPrice':  newProduct.sellingPrice,
        'wholesalePrice':newProduct.wholesalePrice,
        'taxRate':       newProduct.taxRate,
        'minStockLevel': newProduct.minStockLevel,
        'maxStockLevel': newProduct.maxStockLevel,
        'reorderPoint':  newProduct.reorderPoint,
        'isActive':      newProduct.isActive,
        'isTrackStock':  newProduct.isTrackStock,
      },
    );

    await _insertAuditLog(
      conn: conn, productId: newProduct.id, userId: userId, userName: userName,
      changeType: 'update',
      oldData: _productToAuditMap(oldProduct, oldProduct.quantity),
      newData: _productToAuditMap(newProduct, newQty),
    );

    return (await getById(newProduct.id))!;
  }

  // ── SOFT DELETE ───────────────────────────────────────────
  Future<void> delete({
    required String       id,
    required ProductModel product,
    required String?      userId,
    required String?      userName,
  }) async {
    final conn = await _db;
    await conn.execute(
      Sql.named('UPDATE warehouse_products SET deleted_at = NOW() WHERE id = @id'),
      parameters: {'id': id},
    );
    await _insertAuditLog(
      conn: conn, productId: id, userId: userId, userName: userName,
      changeType: 'delete',
      oldData: _productToAuditMap(product, product.quantity),
      newData: null,
    );
  }

  // ── SKU EXISTS ────────────────────────────────────────────
  Future<bool> skuExists(String sku, String warehouseId,
      {String? excludeId}) async {
    final conn = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT 1 FROM warehouse_products
        WHERE sku = @sku AND warehouse_id = @warehouseId AND deleted_at IS NULL
        ${excludeId != null ? 'AND id != @excludeId' : ''}
        LIMIT 1
      '''),
      parameters: {
        'sku': sku,
        'warehouseId': warehouseId,
        if (excludeId != null) 'excludeId': excludeId,
      },
    );
    return result.isNotEmpty;
  }

  // ── BARCODE EXISTS (duplicate check) ─────────────────────
  Future<bool> barcodeExists(
      String barcode, String warehouseId, {String? excludeId}) async {
    final conn = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT 1 FROM warehouse_products
        WHERE @barcode = ANY(barcode)
          AND warehouse_id = @warehouseId
          AND deleted_at IS NULL
          ${excludeId != null ? 'AND id != @excludeId' : ''}
        LIMIT 1
      '''),
      parameters: {
        'barcode': barcode,
        'warehouseId': warehouseId,
        if (excludeId != null) 'excludeId': excludeId,
      },
    );
    return result.isNotEmpty;
  }

  // ── GET AUDIT LOG ─────────────────────────────────────────
  Future<List<ProductAuditLog>> getAuditLog(String productId) async {
    final conn = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT id, product_id, user_id, user_name,
               change_type, old_data, new_data, changed_at
        FROM product_audit_log
        WHERE product_id = @productId
        ORDER BY changed_at DESC
      '''),
      parameters: {'productId': productId},
    );
    return result.map((row) {
      final m = row.toColumnMap();
      return ProductAuditLog(
        id:         m['id'].toString(),
        productId:  m['product_id'].toString(),
        userId:     m['user_id']?.toString(),
        userName:   m['user_name']?.toString() ?? 'Unknown',
        changeType: m['change_type'].toString(),
        oldData:    m['old_data'] != null
            ? (m['old_data'] is Map
            ? Map<String, dynamic>.from(m['old_data'] as Map)
            : jsonDecode(m['old_data'].toString()) as Map<String, dynamic>)
            : null,
        newData:    m['new_data'] != null
            ? (m['new_data'] is Map
            ? Map<String, dynamic>.from(m['new_data'] as Map)
            : jsonDecode(m['new_data'].toString()) as Map<String, dynamic>)
            : null,
        changedAt:  m['changed_at'] is DateTime
            ? m['changed_at'] as DateTime
            : DateTime.parse(m['changed_at'].toString()),
      );
    }).toList();
  }

  // ── PRIVATE helpers ───────────────────────────────────────
  Future<void> _insertAuditLog({
    required Connection conn,
    required String productId,
    required String? userId,
    required String? userName,
    required String changeType,
    required Map<String, dynamic>? oldData,
    required Map<String, dynamic>? newData,
  }) async {
    await conn.execute(
      Sql.named('''
        INSERT INTO product_audit_log (
          product_id, user_id, user_name, change_type, old_data, new_data
        ) VALUES (
          @productId, @userId, @userName, @changeType, @oldData, @newData
        )
      '''),
      parameters: {
        'productId':  productId,
        'userId':     userId,
        'userName':   userName ?? 'Unknown',
        'changeType': changeType,
        'oldData':    oldData != null ? jsonEncode(oldData) : null,
        'newData':    newData != null ? jsonEncode(newData) : null,
      },
    );
  }

  Map<String, dynamic> _productToAuditMap(ProductModel p, double qty) => {
    'name': p.name, 'sku': p.sku,
    'barcodes': p.barcodes,
    'category': p.categoryName, 'unit': p.unitOfMeasure,
    'purchase_price': p.purchasePrice,  // ✅ cost_price → purchase_price
    'selling_price': p.sellingPrice,
    'wholesale_price': p.wholesalePrice, 'tax_rate': p.taxRate,
    'min_stock': p.minStockLevel, 'max_stock': p.maxStockLevel,
    'reorder_point': p.reorderPoint, 'is_active': p.isActive,
    'is_track_stock': p.isTrackStock, 'quantity': qty,
  };

  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id': m['id'], 'warehouse_id': m['warehouse_id'],
      'sku': m['sku']?.toString() ?? '',
      'barcode': m['barcode'],
      'name': m['name']?.toString() ?? '',
      'description': m['description']?.toString(),
      'category_id': m['category_id']?.toString(),
      'category_name': m['category_name']?.toString(),
      'unit_of_measure': m['unit_of_measure']?.toString() ?? 'pcs',
      'purchase_price': m['purchase_price'],  // ✅ cost_price → purchase_price
      'selling_price': m['selling_price'],
      'wholesale_price': m['wholesale_price'], 'tax_rate': m['tax_rate'],
      'min_stock_level': m['min_stock_level'],
      'max_stock_level': m['max_stock_level'],
      'reorder_point': m['reorder_point'],
      'is_active': m['is_active'] ?? true,
      'is_track_stock': m['is_track_stock'] ?? true,
      'created_at': m['created_at'], 'updated_at': m['updated_at'],
      'deleted_at': m['deleted_at'],
      'quantity': m['quantity'],
      'reserved_quantity': m['reserved_quantity'],
    };
  }
}

// ── Audit Log Model ───────────────────────────────────────────
class ProductAuditLog {
  final String id, productId, userName, changeType;
  final String? userId;
  final Map<String, dynamic>? oldData, newData;
  final DateTime changedAt;

  const ProductAuditLog({
    required this.id, required this.productId,
    this.userId, required this.userName,
    required this.changeType, this.oldData, this.newData,
    required this.changedAt,
  });

  List<String> get changedFields {
    if (oldData == null || newData == null) return [];
    return newData!.keys.where((k) =>
    oldData![k]?.toString() != newData![k]?.toString()).toList();
  }
}