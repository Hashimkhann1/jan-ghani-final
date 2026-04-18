import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import '../models/assign_stock_item_model.dart';

class AssignStockLocalDatasource {
  final Connection db;

  AssignStockLocalDatasource({required this.db});

  Future<List<Map<String, dynamic>>> getLinkedStores(
      String warehouseId) async {

    final result = await db.execute(
      Sql.named('''
      SELECT store_id, store_name, store_code, store_phone, store_address
      FROM public.linked_stores
      WHERE warehouse_id = @warehouseId
      AND is_active = true
      AND deleted_at IS NULL
      ORDER BY store_name ASC
    '''),
      parameters: {'warehouseId': warehouseId},
    );

    // Convert each row to Map<String, dynamic> with proper type conversion
    return result.map((row) {
      final map = row.toColumnMap();
      // Ensure numeric values are converted properly if needed
      return Map<String, dynamic>.from(map);
    }).toList();
  }


  Future<void> insertTransfer({
    required String id,
    required String warehouseId,
    required String transferNumber,
    required String toStoreId,
    required String toStoreName,
    required String? assignedById,
    required String? assignedByName,
    required String? notes,
    required int totalItems,
    required double totalCost,
    required double totalSalePrice, // Add this parameter
  }) async {
    await db.execute(
      Sql.named('''
      INSERT INTO public.stock_transfers (
        id, warehouse_id, transfer_number,
        to_store_id, to_store_name,
        status, assigned_by_id, assigned_by_name,
        notes, total_items, total_cost, total_sale_price,
        created_at, updated_at
      ) VALUES (
        @id, @warehouseId, @transferNumber,
        @toStoreId, @toStoreName,
        'pending', @assignedById, @assignedByName,
        @notes, @totalItems, @totalCost, @totalSalePrice,
        NOW(), NOW()
      )
    '''),
      parameters: {
        'id': id,
        'warehouseId': warehouseId,
        'transferNumber': transferNumber,
        'toStoreId': toStoreId,
        'toStoreName': toStoreName,
        'assignedById': assignedById,
        'assignedByName': assignedByName,
        'notes': notes,
        'totalItems': totalItems,
        'totalCost': totalCost,
        'totalSalePrice': totalSalePrice,
      },
    );
  }

  Future<void> insertTransferItems({
    required String transferId,
    required String warehouseId,
    required String transferNumber, // Add this parameter
    required List<AssignStockCartItem> items,
  }) async {
    for (final item in items) {
      // Set transfer_number for each item
      final updatedItem = item.copyWith(transferNumber: transferNumber);
      final map = updatedItem.toLocalMap(transferId, warehouseId);

      await db.execute(
        Sql.named('''
        INSERT INTO public.stock_transfer_items (
          id, transfer_id, warehouse_id,
          product_id, inventory_id, product_name,
          sku, barcode, description, category_id,
          unit_of_measure, quantity_requested, quantity_sent, transfer_number,
          purchase_price, sale_price, wholesale_price,
          tax_rate, tax_amount, discount_amount,
          min_stock_level, max_stock_level, reorder_point,
          is_active, total_cost
        ) VALUES (
          @id, @transfer_id, @warehouse_id,
          @product_id, @inventory_id, @product_name,
          @sku, @barcode, @description, @category_id,
          @unit_of_measure, @quantity_requested, @quantity_sent, @transfer_number,
          @purchase_price, @sale_price, @wholesale_price,
          @tax_rate, @tax_amount, @discount_amount,
          @min_stock_level, @max_stock_level, @reorder_point,
          @is_active, @total_cost
        )
      '''),
        parameters: map,
      );
    }
  }

  Future<String> generateTransferNumber(String warehouseId) async {
    final uuid = const Uuid().v4();
    final shortUuid = uuid.substring(0, 8); // Use first 8 chars of UUID
    final date = DateTime.now();
    final dateStr = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

    return 'TRF-$dateStr-$shortUuid';
  }

// Stock check
  Future<bool> hasEnoughStock(
      String productId, String warehouseId, double qty) async {
    final result = await db.execute(
      Sql.named('''
      SELECT quantity FROM public.warehouse_inventory
      WHERE product_id = @productId
      AND warehouse_id = @warehouseId
    '''),
      parameters: {
        'productId': productId,
        'warehouseId': warehouseId,
      },
    );
    if (result.isEmpty) return false;

    // Fix: Handle both String and num types
    final quantityValue = result.first.toColumnMap()['quantity'];
    double available;

    if (quantityValue is String) {
      available = double.tryParse(quantityValue) ?? 0.0;
    } else if (quantityValue is num) {
      available = quantityValue.toDouble();
    } else {
      available = 0.0;
    }

    return available >= qty;
  }


  // Add this helper method to AssignStockLocalDatasource class
  dynamic _safeGetValue(Map<String, dynamic> map, String key) {
    final value = map[key];

    // If it's already the right type, return as is
    if (value is num || value is String || value == null) {
      return value;
    }

    // Try to convert if needed
    return value.toString();
  }

  double _safeGetDouble(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _safeGetInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

}