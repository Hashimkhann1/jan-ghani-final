// =============================================================
// salary_payment_model.dart — ek salary ya advance payment
// =============================================================

enum SalaryPaymentType { salary, advance }

class SalaryPaymentModel {
  final String   id;
  final String   warehouseId;
  final String   employeeId;
  final String?  cashTransactionId;
  final SalaryPaymentType type;
  final double   amount;
  final DateTime salaryMonth; // kis mahine ke liye (1st of month)
  final String?  notes;
  final String?  paidBy;
  final String?  paidByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const SalaryPaymentModel({
    required this.id,
    required this.warehouseId,
    required this.employeeId,
    this.cashTransactionId,
    required this.type,
    required this.amount,
    required this.salaryMonth,
    this.notes,
    this.paidBy,
    this.paidByName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isAdvance => type == SalaryPaymentType.advance;

  String get typeLabel => isAdvance ? 'Advance' : 'Salary';

  static SalaryPaymentType typeFromString(String? s) =>
      s == 'advance' ? SalaryPaymentType.advance : SalaryPaymentType.salary;

  static String typeToString(SalaryPaymentType t) =>
      t == SalaryPaymentType.advance ? 'advance' : 'salary';

  factory SalaryPaymentModel.fromMap(Map<String, dynamic> m) {
    return SalaryPaymentModel(
      id:                m['id']?.toString()           ?? '',
      warehouseId:       m['warehouse_id']?.toString() ?? '',
      employeeId:        m['employee_id']?.toString()  ?? '',
      cashTransactionId: m['cash_transaction_id']?.toString(),
      type:              typeFromString(m['payment_type']?.toString()),
      amount:            _dbl(m['amount']),
      salaryMonth:       _date(m['salary_month']) ?? DateTime.now(),
      notes:             m['notes']?.toString(),
      paidBy:            m['paid_by']?.toString(),
      paidByName:        m['paid_by_name']?.toString(),
      createdAt:         _date(m['created_at']) ?? DateTime.now(),
      updatedAt:         _date(m['updated_at']) ?? DateTime.now(),
      deletedAt:         _date(m['deleted_at']),
    );
  }

  static double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
