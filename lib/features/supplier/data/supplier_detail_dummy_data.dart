// =============================================================
// supplier_detail_dummy_data.dart
// Sirf development/testing ke liye — Drift DB ready hone pe delete karo
// =============================================================

import 'package:jan_ghani_final/features/supplier/domian/supplier_detail_models.dart';


// ─────────────────────────────────────────────────────────────
// LEDGER ENTRIES  (supplier_ledger table)
// ─────────────────────────────────────────────────────────────

final List<SupplierLedgerEntry> dummyLedgerEntries = [
  SupplierLedgerEntry(
    id:            'led-001',
    supplierId:    'sup-001',
    poId:          'po-001',
    entryType:     'purchase',
    amount:        85000,
    balanceAfter:  85000,
    notes:         'PO-2026-000001 — grocery items',
    createdByName: 'Ahmed (Owner)',
    createdAt:     DateTime(2026, 1, 5),
    balanceBefore: 0,
  ),
  SupplierLedgerEntry(
    id:            'led-002',
    supplierId:    'sup-001',
    poId:          null,
    entryType:     'payment',
    amount:        -50000,
    balanceAfter:  35000,
    notes:         'Cash payment',
    createdByName: 'Ahmed (Owner)',
    createdAt:     DateTime(2026, 1, 18),
    balanceBefore: 0,
  ),
  SupplierLedgerEntry(
    id:            'led-003',
    supplierId:    'sup-001',
    poId:          'po-002',
    entryType:     'purchase',
    amount:        120000,
    balanceAfter:  155000,
    notes:         'PO-2026-000008 — monthly stock',
    createdByName: 'Ahmed (Owner)',
    createdAt:     DateTime(2026, 2, 3),
    balanceBefore: 0,
  ),
  SupplierLedgerEntry(
    id:            'led-004',
    supplierId:    'sup-001',
    poId:          null,
    entryType:     'return',
    amount:        -8000,
    balanceAfter:  147000,
    notes:         'Damaged goods return — 5 boxes',
    createdByName: 'Ali (Manager)',
    createdAt:     DateTime(2026, 2, 10),
    balanceBefore: 0,
  ),
  SupplierLedgerEntry(
    id:            'led-005',
    supplierId:    'sup-001',
    poId:          null,
    entryType:     'payment',
    amount:        -100000,
    balanceAfter:  47000,
    notes:         'Bank transfer',
    createdByName: 'Ahmed (Owner)',
    createdAt:     DateTime(2026, 2, 28),
    balanceBefore: 0,
  ),
  SupplierLedgerEntry(
    id:            'led-006',
    supplierId:    'sup-001',
    poId:          'po-003',
    entryType:     'purchase',
    amount:        95000,
    balanceAfter:  142000,
    notes:         'PO-2026-000015 — Ramadan stock',
    createdByName: 'Ahmed (Owner)',
    createdAt:     DateTime(2026, 3, 15),
    balanceBefore: 0,
  ),
  SupplierLedgerEntry(
    id:            'led-007',
    supplierId:    'sup-001',
    poId:          null,
    entryType:     'adjustment',
    amount:        -130000,
    balanceAfter:  12000,
    notes:         'Partial settlement agreed',
    createdByName: 'Ahmed (Owner)',
    createdAt:     DateTime(2026, 3, 28),
    balanceBefore: 0,
  ),
];

// ─────────────────────────────────────────────────────────────
// PURCHASE ORDER ITEMS  (purchase_order_items table)
// ─────────────────────────────────────────────────────────────

final _itemsPo001 = [
  PurchaseOrderItem(id: 'poi-001', poId: 'po-001', productId: 'prod-01',
      productName: 'Sunflower Oil 1L',    sku: 'SKU-001',
      quantityOrdered: 50,  quantityReceived: 50,  unitCost: 480, totalCost: 24000),
  PurchaseOrderItem(id: 'poi-002', poId: 'po-001', productId: 'prod-02',
      productName: 'Basmati Rice 5kg',    sku: 'SKU-012',
      quantityOrdered: 100, quantityReceived: 100, unitCost: 650, totalCost: 65000),
];

