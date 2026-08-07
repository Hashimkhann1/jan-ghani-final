import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_provider.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/provider/product_provider.dart';

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
    // Purana detail + "Confirm & Assign Stock" wala dialog (bilkul same).
    void openConfirm() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _AssignStockConfirmDialog(
          assignedById: assignedById,
          assignedByName: assignedByName,
        ),
      );
    }

    // Qty 0 wale products — yeh transfer inka stock nahi bhejega, sirf
    // product info (price/barcode) store par update karega.
    final zeroQtyNames = ref
        .read(assignStockProvider)
        .cartItems
        .where((i) => i.quantity == 0)
        .map((i) => i.productName)
        .toList();

    // Koi 0-qty nahi → seedha purana confirm dialog (flow same).
    if (zeroQtyNames.isEmpty) {
      openConfirm();
      return;
    }

    // Koi 0-qty hai → pehle warning dialog, Confirm par purana dialog khulta hai.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _ZeroQtyWarningDialog(
        productNames: zeroQtyNames,
        onCancel: () => Navigator.of(dialogCtx).pop(),
        onConfirm: () {
          Navigator.of(dialogCtx).pop();
          openConfirm();
        },
      ),
    );
  }
}

// ─── 0-Qty Warning Dialog ─────────────────────────────────────────────────
// Jab kisi cart item ki qty 0 ho: user ko product naam(s) dikha kar batao
// ke yeh sirf info update hai (stock nahi jayega). Confirm par aage badho.
class _ZeroQtyWarningDialog extends StatelessWidget {
  final List<String> productNames;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _ZeroQtyWarningDialog({
    required this.productNames,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColor.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        color: AppColor.warning, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Qty 0 — sirf info update',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Message
              const Text(
                'In products ki Qty 0 hai. Yeh transfer inka stock NAHI bhejega — '
                'sirf inki product info (price, barcode waghera) store par update karega:',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColor.textSecondary,
                    height: 1.4),
              ),
              const SizedBox(height: 12),
              // Product list
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.warningLight,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColor.warning.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final name in productNames)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.circle,
                                size: 6, color: AppColor.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.textPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColor.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Qty 0',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.warning)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColor.grey300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: AppColor.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 18),
                      label: const Text('Confirm',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                            // Transfer ke baad products reload — reserved/
                            // available qty inventory + assign dono screen par
                            // foran update (manual refresh/restart ki zaroorat nahi).
                            ref
                                .read(productProvider.notifier)
                                .loadProducts();
                            // Offline save hua to alag (info) message —
                            // transfer local mein safe hai, internet aate hi
                            // background sync store tak push kar degi.
                            final offline = ref
                                .read(assignStockProvider)
                                .lastSaveOffline;
                            // Desktop ke liye chhota card, screen ke
                            // right-bottom par (full-width nahi).
                            final screenW =
                                MediaQuery.of(context).size.width;
                            const cardW = 380.0;
                            final leftMargin =
                                (screenW - cardW - 24)
                                    .clamp(16.0, double.infinity);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                        offline
                                            ? Icons.cloud_off_rounded
                                            : Icons.check_circle,
                                        color: Colors.white,
                                        size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        offline
                                            ? 'Internet nahi — transfer save ho gayi. '
                                                'Internet aate hi store ko sync ho jayegi.'
                                            : 'Stock assign ho gaya!',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: offline
                                    ? AppColor.info
                                    : AppColor.success,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(
                                    seconds: offline ? 5 : 3),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(8)),
                                margin: EdgeInsets.only(
                                  left: leftMargin,
                                  right: 24,
                                  bottom: 24,
                                ),
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