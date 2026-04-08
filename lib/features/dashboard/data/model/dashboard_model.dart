class WeeklySale {
  final String day;
  final double amount;
  const WeeklySale(this.day, this.amount);
}

class TopProduct {
  final int rank;
  final String name;
  final int qty;
  final double amount;
  const TopProduct(this.rank, this.name, this.qty, this.amount);
}

class TopCustomer {
  final int rank;
  final String name;
  final int orders;
  final double amount;
  const TopCustomer(this.rank, this.name, this.orders, this.amount);
}

class DashboardData {
  final double cashSale;
  final double cardSale;
  final double creditSale;
  final double installment;
  final double totalSale;
  final double totalAmount;
  final List<WeeklySale> weeklySales;
  final List<TopProduct> topProducts;
  final List<TopCustomer> topCustomers;

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

  // Dummy data — replace with your API call
  static DashboardData dummy() {
    return const DashboardData(
      cashSale: 284500,
      cardSale: 95000,
      creditSale: 162300,
      installment: 48000,
      totalSale: 446800,
      totalAmount: 589800,
      weeklySales: [
        WeeklySale('Mon', 52000),
        WeeklySale('Tue', 78000),
        WeeklySale('Wed', 61000),
        WeeklySale('Thu', 93000),
        WeeklySale('Fri', 128000),
        WeeklySale('Sat', 145000),
        WeeklySale('Sun', 134000),
      ],
      topProducts: [
        TopProduct(1, 'Basmati Rice', 145, 174000),
        TopProduct(2, 'Sugar 1kg', 132, 158400),
        TopProduct(3, 'Flour 5kg', 118, 141600),
        TopProduct(4, 'Cooking Oil', 105, 126000),
        TopProduct(5, 'Dal Moong', 98, 117600),
        TopProduct(6, 'Tea 500g', 87, 104400),
        TopProduct(7, 'Salt 1kg', 76, 91200),
        TopProduct(8, 'Biscuits Box', 65, 78000),
        TopProduct(9, 'Soap Bar', 54, 64800),
        TopProduct(10, 'Shampoo', 43, 51600),
      ],
      topCustomers: [
        TopCustomer(1, 'Ahmed Traders', 34, 289000),
        TopCustomer(2, 'Ali Brothers', 29, 246500),
        TopCustomer(3, 'Karachi Store', 27, 229500),
        TopCustomer(4, 'Lahore Mart', 24, 204000),
        TopCustomer(5, 'Star Shop', 22, 187000),
        TopCustomer(6, 'City General', 20, 170000),
        TopCustomer(7, 'Punjab Traders', 18, 153000),
        TopCustomer(8, 'Sindh Mart', 16, 136000),
        TopCustomer(9, 'Capital Store', 14, 119000),
        TopCustomer(10, 'North Traders', 12, 102000),
      ],
    );
  }
}