// =============================================================
// purchase_order_dummy_data.dart
// Development ke liye — Drift DB ready hone pe delete karo
// =============================================================

import '../domain/purchase_order_model.dart';

// ─────────────────────────────────────────────────────────────
// ITEMS
// ─────────────────────────────────────────────────────────────

final _itemsPo021 = [
  PurchaseOrderItem(id: 'poi-001', poId: 'po-021', tenantId: 't-001',
      productId: 'prod-01', productName: 'Sunflower Oil 1L', sku: 'SKU-001',
      quantityOrdered: 100, quantityReceived: 50,
      unitCost: 480, totalCost: 48000, salePrice: 650),
  PurchaseOrderItem(id: 'poi-002', poId: 'po-021', tenantId: 't-001',
      productId: 'prod-02', productName: 'Basmati Rice 5kg', sku: 'SKU-012',
      quantityOrdered: 150, quantityReceived: 100,
      unitCost: 650, totalCost: 97500, salePrice: 850),
];

final _itemsPo020 = [
  PurchaseOrderItem(id: 'poi-003', poId: 'po-020', tenantId: 't-001',
      productId: 'prod-01', productName: 'Sunflower Oil 1L', sku: 'SKU-001',
      quantityOrdered: 50, quantityReceived: 0,
      unitCost: 480, totalCost: 24000, salePrice: 650),
  PurchaseOrderItem(id: 'poi-004', poId: 'po-020', tenantId: 't-001',
      productId: 'prod-03', productName: 'Surf Excel 1kg', sku: 'SKU-034',
      quantityOrdered: 60, quantityReceived: 0,
      unitCost: 320, totalCost: 19200, salePrice: null),
  PurchaseOrderItem(id: 'poi-005', poId: 'po-020', tenantId: 't-001',
      productId: 'prod-05', productName: 'Tapal Danedar 500g', sku: 'SKU-078',
      quantityOrdered: 80, quantityReceived: 0,
      unitCost: 350, totalCost: 28000, salePrice: 480),
];

final _itemsPo019 = [
  PurchaseOrderItem(id: 'poi-006', poId: 'po-019', tenantId: 't-001',
      productId: 'prod-02', productName: 'Basmati Rice 5kg', sku: 'SKU-012',
      quantityOrdered: 200, quantityReceived: 200,
      unitCost: 650, totalCost: 130000, salePrice: 850),
  PurchaseOrderItem(id: 'poi-007', poId: 'po-019', tenantId: 't-001',
      productId: 'prod-04', productName: 'Nestle Milk Pack 1L', sku: 'SKU-056',
      quantityOrdered: 300, quantityReceived: 300,
      unitCost: 145, totalCost: 43500, salePrice: 190),
  PurchaseOrderItem(id: 'poi-008', poId: 'po-019', tenantId: 't-001',
      productId: 'prod-06', productName: 'Dates Box 1kg', sku: 'SKU-092',
      quantityOrdered: 100, quantityReceived: 100,
      unitCost: 850, totalCost: 85000, salePrice: 1100),
];

final _itemsPo018 = [
  PurchaseOrderItem(id: 'poi-009', poId: 'po-018', tenantId: 't-001',
      productId: 'prod-03', productName: 'Surf Excel 1kg', sku: 'SKU-034',
      quantityOrdered: 80, quantityReceived: 0,
      unitCost: 320, totalCost: 25600, salePrice: null),
  PurchaseOrderItem(id: 'poi-010', poId: 'po-018', tenantId: 't-001',
      productId: 'prod-07', productName: 'Colgate 150g', sku: 'SKU-103',
      quantityOrdered: 60, quantityReceived: 0,
      unitCost: 185, totalCost: 11100, salePrice: 240),
];

final _itemsPo017 = [
  PurchaseOrderItem(id: 'poi-011', poId: 'po-017', tenantId: 't-001',
      productId: 'prod-05', productName: 'Tapal Danedar 500g', sku: 'SKU-078',
      quantityOrdered: 100, quantityReceived: 0,
      unitCost: 350, totalCost: 35000, salePrice: null),
  PurchaseOrderItem(id: 'poi-012', poId: 'po-017', tenantId: 't-001',
      productId: 'prod-08', productName: 'Knorr Noodles 72g', sku: 'SKU-115',
      quantityOrdered: 200, quantityReceived: 0,
      unitCost: 40, totalCost: 8000, salePrice: null),
];

// ─────────────────────────────────────────────────────────────
// PURCHASE ORDERS
// ─────────────────────────────────────────────────────────────

