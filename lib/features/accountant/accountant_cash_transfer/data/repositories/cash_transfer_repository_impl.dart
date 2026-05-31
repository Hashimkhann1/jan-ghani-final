import '../../domain/repositories/cash_transfer_repository.dart';
import '../datasource/cash_transfer_remote_datasource.dart';
import '../model/cash_transfer_model.dart';

class CashTransferRepositoryImpl implements CashTransferRepository {
  final CashTransferRemoteDatasource datasource;
  const CashTransferRepositoryImpl(this.datasource);

  @override
  Future<void> sendCash({
    required String warehouseId,
    required String warehouseName,
    required double amount,
    String? sentById,
    required String sentByName,
    String? notes,
  }) =>
      datasource.sendCash(
        warehouseId: warehouseId,
        warehouseName: warehouseName,
        amount: amount,
        sentById: sentById,
        sentByName: sentByName,
        notes: notes,
      );

  @override
  Future<List<CashTransferModel>> getMyTransfers() =>
      datasource.getMyTransfers();

  @override
  Future<List<CashTransferModel>> getTransfersByWarehouse(String warehouseId) =>
      datasource.getTransfersByWarehouse(warehouseId);
}
