// lib/features/branch/reports/data/model/csr_model.dart

enum CsrType { sale, saleReturn }

class CsrItemDetail {
  final String productName;
  final String? sku;
  final double salePrice;
  final double purchasePrice;
  final double quantity;
  final double discount;
  final double totalAmount;

  const CsrItemDetail({
    required this.productName,
    this.sku,
    required this.salePrice,
    required this.purchasePrice,
    required this.quantity,
    required this.discount,
    required this.totalAmount,
  });

  String get priceLabel => 'Rs ${salePrice.toStringAsFixed(0)}';
  String get totalLabel => 'Rs ${totalAmount.toStringAsFixed(0)}';
  String get qtyLabel => quantity % 1 == 0
      ? quantity.toInt().toString()
      : quantity.toStringAsFixed(2);

  static CsrItemDetail fromMap(Map<String, dynamic> m) => CsrItemDetail(
    productName: m['product_name']?.toString() ?? '',
    sku: m['sku']?.toString(),
    salePrice: _dbl(m['sale_price']) ?? 0,
    purchasePrice: _dbl(m['purchase_price']) ?? 0,
    quantity: _dbl(m['quantity']) ?? 0,
    discount: _dbl(m['discount']) ?? 0,
    totalAmount: _dbl(m['total_amount']) ?? 0,
  );

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class CsrEntry {
  final String id;
  final CsrType type;

  // Sale fields
  final String? invoiceNo;
  final DateTime? invoiceDate;
  final String? paymentType;
  final String? notes;

  // Return fields
  final String? returnNo;
  final DateTime? returnDate;
  final String? refundType;
  final String? returnReason;
  final String? invoiceId;

  // Common
  final String status;
  final double totalAmount;
  final double totalDiscount;
  final double grandTotal;
  final String? customerId;
  final String? customerName;
  final String? counterName;
  final String? cashierName;
  final List<CsrItemDetail> items;

  const CsrEntry({
    required this.id,
    required this.type,
    this.invoiceNo,
    this.invoiceDate,
    this.paymentType,
    this.notes,
    this.returnNo,
    this.returnDate,
    this.refundType,
    this.returnReason,
    this.invoiceId,
    required this.status,
    required this.totalAmount,
    required this.totalDiscount,
    required this.grandTotal,
    this.customerId,
    this.customerName,
    this.counterName,
    this.cashierName,
    required this.items,
  });

  DateTime get entryDate => type == CsrType.sale
      ? (invoiceDate ?? DateTime.now())
      : (returnDate ?? DateTime.now());

  String get entryNo => type == CsrType.sale
      ? (invoiceNo ?? '')
      : (returnNo ?? '');

  String get paymentLabel => type == CsrType.sale
      ? (paymentType ?? 'cash')
      : (refundType ?? 'cash');

  String get grandTotalLabel => 'Rs ${grandTotal.toStringAsFixed(0)}';
  String get discountLabel => 'Rs ${totalDiscount.toStringAsFixed(0)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CsrEntry && id == other.id;

  @override
  int get hashCode => id.hashCode;
}