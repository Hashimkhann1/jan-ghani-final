import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/color/app_color.dart';
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
    _qtyCtrl = TextEditingController(text: _fmtQty(item.quantity));
    _priceCtrl = TextEditingController(text: item.salePrice.toStringAsFixed(0));
    _taxCtrl = TextEditingController(text: item.taxAmount.toStringAsFixed(0));
    _disCtrl = TextEditingController(text: item.discountAmount.toStringAsFixed(0));
    _subCtrl = TextEditingController(text: item.subTotal.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(CartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final item = widget.cartItem;

    if (!_qtyFocused) {
      final newQty = _fmtQty(item.quantity);
      if (_qtyCtrl.text != newQty) _qtyCtrl.text = newQty;
    }

    if (!_subFocused) {
      final newSub = item.subTotal.toStringAsFixed(0);
      if (_subCtrl.text != newSub) _subCtrl.text = newSub;
    }

    final newPrice = item.salePrice.toStringAsFixed(0);
    if (_priceCtrl.text != newPrice) _priceCtrl.text = newPrice;

    final newTax = item.taxAmount.toStringAsFixed(0);
    if (_taxCtrl.text != newTax) _taxCtrl.text = newTax;

    final newDis = item.discountAmount.toStringAsFixed(0);
    if (_disCtrl.text != newDis) _disCtrl.text = newDis;
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

  String _fmtQty(double q) => q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  void _commitQty() {
    final val = double.tryParse(_qtyCtrl.text.trim());
    if (val != null && val > 0) {
      ref.read(saleInvoiceProvider.notifier).updateQuantity(widget.cartItem.cartId, val);
    } else {
      _qtyCtrl.text = _fmtQty(widget.cartItem.quantity);
    }
  }

  void _commitPrice() {
    final val = double.tryParse(_priceCtrl.text.trim());
    if (val != null && val >= 0) {
      ref.read(saleInvoiceProvider.notifier).updateSalePrice(widget.cartItem.cartId, val);
    } else {
      _priceCtrl.text = widget.cartItem.salePrice.toStringAsFixed(0);
    }
  }

  void _commitTax() {
    final val = double.tryParse(_taxCtrl.text.trim());
    if (val != null && val >= 0) {
      ref.read(saleInvoiceProvider.notifier).updateTax(widget.cartItem.cartId, val);
    } else {
      _taxCtrl.text = widget.cartItem.taxAmount.toStringAsFixed(0);
    }
  }

  void _commitDis() {
    final val = double.tryParse(_disCtrl.text.trim());
    if (val != null && val >= 0) {
      ref.read(saleInvoiceProvider.notifier).updateDiscount(widget.cartItem.cartId, val);
    } else {
      _disCtrl.text = widget.cartItem.discountAmount.toStringAsFixed(0);
    }
  }

  void _commitSub() {
    final val = double.tryParse(_subCtrl.text.trim());
    if (val != null && val >= 0) {
      ref.read(saleInvoiceProvider.notifier).updateSubTotal(widget.cartItem.cartId, val);
    } else {
      _subCtrl.text = widget.cartItem.subTotal.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(saleInvoiceProvider.notifier);
    final item = widget.cartItem;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Row(children: [
        Expanded(
            flex: 3,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.product.category,
                    style: const TextStyle(fontSize: 9, color: AppColor.textHint),
                  ),
                ])),
        Expanded(
          flex: 2,
          child: _TF(
            controller: _qtyCtrl,
            onFocusChange: (focused) {
              _qtyFocused = focused;
              if (!focused) _commitQty();},
            onSubmitted: (_) => _commitQty(),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val > 0) {
                ref.read(saleInvoiceProvider.notifier).updateQuantity(widget.cartItem.cartId, val);
              }
              },
          ),
        ),
        Expanded(
            flex: 2,
            child: _TF(
              controller: _priceCtrl,
              onFocusChange: (focused) {
                if (!focused) _commitPrice();
              },
              onSubmitted: (_) => _commitPrice(),
              onChanged: (v) {
                final val = double.tryParse(v);
                if (val != null && val >= 0) {
                  ref.read(saleInvoiceProvider.notifier).updateSalePrice(widget.cartItem.cartId, val);
                }
              },
            ),
        ),
        Expanded(
          flex: 2,
          child: _TF(
            controller: _taxCtrl,
            prefix: 'Rs',
            onFocusChange: (focused) {
              if (!focused) _commitTax();},
            onSubmitted: (_) => _commitTax(),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0) {
                ref.read(saleInvoiceProvider.notifier).updateTax(widget.cartItem.cartId, val);
              }},
          ),
        ),
        Expanded(
          flex: 2,
          child: _TF(
              controller: _disCtrl,
              prefix: 'Rs',
              onFocusChange: (focused) {
                if (!focused) _commitDis();
              },
              onSubmitted: (_) => _commitDis(),
              onChanged: (v) {
                final val = double.tryParse(v);
                if (val != null && val >= 0) {
                  ref.read(saleInvoiceProvider.notifier).updateDiscount(widget.cartItem.cartId, val);
                }
              },
            ),
        ),
        Expanded(
            flex: 2,
            child: _TF(
              controller: _subCtrl,
              highlighted: true,
              onFocusChange: (focused) {
                _subFocused = focused;
                if (!focused) _commitSub();
              },
              onSubmitted: (_) => _commitSub(),
              onChanged: (v) {
                final val = double.tryParse(v);
                if (val != null && val >= 0) {
                  ref.read(saleInvoiceProvider.notifier).updateSubTotal(widget.cartItem.cartId, val);
                }
              },
            )),
        GestureDetector(
          onTap: () => notifier.removeFromCart(item.cartId),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColor.errorLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.delete_outline, size: 14, color: AppColor.error),
          ),
        ),
      ]),
    );
  }
}


class _TF extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<bool> onFocusChange;
  final ValueChanged<String> onSubmitted;
  final String? prefix;
  final bool highlighted;
  final ValueChanged<String>? onChanged;

  const _TF({
    required this.controller,
    required this.onFocusChange,
    required this.onSubmitted,
    this.prefix,
    this.highlighted = false,
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
    _focus.addListener(() {
      widget.onFocusChange(_focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextField(
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
          fontSize: 11,
          fontWeight:
          widget.highlighted ? FontWeight.w700 : FontWeight.w400,
          color: widget.highlighted ? AppColor.primary : AppColor.textPrimary,
        ),
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          prefixText:
          widget.prefix != null ? '${widget.prefix} ' : null,
          prefixStyle:
          const TextStyle(fontSize: 9, color: AppColor.textHint),
          isDense: true,
          filled: true,
          fillColor: widget.highlighted ? AppColor.primary.withOpacity(0.06) : AppColor.grey100,
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