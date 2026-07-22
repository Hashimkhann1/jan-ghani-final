class CustomerAccountModel {
  final String   id;            // users.id (Supabase)
  final String   fullName;
  final String   email;
  final String   password;
  final String   customerToken; // = customer.id (PostgreSQL)
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerAccountModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.customerToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerAccountModel.fromMap(Map<String, dynamic> m) {
    return CustomerAccountModel(
      id:            m['id']?.toString()             ?? '',
      fullName:      m['full_name']?.toString()      ?? '',
      email:         m['email']?.toString()          ?? '',
      password:      m['password']?.toString()       ?? '',
      customerToken: m['customer_token']?.toString() ?? '',
      createdAt:     _date(m['created_at'])          ?? DateTime.now(),
      updatedAt:     _date(m['updated_at'])          ?? DateTime.now(),
    );
  }

  static DateTime? _date(dynamic v) {
    if (v == null)     return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CustomerAccountModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
