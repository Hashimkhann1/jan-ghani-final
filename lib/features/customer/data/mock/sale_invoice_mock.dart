// lib/data/mock/sale_invoice_mock.dart

import '../model/sale_invoice_model.dart';

final List<SaleInvoiceModel> saleInvoiceMockData = [
  SaleInvoiceModel(
    id:            'inv-001',
    invoiceNumber: 'INV-0041',
    customerId:    'cust-001',
    date:          DateTime(2026, 3, 28),
    totalAmount:   18000,
    paidAmount:    6000,
    status:        'partial',
    items: const [
      SaleInvoiceItemModel(productName: 'Cement (50kg)',    qty: 10, unitPrice: 900,  discountAmount: 100, taxAmount: 450),
      SaleInvoiceItemModel(productName: 'Sand (cubic ft)',  qty: 5,  unitPrice: 600,  discountAmount: 0,   taxAmount: 0),
      SaleInvoiceItemModel(productName: 'Bricks (per 100)',qty: 1,  unitPrice: 6000, discountAmount: 200, taxAmount: 480),
    ],
  ),
  SaleInvoiceModel(
    id:            'inv-002',
    invoiceNumber: 'INV-0039',
    customerId:    'cust-001',
    date:          DateTime(2026, 3, 20),
    totalAmount:   24000,
    paidAmount:    24000,
    status:        'paid',
    items: const [
      SaleInvoiceItemModel(productName: 'Steel Rod (12mm)', qty: 20, unitPrice: 1200, discountAmount: 0, taxAmount: 2400),
    ],
  ),
  SaleInvoiceModel(
    id:            'inv-003',
    invoiceNumber: 'INV-0035',
    customerId:    'cust-001',
    date:          DateTime(2026, 3, 10),
    totalAmount:   15000,
    paidAmount:    0,
    status:        'due',
    items: const [
      SaleInvoiceItemModel(productName: 'Floor Tiles (sq ft)', qty: 50, unitPrice: 250, discountAmount: 500, taxAmount: 625),
      SaleInvoiceItemModel(productName: 'Tile Adhesive',       qty: 5,  unitPrice: 500, discountAmount: 0,   taxAmount: 0),
    ],
  ),
  SaleInvoiceModel(
    id:            'inv-004',
    invoiceNumber: 'INV-0031',
    customerId:    'cust-001',
    date:          DateTime(2026, 2, 14),
    totalAmount:   42000,
    paidAmount:    42000,
    status:        'paid',
    items: const [
      SaleInvoiceItemModel(productName: 'Cement (50kg)',    qty: 20, unitPrice: 900,  discountAmount: 0,   taxAmount: 900),
      SaleInvoiceItemModel(productName: 'Steel Rod (10mm)',qty: 20, unitPrice: 1200, discountAmount: 300, taxAmount: 2400),
    ],
  ),
];