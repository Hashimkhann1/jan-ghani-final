import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/accountant_transfer_model.dart';
import '../provider/accountant_transfer_provider.dart';

// =============================================================
// Accountant → Stock Transfer Record (read-only)
// Sare stock transfers. Transfer tap → expand → poora data + items
// =============================================================
class AccountantStockTransferRecordScreen extends ConsumerStatefulWidget {
  final String warehouseId;
  const AccountantStockTransferRecordScreen({
    super.key,
    required this.warehouseId,
  });

  @override
  ConsumerState<AccountantStockTransferRecordScreen> createState() =>
      _AccountantStockTransferRecordScreenState();
}

class _AccountantStockTransferRecordScreenState
    extends ConsumerState<AccountantStockTransferRecordScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final transfersAsync =
        ref.watch(accAllTransfersProvider(widget.warehouseId));

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text(
          'Stock Transfers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColor.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textDark),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Transfer no. ya store dhoondein...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColor.textMuted),
                  filled: true,
                  fillColor: AppColor.grey100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── List ──────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColor.primary,
                onRefresh: () async =>
                    ref.invalidate(accAllTransfersProvider(widget.warehouseId)),
                child: transfersAsync.when(
                  data: (all) {
                    final list = _query.isEmpty
                        ? all
                        : all
                            .where((t) =>
                                t.transferNumber
                                    .toLowerCase()
                                    .contains(_query) ||
                                t.toStoreName
                                    .toLowerCase()
                                    .contains(_query))
                            .toList();

                    if (list.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'Koi transfer nahi mila',
                              style: TextStyle(color: AppColor.textMuted),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _TransferCard(transfer: list[i]),
                    );
                  },
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 7,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _ShimmerBox(height: 86),
                    ),
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
          ],
        ),
      ),
    );
  }
}

// ── Transfer Card (expandable) ────────────────────────────────────────────────
class _TransferCard extends ConsumerWidget {
  final AccTransferModel transfer;
  const _TransferCard({required this.transfer});

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'Rs. $s';
  }

  String _date(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'received':
      case 'accepted':
      case 'approved':  return AppColor.cashIn;
      case 'rejected':
      case 'cancelled': return AppColor.cashOut;
      case 'pending':   return const Color(0xFFF59E0B);
      default:          return AppColor.textMuted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(transfer.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: AppColor.primary, size: 22),
          ),
          title: Text(
            transfer.transferNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColor.textDark,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${transfer.toStoreName}  •  ${_date(transfer.createdAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColor.textMuted),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(transfer.totalCost),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  transfer.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          children: [
            // ── Full transfer info ────────────────────────────
            const Divider(height: 1),
            const SizedBox(height: 10),
            _infoRow('Transfer No.', transfer.transferNumber),
            _infoRow('To Store', transfer.toStoreName),
            _infoRow('Status', transfer.statusLabel),
            _infoRow('Date', _date(transfer.createdAt)),
            _infoRow('Assigned At', _date(transfer.assignedAt)),
            if (transfer.assignedByName?.isNotEmpty == true)
              _infoRow('Assigned By', transfer.assignedByName!),
            _infoRow('Total Items', '${transfer.totalItems}'),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Amounts ───────────────────────────────────────
            _amountRow('Total Cost', transfer.totalCost, bold: true),
            _amountRow('Total Sale Price', transfer.totalSalePrice,
                valueColor: AppColor.cashIn),

            const SizedBox(height: 12),

            // ── Items ─────────────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Items',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColor.textDark,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _TransferItemsList(transferId: transfer.id),

            if (transfer.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Note: ${transfer.notes}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColor.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColor.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: bold ? AppColor.textDark : AppColor.textMuted,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            _money(value),
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? AppColor.textDark,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transfer Items (lazy load) ────────────────────────────────────────────────
class _TransferItemsList extends ConsumerWidget {
  final String transferId;
  const _TransferItemsList({required this.transferId});

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'Rs. $s';
  }

  String _qty(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(accTransferItemsProvider(transferId));

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Koi item nahi',
              style: TextStyle(fontSize: 12, color: AppColor.textMuted),
            ),
          );
        }
        return Column(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 6, color: AppColor.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textDark,
                          ),
                        ),
                        Text(
                          '${_qty(item.quantitySent)} ${item.unitOfMeasure} × ${_money(item.unitCost)}'
                          '${item.sku?.isNotEmpty == true ? '  •  ${item.sku}' : ''}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColor.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _money(item.totalCost),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textDark,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColor.primary),
        ),
      ),
      error: (e, _) => const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Items load nahi hue',
          style: TextStyle(fontSize: 12, color: Colors.red),
        ),
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
      );
}
