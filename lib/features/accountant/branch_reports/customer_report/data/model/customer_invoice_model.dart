class CustomerInvoiceModel {
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
  final String?  cashierName;
  final List<CustomerInvoiceItemDetail> items;

  const CustomerInvoiceModel({
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
    this.cashierName,
    required this.items,
  });

  String get grandTotalLabel  => 'Rs ${grandTotal.toStringAsFixed(0)}';
  String get totalAmountLabel => 'Rs ${totalAmount.toStringAsFixed(0)}';
  String get discountLabel    => 'Rs ${totalDiscount.toStringAsFixed(0)}';

  double get totalProfit =>
      items.fold(0.0, (sum, item) => sum + item.profit);
  String get totalProfitLabel => 'Rs ${totalProfit.toStringAsFixed(0)}';
}

class CustomerInvoiceItemDetail {
  final String  productName;
  final String? sku;
  final double  salePrice;
  final double  purchasePrice;
  final double  price;
  final double  quantity;
  final double  discount;
  final double  totalAmount;

  const CustomerInvoiceItemDetail({
    required this.productName,
    this.sku,
    required this.salePrice,
    required this.purchasePrice,
    required this.price,
    required this.quantity,
    required this.discount,
    required this.totalAmount,
  });

  String get priceLabel         => 'Rs ${price.toStringAsFixed(0)}';
  String get salePriceLabel     => 'Rs ${salePrice.toStringAsFixed(0)}';
  String get purchasePriceLabel => 'Rs ${purchasePrice.toStringAsFixed(0)}';
  String get totalLabel         => 'Rs ${totalAmount.toStringAsFixed(0)}';
  double get profit             => (salePrice - purchasePrice) * quantity;
  String get profitLabel        => 'Rs ${profit.toStringAsFixed(0)}';
  bool   get isProfitPositive   => profit >= 0;

  String get qtyLabel => quantity % 1 == 0
      ? quantity.toInt().toString()
      : quantity.toStringAsFixed(2);

  static CustomerInvoiceItemDetail fromMap(Map<String, dynamic> m) =>
      CustomerInvoiceItemDetail(
        productName:   m['product_name']?.toString()  ?? '',
        sku:           m['sku']?.toString(),
        salePrice:     _dbl(m['sale_price'])     ?? 0,
        purchasePrice: _dbl(m['purchase_price']) ?? 0,
        price:         _dbl(m['price'])          ?? 0,
        quantity:      _dbl(m['quantity'])       ?? 0,
        discount:      _dbl(m['discount'])       ?? 0,
        totalAmount:   _dbl(m['total_amount'])   ?? 0,
      );

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}