// lib/features/branch/branch_info/data/model/branch_model.dart

class BranchModel {
  final String id;
  final String code;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const BranchModel({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    this.phone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory BranchModel.fromMap(Map<String, dynamic> m) => BranchModel(
    id: m['id'] as String,
    code: m['code']?.toString() ?? '',
    name: m['name']?.toString() ?? '',
    address: m['address']?.toString(),
    phone: m['phone']?.toString(),
    isActive: m['is_active'] is bool
        ? m['is_active'] as bool
        : (m['is_active']?.toString() == 'true'),
    createdAt: m['created_at'] is DateTime
        ? m['created_at'] as DateTime
        : DateTime.parse(m['created_at'].toString()),
    updatedAt: m['updated_at'] is DateTime
        ? m['updated_at'] as DateTime
        : DateTime.parse(m['updated_at'].toString()),
    deletedAt: m['deleted_at'] == null
        ? null
        : (m['deleted_at'] is DateTime
        ? m['deleted_at'] as DateTime
        : DateTime.parse(m['deleted_at'].toString())),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'code': code,
    'name': name,
    'address': address,
    'phone': phone,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };

}