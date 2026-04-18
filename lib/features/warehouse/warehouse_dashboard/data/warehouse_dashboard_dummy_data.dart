import '../domain/warehouse_dashboard_models.dart';

const dummyDashboardStats = DashboardStats(
  totalProducts:       1248,
  lowStockCount:       23,
  activeSuppliers:     14,
  totalOutstanding:    55500,
  pendingPOs:          7,
  unsyncedRecords:     8,
  totalPurchaseAmount: 125000, // ← naya
  totalOrdersCount:    21,     // ← naya
);

// Pending transfers — abhi dummy (real baad mein)
final dummyPendingTransfers = [
  PendingTransfer(
    id:             'trf-012',
    transferNumber: 'TRF-2026-000012',
    fromLocation:   'WH-MAIN',
    toLocation:     'STORE-01',
    status:         'approved',
    totalItems:     12,
    totalCost:      45000,
    requestedAt:    DateTime(2026, 4, 2),
  ),
  PendingTransfer(
    id:             'trf-013',
    transferNumber: 'TRF-2026-000013',
    fromLocation:   'WH-MAIN',
    toLocation:     'STORE-02',
    status:         'requested',
    totalItems:     8,
    totalCost:      28000,
    requestedAt:    DateTime(2026, 4, 3),
  ),
];

// Stock movements — abhi dummy
final dummyStockMovements = [
  StockMovementEntry(
    id:              'mov-001',
    productName:     'Sunflower Oil 1L',
    movementType:    'purchase_in',
    referenceType:   'purchase',
    referenceNumber: 'PO-000021',
    quantity:        200,
    createdAt:       DateTime(2026, 4, 5, 9, 14),
  ),
  StockMovementEntry(
    id:              'mov-002',
    productName:     'Basmati Rice 5kg',
    movementType:    'transfer_out',
    referenceType:   'transfer',
    referenceNumber: 'TRF-000012',
    quantity:        -50,
    createdAt:       DateTime(2026, 4, 5, 11, 30),
  ),
];