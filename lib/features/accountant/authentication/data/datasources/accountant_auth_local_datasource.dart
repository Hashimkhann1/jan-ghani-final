import 'package:shared_preferences/shared_preferences.dart';

abstract class AccountantAuthLocalDatasource {
  Future<void> saveUser(Map<String, dynamic> map);
  Future<Map<String, dynamic>?> getUser();
  Future<void> clearUser();
}

class AccountantAuthLocalDatasourceImpl
    implements AccountantAuthLocalDatasource {

  static const _kId            = 'acc_id';
  static const _kFullName      = 'acc_full_name';
  static const _kEmail         = 'acc_email';
  static const _kRole          = 'acc_role';
  static const _kBranchId      = 'acc_branch_id';
  static const _kWarehouseId   = 'acc_warehouse_id';
  static const _kCustomerToken = 'acc_customer_token';
  static const _kIsActive      = 'acc_is_active';
  static const _kCreatedAt     = 'acc_created_at';

  @override
  Future<void> saveUser(Map<String, dynamic> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kId,       map['id']);
    await prefs.setString(_kFullName, map['full_name']);
    await prefs.setString(_kEmail,    map['email']);
    await prefs.setString(_kRole,     map['role']);
    await prefs.setBool  (_kIsActive, map['is_active'] ?? true);
    await prefs.setString(_kCreatedAt,map['created_at']);

    if (map['branch_id'] != null)
      await prefs.setString(_kBranchId, map['branch_id']);
    if (map['warehouse_id'] != null)
      await prefs.setString(_kWarehouseId, map['warehouse_id']);
    if (map['customer_token'] != null)
      await prefs.setString(_kCustomerToken, map['customer_token']);
  }

  @override
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kId);
    if (id == null) return null;

    return {
      'id'             : id,
      'full_name'      : prefs.getString(_kFullName) ?? '',
      'email'          : prefs.getString(_kEmail) ?? '',
      'role'           : prefs.getString(_kRole) ?? '',
      'branch_id'      : prefs.getString(_kBranchId),
      'warehouse_id'   : prefs.getString(_kWarehouseId),
      'customer_token' : prefs.getString(_kCustomerToken),
      'is_active'      : prefs.getBool(_kIsActive) ?? true,
      'created_at'     : prefs.getString(_kCreatedAt) ?? DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kFullName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kRole);
    await prefs.remove(_kBranchId);
    await prefs.remove(_kWarehouseId);
    await prefs.remove(_kCustomerToken);
    await prefs.remove(_kIsActive);
    await prefs.remove(_kCreatedAt);
  }
}