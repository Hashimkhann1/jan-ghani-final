// import 'package:postgres/postgres.dart';
//
// import '../../../../../core/service/db/db_service.dart';
// import '../model/branch_stock_model.dart';
//
// class BranchStockDataSource {
//
//   // ── POS ke liye: saare products ek baar load (barcode scan zarori hai) ──
//   Future<List<BranchStockModel>> getAll(String storeId) async {
//     final conn   = await DataBaseService.getConnection();
//     final result = await conn.execute(
//       Sql.named('''
//         SELECT
//           id              AS inv_id,
//           store_id,
//           product_id,
//           stock           AS quantity,
//           0               AS reserved_quantity,
//           sku,
//           barcode::text,
//           product_name    AS name,
//           NULL            AS description,
//           unit            AS unit_of_measure,
//           purchase_price  AS cost_price,
//           sale_price      AS selling_price,
//           wholesale_price,
//           0               AS tax_rate,
//           0               AS discount,
//           min_stock       AS min_stock_level,
//           max_stock       AS max_stock_level,
//           0               AS reorder_point,
//           true            AS is_active,
//           true            AS is_track_stock,
//           NULL            AS last_counted_at,
//           NULL            AS last_movement_at,
//           shelf_name,
//           updated_at
//         FROM public.branch_stock_inventory
//         WHERE store_id = @storeId
//         ORDER BY product_name ASC
//       '''),
//       parameters: {'storeId': storeId},
//     );
//     return result.map((r) => BranchStockModel.fromMap(_toMap(r))).toList();
//   }
//
//   // ── Inventory screen ke liye: paginated + server-side search/filter ──
//   Future<({List<BranchStockModel> rows, int totalCount})> getPaginated({
//     required String storeId,
//     required int    page,
//     required int    pageSize,
//     String          search       = '',
//     String          filterStatus = 'all',
//   }) async {
//     final conn = await DataBaseService.getConnection();
//
//     final conditions = <String>['store_id = @storeId'];
//     final params     = <String, dynamic>{'storeId': storeId};
//
//     if (search.trim().isNotEmpty) {
//       conditions.add('''
//         (
//           LOWER(product_name) LIKE @search
//           OR LOWER(sku)       LIKE @search
//           OR barcode::text    LIKE @search
//         )
//       ''');
//       params['search'] = '%${search.trim().toLowerCase()}%';
//     }
//
//     if (filterStatus == 'in_stock') {
//       conditions.add('stock > min_stock');
//     } else if (filterStatus == 'low_stock') {
//       conditions.add('stock <= min_stock AND stock > 0');
//     } else if (filterStatus == 'out_of_stock') {
//       conditions.add('stock <= 0');
//     }
//
//     final whereClause = conditions.join(' AND ');
//
//     final countResult = await conn.execute(
//       Sql.named(
//           'SELECT COUNT(*) FROM public.branch_stock_inventory WHERE $whereClause'),
//       parameters: params,
//     );
//     final totalCount = int.tryParse(
//         countResult.first.toColumnMap().values.first.toString()) ??
//         0;
//
//     params['limit']  = pageSize;
//     params['offset'] = page * pageSize;
//
//     final result = await conn.execute(
//       Sql.named('''
//         SELECT
//           id              AS inv_id,
//           store_id,
//           product_id,
//           stock           AS quantity,
//           0               AS reserved_quantity,
//           sku,
//           barcode::text,
//           product_name    AS name,
//           NULL            AS description,
//           unit            AS unit_of_measure,
//           purchase_price  AS cost_price,
//           sale_price      AS selling_price,
//           wholesale_price,
//           0               AS tax_rate,
//           0               AS discount,
//           min_stock       AS min_stock_level,
//           max_stock       AS max_stock_level,
//           0               AS reorder_point,
//           true            AS is_active,
//           true            AS is_track_stock,
//           NULL            AS last_counted_at,
//           NULL            AS last_movement_at,
//           shelf_name,
//           updated_at
//         FROM public.branch_stock_inventory
//         WHERE $whereClause
//         ORDER BY product_name ASC
//         LIMIT @limit OFFSET @offset
//       '''),
//       parameters: params,
//     );
//
//     return (
//     rows:       result.map((r) => BranchStockModel.fromMap(_toMap(r))).toList(),
//     totalCount: totalCount,
//     );
//   }
//
//   // ── Full Product Update (Owner only) ────────────────────────────────
//   // ✅ barcode column update nahi karta — text[] array literal issue se bachne ke liye
//   Future<void> updateProduct(BranchStockInventory p) async {
//     final conn = await DataBaseService.getConnection();
//     await conn.execute(
//       Sql.named('''
//         UPDATE public.branch_stock_inventory SET
//           product_name    = @productName,
//           sku             = @sku,
//           purchase_price  = @purchasePrice,
//           sale_price      = @salePrice,
//           wholesale_price = @wholesalePrice,
//           stock           = @stock,
//           min_stock       = @minStock,
//           max_stock       = @maxStock,
//           unit            = @unit,
//           shelf_name      = @shelfName,
//           updated_at      = @updatedAt
//         WHERE id = @id AND store_id = @storeId
//       '''),
//       parameters: {
//         'id':             p.id,
//         'storeId':        p.storeId,
//         'productName':    p.productName,
//         'sku':            p.sku,
//         'purchasePrice':  p.purchasePrice,
//         'salePrice':      p.salePrice,
//         'wholesalePrice': p.wholesalePrice,
//         'stock':          p.stock,
//         'minStock':       p.minStock,
//         'maxStock':       p.maxStock,
//         'unit':           p.unit,
//         'shelfName':      p.shelfName,
//         'updatedAt':      DateTime.now().toIso8601String(),
//       },
//     );
//   }
//
//   // ── Shelf-only Update (Manager only) ───────────────────────────────
//   Future<void> updateShelfName({
//     required String id,
//     required String storeId,
//     required String? shelfName,
//   }) async {
//     final conn = await DataBaseService.getConnection();
//     await conn.execute(
//       Sql.named('''
//         UPDATE public.branch_stock_inventory SET
//           shelf_name = @shelfName,
//           updated_at = @updatedAt
//         WHERE id = @id AND store_id = @storeId
//       '''),
//       parameters: {
//         'id':        id,
//         'storeId':   storeId,
//         'shelfName': shelfName,
//         'updatedAt': DateTime.now().toIso8601String(),
//       },
//     );
//   }
//
//   // ── Product Delete ──────────────────────────────────────────────
//   Future<void> deleteProduct(String id) async {
//     final conn = await DataBaseService.getConnection();
//     await conn.execute(
//       Sql.named(
//           'DELETE FROM public.branch_stock_inventory WHERE id = @id'),
//       parameters: {'id': id},
//     );
//   }
//
//   // ── Helpers ─────────────────────────────────────────────────────
//   String? parseBarcode(dynamic value) {
//     if (value == null) return null;
//     return value.toString().replaceAll('{', '').replaceAll('}', '');
//   }
//
//   Map<String, dynamic> _toMap(ResultRow row) {
//     final m = row.toColumnMap();
//     return {
//       'inv_id':            m['inv_id']?.toString()          ?? '',
//       'store_id':          m['store_id']?.toString()        ?? '',
//       'product_id':        m['product_id']?.toString()      ?? '',
//       'sku':               m['sku']?.toString()             ?? '',
//       'barcode':           m['barcode']?.toString(),
//       'name':              m['name']?.toString()            ?? '',
//       'description':       m['description']?.toString(),
//       'unit_of_measure':   m['unit_of_measure']?.toString() ?? 'pcs',
//       'cost_price':        m['cost_price'],
//       'selling_price':     m['selling_price'],
//       'wholesale_price':   m['wholesale_price'],
//       'tax_rate':          m['tax_rate']          ?? 0.0,
//       'discount':          m['discount']          ?? 0.0,
//       'min_stock_level':   m['min_stock_level']   ?? 0,
//       'max_stock_level':   m['max_stock_level']   ?? 0,
//       'reorder_point':     m['reorder_point']     ?? 0,
//       'is_active':         m['is_active']         ?? true,
//       'is_track_stock':    m['is_track_stock']    ?? true,
//       'quantity':          m['quantity'],
//       'reserved_quantity': m['reserved_quantity'] ?? 0,
//       'last_counted_at':   null,
//       'last_movement_at':  null,
//       'shelf_name':        m['shelf_name']?.toString(),     // ✅ NEW
//       'updated_at':        m['updated_at']?.toString()
//           ?? DateTime.now().toIso8601String(),
//     };
//   }
// }
//
// // ── BranchStockInventory model ──────────────────────────────────────
// class BranchStockInventory {
//   final String?      id;
//   final String       storeId;
//   final String       productId;
//   final List<String> barcode;
//   final String       sku;
//   final String       productName;
//   final double       purchasePrice;
//   final double       salePrice;
//   final double       wholesalePrice;
//   final double       stock;
//   final double       minStock;
//   final double       maxStock;
//   final String       unit;
//   final String?      shelfName; // ✅ NEW
//
//   BranchStockInventory({
//     this.id,
//     required this.storeId,
//     required this.productId,
//     required this.barcode,
//     required this.sku,
//     required this.productName,
//     required this.purchasePrice,
//     required this.salePrice,
//     required this.wholesalePrice,
//     required this.stock,
//     this.minStock = 0,
//     this.maxStock = 0,
//     required this.unit,
//     this.shelfName, // ✅ NEW
//   });
//
//   Map<String, dynamic> toJson() => {
//     'store_id':        storeId,
//     'product_id':      productId,
//     'barcode':         barcode,
//     'sku':             sku,
//     'product_name':    productName,
//     'purchase_price':  purchasePrice,
//     'sale_price':      salePrice,
//     'wholesale_price': wholesalePrice,
//     'stock':           stock,
//     'min_stock':       minStock,
//     'max_stock':       maxStock,
//     'unit':            unit,
//     'shelf_name':      shelfName,  // ✅ NEW
//     'updated_at':      DateTime.now().toIso8601String(),
//   };
// }



