class StoreModel {
  final String storeId;
  final String storeCode;
  final String storeName;
  final String? storeAddress;
  final String? storePhone;
  final bool isActive;
  final DateTime createdAt;

  StoreModel({
    required this.storeId,
    required this.storeCode,
    required this.storeName,
    this.storeAddress,
    this.storePhone,
    required this.isActive,
    required this.createdAt,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    return StoreModel(
      storeId: map['id'] as String,
      storeCode: map['code'] as String,
      storeName: map['name'] as String,
      storeAddress: map['address'] as String?,
      storePhone: map['phone'] as String?,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}