final _itemsPo002 = [
  PurchaseOrderItem(id: 'poi-003', poId: 'po-002', productId: 'prod-01',
      productName: 'Sunflower Oil 1L',    sku: 'SKU-001',
      quantityOrdered: 50,  quantityReceived: 50,  unitCost: 480, totalCost: 24000),
  PurchaseOrderItem(id: 'poi-004', poId: 'po-002', productId: 'prod-02',
      productName: 'Basmati Rice 5kg',    sku: 'SKU-012',
      quantityOrdered: 100, quantityReceived: 100, unitCost: 650, totalCost: 65000),
  PurchaseOrderItem(id: 'poi-005', poId: 'po-002', productId: 'prod-03',
      productName: 'Surf Excel 1kg',      sku: 'SKU-034',
      quantityOrdered: 60,  quantityReceived: 40,  unitCost: 320, totalCost: 19200),
  PurchaseOrderItem(id: 'poi-006', poId: 'po-002', productId: 'prod-04',
      productName: 'Nestle Milk Pack 1L', sku: 'SKU-056',
      quantityOrdered: 80,  quantityReceived: 0,   unitCost: 145, totalCost: 11600),
];

final _itemsPo003 = [
  PurchaseOrderItem(id: 'poi-007', poId: 'po-003', productId: 'prod-05',
      productName: 'Tapal Danedar 500g',  sku: 'SKU-078',
      quantityOrdered: 200, quantityReceived: 0,   unitCost: 350, totalCost: 70000),
  PurchaseOrderItem(id: 'poi-008', poId: 'po-003', productId: 'prod-06',
      productName: 'Dates Box 1kg',       sku: 'SKU-092',
      quantityOrdered: 100, quantityReceived: 0,   unitCost: 250, totalCost: 25000),
];

final _itemsPo004 = [
  PurchaseOrderItem(id: 'poi-009', poId: 'po-004', productId: 'prod-01',
      productName: 'Sunflower Oil 1L',    sku: 'SKU-001',
      quantityOrdered: 150, quantityReceived: 80,  unitCost: 480, totalCost: 72000),
  PurchaseOrderItem(id: 'poi-010', poId: 'po-004', productId: 'prod-02',
      productName: 'Basmati Rice 5kg',    sku: 'SKU-012',
      quantityOrdered: 120, quantityReceived: 60,  unitCost: 650, totalCost: 78000),
];

// ─────────────────────────────────────────────────────────────
// PURCHASE ORDERS  (purchase_orders table)
// ─────────────────────────────────────────────────────────────

final List<SupplierPurchaseOrder> dummyPurchaseOrders = [
  SupplierPurchaseOrder(
    id:             'po-001',
    poNumber:       'PO-2026-000001',
    orderDate:      DateTime(2026, 1, 5),
    expectedDate:   DateTime(2026, 1, 10),
    receivedDate:   DateTime(2026, 1, 9),
    status:         'received',
    subtotal:       85000,
    discountAmount: 0,
    taxAmount:      0,
    totalAmount:    85000,
    paidAmount:     85000,
    notes:          'Regular monthly order',
    createdAt:      DateTime(2026, 1, 5),
    items:          _itemsPo001,
  ),
  SupplierPurchaseOrder(
    id:             'po-002',
    poNumber:       'PO-2026-000008',
    orderDate:      DateTime(2026, 2, 3),
    expectedDate:   DateTime(2026, 2, 8),
    receivedDate:   DateTime(2026, 2, 7),
    status:         'received',
    subtotal:       125000,
    discountAmount: 5000,
    taxAmount:      0,
    totalAmount:    120000,
    paidAmount:     108000,
    notes:          null,
    createdAt:      DateTime(2026, 2, 3),
    items:          _itemsPo002,
  ),
  SupplierPurchaseOrder(
    id:             'po-003',
    poNumber:       'PO-2026-000015',
    orderDate:      DateTime(2026, 3, 15),
    expectedDate:   DateTime(2026, 3, 22),
    receivedDate:   null,
    status:         'ordered',
    subtotal:       95000,
    discountAmount: 0,
    taxAmount:      0,
    totalAmount:    95000,
    paidAmount:     0,
    notes:          'Ramadan special stock',
    createdAt:      DateTime(2026, 3, 15),
    items:          _itemsPo003,
  ),
  SupplierPurchaseOrder(
    id:             'po-004',
    poNumber:       'PO-2026-000021',
    orderDate:      DateTime(2026, 3, 28),
    expectedDate:   DateTime(2026, 4, 5),
    receivedDate:   null,
    status:         'partial',
    subtotal:       150000,
    discountAmount: 0,
    taxAmount:      0,
    totalAmount:    150000,
    paidAmount:     75000,
    notes:          'Large bulk order',
    createdAt:      DateTime(2026, 3, 28),
    items:          _itemsPo004,
  ),
];

// ─────────────────────────────────────────────────────────────
// FINANCIAL SUMMARY  (v_supplier_balances)
// ─────────────────────────────────────────────────────────────

const dummyFinancialSummary = SupplierFinancialSummary(
  outstandingBalance: 12000,
  totalPurchased:     450000,
  totalPaid:          438000,
  totalOrders:        24,
  pendingOrders:      2,
);