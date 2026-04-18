// =============================================================
// warehouse_expense_model.dart
// Domain models for warehouse_expense feature
// =============================================================

class WarehouseExpenseModel {
  final String   id;
  final String   warehouseId;
  final String?  cashTransactionId;
  final String   expenseHead;
  final double   amount;
  final String?  description;
  final DateTime expenseDate;
  final String?  createdBy;
  final String?  createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String   syncId;
  final bool     isSynced;

  const WarehouseExpenseModel({
    required this.id,
    required this.warehouseId,
    this.cashTransactionId,
    required this.expenseHead,
    required this.amount,
    this.description,
    required this.expenseDate,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncId,
    this.isSynced = false,
  });

  factory WarehouseExpenseModel.fromMap(Map<String, dynamic> m) {
    return WarehouseExpenseModel(
      id:                 m['id'].toString(),
      warehouseId:        m['warehouse_id'].toString(),
      cashTransactionId:  m['cash_transaction_id']?.toString(),
      expenseHead:        m['expense_head'].toString(),
      amount:             _toDouble(m['amount']),
      description:        m['description']?.toString(),
      expenseDate:        _toDate(m['expense_date'])!,
      createdBy:          m['created_by']?.toString(),
      createdByName:      m['created_by_name']?.toString(),
      createdAt:          _toDate(m['created_at'])!,
      updatedAt:          _toDate(m['updated_at'])!,
      deletedAt:          _toDate(m['deleted_at']),
      syncId:             m['sync_id'].toString(),
      isSynced:           m['is_synced'] as bool? ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Expense Stats — screen ke upar cards ke liye
// ─────────────────────────────────────────────────────────────
class ExpenseStats {
  final int    totalCount;
  final double todayTotal;
  final double thisMonthTotal;

  const ExpenseStats({
    this.totalCount    = 0,
    this.todayTotal    = 0,
    this.thisMonthTotal = 0,
  });
}

// ─────────────────────────────────────────────────────────────
// Quick Select chips — image mein jo chips hain
// ─────────────────────────────────────────────────────────────
const kExpenseQuickSelect = [
  'Rent',
  'Electricity',
  'Salary',
  'Transport',
  'Maintenance',
  'Grocery',
  'Miscellaneous',
];

// ── Helpers ───────────────────────────────────────────────────
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num)  return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

DateTime? _toDate(dynamic v) {
  if (v == null)     return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}