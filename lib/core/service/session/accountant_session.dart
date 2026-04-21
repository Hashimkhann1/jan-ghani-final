import 'package:shared_preferences/shared_preferences.dart';

class AccountantSession {
  // ── Keys ────────────────────────────────────────────────────────────────────
  static const _kId        = 'acc_id';
  static const _kName      = 'acc_name';
  static const _kUsername  = 'acc_username';
  static const _kPhone     = 'acc_phone';
  static const _kIsActive  = 'acc_is_active';
  static const _kCreatedAt = 'acc_created_at';

  // ── Save ────────────────────────────────────────────────────────────────────
  static Future<void> save({
    required String id,
    required String name,
    required String username,
    String? phone,
    required bool isActive,
    required String createdAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kId,        id);
    await prefs.setString(_kName,      name);
    await prefs.setString(_kUsername,  username);
    await prefs.setString(_kPhone,     phone ?? '');
    await prefs.setBool  (_kIsActive,  isActive);
    await prefs.setString(_kCreatedAt, createdAt);
  }

  // ── Getters ─────────────────────────────────────────────────────────────────
  static Future<String?> getId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kId);
    return (id == null || id.isEmpty) ? null : id;
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kName);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUsername);
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString(_kPhone);
    return (p == null || p.isEmpty) ? null : p;
  }

  // ── Get All ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kId);
    if (id == null || id.isEmpty) return null;

    return {
      'id'        : id,
      'name'      : prefs.getString(_kName)      ?? '',
      'username'  : prefs.getString(_kUsername)  ?? '',
      'phone'     : prefs.getString(_kPhone)      ?? '',
      'is_active' : prefs.getBool(_kIsActive)     ?? true,
      'created_at': prefs.getString(_kCreatedAt)  ?? '',
    };
  }

  // ── Login Check ─────────────────────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final id = await getId();
    return id != null;
  }

  // ── Clear (Logout) ──────────────────────────────────────────────────────────
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kName);
    await prefs.remove(_kUsername);
    await prefs.remove(_kPhone);
    await prefs.remove(_kIsActive);
    await prefs.remove(_kCreatedAt);
  }
}