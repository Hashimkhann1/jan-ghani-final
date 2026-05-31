// =============================================================
// accountant_warehouse_model.dart
// Warehouses list ka model (read-only) — warehouses table
// =============================================================

class AccountantWarehouseModel {
  final String  id;
  final String  name;
  final String? code;
  final String? address;
  final String? phone;
  final bool    isActive;

  const AccountantWarehouseModel({
    required this.id,
    required this.name,
    this.code,
    this.address,
    this.phone,
    required this.isActive,
  });

  factory AccountantWarehouseModel.fromMap(Map<String, dynamic> map) {
    return AccountantWarehouseModel(
      id:       map['id']?.toString() ?? '',
      name:     map['name']?.toString() ?? 'Unknown Warehouse',
      code:     map['code']?.toString(),
      address:  map['address']?.toString(),
      phone:    map['phone']?.toString(),
      isActive: map['is_active'] == true || map['is_active'] == 't',
    );
  }
}
