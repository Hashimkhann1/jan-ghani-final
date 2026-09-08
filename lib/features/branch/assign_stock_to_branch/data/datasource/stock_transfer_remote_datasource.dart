import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/service/db/db_service.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_inventory_model.dart';
import '../model/stock_transfer_model.dart';

/// Ek status ke transfers ka count + aggregate totals.
class TransferStatusAgg {
  final int    count;
  final int    totalUnits;
  final double totalCost;
  final double totalSale;

  const TransferStatusAgg({
    this.count = 0,
    this.totalUnits = 0,
    this.totalCost = 0,
    this.totalSale = 0,
  });
}

class _MutAgg {
  int count = 0;
  int units = 0;
  double cost = 0;
  double sale = 0;
}

class StockTransferRemoteDataSource {
  final SupabaseClient _client;

  StockTransferRemoteDataSource(this._client);

  // Store ke saare transfers fetch karo
  Future<List<StockTransfer>> fetchTransfersByStore(String storeId) async {
    final response = await _client
        .from('stock_transfers')
        .select('*, stock_transfer_items(*)')
        .eq('to_store_id', storeId)
        .isFilter('deleted_at', null)
        .order('assigned_at', ascending: false);

    return (response as List)
        .map((json) => StockTransfer.fromJson(json))
        .toList();
  }

