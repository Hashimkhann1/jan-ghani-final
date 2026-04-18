// =============================================================
// purchase_invoice_screen.dart
// UPDATED: existingOrder parameter — edit mode support
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/purchase_invoice_model.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_invoice_provider/purchase_invoice_provider.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/widgets/purchase_invoice_widgets/po_cart_panel.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/widgets/purchase_invoice_widgets/po_product_list_panel.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/provider/supplier_provider/supplier_provider.dart';

class PurchaseInvoiceScreen extends ConsumerStatefulWidget {
  /// Null = New PO mode
  /// Set  = Edit mode (pending invoice receive karne ke liye)
  final PurchaseOrderModel? existingOrder;

  const PurchaseInvoiceScreen({
    super.key,
    this.existingOrder,
  });

  @override
  ConsumerState<PurchaseInvoiceScreen> createState() =>
      _PurchaseInvoiceScreenState();
}

class _PurchaseInvoiceScreenState
    extends ConsumerState<PurchaseInvoiceScreen> {

  bool _loaded = false; // ek baar hi load ho

  @override
  void initState() {
    super.initState();

    // Edit mode: pehle frame ke baad data load karo
    if (widget.existingOrder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingOrder();
      });
    }
  }

  void _loadExistingOrder() {
    if (_loaded) return;
    _loaded = true;

    final suppliers =
    ref.read(supplierProvider).allSuppliers
        .where((s) => s.deletedAt == null && s.isActive)
        .map((s) => PoSupplier(
      id:           s.id,
      name:         s.name,
      company:      s.companyName  ?? '',
      phone:        s.phone,
      paymentTerms: s.paymentTerms ?? 30,
    ))
        .toList();

    ref.read(purchaseInvoiceProvider.notifier)
        .loadFromExistingOrder(widget.existingOrder!, suppliers);
  }

  @override
  void dispose() {
    // Screen close hone pe cart clear karo
    // (taake agla new PO fresh start ho)
    // Note: clearCart() automatically _existingOrderId reset karta hai
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingOrder != null;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        children: [
          // ── Top Bar ───────────────────────────────────────
          _TopBar(isEditMode: isEditMode,
              poNumber: widget.existingOrder?.poNumber),

          // ── Main Content ──────────────────────────────────
          Expanded(
            child: Row(
              children: const [
                // Left: Products list
                SizedBox(
                  width: 420,
                  child: PoProductListPanel(),
                ),
                // Right: Cart + summary
                Expanded(
                  child: PoCartPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final bool    isEditMode;
  final String? poNumber;

  const _TopBar({required this.isEditMode, this.poNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color:  AppColor.surface,
        border: Border(
            bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () {
              // Screen pop karne se pehle cart clear karo
              ref.read(purchaseInvoiceProvider.notifier).clearCart();
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        AppColor.grey100,
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(color: AppColor.grey200),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: AppColor.textPrimary),
            ),
          ),
          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditMode ? 'Update Purchase Invoice' : 'New Purchase Invoice',
                style: const TextStyle(
                    fontSize:   20,
                    fontWeight: FontWeight.w700,
                    color:      AppColor.textPrimary),
              ),
              Text(
                isEditMode
                    ? 'PO ${poNumber ?? ''} — update karo ya complete mark karo'
                    : 'Products choose karo aur invoice banao',
                style: const TextStyle(
                    fontSize: 13,
                    color:    AppColor.textSecondary),
              ),
            ],
          ),

          const Spacer(),

          // Edit mode badge
          if (isEditMode)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:        AppColor.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColor.warning.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note_rounded,
                      size: 14, color: AppColor.warning),
                  const SizedBox(width: 6),
                  Text('Edit Mode',
                      style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color:      AppColor.warning)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


// // =============================================================
// // purchase_invoice_screen.dart
// // Sale Invoice Screen ki tarah — bilkul same layout
// // Left (30%): Product List
// // Right (70%): PO Cart Panel
// // =============================================================
//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:jan_ghani_final/core/color/app_color.dart';
// import 'package:jan_ghani_final/features/purchase_invoice/presentation/widgets/purchase_invoice_widgets/po_cart_panel.dart';
// import 'package:jan_ghani_final/features/purchase_invoice/presentation/widgets/purchase_invoice_widgets/po_product_list_panel.dart';
//
//
// class PurchaseInvoiceScreen extends ConsumerWidget {
//   const PurchaseInvoiceScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       backgroundColor: AppColor.background,
//       appBar:          _buildAppBar(context),
//       body: const Row(
//         children: [
//           // ── Left: Product List (30%) ─────────────────────────
//           Expanded(flex: 30, child: PoProductListPanel()),
//
//           // ── Right: PO Cart Panel (70%) ───────────────────────
//           Expanded(flex: 70, child: PoCartPanel()),
//         ],
//       ),
//     );
//   }
//
//   PreferredSizeWidget _buildAppBar(BuildContext context) {
//     return AppBar(
//       backgroundColor:  AppColor.white,
//       elevation:        0,
//       surfaceTintColor: Colors.transparent,
//       titleSpacing:     16,
//       title: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color:        AppColor.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Icon(Icons.shopping_bag_outlined,
//                 color: AppColor.primary, size: 18),
//           ),
//           const SizedBox(width: 10),
//           const Text('Purchase Invoice',
//               style: TextStyle(
//                   fontSize:   16,
//                   fontWeight: FontWeight.w700,
//                   color:      AppColor.textPrimary)),
//         ],
//       ),
//       actions: [
//         // Hint badge
//         Container(
//           margin:  const EdgeInsets.only(right: 8),
//           padding: const EdgeInsets.symmetric(
//               horizontal: 10, vertical: 6),
//           decoration: BoxDecoration(
//             color:        AppColor.infoLight,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: const Row(
//             children: [
//               Icon(Icons.touch_app_outlined,
//                   size: 13, color: AppColor.info),
//               SizedBox(width: 4),
//               Text('Double tap product to add',
//                   style: TextStyle(
//                       fontSize:   11,
//                       color:      AppColor.info,
//                       fontWeight: FontWeight.w500)),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//       ],
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(height: 1, color: AppColor.grey200),
//       ),
//     );
//   }
// }
