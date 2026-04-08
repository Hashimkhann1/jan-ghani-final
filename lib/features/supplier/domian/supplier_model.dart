// =============================================================
// supplier_model.dart
// Supplier ka data model — warehouse_schema_v2.sql ke
// suppliers table + v_supplier_balances view se map kiya hua
// =============================================================

class SupplierModel {
  // ── suppliers table columns ──────────────────────────────
  final String id;            // UUID PRIMARY KEY
  final String tenantId;      // tenant isolation ke liye
  final String name;          // supplier ka naam (required)
  final String? companyName;   // company / business ka naam
  final String? contactPerson;// contact person ka naam
  final String? email;        // email address
  final String phone;         // phone number (required)
  final String? address;      // physical address
  final String? code;         // auto-generated: 'SUPP-0001' (schema: code TEXT)
  final String? taxId;        // NTN / tax number
  final int paymentTerms;     // credit days (default: 30)
  final bool isActive;        // active/inactive status
  final String? notes;        // extra notes
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;  // soft delete

  // ── v_supplier_balances view columns ─────────────────────
  // FIX 2: balance ab directly suppliers table mein nahi hai
  // supplier_ledger se compute hota hai — view se aata hai
  final double outstandingBalance; // positive = hum ne dena hai

  // ── purchase_orders se aggregate (UI ke liye) ─────────────
  final int totalOrders;          // total PO count
  final double totalPurchaseAmount; // sab POs ka total_amount sum

  const SupplierModel({
    required this.id,
    required this.tenantId,
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
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.outstandingBalance,
    required this.totalOrders,
    required this.totalPurchaseAmount,
  });

  // ── Balance helpers ───────────────────────────────────────

  /// Hum ne supplier ko dena hai
  bool get hasDue => outstandingBalance > 0;

  /// Account bilkul clear hai
  bool get isClear => outstandingBalance == 0;

  /// Balance display text
  String get balanceLabel {
    if (isClear) return 'Clear';
    if (hasDue) return 'Rs ${outstandingBalance.toStringAsFixed(0)} Due';
    return 'Rs ${outstandingBalance.abs().toStringAsFixed(0)} Advance';
  }

  /// Credit days display
  String get paymentTermsLabel => '$paymentTerms days';

  // ── fromMap (Drift / DB se data aane per) ─────────────────
  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id:                   map['id']             as String,
      tenantId:             map['tenant_id']      as String,
      name:                 map['name']           as String,
      companyName:          map['company_name']   as String?,
      contactPerson:        map['contact_person'] as String?,
      email:                map['email']          as String?,
      phone:                map['phone']          as String,
      address:              map['address']        as String?,
      code:                 map['code']           as String?,
      taxId:                map['tax_id']         as String?,
      paymentTerms:         map['payment_terms']  as int? ?? 30,
      isActive:             map['is_active']      as bool? ?? true,
      notes:                map['notes']          as String?,
      createdAt:            DateTime.parse(map['created_at'] as String),
      updatedAt:            DateTime.parse(map['updated_at'] as String),
      deletedAt:            map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      outstandingBalance:   (map['outstanding_balance'] as num?)?.toDouble() ?? 0.0,
      totalOrders:          map['total_orders']   as int? ?? 0,
      totalPurchaseAmount:  (map['total_purchase_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ── toMap (DB mein save karne ke liye) ────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id':             id,
      'tenant_id':      tenantId,
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
    };
  }

  // ── copyWith (state update ke liye) ───────────────────────
  SupplierModel copyWith({
    String?  name,
    String?  companyName,
    String?  contactPerson,
    String?  email,
    String?  phone,
    String?  address,
    String?  code,
    String?  taxId,
    int?     paymentTerms,
    bool?    isActive,
    String?  notes,
    double?  outstandingBalance,
    int?     totalOrders,
    double?  totalPurchaseAmount,
  }) {
    return SupplierModel(
      id:                   id,
      tenantId:             tenantId,
      name:                 name              ?? this.name,
      companyName:          companyName       ?? this.companyName,
      contactPerson:        contactPerson     ?? this.contactPerson,
      email:                email             ?? this.email,
      phone:                phone             ?? this.phone,
      address:              address           ?? this.address,
      code:                 code              ?? this.code,
      taxId:                taxId             ?? this.taxId,
      paymentTerms:         paymentTerms      ?? this.paymentTerms,
      isActive:             isActive          ?? this.isActive,
      notes:                notes             ?? this.notes,
      createdAt:            createdAt,
      updatedAt:            DateTime.now(),
      deletedAt:            deletedAt,
      outstandingBalance:   outstandingBalance ?? this.outstandingBalance,
      totalOrders:          totalOrders        ?? this.totalOrders,
      totalPurchaseAmount:  totalPurchaseAmount ?? this.totalPurchaseAmount,
    );
  }
}