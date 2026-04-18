import 'package:flutter/cupertino.dart';
import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/branch_stock_model.dart';

class BranchStockDataSource {

  Future<List<BranchStockModel>> getAll(String storeId) async {
    final conn = await DataBaseService.getConnection();

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

  String? parseBarcode(dynamic value) {
    if (value == null) return null;
    return value
        .toString()
        .replaceAll('{', '')
        .replaceAll('}', '');
    /// Result: "897422342" ya "0731811817180,6115126632715,6127530860240"
  }

  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'inv_id':            m['inv_id']?.toString()         ?? '',
      'store_id':          m['store_id']?.toString()       ?? '',
      'product_id':        m['product_id']?.toString()     ?? '',
      'sku':               m['sku']?.toString()            ?? '',
      'barcode':           m['barcode']?.toString(),
      'name':              m['name']?.toString()           ?? '',
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