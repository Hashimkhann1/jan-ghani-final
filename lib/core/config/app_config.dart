import 'dart:convert';
import 'package:flutter/services.dart';

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
  static String get dbHost       => _config['db_host'];
  static int    get dbPort       => _config['db_port'];
  static String get dbName       => _config['db_name'];
  static String get dbUser       => _config['db_user'];
  static String get dbPassword   => _config['db_password'];

  static bool get isWarehouse => appMode == 'warehouse';
  static bool get isStore     => appMode == 'store';
}