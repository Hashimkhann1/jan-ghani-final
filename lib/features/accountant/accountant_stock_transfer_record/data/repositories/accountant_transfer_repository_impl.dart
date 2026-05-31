import '../../domain/repositories/accountant_transfer_repository.dart';
import '../datasource/accountant_transfer_remote_datasource.dart';
import '../model/accountant_transfer_model.dart';

class AccountantTransferRepositoryImpl
    implements AccountantTransferRepository {
  final AccountantTransferRemoteDatasource datasource;
  const AccountantTransferRepositoryImpl(this.datasource);

  @override
  Future<List<AccTransferModel>> getAllTransfers(String warehouseId) =>
      datasource.getAllTransfers(warehouseId);

  @override
  Future<List<AccTransferItemModel>> getTransferItems(String transferId) =>
      datasource.getTransferItems(transferId);
}
