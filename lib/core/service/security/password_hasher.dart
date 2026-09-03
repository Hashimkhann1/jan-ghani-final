import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Central place for turning a plaintext password into the value we store in
/// `branch_users.password_hash` and for verifying a login attempt against it.
///
/// The username is mixed into the digest so two users with the same password
/// get different hashes (per-user salt without needing an extra column).
class PasswordHasher {
  PasswordHasher._();

  // App level pepper. Not a secret store, but keeps a raw DB dump from being
  // trivially reversible with a plain rainbow table.
  static const String _pepper = 'jan_ghani::branch_users::v1';

  /// SHA-256 hex digest of `username:pepper:password`.
  static String hash(String username, String password) {
    final salt = username.trim().toLowerCase();
    final bytes = utf8.encode('$salt::$_pepper::$password');
    return sha256.convert(bytes).toString();
  }

  /// True if [stored] is shaped like one of our SHA-256 hex digests.
  /// Used to tell a hashed value apart from a legacy plaintext password.
  static bool looksHashed(String stored) {
    if (stored.length != 64) return false;
    return RegExp(r'^[0-9a-f]{64}$').hasMatch(stored);
  }

  /// Verify [password] for [username] against the [stored] column value.
  /// Accepts both the new hash and a legacy plaintext value so existing
  /// accounts keep working until they are re-hashed.
  static bool verify({
    required String username,
    required String password,
    required String stored,
  }) {
    if (stored.isEmpty) return false;
    if (looksHashed(stored)) {
      return stored == hash(username, password);
    }
    // Legacy plaintext row.
    return stored == password;
  }
}
