// =============================================================
// auth_local_storage.dart
// SharedPreferences mein logged in user save karo
// =============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalStorage {
  static const String _keyUser      = 'logged_in_user';
  static const String _keyIsLogged  = 'is_logged_in';

  // ── User save karo (login ke baad) ───────────────────────
  static Future<void> saveUser(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(userMap));
    await prefs.setBool(_keyIsLogged, true);
  }

  // ── User load karo (app start pe) ────────────────────────
  static Future<Map<String, dynamic>?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool(_keyIsLogged) ?? false;
    if (!isLogged) return null;

    final userJson = prefs.getString(_keyUser);
    if (userJson == null) return null;

    return jsonDecode(userJson) as Map<String, dynamic>;
  }

  // ── Clear karo (logout ke baad) ───────────────────────────
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyIsLogged);
  }

  // ── Check karo ───────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLogged) ?? false;
  }
}
