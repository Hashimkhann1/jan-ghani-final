class WeeklySale {
  final String day;
  final double amount;
  const WeeklySale(this.day, this.amount);
}

class TopProduct {
  final int    rank;
  final String name;
  final int    qty;
  final double amount;
  const TopProduct(this.rank, this.name, this.qty, this.amount);
}

class TopCustomer {
  final int    rank;
  final String name;
  final int    orders;
  final double amount;
  const TopCustomer(this.rank, this.name, this.orders, this.amount);
}

class DashboardData {
  final double             cashSale;
  final double             cardSale;
  final double             creditSale;
  final double             installment;
  final double             totalSale;
  final double             totalAmount;
  final List<WeeklySale>   weeklySales;
  final List<TopProduct>   topProducts;
  final List<TopCustomer>  topCustomers;

  const DashboardData({
    required this.cashSale,
    required this.cardSale,
    required this.creditSale,
    required this.installment,
    required this.totalSale,
    required this.totalAmount,
    required this.weeklySales,
    required this.topProducts,
    required this.topCustomers,
  });

  static DashboardData empty() => const DashboardData(
    cashSale:    0,
    cardSale:    0,
    creditSale:  0,
    installment: 0,
    totalSale:   0,
    totalAmount: 0,
    weeklySales: [],
    topProducts: [],
    topCustomers: [],
  );
}