class CustomerReturnInvoice {
  final String   id;
  final String   returnNo;
  final DateTime returnDate;
  final String?  customerName;
  final String?  customerId;
  final String?  invoiceId;
  final double   totalAmount;
  final double   totalDiscount;
  final double   grandTotal;
  final String   status;
  final String?  returnReason;
  final String?  refundType;
  final List<String>             paymentMethods;
  final List<CustomerReturnItem> items;

  const CustomerReturnInvoice({
    required this.id,
    required this.returnNo,
    required this.returnDate,
    this.customerName,
    this.customerId,
    this.invoiceId,
    required this.totalAmount,
    required this.totalDiscount,
    required this.grandTotal,
    required this.status,
    this.returnReason,
    this.refundType,
    required this.paymentMethods,
    required this.items,
  });

  double get totalQuantity => items.fold(0, (s, i) => s + i.quantity);
  String get customerLabel => customerName ?? 'Walk In';
  String get paymentLabel {
    if (paymentMethods.isEmpty) return '—';
    return paymentMethods
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(', ');
  }
}

class CustomerReturnItem {
  final String  productName;
  final String? sku;
  final double  price;
  final double  quantity;
  final double  discount;
  final double  totalAmount;

  const CustomerReturnItem({
    required this.productName,
    this.sku,
    required this.price,
    required this.quantity,
    required this.discount,
    required this.totalAmount,
  });
}

class CustomerReturnSummary {
  final int    totalReturns;
  final double totalAmount;
  final double totalQuantity;
  final double totalDiscount;

  const CustomerReturnSummary({
    required this.totalReturns,
    required this.totalAmount,
    required this.totalQuantity,
    required this.totalDiscount,
  });
}