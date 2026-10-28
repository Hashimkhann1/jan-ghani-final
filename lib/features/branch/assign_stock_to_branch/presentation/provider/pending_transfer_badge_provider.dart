import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'stock_transfer_provider.dart';

/// Branch ke liye abhi tak accept/reject na hue (pending) transfers ka
/// count + total units, aur sab se naya aaya hua transfer (notification ke
/// liye). `incomingSeq` har naye transfer par badhta hai taake listener
/// same transfer par dobara na chale.
class PendingTransferState {
  final int    count;
  final int    units;
  final int    incomingSeq;
  final String? incomingNumber;
  final int    incomingUnits;

  const PendingTransferState({
    this.count          = 0,
    this.units          = 0,
    this.incomingSeq    = 0,
    this.incomingNumber,
    this.incomingUnits  = 0,
  });

  PendingTransferState copyWith({
    int? count,
    int? units,
    int? incomingSeq,
    String? incomingNumber,
    int? incomingUnits,
  }) =>
      PendingTransferState(
        count:          count          ?? this.count,
        units:          units          ?? this.units,
        incomingSeq:    incomingSeq    ?? this.incomingSeq,
        incomingNumber: incomingNumber ?? this.incomingNumber,
        incomingUnits:  incomingUnits  ?? this.incomingUnits,
      );
}

final pendingTransferBadgeProvider =
    NotifierProvider<PendingTransferBadgeNotifier, PendingTransferState>(
  PendingTransferBadgeNotifier.new,
);

class PendingTransferBadgeNotifier extends Notifier<PendingTransferState> {
  RealtimeChannel? _channel;
  Timer?           _poll;

  @override
  PendingTransferState build() {
    final storeId = ref.watch(currentStoreIdProvider);

    ref.onDispose(() {
      _channel?.unsubscribe();
      _poll?.cancel();
    });

    if (storeId.isEmpty) return const PendingTransferState();

    _refresh(storeId);
    _listen(storeId);
    // Realtime miss ho jaye (offline / reconnect) to bhi badge theek ho jaye.
    _poll = Timer.periodic(
        const Duration(minutes: 2), (_) => _refresh(storeId));

    return const PendingTransferState();
  }

  Future<void> _refresh(String storeId) async {
    try {
      final agg = await ref
          .read(stockTransferDataSourceProvider)
          .fetchStatusAggregates(storeId);
      final p = agg['pending'];
      state = state.copyWith(count: p?.count ?? 0, units: p?.totalUnits ?? 0);
    } catch (e) {
      debugPrint('[PendingTransferBadge] refresh failed: $e');
    }
  }

  void _listen(String storeId) {
    _channel = Supabase.instance.client
        .channel('branch_pending_transfers_$storeId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.all,
          schema: 'public',
          table:  'stock_transfers',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'to_store_id',
            value:  storeId,
          ),
          callback: (payload) async {
            final row = payload.newRecord;
            final isNewPending =
                payload.eventType == PostgresChangeEvent.insert &&
                    row['status'] == 'pending';

            await _refresh(storeId);

            if (isNewPending) {
              state = state.copyWith(
                incomingSeq:    state.incomingSeq + 1,
                incomingNumber: row['transfer_number']?.toString(),
                incomingUnits:
                    (num.tryParse('${row['total_items']}') ?? 0).toInt(),
              );
              // Agar transfers screen khuli hai to list bhi taza ho jaye.
              ref.invalidate(stockTransferProvider);
            }
          },
        )
        .subscribe();
  }
}
