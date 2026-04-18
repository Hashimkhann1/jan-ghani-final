import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'stock_transfer_sync_service.dart';

final stockTransferSyncServiceProvider = Provider<StockTransferSyncService>((ref) {
  final service = StockTransferSyncService(
    supabase: Supabase.instance.client,
    db: DatabaseService.connection,
  );

  // App start hote hi — missed transfers check + realtime start
  service.startListening(AppConfig.warehouseId);

  ref.onDispose(() => service.stopListening());

  return service;
});