class BranchModel {
  final String  id;
  final String  code;
  final String  name;
  final String  address;
  final String  phone;
  final bool    isActive;
  final DateTime createdAt;

  const BranchModel({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.phone,
    required this.isActive,
    required this.createdAt,
  });

  factory BranchModel.fromMap(Map<String, dynamic> m) => BranchModel(
    id:        m['id']        as String,
    code:      m['code']      as String?  ?? '',
    name:      m['name']      as String?  ?? '',
    address:   m['address']   as String?  ?? '',
    phone:     m['phone']     as String?  ?? '',
    isActive:  m['is_active'] as bool?    ?? true,
    createdAt: DateTime.tryParse(
        m['created_at']?.toString() ?? '') ??
        DateTime.now(),
  );
}