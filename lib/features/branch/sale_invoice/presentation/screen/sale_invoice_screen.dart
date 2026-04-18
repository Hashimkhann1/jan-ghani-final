import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';
import '../widget/cart_panel.dart';
import '../widget/product_list_panel.dart';

class SaleInvoiceScreen extends ConsumerWidget {
  const SaleInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(saleInvoiceProvider);
    final isReturn = state.saleType == SaleType.saleReturn;
    final accent   = isReturn ? AppColor.error : AppColor.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        titleSpacing:     16,
        title: Row(
          children: [
            // Logo/Icon area
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent,
                    accent.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isReturn
                    ? Icons.assignment_return_outlined
                    : Icons.point_of_sale_outlined,
                color: Colors.white,
                size:  18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReturn ? 'Sale Return' : 'Sale Invoice',
                  style: const TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.w800,
                      color:      AppColor.textPrimary),
                ),
                Text(
                  isReturn
                      ? 'Return process karein'
                      : 'New sale record karein',
                  style: const TextStyle(
                      fontSize: 11,
                      color:    AppColor.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!isReturn)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 0),
              decoration: BoxDecoration(
                color:        AppColor.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(
                    color: AppColor.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 13, color: AppColor.primary),
                  SizedBox(width: 4),
                  Text('Double tap to add',
                      style: TextStyle(
                          fontSize:   11,
                          color:      AppColor.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1,
              color: isReturn
                  ? AppColor.error.withOpacity(0.3)
                  : AppColor.grey200),
        ),
      ),
      body: const Row(
        children: [
          Expanded(flex: 28, child: ProductListPanel()),
          Expanded(flex: 72, child: CartPanel()),
        ],
      ),
    );
  }
}