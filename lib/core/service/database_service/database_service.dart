import 'dart:async';

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:postgres/postgres.dart';

class DatabaseService {
  static Connection? _connection;

  // FIX 1: Race condition fix
  // Pehle: Future.wait se 3 parallel calls aati thi, teeno null
  // dekhti thi aur teeno connect karne lagti thi = 3x "DB connected!"
  // Ab: Completer lagaya — pehli call connect karti hai, baaki wait karti hain
  static Completer<Connection>? _completer;

  // FIX 2: Test ke liye block flag
  // Sirf test files mein use hoga — production code pe koi effect nahi
  static bool _blockedForTest = false;

  // Connect karo — ORIGINAL CODE SAME, sirf Completer wrap kiya
  static Future<Connection> getConnection() async {
    // Sirf test environment mein true hoga
    if (_blockedForTest) {
      throw Exception('DatabaseService: test environment mein real DB blocked hai');
    }

    // Already connected — ORIGINAL CHECK SAME
    if (_connection != null) return _connection!;

    // FIX 1: Agar connection chal rahi hai toh uska wait karo
    if (_completer != null) return _completer!.future;

    _completer = Completer<Connection>();

    try {
      // ORIGINAL CONNECTION CODE — BILKUL SAME
      _connection = await Connection.open(
        Endpoint(
          host:     AppConfig.dbHost,
          port:     AppConfig.dbPort,
          database: AppConfig.dbName,
          username: AppConfig.dbUser,
          password: AppConfig.dbPassword,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
        ),
      );

      _completer!.complete(_connection!);
      _completer = null;

      // ORIGINAL PRINT — SAME, ab sirf 1 baar aayega
      print('✅ Database connected!');
      return _connection!;
    } catch (e) {
      final c = _completer!;
      _completer = null;
      c.completeError(e);
      rethrow;
    }
  }

  // Connection band karo — ORIGINAL SAME
  static Future<void> close() async {
    await _connection?.close();
    _connection = null;
    _completer = null; // FIX: completer bhi reset karo
  }

  // ORIGINAL GETTER — SAME
  static Connection get connection {
    if (_connection == null) throw Exception('Database not connected!');
    return _connection!;
  }

  // ── Sirf test files ke liye ───────────────────────────────
  // Production code in methods ko kabhi call nahi karta
  static void blockConnectionForTest() {
    _blockedForTest = true;
    _connection = null;
    _completer = null;
  }

  static void resetForTest() {
    _connection = null;
    _completer = null;
    _blockedForTest = false;
  }
}


// import 'package:jan_ghani_final/core/config/app_config.dart';
// import 'package:postgres/postgres.dart';
//
// class DatabaseService {
//   static Connection? _connection;
//
//   // Connect karo
//   static Future<Connection> getConnection() async {
//     if (_connection != null) return _connection!;
//
//     _connection = await Connection.open(
//       Endpoint(
//         host:     AppConfig.dbHost,
//         port:     AppConfig.dbPort,
//         database: AppConfig.dbName,
//         username: AppConfig.dbUser,
//         password: AppConfig.dbPassword,
//       ),
//       settings: const ConnectionSettings(
//         sslMode: SslMode.disable,
//       ),
//     );
//
//     print('✅ Database connected!');
//     return _connection!;
//   }
//
//   // Connection band karo
//   static Future<void> close() async {
//     await _connection?.close();
//     _connection = null;
//   }
//
//   static Connection get connection {
//     if (_connection == null) throw Exception('Database not connected!');
//     return _connection!;
//   }
// }