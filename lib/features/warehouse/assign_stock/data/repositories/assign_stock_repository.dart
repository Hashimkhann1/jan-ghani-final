import 'package:uuid/uuid.dart';
import '../datasources/assign_stock_local_datasource.dart';
import '../datasources/assign_stock_remote_datasource.dart';
import '../models/assign_stock_item_model.dart';
import '../models/assign_stock_model.dart';

class AssignStockRepository {
  final AssignStockLocalDatasource local;
  final AssignStockRemoteDatasource remote;

  AssignStockRepository({
    required this.local,
    required this.remote,
  });

  Future<List<LinkedStoreItem>> getLinkedStores(
      String warehouseId) async {
    final maps = await local.getLinkedStores(warehouseId);
    print(maps);
    return maps.map((m) => LinkedStoreItem.fromMap(m)).toList();
  }

  Future<String> generateTransferNumber(String warehouseId) async {
    return await local.generateTransferNumber(warehouseId);
  }

  Future<bool> checkStock(
      String productId, String warehouseId, double qty) async {
    return await local.hasEnoughStock(productId, warehouseId, qty);
  }

  Future<void> assignStock({
    required String warehouseId,
    required String transferNumber,
    required String toStoreId,
    required String toStoreName,
    required String? assignedById,
    required String? assignedByName,
    required String? notes,
    required List<AssignStockCartItem> items,
  }) async {
    final id = const Uuid().v4();
    final totalCost = items.fold(0.0, (sum, i) => sum + i.totalCost);
    final totalSalePrice = items.fold(0.0, (sum, i) => sum + i.totalSalePrice);

    // 1) PEHLE local: validate + insert + reserve — sab ek transaction mein.
    //    Stock kam ho to yahan throw hoga aur Supabase par kuch save nahi hoga.
    await local.insertTransferWithReservation(
      id: id,
      warehouseId: warehouseId,
      transferNumber: transferNumber,
      toStoreId: toStoreId,
      toStoreName: toStoreName,
      assignedById: assignedById,
      assignedByName: assignedByName,
      notes: notes,
      totalItems: items.length,
      totalCost: totalCost,
      totalSalePrice: totalSalePrice,
      items: items,
    );

    // 2) PHIR Supabase mein mirror karo (store ko turant dikhane ke liye).
    //    Reserved inventory background sync (is_synced=false) se khud push hoti hai.
    await remote.insertTransfer(
      id: id,
      warehouseId: warehouseId,
      transferNumber: transferNumber,
      toStoreId: toStoreId,
      toStoreName: toStoreName,
      assignedById: assignedById,
      assignedByName: assignedByName,
      notes: notes,
      totalItems: items.length,
      totalCost: totalCost,
      totalSalePrice: totalSalePrice,
    );

    await remote.insertTransferItems(
      transferId: id,
      warehouseId: warehouseId,
      transferNumber: transferNumber, // Pass transferNumber
      items: items,
    );
  }
}