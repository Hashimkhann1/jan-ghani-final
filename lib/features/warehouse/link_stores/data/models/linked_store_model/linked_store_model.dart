class LinkedStoreModel {
  final String id;
  final String warehouseId;
  final String storeId;
  final String storeCode;
  final String storeName;
  final String? storeAddress;
  final String? storePhone;
  final String? managerName;
  final String? linkedByName;
  final String? linkedById;
  final bool isActive;
  final DateTime linkedAt;
  final DateTime? deletedAt;

  LinkedStoreModel({
    required this.id,
    required this.warehouseId,
    required this.storeId,
    required this.storeCode,
    required this.storeName,
    this.storeAddress,
    this.storePhone,
    this.managerName,
    this.linkedByName,
    this.linkedById,
    required this.isActive,
    required this.linkedAt,
    this.deletedAt,
  });

  factory LinkedStoreModel.fromMap(Map<String, dynamic> map) {
    return LinkedStoreModel(
      id: map['id'] as String,
      warehouseId: map['warehouse_id'] as String,
      storeId: map['store_id'] as String,
      storeCode: map['store_code'] as String? ?? '',
      storeName: map['store_name'] as String,
      storeAddress: map['store_address'] as String?,
      storePhone: map['store_phone'] as String?,
      managerName: map['manager_name'] as String?,
      linkedByName: map['linked_by_name'] as String?,
      linkedById: map['linked_by_id'] as String?,
      isActive: map['is_active'] as bool,
      linkedAt: map['linked_at'] is String
          ? DateTime.parse(map['linked_at'] as String)
          : map['linked_at'] as DateTime,
      deletedAt: map['deleted_at'] == null
          ? null
          : map['deleted_at'] is String
          ? DateTime.parse(map['deleted_at'] as String)
          : map['deleted_at'] as DateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'warehouse_id': warehouseId,
      'store_id': storeId,
      'store_code': storeCode,
      'store_name': storeName,
      'store_address': storeAddress,
      'store_phone': storePhone,
      'manager_name': managerName,
      'linked_by_name': linkedByName,
      'linked_by_id': linkedById,
      'is_active': isActive,
      'linked_at': linkedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}