// =============================================================
// mock_purchase_order_datasource.dart
// =============================================================

import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/datasource/purchase_order_remote_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_order_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([PurchaseOrderRemoteDataSource])
class MockPurchaseOrderRemoteDataSource extends Mock
    implements PurchaseOrderRemoteDataSource {

  // ── Call tracking ─────────────────────────────────────────
  int    insertSupplierPaymentLedgerCallCount = 0;
  double lastInsertedPaymentAmount            = 0;
  String lastInsertedPaymentNotes             = '';

  int    updateInventoryCallCount = 0;
  double lastInventoryQtyDiff     = 0;

  // ── Default stub data ─────────────────────────────────────
  PurchaseOrderModel? stubGetById;

  @override
  Future<PurchaseOrderModel?> getById(String id) async =>
      stubGetById;

  @override
  Future<void> insertSupplierPaymentLedger({
    required String warehouseId,
    required String supplierId,
    required String poId,
    required double amount,
    String?         notes,
    String?         createdBy,
  }) async {
    insertSupplierPaymentLedgerCallCount++;
    lastInsertedPaymentAmount = amount;
    lastInsertedPaymentNotes  = notes ?? '';
  }

  @override
  Future<PurchaseOrderModel> updatePO({
    required String                 poId,
    required String                 warehouseId,
    required String                 oldStatus,
    String?                         supplierId,
    String?                         status,
    DateTime?                       expectedDate,
    double                          subtotal        = 0,
    double                          discountAmount  = 0,
    double                          taxAmount       = 0,
    double                          totalAmount     = 0,
    double                          paidAmount      = 0,
    double                          remainingAmount = 0,
    String?                         notes,
    String?                         updatedBy,
    String?                         updatedByName,
    List<PurchaseOrderItem>         oldItems        = const [],
    required List<PurchaseOrderItem> items,
  }) async => stubGetById!;

  @override
  Future<PurchaseOrderModel> create({
    required String                  warehouseId,
    required String                  poNumber,
    String?                          destinationLocationId,
    String?                          supplierId,
    String?                          status,
    DateTime?                        expectedDate,
    double                           subtotal        = 0,
    double                           discountAmount  = 0,
    double                           taxAmount       = 0,
    double                           totalAmount     = 0,
    double                           paidAmount      = 0,
    double                           remainingAmount = 0,
    String?                          notes,
    String?                          createdBy,
    String?                          createdByName,
    required List<PurchaseOrderItem> items,
  }) async => stubGetById!;

  @override
  Future<PurchaseOrderStats> getStats(String warehouseId) async =>
      const PurchaseOrderStats(
        totalPOs:         0,
        pendingCount:     0,
        receivedCount:    0,
        thisMonthTotal:   0,
        totalOutstanding: 0,
      );

  @override
  Future<List<PurchaseOrderModel>> getAll(String warehouseId) async => [];
}