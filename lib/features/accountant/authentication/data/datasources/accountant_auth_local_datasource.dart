import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences keys
const _kUserId = 'acc_user_id';
const _kUserName = 'acc_user_name';
const _kUsername = 'acc_username';
const _kUserPhone = 'acc_user_phone';
const _kUserIsActive = 'acc_user_is_active';
const _kUserCreated  = 'acc_user_created_at';

abstract class AccountantAuthLocalDatasource {
  Future<void> saveUser({
    required String id,
    required String name,
    required String username,
    String? phone,
    required bool isActive,
    required String createdAt,
  });

  Future<Map<String, dynamic>?> getUser();
  Future<void> clearUser();
}

class AccountantAuthLocalDatasourceImpl
    implements AccountantAuthLocalDatasource {
  @override
  Future<void> saveUser({
    required String id,
    required String name,
    required String username,
    String? phone,
    required bool isActive,
    required String createdAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, id);
    await prefs.setString(_kUserName, name);
    await prefs.setString(_kUsername, username);
    await prefs.setString(_kUserPhone, phone ?? '');
    await prefs.setBool(_kUserIsActive, isActive);
    await prefs.setString(_kUserCreated, createdAt);
  }

  @override
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kUserId);
    if (id == null || id.isEmpty) return null;

    return {
      'id': id,
      'name': prefs.getString(_kUserName) ?? '',
      'username': prefs.getString(_kUsername) ?? '',
      'phone': prefs.getString(_kUserPhone),
      'is_active': prefs.getBool(_kUserIsActive) ?? true,
      'created_at': prefs.getString(_kUserCreated) ?? '',
    };
  }

  @override
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserName);
    await prefs.remove(_kUsername);
    await prefs.remove(_kUserPhone);
    await prefs.remove(_kUserIsActive);
    await prefs.remove(_kUserCreated);
  }
}