import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';

class CartItemRow extends ConsumerStatefulWidget {
  final CartItem cartItem;
  const CartItemRow({super.key, required this.cartItem});

  @override
  ConsumerState<CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends ConsumerState<CartItemRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _disCtrl;
  late TextEditingController _subCtrl;

  bool _qtyFocused = false;
  bool _subFocused = false;

  @override
  void initState() {
    super.initState();
    final item = widget.cartItem;
    _qtyCtrl   = TextEditingController(text: _fmtQty(item.quantity));
    _priceCtrl = TextEditingController(text: item.salePrice.toStringAsFixed(0));
    _taxCtrl   = TextEditingController(text: item.taxAmount.toStringAsFixed(0));
    _disCtrl   = TextEditingController(text: item.discountAmount.toStringAsFixed(0));
    _subCtrl   = TextEditingController(text: item.subTotal.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(CartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final item = widget.cartItem;

    if (!_qtyFocused) {
      final q = _fmtQty(item.quantity);
      if (_qtyCtrl.text != q) _qtyCtrl.text = q;
    }
    if (!_subFocused) {
      final s = item.subTotal.toStringAsFixed(0);
      if (_subCtrl.text != s) _subCtrl.text = s;
    }
    final p = item.salePrice.toStringAsFixed(0);
    if (_priceCtrl.text != p) _priceCtrl.text = p;
    final t = item.taxAmount.toStringAsFixed(0);
    if (_taxCtrl.text != t) _taxCtrl.text = t;
    final d = item.discountAmount.toStringAsFixed(0);
    if (_disCtrl.text != d) _disCtrl.text = d;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
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
      ref.read(saleInvoiceProvider.notifier)
          .updateQuantity(widget.cartItem.cartId, val);
    } else {
      _qtyCtrl.text = _fmtQty(widget.cartItem.quantity);
    }
  }

  void _commitPrice() {
    final val = double.tryParse(_priceCtrl.text.trim());
    if (val != null && val >= 0) {
      ref.read(saleInvoiceProvider.notifier)
          .updateSalePrice(widget.cartItem.cartId, val);
    } else {
      _priceCtrl.text = widget.cartItem.salePrice.toStringAsFixed(0);
    }
  }

  void _commitTax() {
    final val = double.tryParse(_taxCtrl.text.trim());
    if (val != null && val >= 0) {
      ref.read(saleInvoiceProvider.notifier)
          .updateTax(widget.cartItem.cartId, val);
    } else {
      _taxCtrl.text = widget.cartItem.taxAmount.toStringAsFixed(0);
    }
  }

  void _commitDis() {
    final val = double.tryParse(_disCtrl.text.trim());
    if (val != null && val >= 0) {
      ref.read(saleInvoiceProvider.notifier)
          .updateDiscount(widget.cartItem.cartId, val);
    } else {
      _disCtrl.text = widget.cartItem.discountAmount.toStringAsFixed(0);
    }
  }

  void _commitSub() {
    final val = double.tryParse(_subCtrl.text.trim());
    if (val != null && val >= 0) {
      ref.read(saleInvoiceProvider.notifier)
          .updateSubTotal(widget.cartItem.cartId, val);
    } else {
      _subCtrl.text = widget.cartItem.subTotal.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(saleInvoiceProvider.notifier);
    final item     = widget.cartItem;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:        AppColor.white,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Row(children: [

        // Product Name + SKU
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(
                    fontSize:   13,  // was 11
                    fontWeight: FontWeight.w600,
                    color:      AppColor.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.product.sku,
                style: const TextStyle(
                    fontSize: 10,   // was 9
                    color:    AppColor.textHint),
              ),
            ],
          ),
        ),

        // Qty
        Expanded(
          flex: 2,
          child: _TF(
            controller: _qtyCtrl,
            onFocusChange: (f) {
              _qtyFocused = f;
              if (!f) _commitQty();
            },
            onSubmitted: (_) => _commitQty(),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val > 0) {
                notifier.updateQuantity(item.cartId, val);
              }
            },
          ),
        ),

        // Price
        Expanded(
          flex: 2,
          child: _TF(
            controller: _priceCtrl,
            onFocusChange: (f) { if (!f) _commitPrice(); },
            onSubmitted: (_) => _commitPrice(),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0) {
                notifier.updateSalePrice(item.cartId, val);
              }
            },
          ),
        ),

        // Tax
        Expanded(
          flex: 2,
          child: _TF(
            controller: _taxCtrl,
            prefix: 'Rs',
            onFocusChange: (f) { if (!f) _commitTax(); },
            onSubmitted: (_) => _commitTax(),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0) {
                notifier.updateTax(item.cartId, val);
              }
            },
          ),
        ),

        // Discount
        Expanded(
          flex: 2,
          child: _TF(
            controller: _disCtrl,
            prefix: 'Rs',
            onFocusChange: (f) { if (!f) _commitDis(); },
            onSubmitted: (_) => _commitDis(),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0) {
                notifier.updateDiscount(item.cartId, val);
              }
            },
          ),
        ),

        // Sub Total (highlighted, editable)
        Expanded(
          flex: 2,
          child: _TF(
            controller: _subCtrl,
            highlighted: true,
            onFocusChange: (f) {
              _subFocused = f;
              if (!f) _commitSub();
            },
            onSubmitted: (_) => _commitSub(),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0) {
                notifier.updateSubTotal(item.cartId, val);
              }
            },
          ),
        ),

        // Delete
        GestureDetector(
          onTap: () => notifier.removeFromCart(item.cartId),
          child: Container(
            width:  28,
            height: 28,
            decoration: BoxDecoration(
              color:        AppColor.errorLight,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.delete_outline, size: 15, color: AppColor.error),
          ),
        ),
      ]),
    );
  }
}

// ── Inline Text Field ─────────────────────────────────────────
class _TF extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<bool>    onFocusChange;
  final ValueChanged<String>  onSubmitted;
  final ValueChanged<String>? onChanged;
  final String?               prefix;
  final bool                  highlighted;

  const _TF({
    required this.controller,
    required this.onFocusChange,
    required this.onSubmitted,
    this.onChanged,
    this.prefix,
    this.highlighted = false,
  });

  @override
  State<_TF> createState() => _TFState();
}

class _TFState extends State<_TF> {
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() => widget.onFocusChange(_focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: TextField(
      controller:      widget.controller,
      focusNode:       _focus,
      onSubmitted:     widget.onSubmitted,
      onChanged:       widget.onChanged,
      keyboardType:    const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      textAlign: TextAlign.center,
      cursorHeight: 14,
      style: TextStyle(
        fontSize:   13,   // was 11
        fontWeight: widget.highlighted ? FontWeight.w700 : FontWeight.w500,
        color:      widget.highlighted ? AppColor.primary : AppColor.textPrimary,
      ),
      decoration: InputDecoration(
        prefixText:  widget.prefix != null ? '${widget.prefix} ' : null,
        prefixStyle: const TextStyle(
            fontSize: 10,   // was 9
            color:    AppColor.textHint),
        isDense:     true,
        filled:      true,
        fillColor:   widget.highlighted
            ? AppColor.primary.withOpacity(0.07)
            : AppColor.grey100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
        border:        InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:   BorderSide(
            color: widget.highlighted ? AppColor.primary : AppColor.grey400,
            width: 1.2,
          ),
        ),
      ),
    ),
  );
}