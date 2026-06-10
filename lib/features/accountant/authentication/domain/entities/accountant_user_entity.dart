class AccountantUserEntity {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? branchId;
  final String? warehouseId;
  final String? customerToken;
  final bool isActive;
  final DateTime createdAt;

  const AccountantUserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.branchId,
    this.warehouseId,
    this.customerToken,
    required this.isActive,
    required this.createdAt,
  });
}