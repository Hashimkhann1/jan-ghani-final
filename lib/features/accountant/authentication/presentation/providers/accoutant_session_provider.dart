import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/accountant_user_entity.dart';

class SessionNotifier extends StateNotifier<AccountantUserEntity?> {
  SessionNotifier() : super(null) {
    _restoreSession();
  }

  static const _kId            = 'session_id';
  static const _kFullName      = 'session_full_name';
  static const _kEmail         = 'session_email';
  static const _kRole          = 'session_role';
  static const _kBranchId      = 'session_branch_id';
  static const _kWarehouseId   = 'session_warehouse_id';
  static const _kCustomerToken = 'session_customer_token';
  static const _kIsActive      = 'session_is_active';
  static const _kCreatedAt     = 'session_created_at';

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kId);
    if (id == null || id.isEmpty) return;

    state = AccountantUserEntity(
      id:            id,
      fullName:      prefs.getString(_kFullName)      ?? '',
      email:         prefs.getString(_kEmail)         ?? '',
      role:          prefs.getString(_kRole)          ?? '',
      branchId:      prefs.getString(_kBranchId),
      warehouseId:   prefs.getString(_kWarehouseId),
      customerToken: prefs.getString(_kCustomerToken),
      isActive:      prefs.getBool(_kIsActive)        ?? true,
      createdAt:     DateTime.tryParse(
          prefs.getString(_kCreatedAt) ?? '') ??
          DateTime.now(),
    );
  }

  Future<void> setUser(AccountantUserEntity user) async {
    state = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kId,            user.id);
    await prefs.setString(_kFullName,      user.fullName);
    await prefs.setString(_kEmail,         user.email);
    await prefs.setString(_kRole,          user.role);
    await prefs.setString(_kBranchId,      user.branchId      ?? '');
    await prefs.setString(_kWarehouseId,   user.warehouseId   ?? '');
    await prefs.setString(_kCustomerToken, user.customerToken ?? '');
    await prefs.setBool(  _kIsActive,      user.isActive);
    await prefs.setString(_kCreatedAt,     user.createdAt.toIso8601String());
  }

  Future<void> clear() async {
    state = null;
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

  String? get role          => state?.role;
  String? get branchId      => state?.branchId;
  bool    get isLoggedIn    => state != null;
}

final sessionProvider =
StateNotifierProvider<SessionNotifier, AccountantUserEntity?>(
      (ref) => SessionNotifier(),
);

final currentRoleProvider = Provider<String?>(
      (ref) => ref.watch(sessionProvider)?.role,
);

final currentBranchIdProvider = Provider<String?>(
      (ref) => ref.watch(sessionProvider)?.branchId,
);

final isLoggedInProvider = Provider<bool>(
      (ref) => ref.watch(sessionProvider) != null,
);