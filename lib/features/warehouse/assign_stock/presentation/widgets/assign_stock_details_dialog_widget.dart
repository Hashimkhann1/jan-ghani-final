import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_report_provider.dart';

// ─── Detail Dialog ────────────────────────────────────────────────────────────

class AssignStockDetailsDialogWidget extends ConsumerWidget {
  const AssignStockDetailsDialogWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferReportProvider);

    if (state.selectedTransfer == null) return const SizedBox.shrink();

    final t = state.selectedTransfer!;
    final items = state.selectedItems;

    final subtotal = items.fold(0.0, (s, i) => s + i.totalCost);
    final totalSale = items.fold(0.0, (s, i) => s + i.totalSalePrice);
    final totalTax = items.fold(0.0, (s, i) => s + i.taxAmount);
    final totalDiscount = items.fold(0.0, (s, i) => s + i.discountAmount);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        width: 820,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            // ── Dialog Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColor.grey200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded,
                        color: AppColor.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t.transferNumber,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.textPrimary),
                            ),
                            const SizedBox(width: 10),
                            _StatusBadge(status: t.status),
                          ],
                        ),
                        Text(
                          '${t.toStoreName}  •  ${DateFormat('dd-MM-yyyy').format(t.assignedAt)}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColor.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // ✅ Navigator.pop — showDialog ke saath yahi sahi hai
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColor.textSecondary),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Info Chips ─────────────────────────────────────────
                    Row(
                      children: [
                        _InfoBox(
                            label: 'Assigned At',
                            value: DateFormat('dd-MM-yyyy hh:mm a')
                                .format(t.assignedAt)),
                        const SizedBox(width: 12),
                        _InfoBox(
                            label: 'Assigned By',
                            value: t.assignedByName ?? '—'),
                        const SizedBox(width: 12),
                        _InfoBox(
                            label: 'Total Items',
                            value: '${t.totalItems} products'),
                        if (t.notes != null && t.notes!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoBox(
                                label: 'Notes', value: t.notes!),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Financial Summary ──────────────────────────────────
                    const Text(
                      'Financial Summary',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _FinCard(
                          label: 'Total Cost',
                          value: subtotal.toStringAsFixed(0),
                          icon: Icons.receipt_outlined,
                          iconColor: AppColor.primary,
                          bg: AppColor.primary.withOpacity(0.07),
                        ),
                        const SizedBox(width: 10),
                        _FinCard(
                          label: 'Tax',
                          value: totalTax.toStringAsFixed(0),
                          icon: Icons.percent_rounded,
                          iconColor: Colors.orange,
                          bg: Colors.orange.withOpacity(0.07),
                          prefix: '+ Rs',
                        ),
                        const SizedBox(width: 10),
                        _FinCard(
                          label: 'Discount',
                          value: totalDiscount.toStringAsFixed(0),
                          icon: Icons.local_offer_outlined,
                          iconColor: AppColor.success,
                          bg: AppColor.success.withOpacity(0.07),
                          prefix: '- Rs',
                        ),
                        const SizedBox(width: 10),
                        _FinCard(
                          label: 'Total Sale Price',
                          value: totalSale.toStringAsFixed(0),
                          icon: Icons.sell_outlined,
                          iconColor: const Color(0xFF5C6BC0),
                          bg: const Color(0xFF5C6BC0).withOpacity(0.07),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Products Table ─────────────────────────────────────
                    Text(
                      'Products (${items.length} items)',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary),
                    ),
                    const SizedBox(height: 10),

                    if (state.isLoadingDetail)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColor.grey200),
                        ),
                        child: Column(
                          children: [
                            // Table header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: const BoxDecoration(
                                color: AppColor.grey100,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(10)),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                      flex: 3,
                                      child: _DTH(
                                          text: 'Product',
                                          align: TextAlign.left)),
                                  Expanded(
                                      flex: 1,
                                      child: _DTH(text: 'Qty Sent')),
                                  Expanded(
                                      flex: 2,
                                      child: _DTH(text: 'Purchase Price')),
                                  Expanded(
                                      flex: 2,
                                      child: _DTH(text: 'Sale Price')),
                                  Expanded(
                                      flex: 2,
                                      child: _DTH(text: 'Total Cost')),
                                ],
                              ),
                            ),

                            // Table rows
                            ...items.asMap().entries.map((e) {
                              final i = e.value;
                              final isLast = e.key == items.length - 1;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  border: isLast
                                      ? null
                                      : const Border(
                                      bottom: BorderSide(
                                          color: AppColor.grey200)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            i.productName,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColor.textPrimary),
                                          ),
                                          Text(
                                            i.sku,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColor.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${i.quantitySent.toStringAsFixed(i.quantitySent % 1 == 0 ? 0 : 2)} ${i.unitOfMeasure}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColor.textPrimary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Rs ${i.purchasePrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColor.textPrimary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Rs ${i.salePrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF534AB7)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Rs ${i.totalCost.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColor.primary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Dialog Footer ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColor.grey200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.textSecondary,
                        side: const BorderSide(color: AppColor.grey300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Private Helper Widgets ───────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    switch (status.toLowerCase()) {
      case 'accepted':
        bg = AppColor.success.withOpacity(0.12);
        fg = AppColor.success;
        label = '● Accepted';
        break;
      case 'pending':
        bg = Colors.orange.withOpacity(0.12);
        fg = Colors.orange;
        label = '● Pending';
        break;
      case 'rejected':
        bg = AppColor.error.withOpacity(0.12);
        fg = AppColor.error;
        label = '● Rejected';
        break;
      default:
        bg = AppColor.grey200;
        fg = AppColor.textSecondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _DTH extends StatelessWidget {
  final String text;
  final TextAlign? align;
  const _DTH({required this.text, this.align});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColor.textSecondary),
    textAlign: align ?? TextAlign.center,
  );
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColor.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColor.textHint,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _FinCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String? prefix;

  const _FinCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bg,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${prefix ?? 'Rs'} $value',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: iconColor),
                ),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: iconColor.withOpacity(0.7))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}