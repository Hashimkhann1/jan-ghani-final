// =============================================================
// purchase_invoice_screen.dart
// Sale Invoice Screen ki tarah — bilkul same layout
// Left (30%): Product List
// Right (70%): PO Cart Panel
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/widgets/purchase_invoice_widgets/po_cart_panel.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/widgets/purchase_invoice_widgets/po_product_list_panel.dart';


class PurchaseInvoiceScreen extends ConsumerWidget {
  const PurchaseInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar:          _buildAppBar(context),
      body: const Row(
        children: [
          // ── Left: Product List (30%) ─────────────────────────
          Expanded(flex: 30, child: PoProductListPanel()),

          // ── Right: PO Cart Panel (70%) ───────────────────────
          Expanded(flex: 70, child: PoCartPanel()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor:  AppColor.white,
      elevation:        0,
      surfaceTintColor: Colors.transparent,
      titleSpacing:     16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:        AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                color: AppColor.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Purchase Invoice',
              style: TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.w700,
                  color:      AppColor.textPrimary)),
        ],
      ),
      actions: [
        // Hint badge
        Container(
          margin:  const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color:        AppColor.infoLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.touch_app_outlined,
                  size: 13, color: AppColor.info),
              SizedBox(width: 4),
              Text('Double tap product to add',
                  style: TextStyle(
                      fontSize:   11,
                      color:      AppColor.info,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColor.grey200),
      ),
    );
  }
}
