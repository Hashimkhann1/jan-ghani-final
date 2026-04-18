// =============================================================
// warehouse_finance_model.dart
// Domain models for warehouse_finance feature
// =============================================================

// ─────────────────────────────────────────────────────────────
// MODEL 1: WarehouseFinanceModel
// warehouse_finance table — 1 row per warehouse
// ─────────────────────────────────────────────────────────────
class WarehouseFinanceModel {
  final String  id;
  final String  warehouseId;
  final double  cashInHand;
  final DateTime updatedAt;

  const WarehouseFinanceModel({
    required this.id,
    required this.warehouseId,
    required this.cashInHand,
    required this.updatedAt,
  });

  WarehouseFinanceModel copyWith({
    String?   id,
    String?   warehouseId,
    double?   cashInHand,
    DateTime? updatedAt,
  }) {
    return WarehouseFinanceModel(
      id:          id          ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      cashInHand:  cashInHand  ?? this.cashInHand,
      updatedAt:   updatedAt   ?? this.updatedAt,
    );
  }

  factory WarehouseFinanceModel.fromMap(Map<String, dynamic> m) {
    return WarehouseFinanceModel(
      id:          m['id'].toString(),
      warehouseId: m['warehouse_id'].toString(),
      cashInHand:  _toDouble(m['cash_in_hand']),
      updatedAt:   m['updated_at'] is DateTime
          ? m['updated_at'] as DateTime
          : DateTime.parse(m['updated_at'].toString()),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODEL 2: CashTransactionModel
// cash_transactions table — har entry ka record
// ─────────────────────────────────────────────────────────────
class CashTransactionModel {
  final String   id;
  final String   warehouseId;
  final String   entryType;        // cash_in / purchase / supplier_payment / expense
  final double   amount;
  final double   cashInHandBefore;
  final double   cashInHandAfter;
  final String?  referenceId;
  final String?  notes;
  final String?  createdBy;
  final String?  createdByName;
  final DateTime createdAt;
  final String   syncId;
  final bool     isSynced;
  final DateTime? syncedAt;

  const CashTransactionModel({
    required this.id,
    required this.warehouseId,
    required this.entryType,
    required this.amount,
    required this.cashInHandBefore,
    required this.cashInHandAfter,
    this.referenceId,
    this.notes,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.syncId,
    this.isSynced = false,
    this.syncedAt,
  });

  factory CashTransactionModel.fromMap(Map<String, dynamic> m) {
    return CashTransactionModel(
      id:               m['id'].toString(),
      warehouseId:      m['warehouse_id'].toString(),
      entryType:        m['entry_type'].toString(),
      amount:           _toDouble(m['amount']),
      cashInHandBefore: _toDouble(m['cash_in_hand_before']),
      cashInHandAfter:  _toDouble(m['cash_in_hand_after']),
      referenceId:      m['reference_id']?.toString(),
      notes:            m['notes']?.toString(),
      createdBy:        m['created_by']?.toString(),
      createdByName:    m['created_by_name']?.toString(),
      createdAt:        m['created_at'] is DateTime
          ? m['created_at'] as DateTime
          : DateTime.parse(m['created_at'].toString()),
      syncId:           m['sync_id'].toString(),
      isSynced:         m['is_synced'] as bool? ?? false,
      syncedAt:         m['synced_at'] == null ? null :
      m['synced_at'] is DateTime
          ? m['synced_at'] as DateTime
          : DateTime.tryParse(m['synced_at'].toString()),
    );
  }

  // Entry type ka display naam
  String get entryTypeDisplay {
    switch (entryType) {
      case 'cash_in':          return 'Cash In';
      case 'purchase':         return 'Purchase';
      case 'supplier_payment': return 'Supplier Payment';
      case 'expense':          return 'Expense';
      default:                 return entryType;
    }
  }

  // Cash in hai ya out
  bool get isCashIn => entryType == 'cash_in';
}

// ─────────────────────────────────────────────────────────────
// MODEL 3: WarehouseFinanceSummary
// Dashboard ke liye summary
// ─────────────────────────────────────────────────────────────
class WarehouseFinanceSummary {
  final double cashInHand;
  final double todayCashIn;
  final double todayCashOut;
  final double thisMonthCashIn;
  final double thisMonthCashOut;
  final double totalSupplierDue;

  const WarehouseFinanceSummary({
    this.cashInHand       = 0,
    this.todayCashIn      = 0,
    this.todayCashOut     = 0,
    this.thisMonthCashIn  = 0,
    this.thisMonthCashOut = 0,
    this.totalSupplierDue = 0,
  });

  double get todayNet       => todayCashIn - todayCashOut;
  double get thisMonthNet   => thisMonthCashIn - thisMonthCashOut;
}

// ─────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num)  return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}