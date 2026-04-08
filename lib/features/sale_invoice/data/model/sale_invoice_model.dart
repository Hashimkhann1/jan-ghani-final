enum SaleType { sale, saleReturn }

extension SaleTypeExtension on SaleType {
  String get label {
    switch (this) {
      case SaleType.sale:       return 'Sale';
      case SaleType.saleReturn: return 'Sale Return';
    }
  }
}


class Customer {
  final String id;
  final String name;
  final bool isWalkIn;
  const Customer({required this.id, required this.name, this.isWalkIn = false});
  static const Customer walkIn =
  Customer(id: 'walk_in', name: 'Walk In', isWalkIn: true);
}

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String unit;
  final String? barcode;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.unit = 'pcs',
    this.barcode,
    this.stock = 0,
  });
}


class CartItem {
  final String cartId;
  final Product product;
  final double quantity;
  final double salePrice;
  final double taxAmount;
  final double discountAmount;

  const CartItem({
    required this.cartId,
    required this.product,
    required this.quantity,
    required this.salePrice,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
  });

  double get subTotal => ((salePrice * quantity) + taxAmount - discountAmount).clamp(0.0, double.infinity);

  CartItem copyWith({
    double? quantity,
    double? salePrice,
    double? taxAmount,
    double? discountAmount,
  }) {
    return CartItem(
      cartId: cartId,
      product: product,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice ?? this.salePrice,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}

enum PaymentType { cash, card, credit }

extension PaymentTypeExtension on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.cash:   return 'Cash';
      case PaymentType.card:   return 'Card';
      case PaymentType.credit: return 'Credit';
    }
  }
}

const _grandTotalSentinel = Object();

class SaleInvoiceState {
  final String invoiceNo;
  final DateTime date;
  final Customer selectedCustomer;
  final PaymentType paymentType;
  final SaleType saleType;
  final double? grandTotalOverride;
  final List<CartItem> cartItems;
  final List<Customer> customers;
  final List<Product> products;
  final String searchQuery;

  const SaleInvoiceState({
    required this.invoiceNo,
    required this.date,
    required this.selectedCustomer,
    required this.paymentType,
    required this.cartItems,
    required this.customers,
    required this.products,
    this.saleType = SaleType.sale,
    this.grandTotalOverride,
    this.searchQuery = '',
  });

  double get totalBeforeTax => cartItems.fold(0, (s, i) => s + (i.salePrice * i.quantity));

  double get totalTax => cartItems.fold(0, (s, i) => s + i.taxAmount);

  double get totalDiscount => cartItems.fold(0, (s, i) => s + i.discountAmount);

  int get totalItems => cartItems.length;

  double get grandTotal {
    if (grandTotalOverride != null) return grandTotalOverride!;
    final calculated = cartItems.fold(0.0, (s, i) => s + i.subTotal);
    return saleType == SaleType.saleReturn ? -calculated : calculated;
  }


