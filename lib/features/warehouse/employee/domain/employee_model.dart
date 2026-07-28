// =============================================================
// employee_model.dart — warehouse employee master
// =============================================================

class EmployeeModel {
  final String   id;
  final String   warehouseId;
  final String   name;
  final String?  phone;
  final String?  address;
  final double   monthlySalary;
  final double   maxAdvancePercent; // e.g. 30 = 30%
  final bool     isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const EmployeeModel({
    required this.id,
    required this.warehouseId,
    required this.name,
    this.phone,
    this.address,
    this.monthlySalary     = 0,
    this.maxAdvancePercent = 0,
    this.isActive          = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Max advance (rupees) is employee ke liye = salary × max% ⁄ 100
  double get maxAdvanceAmount => monthlySalary * maxAdvancePercent / 100;

  factory EmployeeModel.fromMap(Map<String, dynamic> m) {
    return EmployeeModel(
      id:                m['id']?.toString()           ?? '',
      warehouseId:       m['warehouse_id']?.toString() ?? '',
      name:              m['name']?.toString()         ?? '',
      phone:             m['phone']?.toString(),
      address:           m['address']?.toString(),
      monthlySalary:     _dbl(m['monthly_salary']),
      maxAdvancePercent: _dbl(m['max_advance_percent']),
      isActive:          m['is_active'] == true || m['is_active'] == 't',
      createdAt:         _date(m['created_at']) ?? DateTime.now(),
      updatedAt:         _date(m['updated_at']) ?? DateTime.now(),
      deletedAt:         _date(m['deleted_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id':                  id,
    'warehouse_id':        warehouseId,
    'name':                name,
    'phone':               phone,
    'address':             address,
    'monthly_salary':      monthlySalary,
    'max_advance_percent': maxAdvancePercent,
    'is_active':           isActive,
  };

  EmployeeModel copyWith({
    String?   name,
    String?   phone,
    String?   address,
    double?   monthlySalary,
    double?   maxAdvancePercent,
    bool?     isActive,
    DateTime? deletedAt,
  }) {
    return EmployeeModel(
      id:                id,
      warehouseId:       warehouseId,
      name:              name              ?? this.name,
      phone:             phone             ?? this.phone,
      address:           address           ?? this.address,
      monthlySalary:     monthlySalary     ?? this.monthlySalary,
      maxAdvancePercent: maxAdvancePercent ?? this.maxAdvancePercent,
      isActive:          isActive          ?? this.isActive,
      createdAt:         createdAt,
      updatedAt:         DateTime.now(),
      deletedAt:         deletedAt         ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EmployeeModel && id == other.id;
  @override
  int get hashCode => id.hashCode;

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
