import '../../domain/entity/accountant_user_entity.dart';

class AccountantUserModel {
  final String id;
  final String name;
  final String? phone;
  final String username;
  final bool isActive;
  final DateTime createdAt;
  final double totalAmount;

  const AccountantUserModel({
    required this.id,
    required this.name,
    this.phone,
    required this.username,
    required this.isActive,
    required this.createdAt,
    required this.totalAmount,
  });

  factory AccountantUserModel.fromJson(Map<String, dynamic> json) {
    final counter = json['accountant_counter'];
    final double amt = counter is Map
        ? ((counter['total_amount'] ?? 0) as num).toDouble()
        : 0.0;
    return AccountantUserModel(
      id:          json['id']        as String,
      name:        json['name']      as String,
      phone:       json['phone']     as String?,
      username:    json['username']  as String,
      isActive:    json['is_active'] as bool? ?? true,
      createdAt:   DateTime.parse(json['created_at'] as String),
      totalAmount: amt,
    );
  }

  AccountantUserEntity toEntity() => AccountantUserEntity(
    id:          id,
    name:        name,
    phone:       phone,
    username:    username,
    isActive:    isActive,
    createdAt:   createdAt,
    totalAmount: totalAmount,
  );
}