  List<Product> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    final q = searchQuery.toLowerCase();
    return products.where((p) =>
    p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q) || (p.barcode != null && p.barcode!.contains(q))).toList();
  }


  SaleInvoiceState copyWith({
    String? invoiceNo,
    DateTime? date,
    Customer? selectedCustomer,
    PaymentType? paymentType,
    SaleType? saleType,
    Object? grandTotalOverride = _grandTotalSentinel,
    List<CartItem>? cartItems,
    List<Customer>? customers,
    List<Product>? products,
    String? searchQuery,
  }) {
    return SaleInvoiceState(
      invoiceNo: invoiceNo ?? this.invoiceNo,
      date: date ?? this.date,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      paymentType: paymentType ?? this.paymentType,
      saleType: saleType ?? this.saleType,
      grandTotalOverride: grandTotalOverride == _grandTotalSentinel ? this.grandTotalOverride : grandTotalOverride as double?,
      cartItems: cartItems ?? this.cartItems,
      customers: customers ?? this.customers,
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final List<Customer> dummyCustomers = [
  Customer.walkIn,
  const Customer(id: 'c1',  name: 'Ahmed Khan'),
  const Customer(id: 'c2',  name: 'Fatima Bibi'),
  const Customer(id: 'c3',  name: 'Muhammad Ali'),
  const Customer(id: 'c4',  name: 'Ayesha Siddiqi'),
  const Customer(id: 'c5',  name: 'Usman Tariq'),
  const Customer(id: 'c6',  name: 'Sana Malik'),
  const Customer(id: 'c7',  name: 'Bilal Raza'),
  const Customer(id: 'c8',  name: 'Nadia Hussain'),
  const Customer(id: 'c9',  name: 'Zubair Ahmed'),
  const Customer(id: 'c10', name: 'Hina Butt'),
];


final List<Product> dummyProducts = [

  const Product(id: '1', name: 'Atta 10kg (Sunridge)',      price: 1150, category: 'Atta & Flour',   unit: 'bag',     stock: 24,  barcode: '6001101000001'),
  const Product(id: '2', name: 'Atta 5kg (Bake Parlor)',    price: 590,  category: 'Atta & Flour',   unit: 'bag',     stock: 36,  barcode: '6001101000002'),
  const Product(id: '3', name: 'Maida 1kg',                 price: 140,  category: 'Atta & Flour',   unit: 'kg',      stock: 50,  barcode: '6001101000003'),
  const Product(id: '4', name: 'Sooji (Semolina) 1kg',      price: 130,  category: 'Atta & Flour',   unit: 'kg',      stock: 40,  barcode: '6001101000004'),
  const Product(id: '5', name: 'Besan 1kg',                 price: 220,  category: 'Atta & Flour',   unit: 'kg',      stock: 30,  barcode: '6001101000005'),
  const Product(id: '6', name: 'Basmati Rice 5kg (Guard)',  price: 1800, category: 'Rice',           unit: 'bag',     stock: 18,  barcode: '6001102000006'),
  const Product(id: '7', name: 'Basmati Rice 1kg',          price: 380,  category: 'Rice',           unit: 'kg',      stock: 60,  barcode: '6001102000007'),
  const Product(id: '8', name: 'Sella Rice 5kg',            price: 1400, category: 'Rice',           unit: 'bag',     stock: 15,  barcode: '6001102000008'),
  const Product(id: '9', name: 'Brown Rice 1kg',            price: 320,  category: 'Rice',           unit: 'kg',      stock: 22,  barcode: '6001102000009'),
  const Product(id: '10', name: 'Masoor Dal 1kg',            price: 350,  category: 'Dal & Pulses',   unit: 'kg',      stock: 45,  barcode: '6001103000010'),
  const Product(id: '11', name: 'Chana Dal 1kg',             price: 280,  category: 'Dal & Pulses',   unit: 'kg',      stock: 38,  barcode: '6001103000011'),
  const Product(id: '12', name: 'Moong Dal 1kg',             price: 320,  category: 'Dal & Pulses',   unit: 'kg',      stock: 33,  barcode: '6001103000012'),
  const Product(id: '13', name: 'Mash Dal 1kg',              price: 420,  category: 'Dal & Pulses',   unit: 'kg',      stock: 27,  barcode: '6001103000013'),
  const Product(id: '14', name: 'Kabuli Chana 1kg',          price: 380,  category: 'Dal & Pulses',   unit: 'kg',      stock: 20,  barcode: '6001103000014'),
  const Product(id: '15', name: 'Dalda Banaspati 2.5kg',     price: 1350, category: 'Cooking Oil',    unit: 'tin',     stock: 30,  barcode: '6001104000015'),
  const Product(id: '16', name: 'Sunflower Oil 1L (Sufi)',   price: 560,  category: 'Cooking Oil',    unit: 'bottle',  stock: 48,  barcode: '6001104000016'),
  const Product(id: '17', name: 'Sunflower Oil 5L (Sufi)',   price: 2600, category: 'Cooking Oil',    unit: 'can',     stock: 12,  barcode: '6001104000017'),
  const Product(id: '18', name: 'Olive Oil 500ml (Goya)',    price: 1800, category: 'Cooking Oil',    unit: 'bottle',  stock: 10,  barcode: '6001104000018'),
  const Product(id: '19', name: 'Canola Oil 3L (Habib)',     price: 1650, category: 'Cooking Oil',    unit: 'can',     stock: 14,  barcode: '6001104000019'),
  const Product(id: '20', name: 'Cheeni (Sugar) 1kg',        price: 160,  category: 'Sugar & Salt',   unit: 'kg',      stock: 80,  barcode: '6001105000020'),
  const Product(id: '21', name: 'Cheeni (Sugar) 5kg',        price: 780,  category: 'Sugar & Salt',   unit: 'bag',     stock: 25,  barcode: '6001105000021'),
  const Product(id: '22', name: 'Namak (Salt) 800g (Shaker)',price: 95,   category: 'Sugar & Salt',   unit: 'pkt',     stock: 60,  barcode: '6001105000022'),
  const Product(id: '23', name: 'Pink Salt 500g',            price: 180,  category: 'Sugar & Salt',   unit: 'pkt',     stock: 35,  barcode: '6001105000023'),
  const Product(id: '24', name: 'Lal Mirch Powder 100g',     price: 85,   category: 'Masala',         unit: 'pkt',     stock: 55,  barcode: '6001106000024'),
  const Product(id: '25', name: 'Haldi Powder 100g',         price: 75,   category: 'Masala',         unit: 'pkt',     stock: 50,  barcode: '6001106000025'),
  const Product(id: '26', name: 'Dhania Powder 100g',        price: 70,   category: 'Masala',         unit: 'pkt',     stock: 45,  barcode: '6001106000026'),
  const Product(id: '27', name: 'Garam Masala 50g (Shan)',   price: 110,  category: 'Masala',         unit: 'pkt',     stock: 40,  barcode: '6001106000027'),
  const Product(id: '28', name: 'Biryani Masala (Shan)',     price: 95,   category: 'Masala',         unit: 'pkt',     stock: 38,  barcode: '6001106000028'),
  const Product(id: '29', name: 'Zeera 100g',                price: 120,  category: 'Masala',         unit: 'pkt',     stock: 30,  barcode: '6001106000029'),
  const Product(id: '30', name: 'Kali Mirch 50g',            price: 150,  category: 'Masala',         unit: 'pkt',     stock: 25,  barcode: '6001106000030'),
  const Product(id: '31', name: 'Tapal Danedar 200g',        price: 380,  category: 'Tea & Coffee',   unit: 'pkt',     stock: 42,  barcode: '6001107000031'),
  const Product(id: '32', name: 'Lipton Yellow Label 200g',  price: 420,  category: 'Tea & Coffee',   unit: 'pkt',     stock: 36,  barcode: '6001107000032'),
  const Product(id: '33', name: 'Nescafe Classic 50g',       price: 650,  category: 'Tea & Coffee',   unit: 'jar',     stock: 20,  barcode: '6001107000033'),
  const Product(id: '34', name: 'Vital Tea 480g',            price: 850,  category: 'Tea & Coffee',   unit: 'pkt',     stock: 18,  barcode: '6001107000034'),
  const Product(id: '35', name: 'Olper Milk 1L',             price: 180,  category: 'Milk & Dairy',   unit: 'pkt',     stock: 72,  barcode: '6001108000035'),
  const Product(id: '36', name: 'Nestle Milk 1L',            price: 195,  category: 'Milk & Dairy',   unit: 'pkt',     stock: 60,  barcode: '6001108000036'),
  const Product(id: '37', name: 'Dairy Queen Dahi 400g',     price: 140,  category: 'Milk & Dairy',   unit: 'pkt',     stock: 30,  barcode: '6001108000037'),
  const Product(id: '38', name: 'Nurpur Butter 200g',        price: 480,  category: 'Milk & Dairy',   unit: 'pkt',     stock: 24,  barcode: '6001108000038'),
  const Product(id: '39', name: 'Olper Cream 200ml',         price: 220,  category: 'Milk & Dairy',   unit: 'pkt',     stock: 36,  barcode: '6001108000039'),
  const Product(id: '40', name: 'Kraft Cheddar Slice 200g',  price: 650,  category: 'Milk & Dairy',   unit: 'pkt',     stock: 15,  barcode: '6001108000040'),
  const Product(id: '41', name: 'Sooper Biscuit 113g',       price: 80,   category: 'Biscuits',       unit: 'pkt',     stock: 90,  barcode: '6001109000041'),
  const Product(id: '42', name: 'Peek Freans Peanut Panda',  price: 95,   category: 'Biscuits',       unit: 'pkt',     stock: 75,  barcode: '6001109000042'),
  const Product(id: '43', name: 'Prince Chocolate 93g',      price: 110,  category: 'Biscuits',       unit: 'pkt',     stock: 60,  barcode: '6001109000043'),
  const Product(id: '44', name: 'Lays Classic 34g',          price: 60,   category: 'Biscuits',       unit: 'pkt',     stock: 100, barcode: '6001109000044'),
  const Product(id: '45', name: 'Kurkure Chutney 62g',       price: 70,   category: 'Biscuits',       unit: 'pkt',     stock: 85,  barcode: '6001109000045'),
  const Product(id: '46', name: 'Pepsi 1.5L',                price: 130,  category: 'Drinks',         unit: 'bottle',  stock: 48,  barcode: '6001110000046'),
  const Product(id: '47', name: 'Coca Cola 1.5L',            price: 130,  category: 'Drinks',         unit: 'bottle',  stock: 48,  barcode: '6001110000047'),
  const Product(id: '48', name: 'Nestle Pure Life 1.5L',     price: 80,   category: 'Drinks',         unit: 'bottle',  stock: 96,  barcode: '6001110000048'),
  const Product(id: '49', name: 'Minute Maid Pulpy 1L',      price: 180,  category: 'Drinks',         unit: 'bottle',  stock: 30,  barcode: '6001110000049'),
  const Product(id: '50', name: '7UP 500ml (Can)',            price: 110,  category: 'Drinks',         unit: 'can',     stock: 0,   barcode: '6001110000050'),
  const Product(id: '51', name: 'Surf Excel 500g',           price: 280,  category: 'Detergent',      unit: 'pkt',     stock: 55,  barcode: '6001111000051'),
  const Product(id: '52', name: 'Ariel 500g',                price: 320,  category: 'Detergent',      unit: 'pkt',     stock: 40,  barcode: '6001111000052'),
  const Product(id: '53', name: 'Safeguard Soap 175g',       price: 120,  category: 'Detergent',      unit: 'pcs',     stock: 80,  barcode: '6001111000053'),
  const Product(id: '54', name: 'Lux Soap 175g',             price: 95,   category: 'Detergent',      unit: 'pcs',     stock: 90,  barcode: '6001111000054'),
  const Product(id: '55', name: 'Bonus Washing Powder 1kg',  price: 230,  category: 'Detergent',      unit: 'pkt',     stock: 35,  barcode: '6001111000055'),
  const Product(id: '56', name: 'Anda (Egg) - Dozen',        price: 360,  category: 'Eggs & Poultry', unit: 'dozen',   stock: 50,  barcode: '6001112000056'),
  const Product(id: '57', name: 'Anda (Egg) - Half Dozen',   price: 190,  category: 'Eggs & Poultry', unit: 'half dz', stock: 40,  barcode: '6001112000057'),
  const Product(id: '58', name: 'National Ketchup 800g',     price: 320,  category: 'Packed Food',    unit: 'bottle',  stock: 28,  barcode: '6001113000058'),
  const Product(id: '59', name: 'Knorr Noodles 66g',         price: 75,   category: 'Packed Food',    unit: 'pkt',     stock: 65,  barcode: '6001113000059'),
  const Product(id: '60', name: 'Maggi Noodles 70g',         price: 70,   category: 'Packed Food',    unit: 'pkt',     stock: 70,  barcode: '6001113000060'),
  const Product(id: '61', name: 'Shezan Jam Mango 440g',     price: 320,  category: 'Packed Food',    unit: 'jar',     stock: 22,  barcode: '6001113000061'),
  const Product(id: '62', name: 'Mitchell Mixed Fruit Jam',  price: 280,  category: 'Packed Food',    unit: 'jar',     stock: 0,   barcode: '6001113000062'),
];