import 'package:postgres/postgres.dart';

import '../../../../../core/service/db/db_service.dart';
import '../model/branch_stock_model.dart';

class BranchStockDataSource {

  // ── POS ke liye: saare products ek baar load (barcode scan zarori hai) ──
  Future<List<BranchStockModel>> getAll(String storeId) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT
          id              AS inv_id,
          store_id,
          product_id,
          stock           AS quantity,
          0               AS reserved_quantity,
          sku,
          barcode::text,
          product_name    AS name,
          NULL            AS description,
          unit            AS unit_of_measure,
          purchase_price  AS cost_price,
          sale_price      AS selling_price,
          wholesale_price,
          0               AS tax_rate,
          0               AS discount,
          min_stock       AS min_stock_level,
          max_stock       AS max_stock_level,
          0               AS reorder_point,
          true            AS is_active,
          true            AS is_track_stock,
          NULL            AS last_counted_at,
          NULL            AS last_movement_at,
          shelf_name,
          updated_at
        FROM public.branch_stock_inventory
        WHERE store_id = @storeId
          AND deleted_at IS NULL
        ORDER BY product_name ASC
      '''),
      parameters: {'storeId': storeId},
    );
    return result.map((r) => BranchStockModel.fromMap(_toMap(r))).toList();
  }

  // ── Inventory screen ke liye: paginated + server-side search/filter ──
  Future<({List<BranchStockModel> rows, int totalCount})> getPaginated({
    required String storeId,
    required int    page,
    required int    pageSize,
    String          search       = '',
    String          filterStatus = 'all',
  }) async {
    final conn = await DataBaseService.getConnection();

    final conditions = <String>['store_id = @storeId', 'deleted_at IS NULL'];
    final params     = <String, dynamic>{'storeId': storeId};

    if (search.trim().isNotEmpty) {
      conditions.add('''
        (
          LOWER(product_name) LIKE @search
          OR LOWER(sku)       LIKE @search
          OR barcode::text    LIKE @search
        )
      ''');
      params['search'] = '%${search.trim().toLowerCase()}%';
    }

    if (filterStatus == 'in_stock') {
      conditions.add('stock > min_stock');
    } else if (filterStatus == 'low_stock') {
      conditions.add('stock <= min_stock AND stock > 0');
    } else if (filterStatus == 'out_of_stock') {
      conditions.add('stock <= 0');
    }

    final whereClause = conditions.join(' AND ');

    final countResult = await conn.execute(
      Sql.named(
          'SELECT COUNT(*) FROM public.branch_stock_inventory WHERE $whereClause'),
      parameters: params,
    );
    final totalCount = int.tryParse(
        countResult.first.toColumnMap().values.first.toString()) ??
        0;

    params['limit']  = pageSize;
    params['offset'] = page * pageSize;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id              AS inv_id,
          store_id,
          product_id,
          stock           AS quantity,
          0               AS reserved_quantity,
          sku,
          barcode::text,
          product_name    AS name,
          NULL            AS description,
          unit            AS unit_of_measure,
          purchase_price  AS cost_price,
          sale_price      AS selling_price,
          wholesale_price,
          0               AS tax_rate,
          0               AS discount,
          min_stock       AS min_stock_level,
          max_stock       AS max_stock_level,
          0               AS reorder_point,
          true            AS is_active,
          true            AS is_track_stock,
          NULL            AS last_counted_at,
          NULL            AS last_movement_at,
          shelf_name,
          updated_at
        FROM public.branch_stock_inventory
        WHERE $whereClause
        ORDER BY product_name ASC
        LIMIT @limit OFFSET @offset
      '''),
      parameters: params,
    );

    return (
    rows:       result.map((r) => BranchStockModel.fromMap(_toMap(r))).toList(),
    totalCount: totalCount,
    );
  }

  // ── Full Product Update (Owner only) ────────────────────────────────
  // ✅ barcode column update nahi karta — text[] array literal issue se bachne ke liye
  Future<void> updateProduct(BranchStockInventory p) async {
    final conn = await DataBaseService.getConnection();

    // ── Pehle old values fetch karo log ke liye ──
    final oldResult = await conn.execute(
      Sql.named('''
        SELECT
          product_name, stock, purchase_price, sale_price,
          wholesale_price, min_stock, max_stock, shelf_name
        FROM public.branch_stock_inventory
        WHERE id = @id AND store_id = @storeId
      '''),
      parameters: {'id': p.id, 'storeId': p.storeId},
    );
    final old = oldResult.isNotEmpty ? oldResult.first.toColumnMap() : {};

    // ── Update karo ──
    await conn.execute(
      Sql.named('''
        UPDATE public.branch_stock_inventory SET
          product_name    = @productName,
          sku             = @sku,
          purchase_price  = @purchasePrice,
          sale_price      = @salePrice,
          wholesale_price = @wholesalePrice,
          stock           = @stock,
          min_stock       = @minStock,
          max_stock       = @maxStock,
          unit            = @unit,
          shelf_name      = @shelfName,
          updated_at      = @updatedAt
        WHERE id = @id AND store_id = @storeId
      '''),
      parameters: {
        'id':             p.id,
        'storeId':        p.storeId,
        'productName':    p.productName,
        'sku':            p.sku,
        'purchasePrice':  p.purchasePrice,
        'salePrice':      p.salePrice,
        'wholesalePrice': p.wholesalePrice,
        'stock':          p.stock,
        'minStock':       p.minStock,
        'maxStock':       p.maxStock,
        'unit':           p.unit,
        'shelfName':      p.shelfName,
        'updatedAt':      DateTime.now().toIso8601String(),
      },
    );

    // ── Log insert karo ──
    await conn.execute(
      Sql.named('''
        INSERT INTO public.branch_stock_inventory_logs (
          store_id, product_id, product_name, change_type,
          old_stock,           new_stock,
          old_sale_price,      new_sale_price,
          old_purchase_price,  new_purchase_price,
          old_wholesale_price, new_wholesale_price,
          old_shelf_name,      new_shelf_name,
          old_min_stock,       new_min_stock,
          old_max_stock,       new_max_stock
        ) VALUES (
          @storeId, @productId, @productName, 'full_update',
          @oldStock,           @newStock,
          @oldSalePrice,       @newSalePrice,
          @oldPurchasePrice,   @newPurchasePrice,
          @oldWholesalePrice,  @newWholesalePrice,
          @oldShelfName,       @newShelfName,
          @oldMinStock,        @newMinStock,
          @oldMaxStock,        @newMaxStock
        )
      '''),
      parameters: {
        'storeId':           p.storeId,
        'productId':         p.productId,
        'productName':       p.productName,
        'oldStock':          old['stock'],
        'newStock':          p.stock,
        'oldSalePrice':      old['sale_price'],
        'newSalePrice':      p.salePrice,
        'oldPurchasePrice':  old['purchase_price'],
        'newPurchasePrice':  p.purchasePrice,
        'oldWholesalePrice': old['wholesale_price'],
        'newWholesalePrice': p.wholesalePrice,
        'oldShelfName':      old['shelf_name']?.toString(),
        'newShelfName':      p.shelfName,
        'oldMinStock':       old['min_stock'],
        'newMinStock':       p.minStock,
        'oldMaxStock':       old['max_stock'],
        'newMaxStock':       p.maxStock,
      },
    );
  }

  // ── Shelf + Min/Max Stock Update (Manager & Cashier) ────────────────
  Future<void> updateShelfAndStockLimits({
    required String  id,
    required String  storeId,
    required String? shelfName,
    required double   minStock,
    required double   maxStock,
  }) async {
    final conn = await DataBaseService.getConnection();

    // ── Pehle old values aur product info fetch karo ──
    final oldResult = await conn.execute(
      Sql.named('''
        SELECT product_id, product_name, shelf_name, min_stock, max_stock
        FROM public.branch_stock_inventory
        WHERE id = @id AND store_id = @storeId
      '''),
      parameters: {'id': id, 'storeId': storeId},
    );
    final old = oldResult.isNotEmpty ? oldResult.first.toColumnMap() : {};

    // ── Update karo ──
    await conn.execute(
      Sql.named('''
        UPDATE public.branch_stock_inventory SET
          shelf_name = @shelfName,
          min_stock  = @minStock,
          max_stock  = @maxStock,
          updated_at = @updatedAt
        WHERE id = @id AND store_id = @storeId
      '''),
      parameters: {
        'id':        id,
        'storeId':   storeId,
        'shelfName': shelfName,
        'minStock':  minStock,
        'maxStock':  maxStock,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );

    // ── Log insert karo ──
    await conn.execute(
      Sql.named('''
        INSERT INTO public.branch_stock_inventory_logs (
          store_id, product_id, product_name, change_type,
          old_shelf_name, new_shelf_name,
          old_min_stock,  new_min_stock,
          old_max_stock,  new_max_stock
        ) VALUES (
          @storeId, @productId, @productName, 'shelf_and_limits_update',
          @oldShelfName, @newShelfName,
          @oldMinStock,  @newMinStock,
          @oldMaxStock,  @newMaxStock
        )
      '''),
      parameters: {
        'storeId':      storeId,
        'productId':    old['product_id']?.toString() ?? '',
        'productName':  old['product_name']?.toString() ?? '',
        'oldShelfName': old['shelf_name']?.toString(),
        'newShelfName': shelfName,
        'oldMinStock':  old['min_stock'],
        'newMinStock':  minStock,
        'oldMaxStock':  old['max_stock'],
        'newMaxStock':  maxStock,
      },
    );
  }

  // ── Product Delete (soft) ───────────────────────────────────────
  // Hard DELETE nahi — push-only sync delete propagate nahi karta, is
  // liye row Supabase/dusri branch se wapas aa jaati thi. Ab
  // deleted_at set karte hain + updated_at bump (sync khud utha lega).
  Future<void> deleteProduct(String id) async {
    final conn = await DataBaseService.getConnection();

    // Log ke liye current values fetch karo.
    final oldResult = await conn.execute(
      Sql.named('''
        SELECT store_id, product_id, product_name, stock
        FROM public.branch_stock_inventory
        WHERE id = @id AND deleted_at IS NULL
      '''),
      parameters: {'id': id},
    );
    if (oldResult.isEmpty) return; // pehle se deleted / mojood nahi
    final old = oldResult.first.toColumnMap();

    await conn.execute(
      Sql.named('''
        UPDATE public.branch_stock_inventory SET
          deleted_at = NOW(),
          updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );

    // Log best-effort — agar change_type ek enum hai jismein 'delete'
    // abhi add nahi hua to delete khud fail na ho.
    try {
      await conn.execute(
        Sql.named('''
          INSERT INTO public.branch_stock_inventory_logs (
            store_id, product_id, product_name, change_type,
            old_stock, new_stock
          ) VALUES (
            @storeId, @productId, @productName, 'delete',
            @oldStock, 0
          )
        '''),
        parameters: {
          'storeId':     old['store_id']?.toString() ?? '',
          'productId':   old['product_id']?.toString() ?? '',
          'productName': old['product_name']?.toString() ?? '',
          'oldStock':    old['stock'],
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ branch_stock_inventory_logs delete-log skip: $e');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────
  String? parseBarcode(dynamic value) {
    if (value == null) return null;
    return value.toString().replaceAll('{', '').replaceAll('}', '');
  }

  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'inv_id':            m['inv_id']?.toString()          ?? '',
      'store_id':          m['store_id']?.toString()        ?? '',
      'product_id':        m['product_id']?.toString()      ?? '',
      'sku':               m['sku']?.toString()             ?? '',
      'barcode':           m['barcode']?.toString(),
      'name':              m['name']?.toString()            ?? '',
      'description':       m['description']?.toString(),
      'unit_of_measure':   m['unit_of_measure']?.toString() ?? 'pcs',
      'cost_price':        m['cost_price'],
      'selling_price':     m['selling_price'],
      'wholesale_price':   m['wholesale_price'],
      'tax_rate':          m['tax_rate']          ?? 0.0,
      'discount':          m['discount']          ?? 0.0,
      'min_stock_level':   m['min_stock_level']   ?? 0,
      'max_stock_level':   m['max_stock_level']   ?? 0,
      'reorder_point':     m['reorder_point']     ?? 0,
      'is_active':         m['is_active']         ?? true,
      'is_track_stock':    m['is_track_stock']    ?? true,
      'quantity':          m['quantity'],
      'reserved_quantity': m['reserved_quantity'] ?? 0,
      'last_counted_at':   null,
      'last_movement_at':  null,
      'shelf_name':        m['shelf_name']?.toString(),
      'updated_at':        m['updated_at']?.toString()
          ?? DateTime.now().toIso8601String(),
    };
  }
}

// ── BranchStockInventory model ──────────────────────────────────────
class BranchStockInventory {
  final String?      id;
  final String       storeId;
  final String       productId;
  final List<String> barcode;
  final String       sku;
  final String       productName;
  final double       purchasePrice;
  final double       salePrice;
  final double       wholesalePrice;
  final double       stock;
  final double       minStock;
  final double       maxStock;
  final String       unit;
  final String?      shelfName;

  BranchStockInventory({
    this.id,
    required this.storeId,
    required this.productId,
    required this.barcode,
    required this.sku,
    required this.productName,
    required this.purchasePrice,
    required this.salePrice,
    required this.wholesalePrice,
    required this.stock,
    this.minStock = 0,
    this.maxStock = 0,
    required this.unit,
    this.shelfName,
  });

  Map<String, dynamic> toJson() => {
    'store_id':        storeId,
    'product_id':      productId,
    'barcode':         barcode,
    'sku':             sku,
    'product_name':    productName,
    'purchase_price':  purchasePrice,
    'sale_price':      salePrice,
    'wholesale_price': wholesalePrice,
    'stock':           stock,
    'min_stock':       minStock,
    'max_stock':       maxStock,
    'unit':            unit,
    'shelf_name':      shelfName,
    'updated_at':      DateTime.now().toIso8601String(),
  };
}