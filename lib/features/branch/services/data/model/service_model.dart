// lib/features/branch/service/data/model/service_model.dart

// ── Service Master Model ───────────────────────────────────────
class ServiceModel {
  final String   id;
  final String   storeId;
  final String   name;
  final String   serviceType;
  final double   perAmount;
  final double   feeAmount;
  final bool     isActive;
  final String?  notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.serviceType,
    required this.perAmount,
    required this.feeAmount,
    required this.isActive,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Fee calculate: amount=5000, perAmount=1000, feeAmount=10 → 50
  double calculateFee(double amount) {
    if (perAmount <= 0) return 0;
    return (amount / perAmount) * feeAmount;
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) => ServiceModel(
    id:          map['id'].toString(),
    storeId:     map['store_id'].toString(),
    name:        map['name'].toString(),
    serviceType: map['service_type'].toString(),
    perAmount:   double.parse(map['per_amount'].toString()),
    feeAmount:   double.parse(map['fee_amount'].toString()),
    isActive:    map['is_active'] as bool? ?? true,
    notes:       map['notes'] as String?,
    createdAt:   DateTime.parse(map['created_at'].toString()),
    updatedAt:   DateTime.parse(map['updated_at'].toString()),
  );

  ServiceModel copyWith({
    String? name,
    String? serviceType,
    double? perAmount,
    double? feeAmount,
    bool?   isActive,
    String? notes,
  }) =>
      ServiceModel(
        id:          id,
        storeId:     storeId,
        name:        name        ?? this.name,
        serviceType: serviceType ?? this.serviceType,
        perAmount:   perAmount   ?? this.perAmount,
        feeAmount:   feeAmount   ?? this.feeAmount,
        isActive:    isActive    ?? this.isActive,
        notes:       notes       ?? this.notes,
        createdAt:   createdAt,
        updatedAt:   updatedAt,
      );
}

// ── Service Cart Item ──────────────────────────────────────────
class ServiceCartItem {
  final String       cartId;
  final ServiceModel service;
  final double       amount;
  final double       calculatedFee;
  final double       discount;       // ← NEW

  const ServiceCartItem({
    required this.cartId,
    required this.service,
    required this.amount,
    required this.calculatedFee,
    this.discount = 0,               // ← NEW
  });

  // total = amount + fee - discount
  double get total => (amount + calculatedFee - discount).clamp(0, double.infinity);

  ServiceCartItem copyWith({double? amount, double? discount}) {
    final newAmount   = amount   ?? this.amount;
    final newDiscount = discount ?? this.discount;
    return ServiceCartItem(
      cartId:        cartId,
      service:       service,
      amount:        newAmount,
      calculatedFee: service.calculateFee(newAmount),
      discount:      newDiscount,
    );
  }
}

// ── Service Payment Entry ──────────────────────────────────────
class ServicePaymentEntry {
  final String method; // 'cash' | 'credit'
  final double amount;
  const ServicePaymentEntry({required this.method, required this.amount});
}

// ── Cash Transfer Type ─────────────────────────────────────────
enum CashTransferType {
  cashToBank,   // branch cash gaya bank mein (customer ne bank se receive kiya)
  bankToCash,   // customer ne bank se bheja, branch ne cash diya
}

// ── Service Invoice State ──────────────────────────────────────
class ServiceInvoiceState {
  final String                invoiceNo;
  final DateTime              date;
  final String?               customerId;
  final String?               customerName;
  final double?               customerBalance;
  final List<ServiceCartItem> cartItems;
  final ServicePaymentEntry?  payment;
  final bool                  isSaving;
  final String?               errorMessage;
  final String?               successMessage;
  final String?               notes;

  const ServiceInvoiceState({
    required this.invoiceNo,
    required this.date,
    this.customerId,
    this.customerName,
    this.customerBalance,
    required this.cartItems,
    this.payment,
    this.isSaving      = false,
    this.errorMessage,
    this.successMessage,
    this.notes,
  });

  double get totalAmount   => cartItems.fold(0, (s, i) => s + i.amount);
  double get totalFee      => cartItems.fold(0, (s, i) => s + i.calculatedFee);
  double get totalDiscount => cartItems.fold(0, (s, i) => s + i.discount); // ← NEW
  double get grandTotal    => totalAmount + totalFee - totalDiscount;       // ← NEW

  bool get hasCustomer => customerId != null;
  bool get isCartEmpty => cartItems.isEmpty;

  ServiceInvoiceState copyWith({
    String?                invoiceNo,
    DateTime?              date,
    String?                customerId,
    String?                customerName,
    double?                customerBalance,
    bool                   clearCustomer  = false,
    List<ServiceCartItem>? cartItems,
    ServicePaymentEntry?   payment,
    bool                   clearPayment   = false,
    bool?                  isSaving,
    String?                errorMessage,
    bool                   clearError     = false,
    String?                successMessage,
    bool                   clearSuccess   = false,
    String?                notes,
    bool                   clearNotes     = false,
  }) =>
      ServiceInvoiceState(
        invoiceNo:       invoiceNo       ?? this.invoiceNo,
        date:            date            ?? this.date,
        customerId:      clearCustomer ? null : (customerId      ?? this.customerId),
        customerName:    clearCustomer ? null : (customerName    ?? this.customerName),
        customerBalance: clearCustomer ? null : (customerBalance ?? this.customerBalance),
        cartItems:       cartItems       ?? this.cartItems,
        payment:         clearPayment  ? null : (payment         ?? this.payment),
        isSaving:        isSaving        ?? this.isSaving,
        errorMessage:    clearError    ? null : errorMessage,
        successMessage:  clearSuccess  ? null : successMessage,
        notes:           clearNotes    ? null : (notes            ?? this.notes),
      );
}