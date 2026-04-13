// =============================================================
// password_helper.dart
// Password ko SHA-256 hash karo
// =============================================================

import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHelper {
  /// Plain text password → SHA-256 hash
  static String hash(String password) {
    final bytes  = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify — plain text vs stored hash
  static bool verify(String plainPassword, String storedHash) {
    return hash(plainPassword) == storedHash;
  }
}
