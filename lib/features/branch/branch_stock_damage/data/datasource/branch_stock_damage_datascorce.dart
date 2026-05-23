// lib/features/branch/branch_stock_damage/data/datasource/branch_stock_damage_datasource.dart

import 'package:postgres/postgres.dart';
import '../../../../../core/service/db/db_service.dart';
import '../model/branch_stock_damage_model.dart';

class BranchStockDamageDataSource {

  Future<({List<BranchStockDamageModel> rows, int totalCount})> getPaginated({
    required String storeId,
    required int    page,
    required int    pageSize,
    String          search       = '',
    String          filterStatus = 'all',
  }) async {
    final conn       = await DataBaseService.getConnection();
    final conditions = <String>['store_id = @storeId'];
    final params     = <String, dynamic>{'storeId': storeId};

    if (search.trim().isNotEmpty) {
      conditions.add("LOWER(product_name) LIKE @search");
      params['search'] = '%${search.trim().toLowerCase()}%';
    }
    if (filterStatus == 'today') {
      conditions.add("DATE(created_at) = CURRENT_DATE");
    } else if (filterStatus == 'this_week') {
      conditions.add("created_at >= DATE_TRUNC('week', CURRENT_DATE)");
    } else if (filterStatus == 'this_month') {
      conditions.add("created_at >= DATE_TRUNC('month', CURRENT_DATE)");
    }

    final where = conditions.join(' AND ');

    final countRes = await conn.execute(
      Sql.named('SELECT COUNT(*) FROM public.branch_stock_damage WHERE $where'),
      parameters: params,
    );
    final totalCount =
        int.tryParse(countRes.first.toColumnMap().values.first.toString()) ?? 0;

    params['limit']  = pageSize;
    params['offset'] = page * pageSize;

    final result = await conn.execute(
      Sql.named('''
        SELECT id, store_id, product_id, product_name,
               sale_price, purchase_price, stock_damage, created_at
        FROM public.branch_stock_damage
        WHERE $where
        ORDER BY created_at DESC
        LIMIT @limit OFFSET @offset
      '''),
      parameters: params,
    );

    return (
    rows:       result.map((r) => BranchStockDamageModel.fromMap(_toMap(r))).toList(),
    totalCount: totalCount,
    );
  }

  Future<Map<String, dynamic>> getStats(String storeId) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        SELECT
          COUNT(*)                                          AS total_records,
          COALESCE(SUM(stock_damage), 0)                   AS total_qty_damaged,
          COALESCE(SUM(stock_damage * purchase_price), 0)  AS total_loss_value
        FROM public.branch_stock_damage
        WHERE store_id = @storeId
      '''),
      parameters: {'storeId': storeId},
    );
    final m = result.first.toColumnMap();
    return {
      'total_records':     int.tryParse(m['total_records'].toString())        ?? 0,
      'total_qty_damaged': double.tryParse(m['total_qty_damaged'].toString()) ?? 0.0,
      'total_loss_value':  double.tryParse(m['total_loss_value'].toString())  ?? 0.0,
    };
  }

  Future<BranchStockDamageModel> addDamage({
    required String storeId,
    required String productId,
    required String productName,
    required double salePrice,
    required double purchasePrice,
    required double stockDamage,   // ✅ double
  }) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO public.branch_stock_damage
          (store_id, product_id, product_name, sale_price, purchase_price, stock_damage)
        VALUES
          (@storeId, @productId, @productName, @salePrice, @purchasePrice, @stockDamage)
        RETURNING *
      '''),
      parameters: {
        'storeId':       storeId,
        'productId':     productId,
        'productName':   productName,
        'salePrice':     salePrice,
        'purchasePrice': purchasePrice,
        'stockDamage':   stockDamage,
      },
    );
    return BranchStockDamageModel.fromMap(_toMap(result.first));
  }

  Future<BranchStockDamageModel> updateDamage({
    required String id,
    required double newStockDamage,  // ✅ int → double
  }) async {
    final conn   = await DataBaseService.getConnection();
    final result = await conn.execute(
      Sql.named('''
        UPDATE public.branch_stock_damage
        SET stock_damage = @stockDamage
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id':          id,
        'stockDamage': newStockDamage,
      },
    );
    return BranchStockDamageModel.fromMap(_toMap(result.first));
  }

  Future<void> deleteDamage(String id) async {
    final conn = await DataBaseService.getConnection();
    await conn.execute(
      Sql.named('DELETE FROM public.branch_stock_damage WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Map<String, dynamic> _toMap(ResultRow row) {
    final m = row.toColumnMap();
    return {
      'id':             m['id']?.toString()           ?? '',
      'store_id':       m['store_id']?.toString()     ?? '',
      'product_id':     m['product_id']?.toString()   ?? '',
      'product_name':   m['product_name']?.toString() ?? '',
      'sale_price':     m['sale_price'],
      'purchase_price': m['purchase_price'],
      'stock_damage':   m['stock_damage'],
      'created_at':     m['created_at']?.toString(),
    };
  }
}