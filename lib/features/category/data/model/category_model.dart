// =============================================================
// category_model.dart
// =============================================================

class CategoryModel {
  final String  id;
  final String  warehouseId;
  final String  name;
  final String? description;
  final String? colorCode;    // hex color — '#FF5733'
  final bool    isActive;
  final DateTime  createdAt;
  final DateTime  updatedAt;
  final DateTime? deletedAt;

  const CategoryModel({
    required this.id,
    required this.warehouseId,
    required this.name,
    this.description,
    this.colorCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // ── fromMap ───────────────────────────────────────────────
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id:          map['id']?.toString()           ?? '',
      warehouseId: map['warehouse_id']?.toString() ?? '',
      name:        map['name']?.toString()         ?? '',
      description: map['description']?.toString(),
      colorCode:   map['color_code']?.toString(),
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
    'description':  description,
    'color_code':   colorCode,
    'is_active':    isActive,
  };

  // ── copyWith ──────────────────────────────────────────────
  CategoryModel copyWith({
    String?   name,
    String?   description,
    String?   colorCode,
    bool?     isActive,
    DateTime? deletedAt,
  }) {
    return CategoryModel(
      id:          id,
      warehouseId: warehouseId,
      name:        name        ?? this.name,
      description: description ?? this.description,
      colorCode:   colorCode   ?? this.colorCode,
      isActive:    isActive    ?? this.isActive,
      createdAt:   createdAt,
      updatedAt:   DateTime.now(),
      deletedAt:   deletedAt   ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CategoryModel(id: $id, name: $name)';
}
