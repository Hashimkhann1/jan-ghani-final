class AccountantUserEntity {
  final String id;
  final String name;
  final String username;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;

  const AccountantUserEntity({
    required this.id,
    required this.name,
    required this.username,
    this.phone,
    required this.isActive,
    required this.createdAt,
  });
}