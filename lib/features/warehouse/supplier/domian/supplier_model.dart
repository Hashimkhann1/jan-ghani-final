// =============================================================
// supplier_model.dart
// =============================================================

class SupplierModel {
  // ── suppliers table columns ──────────────────────────────
  final String  id;
  final String  warehouseId;
  final String  name;
  final String? companyName;
  final String? contactPerson;
  final String? email;
  final String  phone;
  final String? address;
  final String? code;
  final String? taxId;
  final int     paymentTerms;
  final bool    isActive;
  final String? notes;
  final String?   createdById;    // user UUID
  final String?   createdByName;  // user full_name (JOIN se)
  final DateTime  createdAt;
  final DateTime  updatedAt;
  final DateTime? deletedAt;

  // ── Balance ───────────────────────────────────────────────
  // trigger se auto update hota hai
  // = SUM(supplier_ledger.amount)
  // opening + purchases - payments - returns
  final double outstandingBalance;

  // ── purchase_orders aggregate ─────────────────────────────
  final int    totalOrders;
  final double totalPurchaseAmount;

  const SupplierModel({
    required this.id,
    required this.warehouseId,
    required this.name,
    this.companyName,
    this.contactPerson,
    this.email,
    required this.phone,
    this.address,
    this.code,
    this.taxId,
    required this.paymentTerms,
    required this.isActive,
    this.notes,
    this.createdById,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.outstandingBalance,
    required this.totalOrders,
    required this.totalPurchaseAmount,
  });

  // ── Balance helpers ───────────────────────────────────────

  bool get hasDue  => outstandingBalance > 0;
  bool get isClear => outstandingBalance == 0;

  String get balanceLabel {
    if (isClear) return 'Clear';
    if (hasDue)  return 'Rs ${outstandingBalance.toStringAsFixed(2)} Due';
    return 'Rs ${outstandingBalance.abs().toStringAsFixed(0)} Advance';
  }

  String get paymentTermsLabel => '$paymentTerms days';

  // ── fromMap ───────────────────────────────────────────────
  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id:                  map['id']?.toString()             ?? '',
      warehouseId:         map['warehouse_id']?.toString()   ?? '',
      name:                map['name']?.toString()           ?? '',
      companyName:         map['company_name']?.toString(),
      contactPerson:       map['contact_person']?.toString(),
      email:               map['email']?.toString(),
      phone:               map['phone']?.toString()          ?? '',
      address:             map['address']?.toString(),
      code:                map['code']?.toString(),
      taxId:               map['tax_id']?.toString(),
      paymentTerms:        _parseInt(map['payment_terms'])   ?? 30,
      isActive:            map['is_active'] == true ||
          map['is_active'] == 't',
      notes:               map['notes']?.toString(),
      createdById:         map['created_by']?.toString(),
      createdByName:       map['created_by_name']?.toString(),
      createdAt:           map['created_at'] is DateTime
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at'].toString()),
      updatedAt:           map['updated_at'] is DateTime
          ? map['updated_at'] as DateTime
          : DateTime.parse(map['updated_at'].toString()),
      deletedAt:           map['deleted_at'] == null ? null
          : map['deleted_at'] is DateTime
          ? map['deleted_at'] as DateTime
          : DateTime.parse(map['deleted_at'].toString()),
      outstandingBalance:  _parseDouble(map['outstanding_balance'])   ?? 0.0,
      totalOrders:         _parseInt(map['total_orders'])             ?? 0,
      totalPurchaseAmount: _parseDouble(map['total_purchase_amount']) ?? 0.0,
    );
  }

  // ── Safe parsers ──────────────────────────────────────────
  static double? _parseDouble(dynamic v) {
    if (v == null)   return null;
    if (v is double) return v;
    if (v is num)    return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int)  return v;
    if (v is num)  return v.toInt();
    return int.tryParse(v.toString());
  }

  // ── toMap ─────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id':             id,
      'warehouse_id':   warehouseId,
      'name':           name,
      'company_name':   companyName,
      'contact_person': contactPerson,
      'email':          email,
      'phone':          phone,
      'address':        address,
      'code':           code,
      'tax_id':         taxId,
      'payment_terms':  paymentTerms,
      'is_active':      isActive,
      'notes':          notes,
      // outstanding_balance nahi — trigger handle karta hai
    };
  }

  // ── copyWith ──────────────────────────────────────────────
  SupplierModel copyWith({
    String?   name,
    String?   companyName,
    String?   contactPerson,
    String?   email,
    String?   phone,
    String?   address,
    String?   code,
    String?   taxId,
    int?      paymentTerms,
    bool?     isActive,
    String?   notes,
    double?   outstandingBalance,
    int?      totalOrders,
    double?   totalPurchaseAmount,
    String?   createdById,
    String?   createdByName,
    DateTime? deletedAt,
  }) {
    return SupplierModel(
      id:                  id,
      warehouseId:         warehouseId,
      name:                name                ?? this.name,
      companyName:         companyName         ?? this.companyName,
      contactPerson:       contactPerson       ?? this.contactPerson,
      email:               email               ?? this.email,
      phone:               phone               ?? this.phone,
      address:             address             ?? this.address,
      code:                code                ?? this.code,
      taxId:               taxId               ?? this.taxId,
      paymentTerms:        paymentTerms        ?? this.paymentTerms,
      isActive:            isActive            ?? this.isActive,
      notes:               notes               ?? this.notes,
      createdById:         createdById         ?? this.createdById,
      createdByName:       createdByName       ?? this.createdByName,
      createdAt:           createdAt,
      updatedAt:           DateTime.now(),
      deletedAt:           deletedAt           ?? this.deletedAt,
      outstandingBalance:  outstandingBalance  ?? this.outstandingBalance,
      totalOrders:         totalOrders         ?? this.totalOrders,
      totalPurchaseAmount: totalPurchaseAmount ?? this.totalPurchaseAmount,
    );
  }
}