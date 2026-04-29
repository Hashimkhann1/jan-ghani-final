import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_provider.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/provider/auth_provider.dart';

class AssignStockCartSummary extends ConsumerWidget {
  const AssignStockCartSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignStockProvider);
    final notifier = ref.read(assignStockProvider.notifier);
    final auth = ref.watch(authProvider);

    // Check if any item exceeds available stock
    final hasStockIssue = state.cartItems
        .any((item) => item.quantity > item.availableStock);

    // Button disabled if: can't save OR stock issue OR saving in progress
    final buttonEnabled = state.canSave && !state.isSaving && !hasStockIssue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(top: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          // Summary stats
          Expanded(
            child: Row(
              children: [
                _StatChip(
                  label: 'Items',
                  value: '${state.totalItems}',
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: 'Total Qty',
                  value: state.totalQty.toStringAsFixed(2),
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: 'Grand Total',
                  value: 'Rs ${state.grandTotal.toStringAsFixed(0)}',
                  color: AppColor.success,
                ),
              ],
            ),
          ),

          // Stock issue warning chip
          if (hasStockIssue) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColor.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColor.error.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.inventory_2_outlined,
                      size: 14, color: AppColor.error),
                  SizedBox(width: 6),
                  Text(
                    'Kuch items ki quantity available stock se zyada hai',
                    style: TextStyle(fontSize: 12, color: AppColor.error),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Error message
          if (state.errorMessage != null && !hasStockIssue)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColor.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 14, color: AppColor.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColor.error),
                      ),
                    ),
                    GestureDetector(
                      onTap: notifier.clearError,
                      child: const Icon(Icons.close,
                          size: 14, color: AppColor.error),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(width: 12),

          // Assign Stock button — shows dialog first
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 140),
              child: ElevatedButton.icon(
                onPressed: buttonEnabled
                    ? () => _showConfirmDialog(
                  context: context,
                  ref: ref,
                  assignedById: auth.user?.id ?? '',
                  assignedByName:
                  auth.user?.fullName ?? 'Warehouse',
                )
                    : null,
                icon: state.isSaving
                    ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  state.isSaving ? 'Saving...' : 'Assign Stock',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonEnabled
                      ? AppColor.primary
                      : AppColor.grey300,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String assignedById,
    required String assignedByName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssignStockConfirmDialog(
        assignedById: assignedById,
        assignedByName: assignedByName,
      ),
    );
  }
}

// ─── Confirmation Dialog ───────────────────────────────────────────────────

class _AssignStockConfirmDialog extends ConsumerWidget {
  final String assignedById;
  final String assignedByName;

  const _AssignStockConfirmDialog({
    required this.assignedById,
    required this.assignedByName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignStockProvider);
    final notifier = ref.read(assignStockProvider.notifier);

    final totalPurchase = state.cartItems.fold<double>(
      0,
          (sum, i) => sum + (i.purchasePrice * i.quantity),
    );
    final totalSale = state.cartItems.fold<double>(
      0,
          (sum, i) => sum + (i.salePrice * i.quantity),
    );
    final totalTax = state.cartItems.fold<double>(
      0,
          (sum, i) => sum + i.taxAmount,
    );
    final totalDiscount = state.cartItems.fold<double>(
      0,
          (sum, i) => sum + i.discountAmount,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                border: Border(
                    bottom: BorderSide(color: AppColor.primary.withOpacity(0.15))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fact_check_outlined,
                        color: AppColor.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock Assignment Confirm Karo',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary),
                        ),
                        Text(
                          'Transfer # ${state.transferNumber}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColor.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColor.grey100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: AppColor.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // ── Meta info row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetaChip(
                    icon: Icons.store_rounded,
                    label: 'To Store',
                    value: state.selectedStoreName ?? '-',
                    color: AppColor.primary,
                  ),
                  _MetaChip(
                    icon: Icons.person_outline_rounded,
                    label: 'Assigned By',
                    value: assignedByName,
                    color: Colors.indigo,
                  ),
                  _MetaChip(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: _formatDate(DateTime.now()),
                    color: Colors.teal,
                  ),
                  _MetaChip(
                    icon: Icons.inventory_2_outlined,
                    label: 'Total Products',
                    value: '${state.totalItems} items',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),

            // ── Products list (scrollable) ──
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Text(
                'Products',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary),
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: AppColor.grey200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.06),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                            flex: 4,
                            child: _TH(text: 'Product', align: TextAlign.start)),
                        Expanded(flex: 2, child: _TH(text: 'Qty')),
                        Expanded(flex: 2, child: _TH(text: 'Purchase')),
                        Expanded(flex: 2, child: _TH(text: 'Sale')),
                        Expanded(flex: 2, child: _TH(text: 'Total')),
                      ],
                    ),
                  ),
                  // Table rows
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.cartItems.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: AppColor.grey200),
                      itemBuilder: (_, i) {
                        final item = state.cartItems[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.quantity % 1 == 0
                                      ? item.quantity.toInt().toString()
                                      : item.quantity.toStringAsFixed(2),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColor.textPrimary),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Rs ${item.purchasePrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColor.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.salePrice > 0
                                      ? 'Rs ${item.salePrice.toStringAsFixed(0)}'
                                      : '—',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF534AB7),
                                      fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Rs ${item.totalCost.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.primary),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Financial summary ──
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColor.grey100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColor.grey200),
              ),
              child: Row(
                children: [
                  _SummaryCell(
                    label: 'Total Purchase',
                    value: 'Rs ${totalPurchase.toStringAsFixed(0)}',
                    color: AppColor.textPrimary,
                  ),
                  _Divider(),
                  _SummaryCell(
                    label: 'Total Sale',
                    value: 'Rs ${totalSale.toStringAsFixed(0)}',
                    color: const Color(0xFF534AB7),
                  ),
                  _Divider(),
                  _SummaryCell(
                    label: 'Tax',
                    value: 'Rs ${totalTax.toStringAsFixed(0)}',
                    color: Colors.orange,
                  ),
                  _Divider(),
                  _SummaryCell(
                    label: 'Discount',
                    value: 'Rs ${totalDiscount.toStringAsFixed(0)}',
                    color: AppColor.error,
                  ),
                  _Divider(),
                  _SummaryCell(
                    label: 'Grand Total',
                    value: 'Rs ${state.grandTotal.toStringAsFixed(0)}',
                    color: AppColor.success,
                    bold: true,
                  ),
                ],
              ),
            ),

            // ── Notes (if any) ──
            if ((state.notes ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes_rounded,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.notes!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Action buttons ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: AppColor.grey300),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: state.isSaving
                          ? null
                          : () async {
                        final success = await notifier.assignStock(
                          assignedById: assignedById,
                          assignedByName: assignedByName,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          if (success) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.check_circle,
                                        color: Colors.white,
                                        size: 16),
                                    SizedBox(width: 8),
                                    Text('Stock assign ho gaya!'),
                                  ],
                                ),
                                backgroundColor: AppColor.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(8)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        }
                      },
                      icon: state.isSaving
                          ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                          : const Icon(Icons.check_circle_outline_rounded,
                          size: 18),
                      label: Text(
                        state.isSaving
                            ? 'Assigning...'
                            : 'Confirm & Assign Stock',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
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

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  final TextAlign align;

  const _TH({required this.text, this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColor.primary),
    textAlign: align,
  );
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColor.textSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 14 : 12,
                fontWeight:
                bold ? FontWeight.w800 : FontWeight.w600,
                color: color)),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 28,
    color: AppColor.grey200,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

// ─── Stat chip (unchanged) ─────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}