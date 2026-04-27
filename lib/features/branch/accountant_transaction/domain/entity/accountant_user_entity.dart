class AccountantUserEntity {
  final String id;
  final String name;
  final String? phone;
  final String username;
  final bool isActive;
  final DateTime createdAt;
  final double totalAmount;

  const AccountantUserEntity({
    required this.id,
    required this.name,
    this.phone,
    required this.username,
    required this.isActive,
    required this.createdAt,
    required this.totalAmount,
  });

  String get balanceLabel => 'Rs ${totalAmount.toStringAsFixed(0)}';
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}