// lib/data/mock/sale_return_mock.dart

import '../model/sale_return_model.dart';

final List<SaleReturnModel> saleReturnMockData = [
  SaleReturnModel(
    id:               'ret-001',
    returnNumber:     'RET-0012',
    customerId:       'cust-001',
    refInvoiceNumber: 'INV-0039',
    date:             DateTime(2026, 3, 22),
    totalReturnAmount: 4000,
    status:           'approved',
    items: const [
      SaleReturnItemModel(productName: 'Steel Rod (12mm)', qty: 4, unitPrice: 1000, discountAmount: 0, taxAmount: 0),
    ],
  ),
  SaleReturnModel(
    id:               'ret-002',
    returnNumber:     'RET-0009',
    customerId:       'cust-001',
    refInvoiceNumber: 'INV-0031',
    date:             DateTime(2026, 2, 14),
    totalReturnAmount: 2500,
    status:           'pending',
    items: const [
      SaleReturnItemModel(productName: 'Cement (50kg)', qty: 1, unitPrice: 900, discountAmount: 0,   taxAmount: 0),
      SaleReturnItemModel(productName: 'Floor Tiles',   qty: 4, unitPrice: 400, discountAmount: 100, taxAmount: 50),
    ],
  ),
];