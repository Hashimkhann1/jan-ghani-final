import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/cash_transfer_model.dart';
import '../provider/cash_transfer_provider.dart';

// =============================================================
// Accountant → Sent Cash Transfers (read-only status list)
// pending / accepted / rejected dikhata hai
// =============================================================
class AccountantCashTransfersScreen extends ConsumerWidget {
  // Agar warehouseId diya ho to sirf usi warehouse ke transfers,
  // warna accountant ke saare bheje transfers.
  final String? warehouseId;
  const AccountantCashTransfersScreen({super.key, this.warehouseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = warehouseId != null
        ? ref.watch(warehouseCashTransfersProvider(warehouseId!))
        : ref.watch(myCashTransfersProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textDark),
        title: const Text(
          'Cash Transfers',
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
          onRefresh: () async => warehouseId != null
              ? ref.invalidate(warehouseCashTransfersProvider(warehouseId!))
              : ref.invalidate(myCashTransfersProvider),
          child: transfersAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Text(
                        'Abhi tak koi cash transfer nahi',
                        style: TextStyle(color: AppColor.textMuted),
                      ),
                    ),
                  ],
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _TransferTile(transfer: list[i]),
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
                    'Transfers load nahi hue — pull to refresh',
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

class _TransferTile extends StatelessWidget {
  final CashTransferModel transfer;
  const _TransferTile({required this.transfer});

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'Rs. $s';
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  ({Color color, Color bg, IconData icon}) _statusStyle() {
    switch (transfer.status) {
      case 'accepted':
        return (
          color: AppColor.cashIn,
          bg: const Color(0xFFECFDF5),
          icon: Icons.check_circle_rounded
        );
      case 'rejected':
        return (
          color: AppColor.cashOut,
          bg: const Color(0xFFFEF2F2),
          icon: Icons.cancel_rounded
        );
      default: // pending
        return (
          color: const Color(0xFFF59E0B),
          bg: const Color(0xFFFFF4E5),
          icon: Icons.hourglass_top_rounded
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _statusStyle();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: s.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s.icon, color: s.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transfer.warehouseName ?? 'Warehouse',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColor.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _date(transfer.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(transfer.amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transfer.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: s.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
