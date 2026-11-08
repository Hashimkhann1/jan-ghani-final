import 'package:jan_ghani_final/core/config/store_config.dart';
import 'package:postgres/postgres.dart';

class DataBaseService {
  static Connection? _connection;
  static Future<Connection>? _opening;

  /// Last connection failure (for the "cannot connect" screen).
  static String? lastError;

  /// Human-readable target currently configured.
  static String get target =>
      '${StoreConfig.dbUser}@${StoreConfig.dbHost}:${StoreConfig.dbPort}/${StoreConfig.dbName}';

  static Future<Connection> getConnection() async {
    final existing = _connection;
    if (existing != null && existing.isOpen) return existing;

    // Stale/broken handle — drop it before reconnecting.
    if (existing != null && !existing.isOpen) {
      _connection = null;
    }

    // Coalesce concurrent callers onto a single open attempt.
    return _opening ??= _open();
  }

  static Future<Connection> _open() async {
    try {
      final conn = await Connection.open(
        Endpoint(
          host: StoreConfig.dbHost,
          port: StoreConfig.dbPort,
          database: StoreConfig.dbName,
          username: StoreConfig.dbUser,
          password: StoreConfig.dbPassword,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
          timeZone: 'Asia/Karachi',
          connectTimeout: Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 15));
      _connection = conn;
      lastError = null;
      print('PostgreSQL connected!');
      return conn;
    } catch (e) {
      lastError = e.toString();
      print('Connection Error ($target): $e');
      rethrow;
    } finally {
      _opening = null;
    }
  }

  static Future<void> close() async {
    await _connection?.close();
    _connection = null;
    _opening = null;
  }
}
