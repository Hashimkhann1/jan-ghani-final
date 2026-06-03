class AccountantCustomerReportModel {
  final String   id;
  final String   code;
  final String   name;
  final String   phone;
  final String   address;
  final String   customerType; // 'cash' | 'credit' | 'petrol'
  final double   creditLimit;
  final double   balance;
  final bool     isActive;
  final DateTime createdAt;

  const AccountantCustomerReportModel({
    required this.id,
    required this.code,
    required this.name,
    required this.phone,
    required this.address,
    required this.customerType,
    required this.creditLimit,
    required this.balance,
    required this.isActive,
    required this.createdAt,
  });

  /// Credit limit cross hua hai?
  /// Sirf tab check karo jab creditLimit > 0 ho
  bool get isCreditLimitExceeded =>
      creditLimit > 0 && balance > creditLimit;

  /// Limit use percentage (0.0 – 1.0+)
  double get creditUsageRatio =>
      creditLimit > 0 ? (balance / creditLimit).clamp(0.0, double.infinity) : 0.0;

  factory AccountantCustomerReportModel.fromMap(Map<String, dynamic> m) =>
      AccountantCustomerReportModel(
        id:           m['id']            as String,
        code:         m['code']          as String?  ?? '',
        name:         m['name']          as String?  ?? '',
        phone:        m['phone']         as String?  ?? '',
        address:      m['address']       as String?  ?? '',
        customerType: m['customer_type'] as String?  ?? 'cash',
        creditLimit:  double.tryParse(m['credit_limit']?.toString() ?? '0') ?? 0,
        balance:      double.tryParse(m['balance']?.toString()      ?? '0') ?? 0,
        isActive:     m['is_active']     as bool?    ?? true,
        createdAt:    DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

// ── Summary ───────────────────────────────────────────────
class AccountantCustomerReportSummary {
  final int    totalCustomers;
  final int    activeCustomers;
  final double totalOutstanding;
  final double totalCreditLimit;
  final int    limitExceededCount; // ← naya field

  const AccountantCustomerReportSummary({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.totalOutstanding,
    required this.totalCreditLimit,
    this.limitExceededCount = 0,
  });

  factory AccountantCustomerReportSummary.empty() =>
      const AccountantCustomerReportSummary(
        totalCustomers:     0,
        activeCustomers:    0,
        totalOutstanding:   0,
        totalCreditLimit:   0,
        limitExceededCount: 0,
      );
}