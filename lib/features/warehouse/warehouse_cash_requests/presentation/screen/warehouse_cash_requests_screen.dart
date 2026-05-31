import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/warehouse_cash_request_model.dart';
import '../provider/warehouse_cash_requests_provider.dart';

// =============================================================
// Warehouse → Cash Requests (accountant se aayi cash)
// Har request pe Accept / Reject. Accept par local cash_in_hand
// barhta hai (sync up) aur accountant ka cash minus hota hai.
// =============================================================
class WarehouseCashRequestsScreen extends ConsumerWidget {
  const WarehouseCashRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingCashRequestsProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textDark),
        title: const Text(
          'Cash Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColor.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColor.primary,
          onRefresh: () async => ref.invalidate(pendingCashRequestsProvider),
          child: requestsAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Text(
                        'Koi pending cash request nahi',
                        style: TextStyle(color: AppColor.textMuted),
                      ),
                    ),
                  ],
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _RequestCard(request: list[i]),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColor.primary),
            ),
            error: (e, _) => ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'Requests load nahi hue — pull to refresh',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final WarehouseCashRequestModel request;
  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
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
      ref.invalidate(pendingCashRequestsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept
              ? 'Cash accept ho gaya — cash in hand update ho gaya'
              : 'Cash request reject kar di'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masla: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: AppColor.cashIn, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _money(r.amount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'From: ${r.sentByName ?? 'Accountant'}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColor.textMuted),
                    ),
                    Text(
                      _date(r.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              r.notes!,
              style: const TextStyle(fontSize: 12, color: AppColor.textMuted),
            ),
          ],
          const SizedBox(height: 14),
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  height: 22,
                  width: 22,
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Reject',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handle(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.cashIn,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Accept',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
