// =============================================================
// accountant_supplier_model.dart
// Accountant ke supplier LIST ka model (suppliers table)
// Read-only — accountant sirf dekh sakta hai
// =============================================================

class AccountantSupplierModel {
  final String  id;
  final String  name;
  final String? companyName;
  final String? code;
  final String  phone;
  final double  outstandingBalance;
  final bool    isActive;

  const AccountantSupplierModel({
    required this.id,
    required this.name,
    this.companyName,
    this.code,
    required this.phone,
    required this.outstandingBalance,
    required this.isActive,
  });

  bool get hasDue  => outstandingBalance > 0;
  bool get isClear => outstandingBalance == 0;

  factory AccountantSupplierModel.fromMap(Map<String, dynamic> map) {
    return AccountantSupplierModel(
      id:                 map['id']?.toString() ?? '',
      name:               map['name']?.toString() ?? 'Unknown',
      companyName:        map['company_name']?.toString(),
      code:               map['code']?.toString(),
      phone:              map['phone']?.toString() ?? '',
      outstandingBalance: _toDouble(map['outstanding_balance']),
      isActive:           map['is_active'] == true || map['is_active'] == 't',
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
