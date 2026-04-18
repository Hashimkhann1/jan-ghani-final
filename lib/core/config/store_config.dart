import 'dart:convert';
import 'package:flutter/services.dart';

class StoreConfig {
  static late Map<String, dynamic> _config;

  static Future<void> load() async {
    final String content = await rootBundle.loadString('assets/json/branch_config.json');
    _config = jsonDecode(content);
  }

  static String get storeId      => _config['store_id'];
  static String get storeCode    => _config['store_code'];
  static String get storeName    => _config['store_name'];
  static String get storeAddress => _config['store_address'];
  static String get storePhone   => _config['store_phone'];

  static String get dbHost     => _config['db_host'];
  static int    get dbPort     => _config['db_port'] ?? 5432;
  static String get dbName     => _config['db_name'];
  static String get dbUser     => _config['db_user'];
  static String get dbPassword => _config['db_password'];

  // ─── Server ───────────────────────────────────────────────
  static int    get serverPort    => _config['server_port'] ?? 8080;
  static String get serverBaseUrl => 'http://localhost:$serverPort';
}