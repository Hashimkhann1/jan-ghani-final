/// Ek product ka range ka summary (dashboard "top products" graphs ke liye).
class TopProductStat {
  final String productId;
  final String name;
  final double qtySold;
  final double revenue;
  final double profit;
  final double stock; // current stock (negative 0 maana jata hai)

  const TopProductStat({
    required this.productId,
    required this.name,
    required this.qtySold,
    required this.revenue,
    required this.profit,
    required this.stock,
  });
}

/// get_branch_top_products ka natija — pehle se rank + limit ho kar aata hai.
class TopProductsResult {
  final List<TopProductStat> selling, profit, lowStock;
  const TopProductsResult(this.selling, this.profit, this.lowStock);
}
