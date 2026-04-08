// lib/data/model/sale_invoice_model.dart

class SaleInvoiceItemModel {
  final String productName;
  final int    qty;
  final double unitPrice;
  final double discountAmount; // direct discount amount (e.g. 50)
  final double taxAmount;      // direct tax amount (e.g. 450)

  const SaleInvoiceItemModel({
    required this.productName,
    required this.qty,
    required this.unitPrice,
    this.discountAmount = 0,
    this.taxAmount      = 0,
  });

  // (unitPrice × qty) − discount + tax
  double get subtotal => (unitPrice * qty) - discountAmount + taxAmount;
}

class SaleInvoiceModel {
  final String   id;
  final String   invoiceNumber;
  final String   customerId;
  final DateTime date;
  final List<SaleInvoiceItemModel> items;
  final double   totalAmount;
  final double   paidAmount;
  final String   status;

  const SaleInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
  });

  double get dueAmount      => totalAmount - paidAmount;
  String get productSummary => items.map((e) => e.productName).take(3).join(', ');
}