// =============================================================
// company_model.dart  (name-only — Category ka simplified mirror)
// =============================================================

class CompanyModel {
  final String  id;
  final String  warehouseId;
  final String  name;
  final bool    isActive;
  final DateTime  createdAt;
  final DateTime  updatedAt;
  final DateTime? deletedAt;

  const CompanyModel({
    required this.id,
    required this.warehouseId,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // ── fromMap ───────────────────────────────────────────────
  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id:          map['id']?.toString()           ?? '',
      warehouseId: map['warehouse_id']?.toString() ?? '',
      name:        map['name']?.toString()         ?? '',
      isActive:    map['is_active'] == true ||
                   map['is_active'] == 't',
      createdAt:   map['created_at'] is DateTime
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at'].toString()),
      updatedAt:   map['updated_at'] is DateTime
          ? map['updated_at'] as DateTime
          : DateTime.parse(map['updated_at'].toString()),
      deletedAt:   map['deleted_at'] == null ? null
          : map['deleted_at'] is DateTime
              ? map['deleted_at'] as DateTime
              : DateTime.parse(map['deleted_at'].toString()),
    );
  }

  // ── toMap ─────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'id':           id,
    'warehouse_id': warehouseId,
    'name':         name,
    'is_active':    isActive,
  };

  // ── copyWith ──────────────────────────────────────────────
  CompanyModel copyWith({
    String?   name,
    bool?     isActive,
    DateTime? deletedAt,
  }) {
    return CompanyModel(
      id:          id,
      warehouseId: warehouseId,
      name:        name     ?? this.name,
      isActive:    isActive ?? this.isActive,
      createdAt:   createdAt,
      updatedAt:   DateTime.now(),
      deletedAt:   deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CompanyModel(id: $id, name: $name)';
}
