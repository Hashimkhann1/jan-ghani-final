import 'package:jan_ghani_final/core/config/store_config.dart';
import 'package:postgres/postgres.dart';

class DataBaseService {
  static Connection? _connection;

  static Future<Connection> getConnection() async {
    if (_connection != null) return _connection!;

    try {
      _connection = await Connection.open(
        Endpoint(
          host:     StoreConfig.dbHost,
          port:     StoreConfig.dbPort,
          database: StoreConfig.dbName,
          username: StoreConfig.dbUser,
          password: StoreConfig.dbPassword,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
          timeZone: 'Asia/Karachi', // ← UTC se change karo
        ),
      );
      print('✅ PostgreSQL connected!');
      return _connection!;
    } catch (e) {
      print('❌ Connection Error: $e');
      rethrow;
    }
  }

  static Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}