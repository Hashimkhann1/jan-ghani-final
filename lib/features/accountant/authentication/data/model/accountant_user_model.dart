import '../../domain/entities/accountant_user_entity.dart';

class AccountantUserModel extends AccountantUserEntity {
  const AccountantUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.role,
    super.branchId,
    super.warehouseId,
    super.customerToken,
    super.installmentId,
    required super.isActive,
    required super.createdAt,
  });

  factory AccountantUserModel.fromMap(Map<String, dynamic> map) {
    return AccountantUserModel(
      id            : map['id'] as String,
      fullName      : map['full_name'] as String,
      email         : map['email'] as String,
      role          : (map['role'] as String?) ?? '', // '' = account abhi branch se connect nahi
      branchId      : map['branch_id'] as String?,
      warehouseId   : map['warehouse_id'] as String?,
      customerToken : map['customer_token'] as String?,
      installmentId : map['installment_id'] as String?,
      isActive      : map['is_active'] as bool? ?? true,
      createdAt     : DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id'             : id,
    'full_name'      : fullName,
    'email'          : email,
    'role'           : role,
    'branch_id'      : branchId,
    'warehouse_id'   : warehouseId,
    'customer_token' : customerToken,
    'installment_id' : installmentId,
    'is_active'      : isActive,
    'created_at'     : createdAt.toIso8601String(),
  };
}