import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/stock_transfer_mock_data.dart';
import '../../data/model/stock_transfer_model.dart';

// ── Notifier ──
class StockTransferNotifier extends Notifier<List<StockTransfer>> {
  @override
  List<StockTransfer> build() => List.from(mockStockTransfers);

  void acceptTransfer(String transferId) {
    state = [
      for (final t in state)
        if (t.transferId == transferId)
          StockTransfer(
            transferId: t.transferId,
            warehouseName: t.warehouseName,
            warehouseAddress: t.warehouseAddress,
            branchName: t.branchName,
            transferDate: t.transferDate,
            notes: t.notes,
            items: t.items,
            status: TransferStatus.accepted,
          )
        else
          t,
    ];
  }
}

final stockTransferProvider =
    NotifierProvider<StockTransferNotifier, List<StockTransfer>>(
  StockTransferNotifier.new,
);

// ── Stats ──
final pendingTransfersCountProvider = Provider<int>((ref) {
  return ref
      .watch(stockTransferProvider)
      .where((t) => t.status == TransferStatus.pending)
      .length;
});
