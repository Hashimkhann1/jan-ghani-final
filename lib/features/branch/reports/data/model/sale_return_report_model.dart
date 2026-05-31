class SaleReturnModel {
  final String   id;
  final String   returnNo;
  final DateTime returnDate;
  final String   refundType;
  final String   status;
  final double   totalAmount;
  final double   totalDiscount;
  final double   grandTotal;
  final String?  customerId;
  final String?  customerName;
  final String?  counterName;
  final String?  cashierName;
  final String?  returnReason;
  final String?  invoiceId;
  final List<SaleReturnItemDetail> items;

  const SaleReturnModel({
    required this.id,
    required this.returnNo,
    required this.returnDate,
    required this.refundType,
    required this.status,
    required this.totalAmount,
    required this.totalDiscount,
    required this.grandTotal,
    this.customerId,
    this.customerName,
    this.counterName,
    this.cashierName,
    this.returnReason,
    this.invoiceId,
    required this.items,
  });

  String get grandTotalLabel  => 'Rs ${grandTotal.toStringAsFixed(0)}';
  String get totalAmountLabel => 'Rs ${totalAmount.toStringAsFixed(0)}';
  String get discountLabel    => 'Rs ${totalDiscount.toStringAsFixed(0)}';

  String get refundLabel {
    switch (refundType) {
      case 'cash':   return 'Cash';
      case 'card':   return 'Card';
      case 'credit': return 'Credit';
      default:       return refundType;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default:          return status;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SaleReturnModel && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

class SaleReturnItemDetail {
  final String  productName;
  final String? sku;
  final String? barcode;
  final double  salePrice;      // ← price ki jagah
  final double  purchasePrice;  // ← naya
  final double  quantity;
  final double  discount;
  final double  subtotal;
  final double  totalAmount;

  const SaleReturnItemDetail({
    required this.productName,
    this.sku,
    this.barcode,
    required this.salePrice,
    required this.purchasePrice,
    required this.quantity,
    required this.discount,
    required this.subtotal,
    required this.totalAmount,
  });

  String get priceLabel => 'Rs ${salePrice.toStringAsFixed(0)}';
  String get totalLabel => 'Rs ${totalAmount.toStringAsFixed(0)}';
  String get qtyLabel   => quantity % 1 == 0
      ? quantity.toInt().toString()
      : quantity.toStringAsFixed(2);

  static SaleReturnItemDetail fromMap(Map<String, dynamic> m) =>
      SaleReturnItemDetail(
        productName:   m['product_name']?.toString()  ?? '',
        sku:           m['sku']?.toString(),
        barcode:       m['barcode']?.toString(),
        salePrice:     _dbl(m['sale_price'])     ?? 0,
        purchasePrice: _dbl(m['purchase_price']) ?? 0,
        quantity:      _dbl(m['quantity'])       ?? 0,
        discount:      _dbl(m['discount'])       ?? 0,
        subtotal:      _dbl(m['subtotal'])       ?? 0,
        totalAmount:   _dbl(m['total_amount'])   ?? 0,
      );

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}