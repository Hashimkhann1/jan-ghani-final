class CashierData {
  final double counterCash;
  final double counterCashToday;
  final double cashSale;
  final int cashTxn;
  final double cardSale;
  final int cardTxn;
  final double creditSale;
  final int creditTxn;
  final double installment;
  final int installmentTxn;
  final List<CashierWithdrawal> withdrawals;

  CashierData({
    required this.counterCash,
    required this.counterCashToday,
    required this.cashSale,
    required this.cashTxn,
    required this.cardSale,
    required this.cardTxn,
    required this.creditSale,
    required this.creditTxn,
    required this.installment,
    required this.installmentTxn,
    required this.withdrawals,
  });

  double get totalSales => cashSale + cardSale + creditSale + installment;
  int get totalTxn => cashTxn + cardTxn + creditTxn + installmentTxn;

  factory CashierData.dummy() => CashierData(
    counterCash: 24500,
    counterCashToday: 3200,
    cashSale: 48200,
    cashTxn: 32,
    cardSale: 31750,
    cardTxn: 18,
    creditSale: 19400,
    creditTxn: 11,
    installment: 12600,
    installmentTxn: 7,
    withdrawals: [
      CashierWithdrawal(managerName: 'Ahmed Raza', amount: 10000, time: '10:30 AM', note: 'Morning handover'),
      CashierWithdrawal(managerName: 'Ahmed Raza', amount: 8500,  time: '02:15 PM', note: 'Afternoon shift'),
      CashierWithdrawal(managerName: 'Usman Ali',  amount: 6000,  time: '05:00 PM', note: 'Evening closing'),
    ],
  );
}

class CashierTransaction {
  final String name;
  final String type;
  final double amount;
  final String time;
  CashierTransaction(this.name, this.type, this.amount, this.time);
}


class CashierWithdrawal {
  final String managerName;
  final double amount;
  final String time;
  final String note;

  CashierWithdrawal({
    required this.managerName,
    required this.amount,
    required this.time,
    required this.note,
  });
}


