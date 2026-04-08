// =============================================================
// warehouse_dashboard_dummy_data.dart
// Development/testing ke liye — Drift DB ready hone pe delete karo
// =============================================================

import '../domain/warehouse_dashboard_models.dart';

// ─────────────────────────────────────────────────────────────
// DASHBOARD STATS
// ─────────────────────────────────────────────────────────────

const dummyDashboardStats = DashboardStats(
  totalProducts:    1248,
  lowStockCount:    23,
  activeSuppliers:  14,
  totalOutstanding: 55500,  // Rs 55.5K
  pendingPOs:       7,
  unsyncedRecords:  8,
);

// ─────────────────────────────────────────────────────────────
// RECENT PURCHASE ORDERS
// ─────────────────────────────────────────────────────────────

final dummyRecentPOs = [
  RecentPurchaseOrder(
    id:           'po-021',
    poNumber:     'PO-2026-000021',
    supplierName: 'Usman Farooq',
    status:       'partial',
    totalAmount:  150000,
    orderDate:    DateTime(2026, 4, 4),
  ),
  RecentPurchaseOrder(
    id:           'po-020',
    poNumber:     'PO-2026-000020',
    supplierName: 'Ahmed Raza',
    status:       'ordered',
    totalAmount:  85000,
    orderDate:    DateTime(2026, 4, 3),
  ),
  RecentPurchaseOrder(
    id:           'po-019',
    poNumber:     'PO-2026-000019',
    supplierName: 'Bilal Khan',
    status:       'received',
    totalAmount:  320000,
    orderDate:    DateTime(2026, 4, 2),
  ),
  RecentPurchaseOrder(
    id:           'po-018',
    poNumber:     'PO-2026-000018',
    supplierName: 'Tariq Mehmood',
    status:       'draft',
    totalAmount:  45000,
    orderDate:    DateTime(2026, 4, 1),
  ),
];

// ─────────────────────────────────────────────────────────────
// PENDING TRANSFERS
// ─────────────────────────────────────────────────────────────

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
  PendingTransfer(
    id:             'trf-014',
    transferNumber: 'TRF-2026-000014',
    fromLocation:   'WH-MAIN',
    toLocation:     'STORE-03',
    status:         'requested',
    totalItems:     5,
    totalCost:      18000,
    requestedAt:    DateTime(2026, 4, 4),
  ),
];

// ─────────────────────────────────────────────────────────────
// LOW STOCK ITEMS
// ─────────────────────────────────────────────────────────────

final dummyLowStockItems = [
  LowStockItem(
    productId:      'prod-01',
    productName:    'Sunflower Oil 1L',
    sku:            'SKU-001',
    currentStock:   18,
    reorderPoint:   50,
    maxStockLevel:  100,
    quantityToOrder: 82,
  ),
  LowStockItem(
    productId:      'prod-02',
    productName:    'Basmati Rice 5kg',
    sku:            'SKU-012',
    currentStock:   12,
    reorderPoint:   40,
    maxStockLevel:  100,
    quantityToOrder: 88,
  ),
  LowStockItem(
    productId:      'prod-03',
    productName:    'Surf Excel 1kg',
    sku:            'SKU-034',
    currentStock:   32,
    reorderPoint:   30,
    maxStockLevel:  100,
    quantityToOrder: 68,
  ),
  LowStockItem(
    productId:      'prod-04',
    productName:    'Nestle Milk Pack 1L',
    sku:            'SKU-056',
    currentStock:   40,
    reorderPoint:   35,
    maxStockLevel:  100,
    quantityToOrder: 60,
  ),
  LowStockItem(
    productId:      'prod-05',
    productName:    'Tapal Danedar 500g',
    sku:            'SKU-078',
    currentStock:   25,
    reorderPoint:   20,
    maxStockLevel:  100,
    quantityToOrder: 75,
  ),
];

// ─────────────────────────────────────────────────────────────
// SUPPLIER DUES
// ─────────────────────────────────────────────────────────────

final dummySupplierDues = [
  SupplierDue(
    supplierId:        'sup-001',
    supplierName:      'Ahmed Raza',
    companyName:       'Raza Traders',
    paymentTerms:      30,
    outstandingAmount: 12000,
  ),
  SupplierDue(
    supplierId:        'sup-005',
    supplierName:      'Usman Farooq',
    companyName:       'Farooq Wholesale',
    paymentTerms:      60,
    outstandingAmount: 35000,
  ),
  SupplierDue(
    supplierId:        'sup-004',
    supplierName:      'Kamran Iqbal',
    companyName:       'Iqbal & Sons',
    paymentTerms:      30,
    outstandingAmount: 8500,
  ),
];

// ─────────────────────────────────────────────────────────────
// STOCK MOVEMENTS (aaj ki)
// ─────────────────────────────────────────────────────────────

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
  StockMovementEntry(
    id:              'mov-003',
    productName:     'Surf Excel 1kg',
    movementType:    'purchase_in',
    referenceType:   'purchase',
    referenceNumber: 'PO-000019',
    quantity:        120,
    createdAt:       DateTime(2026, 4, 5, 13, 45),
  ),
  StockMovementEntry(
    id:              'mov-004',
    productName:     'Tapal Danedar 500g',
    movementType:    'return_in',
    referenceType:   'adjustment',
    referenceNumber: null,
    quantity:        15,
    createdAt:       DateTime(2026, 4, 5, 15, 20),
  ),
];