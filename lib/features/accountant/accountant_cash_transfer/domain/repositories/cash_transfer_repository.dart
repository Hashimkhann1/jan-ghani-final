import '../../data/model/cash_transfer_model.dart';

abstract class CashTransferRepository {
  Future<void> sendCash({
    required String warehouseId,
    required String warehouseName,
    required double amount,
    String? sentById,
    required String sentByName,
    String? notes,
  });

  Future<List<CashTransferModel>> getMyTransfers();
  Future<List<CashTransferModel>> getTransfersByWarehouse(String warehouseId);
}
