
class CustomerModel {
  // ── customers table columns ──────────────────────────────
  final String id;
  final String tenantId;
  final String storeId;
  final String code;            // CUST-0001
  final String name;
  final String phone;
  final String? address;
  final String customerType;    // walkin | credit | wholesale
  final double creditLimit;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // ── v_customer_balances view columns ─────────────────────
  final double currentBalance;  // positive = customer ne dena hai
  final double availableCredit; // creditLimit - currentBalance

  // ── sales se aggregate (UI ke liye) ──────────────────────
  final int totalSales;
  final double totalSaleAmount;

  const CustomerModel({
    required this.id,
    required this.tenantId,
    required this.storeId,
    required this.code,
    required this.name,
    required this.phone,
    this.address,
    required this.customerType,
    required this.creditLimit,
    required this.isActive,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.currentBalance,
    required this.availableCredit,
    required this.totalSales,
    required this.totalSaleAmount,
  });

  // ── Balance helpers ───────────────────────────────────────

  bool get hasBalance  => currentBalance > 0;
  bool get isClear     => currentBalance == 0;
  bool get isWalkin    => customerType == 'walkin';
  bool get isCredit    => customerType == 'credit';
  bool get isWholesale => customerType == 'wholesale';

  String get balanceLabel {
    if (isClear)      return 'Clear';
    if (hasBalance)   return 'Rs ${currentBalance.toStringAsFixed(0)} Due';
    return 'Rs ${currentBalance.abs().toStringAsFixed(0)} Advance';
  }

  String get creditLimitLabel => 'Rs ${creditLimit.toStringAsFixed(0)}';

  String get typeLabel {
    switch (customerType) {
      case 'credit':    return 'Credit';
      case 'wholesale': return 'Wholesale';
      default:          return 'Walk-in';
    }
  }

  // ── fromMap ───────────────────────────────────────────────
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id:             map['id']              as String,
      tenantId:       map['tenant_id']       as String,
      storeId:        map['store_id']        as String,
      code:           map['code']            as String,
      name:           map['name']            as String,
      phone:          map['phone']           as String,
      address:        map['address']         as String?,
      customerType:   map['customer_type']   as String? ?? 'walkin',
      creditLimit:    (map['credit_limit']   as num?)?.toDouble() ?? 0.0,
      isActive:       map['is_active']       as bool? ?? true,
      notes:          map['notes']           as String?,
      createdAt:      DateTime.parse(map['created_at'] as String),
      updatedAt:      DateTime.parse(map['updated_at'] as String),
      deletedAt:      map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      currentBalance:  (map['current_balance']  as num?)?.toDouble() ?? 0.0,
      availableCredit: (map['available_credit'] as num?)?.toDouble() ?? 0.0,
      totalSales:      map['total_sales']        as int? ?? 0,
      totalSaleAmount: (map['total_sale_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ── toMap ─────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id':            id,
      'tenant_id':     tenantId,
      'store_id':      storeId,
      'code':          code,
      'name':          name,
      'phone':         phone,
      'address':       address,
      'customer_type': customerType,
      'credit_limit':  creditLimit,
      'is_active':     isActive,
      'notes':         notes,
    };
  }

  // ── copyWith ──────────────────────────────────────────────
  CustomerModel copyWith({
    String?  name,
    String?  phone,
    String?  address,
    String?  customerType,
    double?  creditLimit,
    bool?    isActive,
    String?  notes,
    double?  currentBalance,
    double?  availableCredit,
    int?     totalSales,
    double?  totalSaleAmount,
  }) {
    return CustomerModel(
      id:             id,
      tenantId:       tenantId,
      storeId:        storeId,
      code:           code,
      name:           name           ?? this.name,
      phone:          phone          ?? this.phone,
      address:        address        ?? this.address,
      customerType:   customerType   ?? this.customerType,
      creditLimit:    creditLimit    ?? this.creditLimit,
      isActive:       isActive       ?? this.isActive,
      notes:          notes          ?? this.notes,
      createdAt:      createdAt,
      updatedAt:      DateTime.now(),
      deletedAt:      deletedAt,
      currentBalance:  currentBalance  ?? this.currentBalance,
      availableCredit: availableCredit ?? this.availableCredit,
      totalSales:      totalSales      ?? this.totalSales,
      totalSaleAmount: totalSaleAmount ?? this.totalSaleAmount,
    );
  }
}