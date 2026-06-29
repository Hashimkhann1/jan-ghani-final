import 'dart:async';

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

  /// Returns `true` agar Supabase par bhi turant mirror ho gaya,
  /// `false` agar internet na hone ki wajah se sirf local save hua
  /// (background sync internet aate hi khud push kar degi).
  Future<bool> assignStock({
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
    //    Yeh BEST-EFFORT hai: local pehle hi commit ho chuka hai aur
    //    background sync (is_synced=false) internet aate hi row push kar degi.
    //    Is liye agar internet na ho to network error ko swallow karke
    //    "offline saved" (false) return karte hain — taake transfer kamyab
    //    mana jaye, cart clear ho aur number rotate ho (duplicate se bachao).
    //    Network ke ilawa koi aur error (e.g. duplicate) waise hi rethrow hoga.
    //
    //    ⚠️ Timeout zaroori hai: offline mein Supabase ka HTTP client error
    //    turant throw nahi karta — woh DNS/connection par lamba HANG karta hai,
    //    jis se "Assigning..." button atak jaata hai. Timeout se ~8s mein
    //    fail ho kar offline (false) return ho jata hai; local pehle hi saved
    //    + background sync internet aate hi push karegi.
    const remoteTimeout = Duration(seconds: 6);
    try {
      await remote
          .insertTransfer(
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
          )
          .timeout(remoteTimeout);

      await remote
          .insertTransferItems(
            transferId: id,
            warehouseId: warehouseId,
            transferNumber: transferNumber, // Pass transferNumber
            items: items,
          )
          .timeout(remoteTimeout);
      return true; // online — Supabase par bhi ho gaya
    } catch (e) {
      if (e is TimeoutException || _isNetworkError(e)) {
        return false; // offline — local saved, sync baad mein push karegi
      }
      rethrow; // koi aur masla — surface karo
    }
  }

  /// Internet/connection error detect karo (SocketException, host lookup
  /// fail, ClientException waghaira). Sirf in cases mein remote ko skip karte
  /// hain — baaki errors normal tareeqe se uupar jaate hain.
  bool _isNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('clientexception') ||
        s.contains('nodename nor servname') ||
        s.contains('network is unreachable') ||
        s.contains('connection closed') ||
        s.contains('connection refused') ||
        s.contains('connection timed out') ||
        s.contains('errno = 8') ||
        s.contains('errno = 7');
  }
}