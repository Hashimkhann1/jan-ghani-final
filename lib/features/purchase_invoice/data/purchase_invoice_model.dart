// =============================================================
// purchase_invoice_model.dart
// =============================================================

// ── Enums ─────────────────────────────────────────────────────

enum PoType {
  purchase,
  purchaseReturn;

  String get label {
    switch (this) {
      case PoType.purchase:       return 'Purchase';
      case PoType.purchaseReturn: return 'Purchase Return';
    }
  }
}

// ── Supplier ──────────────────────────────────────────────────

class PoSupplier {
  final String id;
  final String name;
  final String company;
  final String phone;
  final int    paymentTerms;

  const PoSupplier({
    required this.id,
    required this.name,
    required this.company,
    required this.phone,
    required this.paymentTerms,
  });

  String get initials => name.split(' ').take(2)
      .map((w) => w[0]).join().toUpperCase();
}

// ── Purchase Product ──────────────────────────────────────────

class PoProduct {
  final String id;
  final String name;
  final String category;
  final String sku;
  final double purchasePrice;  // unitCost → purchasePrice
  final double salePrice;
  final double stock;

  const PoProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.purchasePrice,
    required this.salePrice,
    required this.stock,
  });
}

// ── Purchase Cart Item ────────────────────────────────────────

class PoCartItem {
  final String    cartId;
  final PoProduct product;
  final double    quantity;
  final double    purchasePrice;   // unitCost → purchasePrice
  final double    salePrice;       // default 0
  final double    taxAmount;
  final double    discountAmount;

  const PoCartItem({
    required this.cartId,
    required this.product,
    required this.quantity,
    required this.purchasePrice,
    this.salePrice      = 0,
    this.taxAmount      = 0,
    this.discountAmount = 0,
  });

  // subTotal = (purchasePrice × qty) + tax - discount
  double get subTotal =>
      (purchasePrice * quantity) + taxAmount - discountAmount;

  double? get marginPercent =>
      salePrice > 0 && purchasePrice > 0
          ? ((salePrice - purchasePrice) / purchasePrice) * 100
          : null;

  PoCartItem copyWith({
    double? quantity,
    double? purchasePrice,
    double? salePrice,
    double? taxAmount,
    double? discountAmount,
  }) {
    return PoCartItem(
      cartId:         cartId,
      product:        product,
      quantity:       quantity       ?? this.quantity,
      purchasePrice:  purchasePrice  ?? this.purchasePrice,
      salePrice:      salePrice      ?? this.salePrice,
      taxAmount:      taxAmount      ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}

// ── State ─────────────────────────────────────────────────────

class PurchaseInvoiceState {
  final String           poNumber;
  final DateTime         orderDate;
  final DateTime?        deliveryDate;
  final PoSupplier?      selectedSupplier;
  final PoType           poType;
  final List<PoCartItem> cartItems;
  final List<PoSupplier> suppliers;
  final List<PoProduct>  products;
  final String           searchQuery;

  const PurchaseInvoiceState({
    required this.poNumber,
    required this.orderDate,
    this.deliveryDate,
    required this.selectedSupplier,
    required this.poType,
    required this.cartItems,
    required this.suppliers,
    required this.products,
    this.searchQuery = '',
  });

  List<PoProduct> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    final q = searchQuery.toLowerCase();
    return products.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.sku.toLowerCase().contains(q)).toList();
  }

  int    get totalItems     => cartItems.length;
  double get totalBeforeTax => cartItems.fold(0.0,
      (sum, i) => sum + (i.purchasePrice * i.quantity));
  double get totalTax       => cartItems.fold(0.0,
      (sum, i) => sum + i.taxAmount);
  double get totalDiscount  => cartItems.fold(0.0,
      (sum, i) => sum + i.discountAmount);
  double get grandTotal     =>
      totalBeforeTax + totalTax - totalDiscount;
  double get totalProfit {
    double p = 0;
    for (final item in cartItems) {
      if (item.salePrice > 0) {
        p += (item.salePrice - item.purchasePrice) * item.quantity;
      }
    }
    return p;
  }

  PurchaseInvoiceState copyWith({
    String?           poNumber,
    DateTime?         orderDate,
    DateTime?         deliveryDate,
    PoSupplier?       selectedSupplier,
    PoType?           poType,
    List<PoCartItem>? cartItems,
    List<PoSupplier>? suppliers,
    List<PoProduct>?  products,
    String?           searchQuery,
    bool              clearDeliveryDate = false,
  }) {
    return PurchaseInvoiceState(
      poNumber:         poNumber         ?? this.poNumber,
      orderDate:        orderDate        ?? this.orderDate,
      deliveryDate:     clearDeliveryDate
          ? null : (deliveryDate ?? this.deliveryDate),
      selectedSupplier: selectedSupplier ?? this.selectedSupplier,
      poType:           poType           ?? this.poType,
      cartItems:        cartItems        ?? this.cartItems,
      suppliers:        suppliers        ?? this.suppliers,
      products:         products         ?? this.products,
      searchQuery:      searchQuery      ?? this.searchQuery,
    );
  }
}

// ── Dummy Data ────────────────────────────────────────────────

final dummyPoSuppliers = [
  const PoSupplier(id: 's1', name: 'Ahmed Raza',
      company: 'Raza Traders',     phone: '0300-1234567',
      paymentTerms: 30),
  const PoSupplier(id: 's2', name: 'Bilal Khan',
      company: 'Khan Brothers',    phone: '0311-2345678',
      paymentTerms: 15),
  const PoSupplier(id: 's3', name: 'Tariq Mehmood',
      company: 'TM Distributors',  phone: '0321-3456789',
      paymentTerms: 45),
  const PoSupplier(id: 's4', name: 'Kamran Iqbal',
      company: 'Iqbal & Sons',     phone: '0332-4567890',
      paymentTerms: 30),
  const PoSupplier(id: 's5', name: 'Usman Farooq',
      company: 'Farooq Wholesale', phone: '0343-5678901',
      paymentTerms: 60),
];

final dummyPoProducts = [
  const PoProduct(id: 'P01', name: 'Sunflower Oil 1L',
      category: 'Cooking Oil', sku: 'SKU-001',
      purchasePrice: 480, salePrice: 650, stock: 18),
  const PoProduct(id: 'P02', name: 'Basmati Rice 5kg',
      category: 'Rice',        sku: 'SKU-012',
      purchasePrice: 650, salePrice: 850, stock: 12),
  const PoProduct(id: 'P03', name: 'Surf Excel 1kg',
      category: 'Detergent',   sku: 'SKU-034',
      purchasePrice: 320, salePrice: 420, stock: 32),
  const PoProduct(id: 'P04', name: 'Nestle Milk 1L',
      category: 'Dairy',       sku: 'SKU-056',
      purchasePrice: 145, salePrice: 190, stock: 40),
  const PoProduct(id: 'P05', name: 'Tapal Danedar 500g',
      category: 'Tea',         sku: 'SKU-078',
      purchasePrice: 350, salePrice: 480, stock: 25),
  const PoProduct(id: 'P06', name: 'Colgate 150g',
      category: 'Personal',    sku: 'SKU-103',
      purchasePrice: 185, salePrice: 240, stock: 60),
  const PoProduct(id: 'P07', name: 'Knorr Noodles 72g',
      category: 'Food',        sku: 'SKU-115',
      purchasePrice: 40,  salePrice: 55,  stock: 200),
  const PoProduct(id: 'P08', name: 'Dates Box 1kg',
      category: 'Dry Fruit',   sku: 'SKU-092',
      purchasePrice: 850, salePrice: 1100, stock: 5),
];
