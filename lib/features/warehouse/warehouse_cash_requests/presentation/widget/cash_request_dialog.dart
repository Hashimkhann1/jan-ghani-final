import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/warehouse_cash_request_model.dart';
import '../provider/warehouse_cash_requests_provider.dart';

// =============================================================
// Global Cash Request Card (non-modal, top-right)
// Accountant se aayi pending cash request — warehouse ki KISI bhi
// screen ke top-right corner par compact card. NON-BLOCKING —
// user peeche baaki screens par navigate kar sakta hai.
//
// SideBar ke Stack overlay mein render hota hai. Accept/Reject
// hone par provider (realtime) update se card khud hat jata hai.
// =============================================================
class CashRequestCard extends ConsumerStatefulWidget {
  final WarehouseCashRequestModel request;
  const CashRequestCard({super.key, required this.request});

  @override
  ConsumerState<CashRequestCard> createState() => _CashRequestCardState();
}

class _CashRequestCardState extends ConsumerState<CashRequestCard> {
  bool _busy = false;

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'Rs. $s';
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _handle(bool accept) async {
    setState(() => _busy = true);
    final action = ref.read(cashRequestActionProvider);
    try {
      if (accept) {
        await action.accept(widget.request);
      } else {
        await action.reject(widget.request);
      }
      // Success: realtime stream se ye request pending list se hat jayegi →
      // card khud remove ho jayega. _busy true hi rehta hai (double-tap rok).
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept
              ? 'Cash accept ho gaya — cash in hand update ho gaya'
              : 'Cash request reject kar di'),
        ),
      );
    } catch (e) {
      // Error (offline / already-processed) — card khula rehta hai, retry
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Masla: ${e.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;

    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.25),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + info ───────────────────────────
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: AppColor.cashIn, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Cash Request',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textMuted,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _money(r.amount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColor.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'From: ${r.sentByName ?? 'Accountant'}  •  ${_date(r.createdAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColor.textMuted),
            ),
            const SizedBox(height: 12),

            // ── Actions ────────────────────────────────────────
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColor.primary),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handle(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.cashOut,
                        side: const BorderSide(color: AppColor.cashOut),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Reject',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handle(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.cashIn,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Accept',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
