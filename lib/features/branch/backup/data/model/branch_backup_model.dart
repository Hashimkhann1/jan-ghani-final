class BackupBranchModel {
  final String id;
  final String code;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;

  const BackupBranchModel({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    this.phone,
    required this.isActive,
    required this.createdAt,
  });

  factory BackupBranchModel.fromMap(Map<String, dynamic> map) {
    return BackupBranchModel(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() => name;
}