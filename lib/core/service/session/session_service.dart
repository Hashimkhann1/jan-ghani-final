import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyUserId     = 'user_id';
  static const _keyStoreId    = 'store_id';
  static const _keyRole       = 'user_role';
  static const _keyCounterId  = 'counter_id';
  static const _keyUsername   = 'username';
  static const _keyFullName   = 'full_name';
  static const _keyIsLoggedIn = 'is_logged_in';

  // ── SAVE ─────────────────────────────────────────────────
  static Future<void> saveSession({
    required String  userId,
    required String  storeId,
    required String  role,
    required String  username,
    required String  fullName,
    String?          counterId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId,     userId);
    await prefs.setString(_keyStoreId,    storeId);
    await prefs.setString(_keyRole,       role);
    await prefs.setString(_keyUsername,   username);
    await prefs.setString(_keyFullName,   fullName);
    await prefs.setBool  (_keyIsLoggedIn, true);

    if (counterId != null) {
      await prefs.setString(_keyCounterId, counterId);
    } else {
      await prefs.remove(_keyCounterId);
    }
  }

  // ── GET ───────────────────────────────────────────────────
  static Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'user_id':    prefs.getString(_keyUserId),
      'store_id':   prefs.getString(_keyStoreId),
      'role':       prefs.getString(_keyRole),
      'username':   prefs.getString(_keyUsername),
      'full_name':  prefs.getString(_keyFullName),
      'counter_id': prefs.getString(_keyCounterId),
    };
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<String?> getStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStoreId);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  static Future<String?> getCounterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCounterId);
  }

  // ── CLEAR (Logout) ────────────────────────────────────────
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}