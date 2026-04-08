import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/color/app_color.dart';
import '../widget/cart_panel.dart';
import '../widget/product_list_panel.dart';


class SaleInvoiceScreen extends ConsumerWidget {
  const SaleInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: _buildAppBar(context),
      body: const Row(
        children: [
          // ─── Left: Product List (40%) ────────────────────────────────
          Expanded(
            flex: 30,
            child: ProductListPanel(),
          ),

          // ─── Right: Cart Panel (60%) ─────────────────────────────────
          Expanded(
            flex: 70,
            child: CartPanel(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColor.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Sale Invoice',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        // Help badge
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColor.infoLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 13, color: AppColor.info),
              SizedBox(width: 4),
              Text(
                'Double tap product to add',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColor.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
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