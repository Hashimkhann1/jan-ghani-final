import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/service/db/db_service.dart';
import '../model/stock_return_model.dart';

class StockReturnDataSource {
  final SupabaseClient _client;
  StockReturnDataSource(this._client);

  double _d(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  // ── Branch ka linked warehouse ──────────────────────────────
  Future<String?> getWarehouseId(String storeId) async {
    final row = await _client
        .from('linked_stores')
        .select('warehouse_id')
        .eq('store_id', storeId)
        .eq('is_active', true)
        .isFilter('deleted_at', null)
        .limit(1)
        .maybeSingle();
    return row?['warehouse_id']?.toString();
  }

  String nextReturnNumber() {
    final now = DateTime.now();
    final r   = (now.millisecondsSinceEpoch % 900000 + Random().nextInt(99))
        .toString().padLeft(6, '0');
    return 'RET-${now.year}-$r';
  }

  // ── SEND ────────────────────────────────────────────────────
  // Ek local transaction: branch stock minus + Supabase insert.
  // Supabase fail ho to throw -> local rollback (stock minus nahi hota).
  // Local commit fail ho (Supabase insert ke baad) to header delete.
  Future<String> sendReturn({
    required String storeId,
    required String storeName,
    required String warehouseId,
    required String userId,
    required String userName,
    required String? notes,
    required List<ReturnCartLine> lines,
  }) async {
    final conn = await DataBaseService.getConnection();
    final returnNo = nextReturnNumber();
    String? returnId;

    try {
      await conn.runTx((tx) async {
        final itemRows = <Map<String, dynamic>>[];
        var totalQty = 0.0, totalCost = 0.0, totalSale = 0.0;

        for (final l in lines) {
          final res = await tx.execute(
            r'''SELECT id, product_id, sku, product_name, purchase_price,
                       sale_price, wholesale_price, min_stock, max_stock, unit,
                       category_id, shelf_name, stock, product_type,
                       COALESCE(array_to_json(barcode)::text, '[]') AS barcode_json
                FROM public.branch_stock_inventory
                WHERE store_id = $1 AND product_id = $2 AND deleted_at IS NULL
                FOR UPDATE''',
            parameters: [storeId, l.productId],
          );
          if (res.isEmpty) {
            throw Exception('${l.name}: branch stock mein nahi mila');
          }
          final m = res.first.toColumnMap();
          if (m['product_type'].toString() != 'physical') {
            throw Exception('${l.name}: digital product return nahi ho sakta');
          }
          final stock = _d(m['stock']);
          if (l.qty <= 0 || l.qty > stock) {
            throw Exception(
                '${l.name}: stock kam hai (available ${stock.toStringAsFixed(0)})');
          }

          await tx.execute(
            r'''UPDATE public.branch_stock_inventory
                SET stock = stock - $1, updated_at = NOW()
                WHERE store_id = $2 AND product_id = $3''',
            parameters: [l.qty, storeId, l.productId],
          );

          final cost = _d(m['purchase_price']);
          final sale = _d(m['sale_price']);
          totalQty  += l.qty;
          totalCost += cost * l.qty;
          totalSale += sale * l.qty;

          itemRows.add({
            'product_id':        l.productId,
            'inventory_id':      m['id']?.toString(),
            'product_name':      m['product_name'].toString(),
            'sku':               m['sku']?.toString(),
            'barcode':           List<String>.from(
                jsonDecode(m['barcode_json'].toString()) as List),
            'category_id':       m['category_id']?.toString(),
            'unit':              m['unit']?.toString() ?? 'pcs',
            'purchase_price':    cost,
            'sale_price':        sale,
            'wholesale_price':   _d(m['wholesale_price']),
            'min_stock':         _d(m['min_stock']),
            'max_stock':         _d(m['max_stock']),
            'shelf_name':        m['shelf_name']?.toString(),
            'stock_before':      stock,
            'quantity_returned': l.qty,
            'total_cost':        cost * l.qty,
            'total_sale_price':  sale * l.qty,
          });
        }

        final header = await _client.from('stock_returns').insert({
          'return_number':    returnNo,
          'from_store_id':    storeId,
          'from_store_name':  storeName,
          'warehouse_id':     warehouseId,
          'status':           'pending',
          'returned_by_id':   userId.isEmpty ? null : userId,
          'returned_by_name': userName,
          'notes':            (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
          'total_items':      totalQty,
          'total_cost':       totalCost,
          'total_sale_price': totalSale,
        }).select('id').single();
        returnId = header['id'].toString();

        await _client.from('stock_return_items').insert(
          itemRows.map((r) => {...r, 'return_id': returnId}).toList(),
        );
      });
    } catch (e) {
      // Header ban gaya lekin baad mein kuch fail hua -> saaf karo.
      if (returnId != null) {
        try {
          await _client.from('stock_returns').delete().eq('id', returnId!);
        } catch (ce) {
          debugPrint('❌ return cleanup failed: $ce');
        }
      }
      rethrow;
    }
    return returnNo;
  }

  // ── LIST ────────────────────────────────────────────────────
  Future<List<StockReturn>> fetchReturns(String storeId,
      {required String status, int limit = 100}) async {
    final res = await _client
        .from('stock_returns')
        .select('*, stock_return_items(*)')
        .eq('from_store_id', storeId)
        .eq('status', status)
        .isFilter('deleted_at', null)
        .order('returned_at', ascending: false)
        .limit(limit);
    return (res as List)
        .map((e) => StockReturn.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, int>> fetchCounts(String storeId) async {
    final res = await _client
        .from('stock_returns')
        .select('status')
        .eq('from_store_id', storeId)
        .isFilter('deleted_at', null);
    final out = {'pending': 0, 'accepted': 0, 'rejected': 0};
    for (final r in (res as List)) {
      final s = (r as Map)['status'].toString();
      if (out.containsKey(s)) out[s] = out[s]! + 1;
    }
    return out;
  }

  // ── REJECT -> stock wapis ───────────────────────────────────
  // Warehouse ne reject kiya aur branch ne abhi stock wapis nahi liya
  // (stock_restored = false): claim karo (atomic flag), phir local stock
  // add karo. Local fail ho to flag wapis false (retry ho sake).
  // Return: kitne returns ka stock wapis aaya.
  Future<int> restoreRejectedReturns(String storeId) async {
    final claimed = await _client
        .from('stock_returns')
        .select('id')
        .eq('from_store_id', storeId)
        .eq('status', 'rejected')
        .eq('stock_restored', false)
        .isFilter('deleted_at', null);

    var restored = 0;
    for (final row in (claimed as List)) {
      final id = (row as Map)['id'].toString();

      // Atomic claim: sirf ek caller jeetta hai.
      final won = await _client
          .from('stock_returns')
          .update({
            'stock_restored': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .eq('status', 'rejected')
          .eq('stock_restored', false)
          .select('id, stock_return_items(*)');
      if ((won as List).isEmpty) continue;

      final items = (won.first['stock_return_items'] as List? ?? const [])
          .map((e) => StockReturnItem.fromJson(e as Map<String, dynamic>))
          .toList();
      try {
        await _addBackLocal(storeId, items);
        restored++;
      } catch (e) {
        debugPrint('❌ restore failed for return $id: $e');
        try {
          await _client
              .from('stock_returns')
              .update({'stock_restored': false})
              .eq('id', id);
        } catch (_) {}
      }
    }
    return restored;
  }

  Future<void> _addBackLocal(String storeId, List<StockReturnItem> items) async {
    final conn = await DataBaseService.getConnection();
    await conn.runTx((tx) async {
      for (final it in items) {
        final upd = await tx.execute(
          r'''UPDATE public.branch_stock_inventory
              SET stock = stock + $1, deleted_at = NULL, updated_at = NOW()
              WHERE store_id = $2 AND product_id = $3''',
          parameters: [it.quantityReturned, storeId, it.productId],
        );
        if (upd.affectedRows == 0) {
          // Row beech mein purge ho gayi ho to snapshot se dobara banao.
          await tx.execute(
            r'''INSERT INTO public.branch_stock_inventory
                (store_id, product_id, barcode, sku, product_name,
                 purchase_price, sale_price, wholesale_price, stock,
                 min_stock, max_stock, unit, category_id, shelf_name,
                 product_type)
                VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,'physical')''',
            parameters: [
              storeId, it.productId, _pgArray(it.barcode), it.sku,
              it.productName, it.purchasePrice, it.salePrice,
              it.wholesalePrice, it.quantityReturned, it.minStock,
              it.maxStock, it.unit, it.categoryId, it.shelfName,
            ],
          );
        }
      }
    });
  }

  String _pgArray(List<String> v) => '{${v.map((s) =>
      '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"').join(',')}}';
}
