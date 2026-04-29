import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/data/models/assign_stock_item_model.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_provider.dart';

class AssignStockCartRow extends ConsumerStatefulWidget {
  final AssignStockCartItem item;

  const AssignStockCartRow({super.key, required this.item});

  @override
  ConsumerState<AssignStockCartRow> createState() =>
      _AssignStockCartRowState();
}

class _AssignStockCartRowState extends ConsumerState<AssignStockCartRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _purchasePriceCtrl;
  late TextEditingController _salePriceCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _disCtrl;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _qtyCtrl = TextEditingController(text: _fmt(i.quantity));
    _purchasePriceCtrl =
        TextEditingController(text: i.purchasePrice.toStringAsFixed(0));
    _salePriceCtrl =
        TextEditingController(text: i.salePrice > 0 ? i.salePrice.toStringAsFixed(0) : '');
    _taxCtrl = TextEditingController(text: i.taxAmount.toStringAsFixed(0));
    _disCtrl = TextEditingController(text: i.discountAmount.toStringAsFixed(0));
  }

  // didUpdateWidget removed intentionally — qty controller ko sync nahi karna
  // warna user ki typed value reset ho jaati thi jab state update hoti thi.

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _salePriceCtrl.dispose();
    _taxCtrl.dispose();
    _disCtrl.dispose();
    super.dispose();
  }

  String _fmt(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(assignStockProvider.notifier);
    final item = widget.item;
    final margin = item.marginPercent;

    // Agar qty available stock se zyada hai tu row red border dikhao
    final isOverStock = item.quantity > item.availableStock;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOverStock
            ? AppColor.errorLight.withOpacity(0.4)
            : AppColor.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverStock ? AppColor.error.withOpacity(0.5) : AppColor.grey200,
          width: isOverStock ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Product name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Text(item.categoryName ?? '-',
                        style: const TextStyle(
                            fontSize: 11, color: AppColor.textSecondary)),
                    if (isOverStock) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Max: ${_fmt(item.availableStock)} ${item.unitOfMeasure}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColor.error,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Qty
          Expanded(
            flex: 2,
            child: _TF(
              controller: _qtyCtrl,
              isError: isOverStock,
              onFocusChange: (f) {
                if (!f) {
                  final val = double.tryParse(_qtyCtrl.text.trim());
                  if (val != null && val > 0) {
                    notifier.updateQuantity(item.cartId, val);
                  }
                }
              },
              onSubmitted: (_) {
                final val = double.tryParse(_qtyCtrl.text.trim());
                if (val != null && val > 0) {
                  notifier.updateQuantity(item.cartId, val);
                }
              },
            ),
          ),

          // Purchase Price
          Expanded(
            flex: 2,
            child: _TF(
              controller: _purchasePriceCtrl,
              enabled: false,
              prefix: 'Rs',
              onFocusChange: (f) {
                if (!f) {
                  final val = double.tryParse(_purchasePriceCtrl.text.trim());
                  if (val != null) notifier.updatePurchasePrice(item.cartId, val);
                }
              },
              onSubmitted: (_) {
                final val = double.tryParse(_purchasePriceCtrl.text.trim());
                if (val != null) notifier.updatePurchasePrice(item.cartId, val);
              },
            ),
          ),

          // Sale Price
          Expanded(
            flex: 2,
            child: _TF(
              controller: _salePriceCtrl,
              enabled: false,
              prefix: 'Rs',
              isPurple: true,
              onFocusChange: (f) {
                if (!f) {
                  final val = double.tryParse(_salePriceCtrl.text.trim());
                  notifier.updateSalePrice(item.cartId, val ?? 0);
                }
              },
              onSubmitted: (_) {
                final val = double.tryParse(_salePriceCtrl.text.trim());
                notifier.updateSalePrice(item.cartId, val ?? 0);
              },
            ),
          ),

          // Margin badge
          SizedBox(
            width: 40,
            child: Center(
              child: margin != null
                  ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColor.successLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${margin.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColor.success),
                  textAlign: TextAlign.center,
                ),
              )
                  : const Text('—',
                  style: TextStyle(fontSize: 10, color: AppColor.textHint),
                  textAlign: TextAlign.center),
            ),
          ),

          // Tax
          Expanded(
            flex: 2,
            child: _TF(
              controller: _taxCtrl,
              enabled: false,
              prefix: 'Rs',
              onFocusChange: (f) {
                if (!f) {
                  final val = double.tryParse(_taxCtrl.text.trim());
                  if (val != null) notifier.updateTax(item.cartId, val);
                }
              },
              onSubmitted: (_) {
                final val = double.tryParse(_taxCtrl.text.trim());
                if (val != null) notifier.updateTax(item.cartId, val);
              },
            ),
          ),

          // Discount
          Expanded(
            flex: 2,
            child: _TF(
              controller: _disCtrl,
              enabled: false,
              prefix: 'Rs',
              onFocusChange: (f) {
                if (!f) {
                  final val = double.tryParse(_disCtrl.text.trim());
                  if (val != null) notifier.updateDiscount(item.cartId, val);
                }
              },
              onSubmitted: (_) {
                final val = double.tryParse(_disCtrl.text.trim());
                if (val != null) notifier.updateDiscount(item.cartId, val);
              },
            ),
          ),

          // Total
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Rs ${item.totalCost.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Delete
          GestureDetector(
            onTap: () => notifier.removeFromCart(item.cartId),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColor.errorLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.delete_outline,
                  size: 14, color: AppColor.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _TF extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<bool> onFocusChange;
  final ValueChanged<String> onSubmitted;
  final String? prefix;
  final bool isPurple;
  final bool? enabled;
  final bool isError;

  const _TF({
    required this.controller,
    required this.onFocusChange,
    required this.onSubmitted,
    this.prefix,
    this.isPurple = false,
    this.enabled = true,
    this.isError = false,
  });

  @override
  State<_TF> createState() => _TFState();
}

class _TFState extends State<_TF> {
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(() => widget.onFocusChange(_focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color fillColor;
    Color textColor;
    FontWeight fontWeight;

    if (widget.isError) {
      fillColor = AppColor.error.withOpacity(0.08);
      textColor = AppColor.error;
      fontWeight = FontWeight.w600;
    } else if (widget.isPurple) {
      fillColor = const Color(0xFFEEEDFE);
      textColor = const Color(0xFF534AB7);
      fontWeight = FontWeight.w600;
    } else {
      fillColor = AppColor.grey100;
      textColor = AppColor.textPrimary;
      fontWeight = FontWeight.w400;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextField(
        enabled: widget.enabled,
        controller: widget.controller,
        focusNode: _focus,
        onSubmitted: widget.onSubmitted,
        keyboardType:
        const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        ],
        textAlign: TextAlign.center,
        cursorHeight: 12,
        style: TextStyle(
            fontSize: 13, fontWeight: fontWeight, color: textColor),
        decoration: InputDecoration(
          prefixText: widget.prefix != null ? '${widget.prefix} ' : null,
          prefixStyle:
          const TextStyle(fontSize: 9, color: AppColor.textHint),
          isDense: true,
          filled: true,
          fillColor: fillColor,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:jan_ghani_final/core/color/app_color.dart';
// import 'package:jan_ghani_final/features/warehouse/assign_stock/data/models/assign_stock_item_model.dart';
// import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_provider.dart';
//
// class AssignStockCartRow extends ConsumerStatefulWidget {
//   final AssignStockCartItem item;
//
//   const AssignStockCartRow({super.key, required this.item});
//
//   @override
//   ConsumerState<AssignStockCartRow> createState() =>
//       _AssignStockCartRowState();
// }
//
// class _AssignStockCartRowState extends ConsumerState<AssignStockCartRow> {
//   late TextEditingController _qtyCtrl;
//   late TextEditingController _purchasePriceCtrl;
//   late TextEditingController _salePriceCtrl;
//   late TextEditingController _taxCtrl;
//   late TextEditingController _disCtrl;
//
//   bool _qtyFocused = false;
//
//   @override
//   void initState() {
//     super.initState();
//     final i = widget.item;
//     _qtyCtrl = TextEditingController(text: _fmt(i.quantity));
//     _purchasePriceCtrl =
//         TextEditingController(text: i.purchasePrice.toStringAsFixed(0));
//     _salePriceCtrl =
//         TextEditingController(text: i.salePrice > 0 ? i.salePrice.toStringAsFixed(0) : '');
//     _taxCtrl = TextEditingController(text: i.taxAmount.toStringAsFixed(0));
//     _disCtrl = TextEditingController(text: i.discountAmount.toStringAsFixed(0));
//   }
//
//   @override
//   void didUpdateWidget(AssignStockCartRow oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (!_qtyFocused) {
//       final v = _fmt(widget.item.quantity);
//       if (_qtyCtrl.text != v) _qtyCtrl.text = v;
//     }
//   }
//
//   @override
//   void dispose() {
//     _qtyCtrl.dispose();
//     _purchasePriceCtrl.dispose();
//     _salePriceCtrl.dispose();
//     _taxCtrl.dispose();
//     _disCtrl.dispose();
//     super.dispose();
//   }
//
//   String _fmt(double q) =>
//       q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);
//
//   @override
//   Widget build(BuildContext context) {
//     final notifier = ref.read(assignStockProvider.notifier);
//     final item = widget.item;
//     final margin = item.marginPercent;
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       decoration: BoxDecoration(
//         color: AppColor.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: AppColor.grey200),
//       ),
//       child: Row(
//         children: [
//           // Product name
//           Expanded(
//             flex: 3,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(item.productName,
//                     style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: AppColor.textPrimary),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis),
//                 Text(item.categoryName ?? '-',
//                     style: const TextStyle(
//                         fontSize: 11, color: AppColor.textSecondary)),
//               ],
//             ),
//           ),
//
//           // Qty
//           Expanded(
//             flex: 2,
//             child: _TF(
//               controller: _qtyCtrl,
//               onFocusChange: (f) {
//                 _qtyFocused = f;
//                 if (!f) {
//                   final val = double.tryParse(_qtyCtrl.text.trim());
//                   if (val != null && val > 0) {
//                     notifier.updateQuantity(item.cartId, val);
//                   }
//                 }
//               },
//               onSubmitted: (_) {
//                 final val = double.tryParse(_qtyCtrl.text.trim());
//                 if (val != null && val > 0) {
//                   notifier.updateQuantity(item.cartId, val);
//                 }
//               },
//             ),
//           ),
//
//           // Purchase Price
//           Expanded(
//             flex: 2,
//             child: _TF(
//               controller: _purchasePriceCtrl,
//               enabled: false,
//               prefix: 'Rs',
//               onFocusChange: (f) {
//                 if (!f) {
//                   final val = double.tryParse(_purchasePriceCtrl.text.trim());
//                   if (val != null) notifier.updatePurchasePrice(item.cartId, val);
//                 }
//               },
//               onSubmitted: (_) {
//                 final val = double.tryParse(_purchasePriceCtrl.text.trim());
//                 if (val != null) notifier.updatePurchasePrice(item.cartId, val);
//               },
//             ),
//           ),
//
//           // Sale Price
//           Expanded(
//             flex: 2,
//             child: _TF(
//               controller: _salePriceCtrl,
//               enabled: false,
//               prefix: 'Rs',
//               isPurple: true,
//               onFocusChange: (f) {
//                 if (!f) {
//                   final val = double.tryParse(_salePriceCtrl.text.trim());
//                   notifier.updateSalePrice(item.cartId, val ?? 0);
//                 }
//               },
//               onSubmitted: (_) {
//                 final val = double.tryParse(_salePriceCtrl.text.trim());
//                 notifier.updateSalePrice(item.cartId, val ?? 0);
//               },
//             ),
//           ),
//
//           // Margin badge
//           SizedBox(
//             width: 40,
//             child: Center(
//               child: margin != null
//                   ? Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 4, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: AppColor.successLight,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   '${margin.toStringAsFixed(0)}%',
//                   style: const TextStyle(
//                       fontSize: 9,
//                       fontWeight: FontWeight.w600,
//                       color: AppColor.success),
//                   textAlign: TextAlign.center,
//                 ),
//               )
//                   : const Text('—',
//                   style: TextStyle(fontSize: 10, color: AppColor.textHint),
//                   textAlign: TextAlign.center),
//             ),
//           ),
//
//           // Tax
//           Expanded(
//             flex: 2,
//             child: _TF(
//               controller: _taxCtrl,
//               enabled: false,
//               prefix: 'Rs',
//               onFocusChange: (f) {
//                 if (!f) {
//                   final val = double.tryParse(_taxCtrl.text.trim());
//                   if (val != null) notifier.updateTax(item.cartId, val);
//                 }
//               },
//               onSubmitted: (_) {
//                 final val = double.tryParse(_taxCtrl.text.trim());
//                 if (val != null) notifier.updateTax(item.cartId, val);
//               },
//             ),
//           ),
//
//           // Discount
//           Expanded(
//             flex: 2,
//             child: _TF(
//               controller: _disCtrl,
//               enabled: false,
//               prefix: 'Rs',
//               onFocusChange: (f) {
//                 if (!f) {
//                   final val = double.tryParse(_disCtrl.text.trim());
//                   if (val != null) notifier.updateDiscount(item.cartId, val);
//                 }
//               },
//               onSubmitted: (_) {
//                 final val = double.tryParse(_disCtrl.text.trim());
//                 if (val != null) notifier.updateDiscount(item.cartId, val);
//               },
//             ),
//           ),
//
//           // Total
//           Expanded(
//             flex: 2,
//             child: Container(
//               margin: const EdgeInsets.symmetric(horizontal: 3),
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
//               decoration: BoxDecoration(
//                 color: AppColor.primary.withOpacity(0.06),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Text(
//                 'Rs ${item.totalCost.toStringAsFixed(0)}',
//                 style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: AppColor.primary),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ),
//
//           // Delete
//           GestureDetector(
//             onTap: () => notifier.removeFromCart(item.cartId),
//             child: Container(
//               width: 26,
//               height: 26,
//               decoration: BoxDecoration(
//                 color: AppColor.errorLight,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: const Icon(Icons.delete_outline,
//                   size: 14, color: AppColor.error),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _TF extends StatefulWidget {
//   final TextEditingController controller;
//   final ValueChanged<bool> onFocusChange;
//   final ValueChanged<String> onSubmitted;
//   final String? prefix;
//   final bool isPurple;
//   final bool? enabled;
//
//   const _TF({
//     required this.controller,
//     required this.onFocusChange,
//     required this.onSubmitted,
//     this.prefix,
//     this.isPurple = false,
//     this.enabled = true,
//   });
//
//   @override
//   State<_TF> createState() => _TFState();
// }
//
// class _TFState extends State<_TF> {
//   late FocusNode _focus;
//
//   @override
//   void initState() {
//     super.initState();
//     _focus = FocusNode();
//     _focus.addListener(() => widget.onFocusChange(_focus.hasFocus));
//   }
//
//   @override
//   void dispose() {
//     _focus.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final fillColor = widget.isPurple
//         ? const Color(0xFFEEEDFE)
//         : AppColor.grey100;
//     final textColor = widget.isPurple
//         ? const Color(0xFF534AB7)
//         : AppColor.textPrimary;
//     final fontWeight =
//     widget.isPurple ? FontWeight.w600 : FontWeight.w400;
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 3),
//       child: TextField(
//         enabled: widget.enabled,
//         controller: widget.controller,
//         focusNode: _focus,
//         onSubmitted: widget.onSubmitted,
//         keyboardType:
//         const TextInputType.numberWithOptions(decimal: true),
//         inputFormatters: [
//           FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
//         ],
//         textAlign: TextAlign.center,
//         cursorHeight: 12,
//         style: TextStyle(
//             fontSize: 13, fontWeight: fontWeight, color: textColor),
//         decoration: InputDecoration(
//           prefixText: widget.prefix != null ? '${widget.prefix} ' : null,
//           prefixStyle:
//           const TextStyle(fontSize: 9, color: AppColor.textHint),
//           isDense: true,
//           filled: true,
//           fillColor: fillColor,
//           contentPadding:
//           const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
//           border: InputBorder.none,
//           enabledBorder: InputBorder.none,
//           focusedBorder: InputBorder.none,
//         ),
//       ),
//     );
//   }
// }