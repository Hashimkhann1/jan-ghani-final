// ─────────────────────────────────────────────────────────────────────────────
// WAREHOUSE MODEL
// ─────────────────────────────────────────────────────────────────────────────

class WarehouseModel {
  final int id;
  final String name;
  final String code;
  final String? address;
  final String? phone;
  final String? email;
  final String? notes;
  final int productCount;
  final int unitCount;
  final int lowStockCount;

  const WarehouseModel({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.phone,
    this.email,
    this.notes,
    this.productCount = 0,
    this.unitCount = 0,
    this.lowStockCount = 0,
  });

  WarehouseModel copyWith({
    int? id,
    String? name,
    String? code,
    String? address,
    String? phone,
    String? email,
    String? notes,
    int? productCount,
    int? unitCount,
    int? lowStockCount,
  }) {
    return WarehouseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      productCount: productCount ?? this.productCount,
      unitCount: unitCount ?? this.unitCount,
      lowStockCount: lowStockCount ?? this.lowStockCount,
    );
  }
}