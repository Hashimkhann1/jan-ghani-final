class CounterModel {
  final String id;
  final String counterName;
  final String username;
  final String password;
  final double cashSale;
  final double cardSale;
  final double creditSale;
  final double installment;
  final double totalSale;

  CounterModel({
    required this.id,
    required this.counterName,
    required this.username,
    required this.password,
    this.cashSale = 0.0,
    this.cardSale = 0.0,
    this.creditSale = 0.0,
    this.installment = 0.0,
    this.totalSale = 0.0,
  });

  CounterModel copyWith({
    String? counterName,
    String? username,
    String? password,
    double? cashSale,
    double? cardSale,
    double? creditSale,
    double? installment,
    double? totalSale,
  }) {
    return CounterModel(
      id: id,
      counterName: counterName ?? this.counterName,
      username: username ?? this.username,
      password: password ?? this.password,
      cashSale: cashSale ?? this.cashSale,
      cardSale: cardSale ?? this.cardSale,
      creditSale: creditSale ?? this.creditSale,
      installment: installment ?? this.installment,
      totalSale: totalSale ?? this.totalSale,
    );
  }

  double get total => cashSale + cardSale + creditSale + installment;
}