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

  /// Staff role + customer account dono → login par "Choose your account".
  /// Owner / accountant / viewer: sirf role + customer_token check (branch ya
  /// warehouse id nahi). Manager: branch_id bhi honi chahiye.
  bool get hasStaffAndCustomer {
    if ((customerToken ?? '').isEmpty) return false;
    if (role == 'manager') return (branchId ?? '').isNotEmpty;
    return role == 'owner' || role == 'accountant' || role == 'viewer';
  }
}
