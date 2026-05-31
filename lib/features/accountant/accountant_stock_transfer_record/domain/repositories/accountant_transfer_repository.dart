import '../../data/model/accountant_transfer_model.dart';

abstract class AccountantTransferRepository {
  Future<List<AccTransferModel>> getAllTransfers(String warehouseId);
  Future<List<AccTransferItemModel>> getTransferItems(String transferId);
}
