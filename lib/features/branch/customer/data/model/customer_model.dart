class CustomerModel {
  final String   id;
  final String   storeId;
  final String   code;
  final String   name;
  final String   phone;
  final String?  address;
  final String   customerType;  // walkin | credit | wholesale
  final double   creditLimit;
  final double   balance;       // DB column — positive = customer ne dena hai
  final bool     isActive;
  final String?  notes;
  final DateTime  createdAt;
  final DateTime  updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;

  const CustomerModel({
    required this.id,
    required this.storeId,
    required this.code,
    required this.name,
    required this.phone,
    this.address,
    required this.customerType,
    required this.creditLimit,
    required this.balance,
    required this.isActive,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncedAt,
  });

  // ── Getters ───────────────────────────────────────────────
  bool get hasBalance  => balance > 0;
  bool get isAdvance   => balance < 0;
  bool get isClear     => balance == 0;
  bool get isWalkin    => customerType == 'walkin';
  bool get isCredit    => customerType == 'credit';
  bool get isWholesale => customerType == 'wholesale';

  double get availableCredit => creditLimit - balance;

  bool get isOverLimit =>
      isCredit && creditLimit > 0 && balance > creditLimit;

  String get balanceLabel {
    if (isClear)    return 'Clear';
    if (hasBalance) return 'Rs ${balance.toStringAsFixed(0)} Due';
    return 'Rs ${balance.abs().toStringAsFixed(0)} Advance';
  }

  String get creditLimitLabel =>
      creditLimit > 0 ? 'Rs ${creditLimit.toStringAsFixed(0)}' : '—';

  String get availableCreditLabel =>
      'Rs ${availableCredit.toStringAsFixed(0)}';

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
      id:           _str(map['id'])            ?? '',
      storeId:      _str(map['store_id'])      ?? '',
      code:         _str(map['code'])           ?? '',
      name:         _str(map['name'])           ?? '',
      phone:        _str(map['phone'])          ?? '',
      address:      _str(map['address']),
      customerType: _str(map['customer_type']) ?? 'walkin',
      creditLimit:  _dbl(map['credit_limit'])  ?? 0.0,
      balance:      _dbl(map['balance'])        ?? 0.0,
      isActive:     map['is_active'] as bool?  ?? true,
      notes:        _str(map['notes']),
      createdAt:    _date(map['created_at'])   ?? DateTime.now(),
      updatedAt:    _date(map['updated_at'])   ?? DateTime.now(),
      deletedAt:    _date(map['deleted_at']),
      syncedAt:     _date(map['synced_at']),
    );
  }

  // ── toMap (sirf editable DB columns) ─────────────────────
  Map<String, dynamic> toMap() {
    return {
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
    String?   code,
    String?   name,
    String?   phone,
    String?   address,
    String?   customerType,
    double?   creditLimit,
    double?   balance,
    bool?     isActive,
    String?   notes,
    DateTime? updatedAt,
    DateTime? syncedAt,
  }) {
    return CustomerModel(
      id:           id,
      storeId:      storeId,
      code:         code          ?? this.code,
      name:         name          ?? this.name,
      phone:        phone         ?? this.phone,
      address:      address       ?? this.address,
      customerType: customerType  ?? this.customerType,
      creditLimit:  creditLimit   ?? this.creditLimit,
      balance:      balance       ?? this.balance,
      isActive:     isActive      ?? this.isActive,
      notes:        notes         ?? this.notes,
      createdAt:    createdAt,
      updatedAt:    updatedAt     ?? DateTime.now(),
      deletedAt:    deletedAt,
      syncedAt:     syncedAt      ?? this.syncedAt,
    );
  }

  // ── Parse helpers ─────────────────────────────────────────
  static String? _str(dynamic v) => v?.toString();

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _date(dynamic v) {
    if (v == null)     return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  // ── Equality ──────────────────────────────────────────────
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CustomerModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CustomerModel(id: $id, code: $code, name: $name, balance: $balance)';
}