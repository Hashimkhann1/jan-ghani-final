import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:postgres/postgres.dart';

class DatabaseService {
  static Connection? _connection;

  // Connect karo
  static Future<Connection> getConnection() async {
    if (_connection != null) return _connection!;

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

    print('✅ Database connected!');
    return _connection!;
  }

  // Connection band karo
  static Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}