  // ── SERVER-SIDE PAGINATION ─────────────────────────────────────────────
  /// Sirf ek status (pending/accepted/rejected) ke, sirf ek page ke rows —
  /// `stock_transfer_items(*)` join ke saath (heavy query, isi liye paged).
  Future<List<StockTransfer>> fetchTransfersPage(
    String storeId, {
    required String status,
    required int offset,
    required int limit,
  }) async {
    final response = await _client
        .from('stock_transfers')
        .select('*, stock_transfer_items(*)')
        .eq('to_store_id', storeId)
        .eq('status', status)
        .isFilter('deleted_at', null)
        .order('assigned_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => StockTransfer.fromJson(json))
        .toList();
  }

  /// Har status ke count + total units/cost/sale — sirf 4 chhote numeric
  /// columns (koi items join nahi), is liye poore store ke liye bhi halka.
  Future<Map<String, TransferStatusAgg>> fetchStatusAggregates(
      String storeId) async {
    final response = await _client
        .from('stock_transfers')
        .select('status, total_items, total_cost, total_sale_price')
        .eq('to_store_id', storeId)
        .isFilter('deleted_at', null);

    final out = <String, _MutAgg>{
      'pending':  _MutAgg(),
      'accepted': _MutAgg(),
      'rejected': _MutAgg(),
    };

    for (final row in (response as List)) {
      final m = row as Map<String, dynamic>;
      final s = (m['status'] ?? '').toString();
      final agg = out[s];
      if (agg == null) continue;
      agg.count += 1;
      agg.units += (num.tryParse('${m['total_items']}') ?? 0).toInt();
      agg.cost  += num.tryParse('${m['total_cost']}')?.toDouble() ?? 0;
      agg.sale  += num.tryParse('${m['total_sale_price']}')?.toDouble() ?? 0;
    }

    return out.map((k, v) => MapEntry(
          k,
          TransferStatusAgg(
            count: v.count,
            totalUnits: v.units,
            totalCost: v.cost,
            totalSale: v.sale,
          ),
        ));
  }

  // Transfer accept karo — ATOMICALLY guarded: sirf tab flip hota hai jab
  // status abhi bhi 'pending' hai. Return: true = is call ne "claim" jeeta
  // (pehli baar accept hua, isi call ko local stock add karni chahiye),
  // false = transfer already non-pending tha (kisi aur device/retry ne
  // pehle hi accept/reject kar diya) — idempotent no-op, local stock
  // dobara add NAHI karni.
  Future<bool> acceptTransfer(String transferId) async {
    final result = await _client
        .from('stock_transfers')
        .update({
      'status':     'accepted',
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', transferId)
        .eq('status', 'pending')
        .select('id');
    return (result as List).isNotEmpty;
  }

  // Compensation: agar Supabase status 'accepted' ho gaya lekin uske baad
  // local stock upsert fail ho jaye, to status wapas 'pending' par revert
  // karo — taake transfer safely retry ho sake (aur stock permanently
  // "gum" na ho).
  Future<void> revertToPending(String transferId) async {
    await _client
        .from('stock_transfers')
        .update({
      'status':     'pending',
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', transferId)
        .eq('status', 'accepted');
  }

  // Transfer reject karo
  Future<void> rejectTransfer(String transferId) async {
    await _client
        .from('stock_transfers')
        .update({
      'status':     'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', transferId);
  }

  // ─── Supabase: Branch stock inventory mein add/update karo ───────────────
  // Supabase SDK List<String> handle kar leta hai directly — no change needed
  Future<void> upsertBranchStock({
    required String storeId,
    required List<StockTransferItem> items,
  }) async {
    for (final item in items) {
      try {
        final existing = await _client
            .from('branch_stock_inventory')
            .select()
            .eq('store_id', storeId)
            .eq('product_id', item.productId)
            .maybeSingle();

        debugPrint(
            '🔍 Product: ${item.productName} | Existing: ${existing != null}');

        if (existing != null) {
          final currentStock = double.parse(existing['stock'].toString());
          final newStock     = currentStock + item.quantitySent;
          debugPrint(
              '📦 Updating stock: $currentStock + ${item.quantitySent} = $newStock');

          await _client
              .from('branch_stock_inventory')
              .update({
            'stock':          newStock,
            'category_id':    item.categoryId,
            'product_name':   item.productName,
            'unit':           item.unitOfMeasure,
            'purchase_price': item.purchasePrice,
            'sale_price':     item.salePrice,
            'wholesale_price':item.wholesalePrice,
            'min_stock':      item.minStockLevel,
            'max_stock':      item.maxStockLevel,
            'barcode':        item.barcode,      // Supabase SDK handles List<String>
            'sku':            item.sku,
            'deleted_at':     null,              // naya stock aaya → product wapas active
            'updated_at':     DateTime.now().toIso8601String(),
          })
              .eq('store_id', storeId)
              .eq('product_id', item.productId);
        } else {
          debugPrint('➕ Inserting new product: ${item.productName}');

          final inventory = BranchStockInventory(
            storeId:        storeId,
            productId:      item.productId,
            categoryId:     item.categoryId,
            barcode:        item.barcode,
            sku:            item.sku,
            productName:    item.productName,
            purchasePrice:  item.purchasePrice,
            salePrice:      item.salePrice,
            wholesalePrice: item.wholesalePrice,
            stock:          item.quantitySent,
            unit:           item.unitOfMeasure,
            minStock:       item.minStockLevel.toDouble(),
            maxStock:       item.maxStockLevel.toDouble(),
          );

          await _client
              .from('branch_stock_inventory')
              .insert(inventory.toJson());
        }
      } catch (e) {
        debugPrint('❌ upsert error for ${item.productName}: $e');
        rethrow;
      }
    }
  }

  // Postgres text[] literal ke andar har element ko double-quote + escape
  // karo (backslash aur double-quote escape). Isse comma/brace/empty-string
  // wale barcode bhi safely handle hote hain — bina is se ek comma-wala
  // barcode poore array ko todh sakta tha ya empty barcode silently gum
  // ho jata tha.
  String _pgTextArrayLiteral(List<String> values) {
    final escaped = values.map((v) {
      final safe = v.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
      return '"$safe"';
    });
    return '{${escaped.join(',')}}';
  }

  // ─── Local PostgreSQL: Branch stock inventory mein add/update karo ───────
  // Poora batch EK transaction mein — agar kisi item par error aaye to
  // saare items rollback ho jate hain. Isse partial-apply hone ke baad
  // retry par pehle-se-committed items dobara add (double-credit) nahi
  // hote.
  Future<void> upsertLocalBranchStock({
    required String storeId,
    required List<StockTransferItem> items,
  }) async {
    final conn = await DataBaseService.getConnection();

    await conn.runTx((tx) async {
      for (final item in items) {
        final existing = await tx.execute(
          r'SELECT stock FROM public.branch_stock_inventory '
          r'WHERE store_id = $1 AND product_id = $2',
          parameters: [storeId, item.productId],
        );

        final barcodeArray = _pgTextArrayLiteral(item.barcode);

        if (existing.isNotEmpty) {
          final currentStock = double.parse(existing.first[0].toString());
          final newStock     = currentStock + item.quantitySent;

          debugPrint(
              '📦 Updating: ${item.productName} | $currentStock + ${item.quantitySent} = $newStock');

          await tx.execute(
            r'''UPDATE public.branch_stock_inventory SET
              stock           = $1,
              purchase_price  = $2,
              sale_price      = $3,
              wholesale_price = $4,
              min_stock       = $5,
              max_stock       = $6,
              barcode         = $7,
              sku             = $8,
              category_id     = $9,
              product_name    = $10,
              unit            = $11,
              deleted_at      = NULL,
              updated_at      = NOW()
            WHERE store_id = $12 AND product_id = $13''',
            parameters: [
              newStock,           // $1
              item.purchasePrice, // $2
              item.salePrice,     // $3
              item.wholesalePrice,// $4
              item.minStockLevel, // $5
              item.maxStockLevel, // $6
              barcodeArray,       // $7
              item.sku,           // $8
              item.categoryId,    // $9
              item.productName,   // $10
              item.unitOfMeasure, // $11
              storeId,            // $12
              item.productId,     // $13
            ],
          );

          debugPrint('✅ Updated: ${item.productName} | New Stock: $newStock');
        } else {
          debugPrint('➕ Inserting: ${item.productName}');

          await tx.execute(
            r'''INSERT INTO public.branch_stock_inventory
              (store_id, product_id, barcode, sku, product_name,
               purchase_price, sale_price, wholesale_price,
               stock, min_stock, max_stock, unit, category_id)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)''',
            parameters: [
              storeId,            // $1
              item.productId,     // $2
              barcodeArray,       // $3
              item.sku,           // $4
              item.productName,   // $5
              item.purchasePrice, // $6
              item.salePrice,     // $7
              item.wholesalePrice,// $8
              item.quantitySent,  // $9
              item.minStockLevel, // $10
              item.maxStockLevel, // $11
              item.unitOfMeasure, // $12
              item.categoryId,    // $13
            ],
          );

          debugPrint('✅ Inserted: ${item.productName}');
        }
      }
    });
  }
}
