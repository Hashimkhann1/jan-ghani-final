import 'package:flutter/material.dart';
import '../service/sync/sync_service.dart';

/// SYNC STATUS WIDGET — UI mein sync status dikhao

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: SyncService().statusStream,
      initialData: SyncService().currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getBgColor(status),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon ──────────────────────────────
              if (status.isSyncing)
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  status.hasInternet ? Icons.cloud_done : Icons.cloud_off,
                  size: 16,
                  color: Colors.white,
                ),

              const SizedBox(width: 8),

              // ── Text ──────────────────────────────
              Text(
                _getStatusText(status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getBgColor(SyncStatus status) {
    if (!status.hasInternet) return Colors.grey.shade600;
    if (status.isSyncing)    return Colors.orange.shade600;
    if (status.lastError != null) return Colors.red.shade600;
    return Colors.green.shade600;
  }

  String _getStatusText(SyncStatus status) {
    if (!status.hasInternet) return '📵 Offline';
    if (status.isSyncing)    return '🔄 Sync ho raha hai...';
    if (status.lastSyncTime != null) {
      final t = status.lastSyncTime!;
      return '✅ Sync: ${t.hour}:${t.minute.toString().padLeft(2,'0')}';
    }
    return '⏳ Sync pending...';
  }
}

// ═══════════════════════════════════════════════════════
//   🔘 SYNC BUTTON — Manual sync ke liye
// ═══════════════════════════════════════════════════════
class SyncButton extends StatelessWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: SyncService().statusStream,
      initialData: SyncService().currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus();

        return IconButton(
          tooltip: 'Abhi Sync Karo',
          onPressed: status.isSyncing
              ? null
              : () => SyncService().syncNow(),
          icon: status.isSyncing
              ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.sync),
        );
      },
    );
  }
}