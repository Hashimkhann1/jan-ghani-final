// =============================================================
// po_cart_row_widget.dart
// unitCost → purchasePrice
// salePrice default 0
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/purchase_invoice_model.dart';

import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_invoice_provider/purchase_invoice_provider.dart';

class PoCartItemRow extends ConsumerStatefulWidget {
  final PoCartItem cartItem;
  const PoCartItemRow({super.key, required this.cartItem});

  @override
  ConsumerState<PoCartItemRow> createState() =>
      _PoCartItemRowState();
}

class _PoCartItemRowState extends ConsumerState<PoCartItemRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _purchasePriceCtrl;
  late TextEditingController _salePriceCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _disCtrl;
  late TextEditingController _subCtrl;

  bool _qtyFocused = false;
  bool _subFocused = false;

  @override
  void initState() {
    super.initState();
    final item = widget.cartItem;
    _qtyCtrl           = TextEditingController(
        text: _fmtQty(item.quantity));
    _purchasePriceCtrl = TextEditingController(
        text: item.purchasePrice.toStringAsFixed(0));
    _salePriceCtrl     = TextEditingController(
        text: item.salePrice > 0
            ? item.salePrice.toStringAsFixed(0) : '');
    _taxCtrl = TextEditingController(
        text: item.taxAmount.toStringAsFixed(0));
    _disCtrl = TextEditingController(
        text: item.discountAmount.toStringAsFixed(0));
    _subCtrl = TextEditingController(
        text: item.subTotal.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(PoCartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final item = widget.cartItem;

    if (!_qtyFocused) {
      final v = _fmtQty(item.quantity);
      if (_qtyCtrl.text != v) _qtyCtrl.text = v;
    }
    if (!_subFocused) {
      final v = item.subTotal.toStringAsFixed(0);
      if (_subCtrl.text != v) _subCtrl.text = v;
    }

    final newPrice = item.purchasePrice.toStringAsFixed(0);
    if (_purchasePriceCtrl.text != newPrice)
      _purchasePriceCtrl.text = newPrice;

    final newTax = item.taxAmount.toStringAsFixed(0);
    if (_taxCtrl.text != newTax) _taxCtrl.text = newTax;

    final newDis = item.discountAmount.toStringAsFixed(0);
    if (_disCtrl.text != newDis) _disCtrl.text = newDis;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _salePriceCtrl.dispose();
    _taxCtrl.dispose();
    _disCtrl.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  String _fmtQty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  void _commitQty() {
    final val = double.tryParse(_qtyCtrl.text.trim());
    if (val != null && val > 0) {
      ref.read(purchaseInvoiceProvider.notifier)
          .updateQuantity(widget.cartItem.cartId, val);
    } else {
      _qtyCtrl.text = _fmtQty(widget.cartItem.quantity);
    }
  }

  void _commitPrice() {
    final val = double.tryParse(_purchasePriceCtrl.text.trim());
    if (val != null && val >= 0) {
      ref.read(purchaseInvoiceProvider.notifier)
          .updatePurchasePrice(widget.cartItem.cartId, val);
    } else {
      _purchasePriceCtrl.text =
          widget.cartItem.purchasePrice.toStringAsFixed(0);
    }
  }

  void _commitSalePrice() {
    final val = double.tryParse(_salePriceCtrl.text.trim());
    ref.read(purchaseInvoiceProvider.notifier)
        .updateSalePrice(widget.cartItem.cartId, val ?? 0);
  }

  void _commitTax() {
    final val = double.tryParse(_taxCtrl.text.trim());
    if (val != null && val >= 0) {
      ref.read(purchaseInvoiceProvider.notifier)
          .updateTax(widget.cartItem.cartId, val);
    } else {
      _taxCtrl.text =
          widget.cartItem.taxAmount.toStringAsFixed(0);
    }
  }

  void _commitDis() {
    final val = double.tryParse(_disCtrl.text.trim());
    if (val != null && val >= 0) {
      ref.read(purchaseInvoiceProvider.notifier)
          .updateDiscount(widget.cartItem.cartId, val);
    } else {
      _disCtrl.text =
          widget.cartItem.discountAmount.toStringAsFixed(0);
    }
  }

  void _commitSub() {
    final val = double.tryParse(_subCtrl.text.trim());
    if (val != null && val >= 0) {
      ref.read(purchaseInvoiceProvider.notifier)
          .updateSubTotal(widget.cartItem.cartId, val);
    } else {
      _subCtrl.text =
          widget.cartItem.subTotal.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(purchaseInvoiceProvider.notifier);
    final item     = widget.cartItem;
    final margin   = item.marginPercent;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        AppColor.white,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Row(
        children: [
          // Product name + category
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.textPrimary),
                    maxLines:  1,
                    overflow: TextOverflow.ellipsis),
                Text(item.product.category,
                    style: const TextStyle(
                        fontSize: 11,
                        color:    AppColor.textSecondary)),
              ],
            ),
          ),

          // Qty
          Expanded(
            flex: 2,
            child: _TF(
              controller:    _qtyCtrl,
              onFocusChange: (f) {
                _qtyFocused = f;
                if (!f) _commitQty();
              },
              onSubmitted: (_) => _commitQty(),
              onChanged:   (v) {
                final val = double.tryParse(v);
                if (val != null && val > 0) {
                  ref.read(purchaseInvoiceProvider.notifier)
                      .updateQuantity(item.cartId, val);
                }
              },
            ),
          ),

          // Purchase Price
          Expanded(
            flex: 2,
            child: _TF(
              controller:    _purchasePriceCtrl,
              prefix:        'Rs',
              onFocusChange: (f) { if (!f) _commitPrice(); },
              onSubmitted:   (_) => _commitPrice(),
              onChanged:     (v) {
                final val = double.tryParse(v);
                if (val != null && val >= 0) {
                  ref.read(purchaseInvoiceProvider.notifier)
                      .updatePurchasePrice(item.cartId, val);
                }
              },
            ),
          ),

          // Sale Price (purple — optional, default 0)
          Expanded(
            flex: 2,
            child: _TF(
              controller:    _salePriceCtrl,
              prefix:        'Rs',
              isPurple:      true,
              onFocusChange: (f) { if (!f) _commitSalePrice(); },
              onSubmitted:   (_) => _commitSalePrice(),
              onChanged:     (v) {
                final val = double.tryParse(v);
                ref.read(purchaseInvoiceProvider.notifier)
                    .updateSalePrice(item.cartId, val ?? 0);
              },
            ),
          ),

          // Margin badge (auto)
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
                            fontSize:   9,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.success),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const Text('—',
                      style: TextStyle(
                          fontSize: 10,
                          color:    AppColor.textHint),
                      textAlign: TextAlign.center),
            ),
          ),

          // Tax
          Expanded(
            flex: 2,
            child: _TF(
              controller:    _taxCtrl,
              prefix:        'Rs',
              onFocusChange: (f) { if (!f) _commitTax(); },
              onSubmitted:   (_) => _commitTax(),
              onChanged:     (v) {
                final val = double.tryParse(v);
                if (val != null && val >= 0) {
                  ref.read(purchaseInvoiceProvider.notifier)
                      .updateTax(item.cartId, val);
                }
              },
            ),
          ),

          // Discount
          Expanded(
            flex: 2,
            child: _TF(
              controller:    _disCtrl,
              prefix:        'Rs',
              onFocusChange: (f) { if (!f) _commitDis(); },
              onSubmitted:   (_) => _commitDis(),
              onChanged:     (v) {
                final val = double.tryParse(v);
                if (val != null && val >= 0) {
                  ref.read(purchaseInvoiceProvider.notifier)
                      .updateDiscount(item.cartId, val);
                }
              },
            ),
          ),

          // Sub Total (highlighted)
          Expanded(
            flex: 2,
            child: _TF(
              controller:    _subCtrl,
              highlighted:   true,
              onFocusChange: (f) {
                _subFocused = f;
                if (!f) _commitSub();
              },
              onSubmitted: (_) => _commitSub(),
              onChanged:   (v) {
                final val = double.tryParse(v);
                if (val != null && val >= 0) {
                  ref.read(purchaseInvoiceProvider.notifier)
                      .updateSubTotal(item.cartId, val);
                }
              },
            ),
          ),

          // Delete
          GestureDetector(
            onTap: () => notifier.removeFromCart(item.cartId),
            child: Container(
              width:  26,
              height: 26,
              decoration: BoxDecoration(
                color:        AppColor.errorLight,
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

// ─── Reusable Text Field ──────────────────────────────────────

class _TF extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<bool>    onFocusChange;
  final ValueChanged<String>  onSubmitted;
  final String?               prefix;
  final bool                  highlighted;
  final bool                  isPurple;
  final ValueChanged<String>? onChanged;

  const _TF({
    required this.controller,
    required this.onFocusChange,
    required this.onSubmitted,
    this.prefix,
    this.highlighted = false,
    this.isPurple    = false,
    this.onChanged,
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
    _focus.addListener(
        () => widget.onFocusChange(_focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color      fillColor;
    Color      textColor;
    FontWeight fontWeight;

    if (widget.highlighted) {
      fillColor  = AppColor.primary.withOpacity(0.06);
      textColor  = AppColor.primary;
      fontWeight = FontWeight.w700;
    } else if (widget.isPurple) {
      fillColor  = const Color(0xFFEEEDFE);
      textColor  = const Color(0xFF534AB7);
      fontWeight = FontWeight.w600;
    } else {
      fillColor  = AppColor.grey100;
      textColor  = AppColor.textPrimary;
      fontWeight = FontWeight.w400;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextField(
        controller:   widget.controller,
        focusNode:    _focus,
        onSubmitted:  widget.onSubmitted,
        keyboardType: const TextInputType.numberWithOptions(
            decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(r'^\d*\.?\d*'))
        ],
        textAlign:    TextAlign.center,
        cursorHeight: 12,
        onChanged:    widget.onChanged,
        style: TextStyle(
            fontSize:   13,
            fontWeight: fontWeight,
            color:      textColor),
        decoration: InputDecoration(
          prefixText:  widget.prefix != null
              ? '${widget.prefix} ' : null,
          prefixStyle: const TextStyle(
              fontSize: 9, color: AppColor.textHint),
          isDense:    true,
          filled:     true,
          fillColor:  fillColor,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 6, vertical: 10),
          border:        InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
