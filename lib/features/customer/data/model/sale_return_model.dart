// lib/data/model/sale_return_model.dart

class SaleReturnItemModel {
  final String productName;
  final int    qty;
  final double unitPrice;
  final double discountAmount;
  final double taxAmount;

  const SaleReturnItemModel({
    required this.productName,
    required this.qty,
    required this.unitPrice,
    this.discountAmount = 0,
    this.taxAmount      = 0,
  });

  double get returnSubtotal => (unitPrice * qty) - discountAmount + taxAmount;
}

class SaleReturnModel {
  final String   id;
  final String   returnNumber;
  final String   customerId;
  final String   refInvoiceNumber;
  final DateTime date;
  final List<SaleReturnItemModel> items;
  final double   totalReturnAmount;
  final String   status;

  const SaleReturnModel({
    required this.id,
    required this.returnNumber,
    required this.customerId,
    required this.refInvoiceNumber,
    required this.date,
    required this.items,
    required this.totalReturnAmount,
    required this.status,
  });

  String get productSummary => items.map((e) => e.productName).take(3).join(', ');
}