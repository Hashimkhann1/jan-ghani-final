import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockTransferSyncService {
  final SupabaseClient _supabase;
  final Connection _db;
  RealtimeChannel? _channel;

  String? _activeWarehouseId;
  Timer? _reconnectTimer;
  bool _isListening = false;
  bool _isReconnecting = false; // 🔑 NEW: reconnect loop rokne ke liye

  StockTransferSyncService({
    required SupabaseClient supabase,
    required Connection db,
  })  : _supabase = supabase,
        _db = db;

  /// App start hone par yeh call karo
  Future<void> startListening(String warehouseId) async {
    _activeWarehouseId = warehouseId;
    print('[SyncService] ✅ Starting for warehouseId: $warehouseId');

    // Step 1: Missed transfers sync karo
    await _syncMissedTransfers(warehouseId);

    // Step 2: Realtime listen shuru karo
    _startRealtimeListener(warehouseId);
  }

  /// Realtime listener — auto reconnect ke saath
  void _startRealtimeListener(String warehouseId) {
    // 🔑 Reconnecting flag set karo PEHLE unsubscribe se
    _isReconnecting = true;

    // Pehle purana channel band karo
    _channel?.unsubscribe();
    _channel = null;
    _isListening = false;

    // 🔑 Thoda delay do taake purana channel ka 'closed' event aa sake
    // aur hum usse ignore kar sakein
    Future.delayed(const Duration(milliseconds: 200), () {
      _isReconnecting = false; // Ab naya channel accept karega events
    });

    print('[SyncService] 📡 Connecting realtime...');

    _channel = _supabase
        .channel('stock_transfers_sync_$warehouseId')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'stock_transfers',
      callback: (payload) async {
        print('[SyncService] 🔔 Realtime change received!');

        final newRow     = payload.newRecord;
        final newStatus  = newRow['status']  as String?;
        final transferId = newRow['id']      as String?;

        print('[SyncService] transferId: $transferId | status: $newStatus');

        if (transferId == null || newStatus == null) return;

        if (newStatus == 'accepted') {
          print('[SyncService] 🚀 Accepted! Syncing...');
          await _syncAcceptedTransfer(
            transferId: transferId,
            newStatus: newStatus,
          );
        }
      },
    )
        .subscribe((status, [error]) {
      print('[SyncService] 📡 Subscription: $status');
      if (error != null) print('[SyncService] ❌ Error: $error');

      if (status == RealtimeSubscribeStatus.subscribed) {
        _isListening = true;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        print('[SyncService] ✅ Realtime connected!');
      }

      // 🔑 KEY FIX: Sirf tab reconnect karo jab hum khud reconnect nahi kar rahe
      if (!_isReconnecting &&
          (status == RealtimeSubscribeStatus.timedOut ||
              status == RealtimeSubscribeStatus.closed)) {
        _isListening = false;
        _scheduleReconnect();
      }
    });
  }

  /// 5 second baad reconnect karo
  void _scheduleReconnect() {
    // Agar already timer chal raha hai to naya mat banao
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;
    if (_activeWarehouseId == null) return;

    print('[SyncService] 🔄 Reconnecting in 5 seconds...');

    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_activeWarehouseId != null) {
        print('[SyncService] 🔄 Attempting reconnect...');
        _startRealtimeListener(_activeWarehouseId!);
      }
    });
  }

  /// Missed transfers check
  Future<void> _syncMissedTransfers(String warehouseId) async {
    try {
      print('[SyncService] 🔍 Checking missed transfers...');

      final localResult = await _db.execute(
        Sql.named('''
          SELECT id FROM public.stock_transfers
          WHERE warehouse_id = @warehouseId
          AND status = 'pending'
        '''),
        parameters: {'warehouseId': warehouseId},
      );

      if (localResult.isEmpty) {
        print('[SyncService] ✅ No pending transfers locally, nothing to check.');
        return;
      }

      final localPendingIds = localResult
          .map((row) => row.toColumnMap()['id'] as String)
          .toList();

      print('[SyncService] 📋 Local pending: ${localPendingIds.length} transfers');

      final supabaseResult = await _supabase
          .from('stock_transfers')
          .select('id, status')
          .eq('warehouse_id', warehouseId)
          .eq('status', 'accepted')
          .inFilter('id', localPendingIds);

      if (supabaseResult.isEmpty) {
        print('[SyncService] ✅ No missed accepted transfers found.');
        return;
      }

      print('[SyncService] 🚀 Found ${supabaseResult.length} missed transfers! Syncing...');

      for (final transfer in supabaseResult) {
        final transferId = transfer['id'] as String;
        print('[SyncService] Syncing missed transfer: $transferId');
        await _syncAcceptedTransfer(
          transferId: transferId,
          newStatus: 'accepted',
        );
      }

      print('[SyncService] 🎉 All missed transfers synced!');
    } catch (e, stack) {
      print('[SyncService] ❌ Error checking missed transfers: $e');
      print('[SyncService] Stack: $stack');
    }
  }

  Future<void> _syncAcceptedTransfer({
    required String transferId,
    required String newStatus,
  }) async {
    try {
      // Double sync se bachao
      final checkResult = await _db.execute(
        Sql.named('''
          SELECT status FROM public.stock_transfers
          WHERE id = @transferId
        '''),
        parameters: {'transferId': transferId},
      );

      if (checkResult.isNotEmpty) {
        final currentStatus =
        checkResult.first.toColumnMap()['status'] as String?;
        if (currentStatus == 'accepted') {
          print('[SyncService] ⏭️ Transfer $transferId already accepted locally, skipping.');
          return;
        }
      }

      print('[SyncService] Step1: updating local status...');
      await _db.execute(
        Sql.named('''
          UPDATE public.stock_transfers
          SET status = @status, updated_at = NOW()
          WHERE id = @transferId
        '''),
        parameters: {'status': newStatus, 'transferId': transferId},
      );
      print('[SyncService] ✅ Step1 done');

      print('[SyncService] Step2: deducting inventory...');
      await _db.execute(
        Sql.named('''
          UPDATE public.warehouse_inventory
          SET quantity = quantity - sti.quantity_sent,
              last_movement_at = NOW(),
              updated_at = NOW()
          FROM public.stock_transfer_items sti
          JOIN public.stock_transfers st ON st.id = sti.transfer_id
          WHERE sti.transfer_id = @transferId
            AND warehouse_inventory.product_id = sti.product_id
            AND warehouse_inventory.warehouse_id = st.warehouse_id
        '''),
        parameters: {'transferId': transferId},
      );
      print('[SyncService] ✅ Step2 done');

      print('[SyncService] Step3: inserting stock movements...');
      await _db.execute(
        Sql.named('''
          INSERT INTO public.warehouse_stock_movements (
            id, warehouse_id, product_id, location_id,
            movement_type, quantity, unit_cost,
            reference_type, reference_id, notes, created_by
          )
          SELECT
            public.uuid_generate_v4(),
            st.warehouse_id, sti.product_id, NULL,
            'transfer_out', sti.quantity_sent, sti.purchase_price,
            'transfer', st.id,
            'Transfer ' || st.transfer_number || ' - ' || st.to_store_name,
            st.assigned_by_id
          FROM public.stock_transfer_items sti
          JOIN public.stock_transfers st ON st.id = sti.transfer_id
          WHERE sti.transfer_id = @transferId
            AND sti.product_id IS NOT NULL
        '''),
        parameters: {'transferId': transferId},
      );
      print('[SyncService] ✅ Step3 done');
      print('[SyncService] 🎉 Transfer $transferId FULLY SYNCED!');
    } catch (e, stack) {
      print('[SyncService] ❌ SYNC FAILED: $e');
      print('[SyncService] Stack: $stack');
    }
  }

  void stopListening() {
    _isReconnecting = true; // 🔑 Stop hote waqt bhi closed event ignore karo
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.unsubscribe();
    _channel = null;
    _isListening = false;
    _activeWarehouseId = null;
    print('[SyncService] 🛑 Stopped.');
  }
}