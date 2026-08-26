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
        } else if (newStatus == 'rejected') {
          print('[SyncService] ↩️ Rejected! Releasing reservation...');
          await _syncRejectedTransfer(transferId: transferId);
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

      // NEW: local transfers jo abhi tak Supabase par kabhi push hi nahi
      // hue (assign ke waqt offline the ya koi non-network error aayi thi)
      // unhe pehle push karo — pehle koi bhi background mechanism yeh nahi
      // karta tha, is liye aisi transfers hamesha ke liye "orphan" (stock
      // reserved par branch ko kabhi dikhi hi nahi) reh jati thin.
      await _pushUnmirroredTransfers(warehouseId, localPendingIds);

      final supabaseResult = await _supabase
          .from('stock_transfers')
          .select('id, status')
          .eq('warehouse_id', warehouseId)
          .inFilter('status', ['accepted', 'rejected'])
          .inFilter('id', localPendingIds);

      if (supabaseResult.isEmpty) {
        print('[SyncService] ✅ No missed accepted/rejected transfers found.');
        return;
      }

      print('[SyncService] 🚀 Found ${supabaseResult.length} missed transfers! Syncing...');

      for (final transfer in supabaseResult) {
        final transferId = transfer['id'] as String;
        final st = transfer['status'] as String?;
        print('[SyncService] Syncing missed transfer: $transferId ($st)');
        if (st == 'accepted') {
          await _syncAcceptedTransfer(
            transferId: transferId,
            newStatus: 'accepted',
          );
        } else if (st == 'rejected') {
          await _syncRejectedTransfer(transferId: transferId);
        }
      }

      print('[SyncService] 🎉 All missed transfers synced!');
    } catch (e, stack) {
      print('[SyncService] ❌ Error checking missed transfers: $e');
      print('[SyncService] Stack: $stack');
    }
  }

  /// `stock_transfers`/`stock_transfer_items` generic table-sync mein
  /// shamil NAHI hain — is liye agar assign-stock ke waqt Supabase-mirror
  /// fail ho jaye (offline ya koi aur error), woh transfer sirf local
  /// Postgres mein reh jaati thi aur kabhi bhi Supabase tak nahi pahunchti
  /// thi (branch ko kabhi dikhti hi nahi, reserved stock permanently
  /// atka reh jata). Yeh function local pending transfers ko Supabase se
  /// compare karke jo wahan bilkul mojood hi nahi unhe (transfer + items)
  /// push kar deta hai.
  Future<void> _pushUnmirroredTransfers(
    String warehouseId,
    List<String> localPendingIds,
  ) async {
    if (localPendingIds.isEmpty) return;
    try {
      final remoteExisting = await _supabase
          .from('stock_transfers')
          .select('id')
          .inFilter('id', localPendingIds);

      final remoteIds =
          (remoteExisting as List).map((r) => r['id'] as String).toSet();
      final missingIds =
          localPendingIds.where((id) => !remoteIds.contains(id)).toList();

      if (missingIds.isEmpty) return;
      print('[SyncService] 📤 ${missingIds.length} transfers Supabase par kabhi nahi pahunchi — pushing...');

      for (final id in missingIds) {
        try {
          final transferRows = await _db.execute(
            Sql.named(
                'SELECT * FROM public.stock_transfers WHERE id = @id'),
            parameters: {'id': id},
          );
          if (transferRows.isEmpty) continue;

          final itemRows = await _db.execute(
            Sql.named(
                'SELECT * FROM public.stock_transfer_items WHERE transfer_id = @id'),
            parameters: {'id': id},
          );

          await _supabase
              .from('stock_transfers')
              .upsert(_forSupabase(transferRows.first.toColumnMap()));

          if (itemRows.isNotEmpty) {
            await _supabase.from('stock_transfer_items').upsert(
                  itemRows.map((r) => _forSupabase(r.toColumnMap())).toList(),
                );
          }
          print('[SyncService] ✅ Pushed missed transfer $id to Supabase.');
        } catch (e) {
          print('[SyncService] ❌ Failed pushing transfer $id: $e');
        }
      }
    } catch (e, stack) {
      print('[SyncService] ❌ Error pushing unmirrored transfers: $e');
      print('[SyncService] Stack: $stack');
    }
  }

  /// Local Postgres row (DateTime objects) ko Supabase-friendly JSON map
  /// mein convert karta hai.
  Map<String, dynamic> _forSupabase(Map<String, dynamic> row) {
    return row.map((key, value) {
      if (value is DateTime) return MapEntry(key, value.toIso8601String());
      return MapEntry(key, value);
    });
  }

  // Step1 (status flip) + Step2 (deduct qty / release reservation) + Step3
  // (movement log) ab EK DB transaction mein hain. Pehle yeh teen alag
  // statements the — agar app Step1 ke baad crash/disconnect ho jata to
  // status 'accepted' reh jata lekin quantity kabhi deduct na hoti, aur
  // upar wala idempotency guard ("already accepted, skip") is ADHOORI
  // state ko hamesha ke liye skip kar deta — reserved_quantity permanently
  // stuck reh jaati. Ab: ya to teeno steps commit hote hain, ya (crash/error
  // par) transaction poora rollback ho jata hai aur status 'pending' hi
  // rehta hai — is se agli koshish (missed-sync/realtime) safely retry kar
  // sakti hai.
  Future<void> _syncAcceptedTransfer({
    required String transferId,
    required String newStatus,
  }) async {
    try {
      await _db.runTx((tx) async {
        // Step1: status ko ATOMICALLY pending→accepted karo. Sirf tabhi
        // aage badho jab yeh update ne sach mein ek row badli (yaani pehle
        // pending tha). Isse missed-sync + realtime dono ek saath chalein
        // to bhi deduction ek hi baar hota hai (double-deduction / race se
        // bachao).
        final statusUpd = await tx.execute(
          Sql.named('''
            UPDATE public.stock_transfers
            SET status = @status, updated_at = NOW()
            WHERE id = @transferId AND status = 'pending'
            RETURNING id
          '''),
          parameters: {'status': newStatus, 'transferId': transferId},
        );
        if (statusUpd.isEmpty) {
          print('[SyncService] ⏭️ Transfer $transferId pending nahi raha (already processed), skipping.');
          return;
        }

        // Step2: physical quantity kam karo aur reservation release karo.
        // quantity ab 0 par floor NAHI hoti — agar transfer available se
        // zyada ho to stock asal minus mein jata hai (deficit visible +
        // movements se reconcile). reserved_quantity phir bhi 0 par capped
        // (negative reserve ka koi matlab nahi).
        await tx.execute(
          Sql.named('''
            UPDATE public.warehouse_inventory
            SET quantity          = quantity - sti.quantity_sent,
                reserved_quantity = GREATEST(0, reserved_quantity - sti.quantity_sent),
                last_movement_at  = NOW(),
                updated_at        = NOW(),
                is_synced         = false
            FROM public.stock_transfer_items sti
            JOIN public.stock_transfers st ON st.id = sti.transfer_id
            WHERE sti.transfer_id = @transferId
              AND warehouse_inventory.product_id = sti.product_id
              AND warehouse_inventory.warehouse_id = st.warehouse_id
          '''),
          parameters: {'transferId': transferId},
        );

        await tx.execute(
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

        print('[SyncService] 🎉 Transfer $transferId FULLY SYNCED!');
      });
    } catch (e, stack) {
      print('[SyncService] ❌ SYNC FAILED: $e');
      print('[SyncService] Stack: $stack');
    }
  }

  /// Transfer reject hone par: SIRF reservation release karo
  /// (`reserved_quantity` kam). Physical `quantity` ko haath nahi lagate —
  /// kyunki create par sirf reserve hua tha, deduct nahi.
  ///
  /// `WHERE status = 'pending'` guard ki wajah se yeh idempotent hai:
  ///  - agar transfer pehle hi accept ho chuka (reservation already released) → kuch nahi.
  ///  - agar pehle hi reject ho chuka → dobara release nahi hoti.
  Future<void> _syncRejectedTransfer({required String transferId}) async {
    try {
      print('[SyncService] Reject: guarded status update...');
      final statusUpd = await _db.execute(
        Sql.named('''
          UPDATE public.stock_transfers
          SET status = 'rejected', updated_at = NOW()
          WHERE id = @transferId AND status = 'pending'
          RETURNING id
        '''),
        parameters: {'transferId': transferId},
      );
      if (statusUpd.isEmpty) {
        print('[SyncService] ⏭️ Transfer $transferId pending nahi raha, reservation release skip.');
        return;
      }

      await _db.execute(
        Sql.named('''
          UPDATE public.warehouse_inventory
          SET reserved_quantity = GREATEST(0, reserved_quantity - sti.quantity_sent),
              updated_at        = NOW(),
              is_synced         = false
          FROM public.stock_transfer_items sti
          JOIN public.stock_transfers st ON st.id = sti.transfer_id
          WHERE sti.transfer_id = @transferId
            AND warehouse_inventory.product_id = sti.product_id
            AND warehouse_inventory.warehouse_id = st.warehouse_id
        '''),
        parameters: {'transferId': transferId},
      );
      print('[SyncService] ✅ Transfer $transferId rejected — reservation released.');
    } catch (e, stack) {
      print('[SyncService] ❌ REJECT SYNC FAILED: $e');
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