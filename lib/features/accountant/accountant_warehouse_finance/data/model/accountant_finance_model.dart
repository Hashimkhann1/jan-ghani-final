// =============================================================
// accountant_finance_model.dart
// Accountant ke Warehouse Finance feature ke models (read-only)
//   • AccFinanceSummary       → RPC accountant_warehouse_finance_summary
//   • AccCashTransactionModel → warehouse_cash_transactions
// =============================================================

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime _toDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString()) ?? DateTime.now();
}

// ─────────────────────────────────────────────────────────────
// SUMMARY
// ─────────────────────────────────────────────────────────────
class AccFinanceSummary {
  final double cashInHand;
  final double totalExpense;
  final double totalCashIn;
  final double totalCashOut;
  final int    totalTransactions;

  const AccFinanceSummary({
    required this.cashInHand,
    required this.totalExpense,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.totalTransactions,
  });

  factory AccFinanceSummary.fromMap(Map<String, dynamic> map) {
    return AccFinanceSummary(
      cashInHand:        _toDouble(map['cash_in_hand']),
      totalExpense:      _toDouble(map['total_expense']),
      totalCashIn:       _toDouble(map['total_cash_in']),
      totalCashOut:      _toDouble(map['total_cash_out']),
      totalTransactions: _toInt(map['total_transactions']),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CASH TRANSACTION  (warehouse_cash_transactions)
// ─────────────────────────────────────────────────────────────
class AccCashTransactionModel {
  final String   id;
  final String   entryType;   // cash_in | purchase | supplier_payment | expense
  final double   amount;
  final double   cashInHandBefore;
  final double   cashInHandAfter;
  final String?  notes;
  final String?  createdByName;
  final DateTime createdAt;
  final String?  supplierName; // sirf supplier_payment ke liye

  const AccCashTransactionModel({
    required this.id,
    required this.entryType,
    required this.amount,
    required this.cashInHandBefore,
    required this.cashInHandAfter,
    this.notes,
    this.createdByName,
    required this.createdAt,
    this.supplierName,
  });

  // cash_in = paisa andar aaya; baaki sab bahar gaya
  bool get isCashIn => entryType == 'cash_in';

  String get entryTypeLabel {
    switch (entryType) {
      case 'cash_in':          return 'Cash In';
      case 'purchase':         return 'Purchase';
      case 'supplier_payment': return 'Supplier Payment';
      case 'expense':          return 'Expense';
      default:                 return entryType;
    }
  }

  factory AccCashTransactionModel.fromMap(Map<String, dynamic> map) {
    return AccCashTransactionModel(
      id:               map['id']?.toString() ?? '',
      entryType:        map['entry_type']?.toString() ?? '',
      amount:           _toDouble(map['amount']),
      cashInHandBefore: _toDouble(map['cash_in_hand_before']),
      cashInHandAfter:  _toDouble(map['cash_in_hand_after']),
      notes:            map['notes']?.toString(),
      createdByName:    map['created_by_name']?.toString(),
      createdAt:        _toDate(map['created_at']),
      supplierName:     map['supplier_name']?.toString(),
    );
  }
}
