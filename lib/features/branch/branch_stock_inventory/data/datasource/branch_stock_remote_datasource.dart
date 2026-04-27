
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
          updated_at
        FROM public.branch_stock_inventory
        WHERE store_id = @storeId
        ORDER BY product_name ASC
      '''),
      parameters: {'storeId': storeId},
    );
    return result.map((r) => BranchStockModel.fromMap(_toMap(r))).toList();
  }

  // ── Inventory screen ke liye: paginated + server-side search/filter ──
  // DB pe sirf zarori rows — 10k products hone pe bhi fast
  Future<({List<BranchStockModel> rows, int totalCount})> getPaginated({
    required String storeId,
    required int    page,        // 0-based
    required int    pageSize,
    String          search      = '',
    String          filterStatus = 'all', // all | in_stock | low_stock | out_of_stock
  }) async {
    final conn = await DataBaseService.getConnection();

    // ── WHERE conditions build karo ─────────────────────────
    final conditions = <String>['store_id = @storeId'];
    final params     = <String, dynamic>{'storeId': storeId};

    // Search — name, SKU, barcode
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

    // Stock filter — reorder_point se compare karo
    if (filterStatus == 'in_stock') {
      conditions.add('stock > reorder_point');
    } else if (filterStatus == 'low_stock') {
      conditions.add('stock <= reorder_point AND stock > 0');
    } else if (filterStatus == 'out_of_stock') {
      conditions.add('stock <= 0');
    }

    final whereClause = conditions.join(' AND ');

    // ── Total count (pagination ke liye) ────────────────────
    final countResult = await conn.execute(
      Sql.named('SELECT COUNT(*) FROM public.branch_stock_inventory WHERE $whereClause'),
      parameters: params,
    );
    final totalCount = int.tryParse(
        countResult.first.toColumnMap().values.first.toString()) ?? 0;

    // ── Paginated rows ───────────────────────────────────────
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
      'updated_at':        m['updated_at']?.toString()
          ?? DateTime.now().toIso8601String(),
    };
  }
}

// ── BranchStockInventory model (unchanged) ─────────────────────────
class BranchStockInventory {
  final String?        id;
  final String         storeId;
  final String         productId;
  final List<String>   barcode;
  final String         sku;
  final String         productName;
  final double         purchasePrice;
  final double         salePrice;
  final double         wholesalePrice;
  final double         stock;
  final double         minStock;
  final double         maxStock;
  final String         unit;

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
    'updated_at':      DateTime.now().toIso8601String(),
  };
}