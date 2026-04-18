import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assign_stock_item_model.dart';

class AssignStockRemoteDatasource {
  final SupabaseClient supabase;

  AssignStockRemoteDatasource({required this.supabase});

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
    required double totalSalePrice,
  }) async {
    await supabase.from('stock_transfers').insert({
      'id': id,
      'warehouse_id': warehouseId,
      'transfer_number': transferNumber,
      'to_store_id': toStoreId,
      'to_store_name': toStoreName,
      'status': 'pending',
      'assigned_by_id': assignedById,
      'assigned_by_name': assignedByName,
      'assigned_at': DateTime.now().toIso8601String(),
      'notes': notes,
      'total_items': totalItems,
      'total_cost': totalCost,
      'total_sale_price': totalSalePrice,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> insertTransferItems({
    required String transferId,
    required String warehouseId,
    required String transferNumber, // Add this parameter
    required List<AssignStockCartItem> items,
  }) async {
    final maps = items.map((item) {
      // Set transfer_number for each item
      final updatedItem = item.copyWith(transferNumber: transferNumber);
      return updatedItem.toRemoteMap(transferId, warehouseId);
    }).toList();

    await supabase.from('stock_transfer_items').insert(maps);
  }

}