class SaleInvoiceListModel {
  final String   id;
  final String   invoiceNo;
  final DateTime invoiceDate;
  final String   paymentType;
  final String   status;
  final double   totalAmount;
  final double   totalDiscount;
  final double   grandTotal;
  final String?  customerId;
  final String?  customerName;
  final String?  counterName;
  final List<SaleInvoiceItemDetail> items;

  const SaleInvoiceListModel({
    required this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.paymentType,
    required this.status,
    required this.totalAmount,
    required this.totalDiscount,
    required this.grandTotal,
    this.customerId,
    this.customerName,
    this.counterName,
    required this.items,
  });

  String get grandTotalLabel   => 'Rs ${grandTotal.toStringAsFixed(0)}';
  String get totalAmountLabel  => 'Rs ${totalAmount.toStringAsFixed(0)}';
  String get discountLabel     => 'Rs ${totalDiscount.toStringAsFixed(0)}';

  String get paymentLabel {
    switch (paymentType) {
      case 'cash':   return 'Cash';
      case 'card':   return 'Card';
      case 'credit': return 'Credit';
      default:       return paymentType;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      case 'returned':  return 'Returned';
      default:          return status;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SaleInvoiceListModel && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

class SaleInvoiceItemDetail {
  final String  productName;
  final String? sku;
  final double  price;
  final double  quantity;
  final double  discount;
  final double  totalAmount;

  const SaleInvoiceItemDetail({
    required this.productName,
    this.sku,
    required this.price,
    required this.quantity,
    required this.discount,
    required this.totalAmount,
  });

  String get priceLabel    => 'Rs ${price.toStringAsFixed(0)}';
  String get totalLabel    => 'Rs ${totalAmount.toStringAsFixed(0)}';
  String get qtyLabel      => quantity % 1 == 0
      ? quantity.toInt().toString()
      : quantity.toStringAsFixed(2);

  static SaleInvoiceItemDetail fromMap(Map<String, dynamic> m) =>
      SaleInvoiceItemDetail(
        productName: m['product_name']?.toString() ?? '',
        sku:         m['sku']?.toString(),
        price:       _dbl(m['price'])        ?? 0,
        quantity:    _dbl(m['quantity'])     ?? 0,
        discount:    _dbl(m['discount'])     ?? 0,
        totalAmount: _dbl(m['total_amount']) ?? 0,
      );

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}