import '../../domain/entities/accountant_user_entity.dart';

class AccountantUserModel extends AccountantUserEntity {
  const AccountantUserModel({
    required super.id,
    required super.name,
    required super.username,
    super.phone,
    required super.isActive,
    required super.createdAt,
  });

  factory AccountantUserModel.fromMap(Map<String, dynamic> map) {
    return AccountantUserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      username: map['username'] as String,
      phone: map['phone'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'username': username,
    'phone': phone,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}