final dummyPurchaseOrders = [
  PurchaseOrderModel(
    id: 'po-021', tenantId: 't-001',
    poNumber: 'PO-2026-000021',
    supplierId: 'sup-005', supplierName: 'Usman Farooq',
    supplierCompany: 'Farooq Wholesale', supplierPhone: '03431234567',
    supplierAddress: 'Hussain Agahi, Multan', supplierTaxId: null,
    supplierPaymentTerms: 60,
    destinationLocationId: 'loc-001', destinationName: 'WH-MAIN',
    status: 'partial',
    orderDate:    DateTime(2026, 4, 4),
    expectedDate: DateTime(2026, 4, 10),
    receivedDate: null,
    subtotal: 150000, discountAmount: 0, taxAmount: 0,
    totalAmount: 150000, paidAmount: 75000,
    notes: 'Ramadan stock — urgent delivery chahiye',
    createdByName: 'Ahmed (Owner)',
    createdAt: DateTime(2026, 4, 4),
    updatedAt: DateTime(2026, 4, 4),
    items: _itemsPo021,
  ),
  PurchaseOrderModel(
    id: 'po-020', tenantId: 't-001',
    poNumber: 'PO-2026-000020',
    supplierId: 'sup-001', supplierName: 'Ahmed Raza',
    supplierCompany: 'Raza Traders', supplierPhone: '03001234567',
    supplierAddress: 'Hall Road, Lahore', supplierTaxId: 'NTN-12345',
    supplierPaymentTerms: 30,
    destinationLocationId: 'loc-001', destinationName: 'WH-MAIN',
    status: 'ordered',
    orderDate:    DateTime(2026, 4, 3),
    expectedDate: DateTime(2026, 4, 9),
    receivedDate: null,
    subtotal: 90000, discountAmount: 5000, taxAmount: 0,
    totalAmount: 85000, paidAmount: 0,
    notes: null,
    createdByName: 'Ahmed (Owner)',
    createdAt: DateTime(2026, 4, 3),
    updatedAt: DateTime(2026, 4, 3),
    items: _itemsPo020,
  ),
  PurchaseOrderModel(
    id: 'po-019', tenantId: 't-001',
    poNumber: 'PO-2026-000019',
    supplierId: 'sup-002', supplierName: 'Bilal Khan',
    supplierCompany: 'Khan Brothers', supplierPhone: '03111234567',
    supplierAddress: 'Saddar, Karachi', supplierTaxId: null,
    supplierPaymentTerms: 15,
    destinationLocationId: 'loc-001', destinationName: 'WH-MAIN',
    status: 'received',
    orderDate:    DateTime(2026, 4, 2),
    expectedDate: DateTime(2026, 4, 7),
    receivedDate: DateTime(2026, 4, 6),
    subtotal: 265000, discountAmount: 7500, taxAmount: 0,
    totalAmount: 257500, paidAmount: 257500,
    notes: null,
    createdByName: 'Ahmed (Owner)',
    createdAt: DateTime(2026, 4, 2),
    updatedAt: DateTime(2026, 4, 6),
    items: _itemsPo019,
  ),
  PurchaseOrderModel(
    id: 'po-018', tenantId: 't-001',
    poNumber: 'PO-2026-000018',
    supplierId: 'sup-003', supplierName: 'Tariq Mehmood',
    supplierCompany: 'TM Distributors', supplierPhone: '03211234567',
    supplierAddress: 'F-7, Islamabad', supplierTaxId: null,
    supplierPaymentTerms: 45,
    destinationLocationId: 'loc-001', destinationName: 'WH-MAIN',
    status: 'draft',
    orderDate:    DateTime(2026, 4, 1),
    expectedDate: DateTime(2026, 4, 8),
    receivedDate: null,
    subtotal: 45000, discountAmount: 0, taxAmount: 0,
    totalAmount: 45000, paidAmount: 0,
    notes: null,
    createdByName: 'Ahmed (Owner)',
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
    items: _itemsPo018,
  ),
  PurchaseOrderModel(
    id: 'po-017', tenantId: 't-001',
    poNumber: 'PO-2026-000017',
    supplierId: 'sup-004', supplierName: 'Kamran Iqbal',
    supplierCompany: 'Iqbal & Sons', supplierPhone: '03321234567',
    supplierAddress: 'Qissa Khwani, Peshawar', supplierTaxId: null,
    supplierPaymentTerms: 30,
    destinationLocationId: 'loc-001', destinationName: 'WH-MAIN',
    status: 'cancelled',
    orderDate:    DateTime(2026, 3, 30),
    expectedDate: null,
    receivedDate: null,
    subtotal: 95000, discountAmount: 0, taxAmount: 0,
    totalAmount: 95000, paidAmount: 0,
    notes: 'Supplier ne delivery refuse kar di',
    createdByName: 'Ahmed (Owner)',
    createdAt: DateTime(2026, 3, 30),
    updatedAt: DateTime(2026, 3, 31),
    items: _itemsPo017,
  ),
];

// ─────────────────────────────────────────────────────────────
// STATS — computed from above orders
// ─────────────────────────────────────────────────────────────

class PurchaseOrderStats {
  final int    totalPOs;
  final int    pendingCount;    // draft + ordered + partial
  final int    receivedCount;
  final double thisMonthTotal;
  final double totalOutstanding;

  const PurchaseOrderStats({
    required this.totalPOs,
    required this.pendingCount,
    required this.receivedCount,
    required this.thisMonthTotal,
    required this.totalOutstanding,
  });
}

final dummyPoStats = PurchaseOrderStats(
  totalPOs:        21,
  pendingCount:    7,
  receivedCount:   11,
  thisMonthTotal:  4200000,  // Rs 4.2M
  totalOutstanding: 56000,   // Rs 56K
);