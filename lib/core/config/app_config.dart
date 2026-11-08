// Updated on 2026-11-08 09:48 AM
import 'dart:convert';
import 'package:flutter/services.dart';

enum AppEnvironment { development, production }


class AppConfig {
  static late Map<String, dynamic> _config;

  // Ek baar load karo app start pe
  static Future<void> load() async {
    final String content = await rootBundle.loadString('assets/json/config.json');
    _config = jsonDecode(content);
  }

  // Getters
  static String get appMode      => _config['app_mode'];
  static String get warehouseId  => _config['warehouse_id'];
  static String get warehouseName=> _config['warehouse_name'];
  static String get warehouseCode=> _config['warehouse_code'];
  static String get dbHost       => _config['db_host'];
  static int    get dbPort       => _config['db_port'];
  static String get dbName       => _config['db_name'];
  static String get dbUser       => _config['db_user'];
  static String get dbPassword   => _config['db_password'];
  // Optional — warehouse Backup screen ke liye pg_dump(.exe) ka poora path.
  // Na ho to app khud dhoondti hai (Program Files\PostgreSQL\<ver>\bin ...).
  static String? get pgDumpPath  => _config['pg_dump_path'] as String?;

  static bool get isWarehouse => appMode == 'warehouse';
  static bool get isStore     => appMode == 'store';



  static const String _env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static AppEnvironment get environment =>
      _env == 'production' ? AppEnvironment.production : AppEnvironment.development;

  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isDevelopment => environment == AppEnvironment.development;

  // Supabase
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // App Name
  static String get appName => isProduction ? 'Jan Ghani' : 'Jan Ghani (Dev)';
}