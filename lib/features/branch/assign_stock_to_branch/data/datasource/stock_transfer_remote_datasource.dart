// import 'package:flutter/cupertino.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import '../../../../../core/service/db/db_service.dart';
// import '../../../branch_stock_inventory/data/model/branch_stock_inventory_model.dart';
// import '../model/stock_transfer_model.dart';
//
// class StockTransferRemoteDataSource {
//   final SupabaseClient _client;
//
//   StockTransferRemoteDataSource(this._client);
//
//   // Store ke saare transfers fetch karo
//   Future<List<StockTransfer>> fetchTransfersByStore(String storeId) async {
//     final response = await _client
//         .from('stock_transfers')
//         .select('*, stock_transfer_items(*)')
//         .eq('to_store_id', storeId)
//         .isFilter('deleted_at', null)
//         .order('assigned_at', ascending: false);
//
//     return (response as List)
//         .map((json) => StockTransfer.fromJson(json))
//         .toList();
//   }
//
//   // Transfer accept karo
//   Future<void> acceptTransfer(String transferId) async {
//     await _client
//         .from('stock_transfers')
//         .update({
//       'status': 'accepted',
//       'updated_at': DateTime.now().toIso8601String(),
//     })
//         .eq('id', transferId);
//   }
//
//   // Transfer reject karo
//   Future<void> rejectTransfer(String transferId) async {
//     await _client
//         .from('stock_transfers')
//         .update({
//       'status': 'rejected',
//       'updated_at': DateTime.now().toIso8601String(),
//     })
//         .eq('id', transferId);
//   }
//
//   // ─── Supabase: Branch stock inventory mein add/update karo ───────────────
//   Future<void> upsertBranchStock({
//     required String storeId,
//     required List<StockTransferItem> items,
//   }) async {
//     for (final item in items) {
//       try {
//         final existing = await _client
//             .from('branch_stock_inventory')
//             .select()
//             .eq('store_id', storeId)
//             .eq('product_id', item.productId)
//             .maybeSingle();
//
//         debugPrint(
//             '🔍 Product: ${item.productName} | Existing: ${existing != null}');
//
//         if (existing != null) {
//           final currentStock = double.parse(existing['stock'].toString());
//           final newStock = currentStock + item.quantitySent;
//           debugPrint(
//               '📦 Updating stock: $currentStock + ${item.quantitySent} = $newStock');
//
//           await _client
//               .from('branch_stock_inventory')
//               .update({
//             'stock': newStock,
//             'category_id': item.categoryId,        // ✅ NEW
//             'purchase_price': item.purchasePrice,
//             'sale_price': item.salePrice,
//             'wholesale_price': item.wholesalePrice,
//             'min_stock': item.minStockLevel,
//             'max_stock': item.maxStockLevel,
//             'barcode': item.barcode,
//             'sku': item.sku,
//             'updated_at': DateTime.now().toIso8601String(),
//           })
//               .eq('store_id', storeId)
//               .eq('product_id', item.productId);
//         } else {
//           debugPrint('➕ Inserting new product: ${item.productName}');
//
//           final inventory = BranchStockInventory(
//             storeId: storeId,
//             productId: item.productId,
//             categoryId: item.categoryId,               // ✅ NEW
//             barcode: item.barcode,
//             sku: item.sku,
//             productName: item.productName,
//             purchasePrice: item.purchasePrice,
//             salePrice: item.salePrice,
//             wholesalePrice: item.wholesalePrice,
//             stock: item.quantitySent,
//             unit: item.unitOfMeasure,
//             minStock: item.minStockLevel.toDouble(),
//             maxStock: item.maxStockLevel.toDouble(),
//           );
//
//           await _client
//               .from('branch_stock_inventory')
//               .insert(inventory.toJson());
//         }
//       } catch (e) {
//         debugPrint('❌ upsert error for ${item.productName}: $e');
//         rethrow;
//       }
//     }
//   }
//
//   // ─── Local PostgreSQL: Branch stock inventory mein add/update karo ───────
//   Future<void> upsertLocalBranchStock({
//     required String storeId,
//     required List<StockTransferItem> items,
//   }) async {
//     final conn = await DataBaseService.getConnection();
//
//     for (final item in items) {
//       try {
//         final existing = await conn.execute(
//           r'SELECT stock FROM public.branch_stock_inventory '
//           r'WHERE store_id = $1 AND product_id = $2',
//           parameters: [storeId, item.productId],
//         );
//
//         if (existing.isNotEmpty) {
//           // ✅ toString() se parse karo — type cast issue fix
//           final currentStock = double.parse(existing.first[0].toString());
//           final newStock = currentStock + item.quantitySent;
//
//           debugPrint(
//               '📦 Updating: ${item.productName} | $currentStock + ${item.quantitySent} = $newStock');
//
//           await conn.execute(
//             r'''UPDATE public.branch_stock_inventory SET
//               stock          = $1,
//               purchase_price = $2,
//               sale_price     = $3,
//               wholesale_price= $4,
//               min_stock      = $5,
//               max_stock      = $6,
//               barcode        = $7,
//               sku            = $8,
//               category_id    = $9,
//               updated_at     = NOW()
//             WHERE store_id = $10 AND product_id = $11''',
//             parameters: [
//               newStock,           // $1
//               item.purchasePrice, // $2
//               item.salePrice,     // $3
//               item.wholesalePrice,// $4
//               item.minStockLevel, // $5
//               item.maxStockLevel, // $6
//               item.barcode,       // $7
//               item.sku,           // $8
//               item.categoryId,    // $9  ✅ NEW
//               storeId,            // $10
//               item.productId,     // $11
//             ],
//           );
//
//           debugPrint('✅ Updated: ${item.productName} | New Stock: $newStock');
//         } else {
//           debugPrint('➕ Inserting: ${item.productName}');
//
//           await conn.execute(
//             r'''INSERT INTO public.branch_stock_inventory
//               (store_id, product_id, barcode, sku, product_name,
//                purchase_price, sale_price, wholesale_price,
//                stock, min_stock, max_stock, unit, category_id)
//             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)''',
//             parameters: [
//               storeId,            // $1
//               item.productId,     // $2
//               item.barcode,       // $3
//               item.sku,           // $4
//               item.productName,   // $5
//               item.purchasePrice, // $6
//               item.salePrice,     // $7
//               item.wholesalePrice,// $8
//               item.quantitySent,  // $9
//               item.minStockLevel, // $10
//               item.maxStockLevel, // $11
//               item.unitOfMeasure, // $12
//               item.categoryId,    // $13 ✅ NEW
//             ],
//           );
//
//           debugPrint('✅ Inserted: ${item.productName}');
//         }
//       } catch (e) {
//         debugPrint('❌ upsertLocal error for ${item.productName}: $e');
//         rethrow;
//       }
//     }
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/service/db/db_service.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_inventory_model.dart';
import '../model/stock_transfer_model.dart';

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

  // Transfer accept karo
  Future<void> acceptTransfer(String transferId) async {
    await _client
        .from('stock_transfers')
        .update({
      'status': 'accepted',
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', transferId);
  }

  // Transfer reject karo
  Future<void> rejectTransfer(String transferId) async {
    await _client
        .from('stock_transfers')
        .update({
      'status': 'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', transferId);
  }

  // ─── Supabase: Branch stock inventory mein add/update karo ───────────────
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
          final newStock = currentStock + item.quantitySent;
          debugPrint(
              '📦 Updating stock: $currentStock + ${item.quantitySent} = $newStock');

          await _client
              .from('branch_stock_inventory')
              .update({
            'stock': newStock,
            'category_id': item.categoryId,        // ✅ NEW
            'product_name': item.productName,       // ✅ NEW
            'unit': item.unitOfMeasure,              // ✅ NEW
            'purchase_price': item.purchasePrice,
            'sale_price': item.salePrice,
            'wholesale_price': item.wholesalePrice,
            'min_stock': item.minStockLevel,
            'max_stock': item.maxStockLevel,
            'barcode': item.barcode,
            'sku': item.sku,
            'updated_at': DateTime.now().toIso8601String(),
          })
              .eq('store_id', storeId)
              .eq('product_id', item.productId);
        } else {
          debugPrint('➕ Inserting new product: ${item.productName}');

          final inventory = BranchStockInventory(
            storeId: storeId,
            productId: item.productId,
            categoryId: item.categoryId,               // ✅ NEW
            barcode: item.barcode,
            sku: item.sku,
            productName: item.productName,
            purchasePrice: item.purchasePrice,
            salePrice: item.salePrice,
            wholesalePrice: item.wholesalePrice,
            stock: item.quantitySent,
            unit: item.unitOfMeasure,
            minStock: item.minStockLevel.toDouble(),
            maxStock: item.maxStockLevel.toDouble(),
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

  // ─── Local PostgreSQL: Branch stock inventory mein add/update karo ───────
  Future<void> upsertLocalBranchStock({
    required String storeId,
    required List<StockTransferItem> items,
  }) async {
    final conn = await DataBaseService.getConnection();

    for (final item in items) {
      try {
        final existing = await conn.execute(
          r'SELECT stock FROM public.branch_stock_inventory '
          r'WHERE store_id = $1 AND product_id = $2',
          parameters: [storeId, item.productId],
        );

        if (existing.isNotEmpty) {
          // ✅ toString() se parse karo — type cast issue fix
          final currentStock = double.parse(existing.first[0].toString());
          final newStock = currentStock + item.quantitySent;

          debugPrint(
              '📦 Updating: ${item.productName} | $currentStock + ${item.quantitySent} = $newStock');

          await conn.execute(
            r'''UPDATE public.branch_stock_inventory SET
              stock          = $1,
              purchase_price = $2,
              sale_price     = $3,
              wholesale_price= $4,
              min_stock      = $5,
              max_stock      = $6,
              barcode        = $7,
              sku            = $8,
              category_id    = $9,
              product_name   = $10,
              unit           = $11,
              updated_at     = NOW()
            WHERE store_id = $12 AND product_id = $13''',
            parameters: [
              newStock,           // $1
              item.purchasePrice, // $2
              item.salePrice,     // $3
              item.wholesalePrice,// $4
              item.minStockLevel, // $5
              item.maxStockLevel, // $6
              item.barcode,       // $7
              item.sku,           // $8
              item.categoryId,    // $9  ✅ NEW
              item.productName,   // $10 ✅ NEW
              item.unitOfMeasure, // $11 ✅ NEW
              storeId,            // $12
              item.productId,     // $13
            ],
          );

          debugPrint('✅ Updated: ${item.productName} | New Stock: $newStock');
        } else {
          debugPrint('➕ Inserting: ${item.productName}');

          await conn.execute(
            r'''INSERT INTO public.branch_stock_inventory
              (store_id, product_id, barcode, sku, product_name,
               purchase_price, sale_price, wholesale_price,
               stock, min_stock, max_stock, unit, category_id)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)''',
            parameters: [
              storeId,            // $1
              item.productId,     // $2
              item.barcode,       // $3
              item.sku,           // $4
              item.productName,   // $5
              item.purchasePrice, // $6
              item.salePrice,     // $7
              item.wholesalePrice,// $8
              item.quantitySent,  // $9
              item.minStockLevel, // $10
              item.maxStockLevel, // $11
              item.unitOfMeasure, // $12
              item.categoryId,    // $13 ✅ NEW
            ],
          );

          debugPrint('✅ Inserted: ${item.productName}');
        }
      } catch (e) {
        debugPrint('❌ upsertLocal error for ${item.productName}: $e');
        rethrow;
      }
    }
  }
}