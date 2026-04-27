// lib/features/branch/sale_invoice/presentation/widget/cart_row_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/cart_nav_provider.dart';
import '../provider/sale_invoice_provider.dart';

// ── Smart format: whole number → integer, decimal → 2 places ──────
String _fmtNum(double v) =>
    v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

class CartItemRow extends ConsumerStatefulWidget {
  final CartItem cartItem;
  final int      rowIndex;

  const CartItemRow({
    super.key,
    required this.cartItem,
    required this.rowIndex,
  });

  @override
  ConsumerState<CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends ConsumerState<CartItemRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _disCtrl;
  late TextEditingController _subCtrl;

  // One FocusNode per column: 0=qty, 1=price, 2=tax, 3=discount, 4=subtotal
  final _fn = List.generate(5, (_) => FocusNode());

  // Track which fields are focused — guards didUpdateWidget from overwriting
  bool _qtyFocused   = false;
  bool _priceFocused = false;
  bool _taxFocused   = false;
  bool _disFocused   = false;
  bool _subFocused   = false;

  // Last nav state row+col so we don't re-focus on every build
  int _lastNavRow = -1;
  int _lastNavCol = -1;

  @override
  void initState() {
    super.initState();
    final item = widget.cartItem;
    _qtyCtrl   = TextEditingController(text: _fmtNum(item.quantity));
    _priceCtrl = TextEditingController(text: _fmtNum(item.salePrice));
    _taxCtrl   = TextEditingController(text: _fmtNum(item.taxAmount));
    _disCtrl   = TextEditingController(text: _fmtNum(item.discountAmount));
    _subCtrl   = TextEditingController(text: _fmtNum(item.subTotal));

    // ✅ FIX: Focus milne pe cartNavProvider bhi sync karo
    // Taki mouse click ke baad arrow keys sahi position se start hon
    void onFocus(int col, bool hasFocus) {
      switch (col) {
        case 0: setState(() { _qtyFocused   = hasFocus; }); break;
        case 1: setState(() { _priceFocused = hasFocus; }); break;
        case 2: setState(() { _taxFocused   = hasFocus; }); break;
        case 3: setState(() { _disFocused   = hasFocus; }); break;
        case 4: setState(() { _subFocused   = hasFocus; }); break;
      }
      if (hasFocus) {
        // Mouse click ya Tab se focus aaya — nav state sync karo
        ref.read(cartNavProvider.notifier).jumpTo(widget.rowIndex, col);
      }
    }

    for (int col = 0; col < _fn.length; col++) {
      final c = col; // closure ke liye capture
      _fn[c].addListener(() => onFocus(c, _fn[c].hasFocus));
    }
  }

  @override
  void didUpdateWidget(CartItemRow old) {
    super.didUpdateWidget(old);
    final item = widget.cartItem;

    // Only update controllers when field is NOT focused (user not typing)
    if (!_qtyFocused) {
      final q = _fmtNum(item.quantity);
      if (_qtyCtrl.text != q) _qtyCtrl.text = q;
    }
    if (!_priceFocused) {
      final p = _fmtNum(item.salePrice);       // ✅ FIX
      if (_priceCtrl.text != p) _priceCtrl.text = p;
    }
    if (!_taxFocused) {
      final t = _fmtNum(item.taxAmount);        // ✅ FIX
      if (_taxCtrl.text != t) _taxCtrl.text = t;
    }
    if (!_disFocused) {
      final d = _fmtNum(item.discountAmount);   // ✅ FIX
      if (_disCtrl.text != d) _disCtrl.text = d;
    }
    if (!_subFocused) {
      final s = _fmtNum(item.subTotal);         // ✅ FIX
      if (_subCtrl.text != s) _subCtrl.text = s;
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose(); _priceCtrl.dispose(); _taxCtrl.dispose();
    _disCtrl.dispose(); _subCtrl.dispose();
    for (final fn in _fn) { fn.dispose(); }
    super.dispose();
  }

  List<TextEditingController> get _ctrls =>
      [_qtyCtrl, _priceCtrl, _taxCtrl, _disCtrl, _subCtrl];

  void _focusCol(int col) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fn[col].requestFocus();
      final ctrl = _ctrls[col];
      ctrl.selection = TextSelection(
        baseOffset:   0,
        extentOffset: ctrl.text.length,
      );
    });
  }

  // ── Commit ────────────────────────────────────────────────────
  void _commitQty() {
    final v = double.tryParse(_qtyCtrl.text.trim());
    if (v != null && v > 0) {
      ref.read(saleInvoiceProvider.notifier).updateQuantity(widget.cartItem.cartId, v);
    } else {
      _qtyCtrl.text = _fmtNum(widget.cartItem.quantity);
    }
  }

  void _commitPrice() {
    final v = double.tryParse(_priceCtrl.text.trim());
    if (v != null && v >= 0) {
      ref.read(saleInvoiceProvider.notifier).updateSalePrice(widget.cartItem.cartId, v);
    } else {
      _priceCtrl.text = _fmtNum(widget.cartItem.salePrice); // ✅ FIX
    }
  }

  void _commitTax() {
    final v = double.tryParse(_taxCtrl.text.trim());
    if (v != null && v >= 0) {
      ref.read(saleInvoiceProvider.notifier).updateTax(widget.cartItem.cartId, v);
    } else {
      _taxCtrl.text = _fmtNum(widget.cartItem.taxAmount); // ✅ FIX
    }
  }

  void _commitDis() {
    final v = double.tryParse(_disCtrl.text.trim());
    if (v != null && v >= 0) {
      ref.read(saleInvoiceProvider.notifier).updateDiscount(widget.cartItem.cartId, v);
    } else {
      _disCtrl.text = _fmtNum(widget.cartItem.discountAmount); // ✅ FIX
    }
  }

  void _commitSub() {
    final v = double.tryParse(_subCtrl.text.trim());
    if (v != null && v >= 0) {
      ref.read(saleInvoiceProvider.notifier).updateSubTotal(widget.cartItem.cartId, v);
    } else {
      _subCtrl.text = _fmtNum(widget.cartItem.subTotal); // ✅ FIX
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(saleInvoiceProvider.notifier);
    final item     = widget.cartItem;
    final nav      = ref.watch(cartNavProvider);

    final isNavRow = nav.isActive && nav.row == widget.rowIndex;

    // Focus only when nav row+col actually changes — not on every build
    if (isNavRow &&
        (nav.row != _lastNavRow || nav.col != _lastNavCol)) {
      _lastNavRow = nav.row;
      _lastNavCol = nav.col;
      _focusCol(nav.col);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isNavRow ? AppColor.primary.withOpacity(0.05) : AppColor.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNavRow ? AppColor.primary : AppColor.grey200,
          width: isNavRow ? 1.5 : 1.0,
        ),
      ),
      child: Row(children: [

        // Product Name + SKU
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.product.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(item.product.sku,
                  style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
            ],
          ),
        ),

        // Qty
        Expanded(
          flex: 2,
          child: _CellTF(
            controller:  _qtyCtrl,
            focusNode:   _fn[0],
            isNavActive: isNavRow && nav.col == 0,
            onChanged:   (v) {
              final val = double.tryParse(v);
              if (val != null && val > 0)
                notifier.updateQuantity(item.cartId, val);
            },
            onSubmitted: (_) => _commitQty(),
          ),
        ),

        // Price
        Expanded(
          flex: 2,
          child: _CellTF(
            controller:  _priceCtrl,
            focusNode:   _fn[1],
            isNavActive: isNavRow && nav.col == 1,
            onChanged:   (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0)
                notifier.updateSalePrice(item.cartId, val);
            },
            onSubmitted: (_) => _commitPrice(),
          ),
        ),

        // Tax
        Expanded(
          flex: 2,
          child: _CellTF(
            controller:  _taxCtrl,
            focusNode:   _fn[2],
            isNavActive: isNavRow && nav.col == 2,
            prefix:      'Rs',
            onChanged:   (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0)
                notifier.updateTax(item.cartId, val);
            },
            onSubmitted: (_) => _commitTax(),
          ),
        ),

        // Discount
        Expanded(
          flex: 2,
          child: _CellTF(
            controller:  _disCtrl,
            focusNode:   _fn[3],
            isNavActive: isNavRow && nav.col == 3,
            prefix:      'Rs',
            onChanged:   (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0)
                notifier.updateDiscount(item.cartId, val);
            },
            onSubmitted: (_) => _commitDis(),
          ),
        ),

        // SubTotal (highlighted)
        Expanded(
          flex: 2,
          child: _CellTF(
            controller:  _subCtrl,
            focusNode:   _fn[4],
            isNavActive: isNavRow && nav.col == 4,
            highlighted: true,
            onChanged:   (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0)
                notifier.updateSubTotal(item.cartId, val);
            },
            onSubmitted: (_) => _commitSub(),
          ),
        ),

        // Delete
        GestureDetector(
          onTap: () => notifier.removeFromCart(item.cartId),
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: AppColor.errorLight,
                borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.delete_outline, size: 15, color: AppColor.error),
          ),
        ),
      ]),
    );
  }
}

// ── Cell TextField ────────────────────────────────────────────────
class _CellTF extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final bool                  isNavActive;
  final bool                  highlighted;
  final String?               prefix;
  final ValueChanged<String>  onChanged;
  final ValueChanged<String>  onSubmitted;

  const _CellTF({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    this.isNavActive  = false,
    this.highlighted  = false,
    this.prefix,
  });

  @override
  State<_CellTF> createState() => _CellTFState();
}

class _CellTFState extends State<_CellTF> {
  @override
  Widget build(BuildContext context) {
    final Color activeColor = widget.isNavActive
        ? AppColor.primary
        : widget.highlighted
        ? AppColor.primary
        : AppColor.grey400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextField(
        controller:      widget.controller,
        focusNode:       widget.focusNode,
        onChanged:       widget.onChanged,
        onSubmitted:     widget.onSubmitted,
        keyboardType:    const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        textAlign:    TextAlign.center,
        cursorHeight: 14,
        style: TextStyle(
          fontSize:   13,
          fontWeight: widget.highlighted ? FontWeight.w700 : FontWeight.w500,
          color: widget.highlighted ? AppColor.primary : AppColor.textPrimary,
        ),
        decoration: InputDecoration(
          prefixText:  widget.prefix != null ? '${widget.prefix} ' : null,
          prefixStyle: const TextStyle(fontSize: 10, color: AppColor.textHint),
          isDense:     true,
          filled:      true,
          fillColor:   widget.isNavActive
              ? AppColor.primary.withOpacity(0.08)
              : widget.highlighted
              ? AppColor.primary.withOpacity(0.07)
              : AppColor.grey100,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
          border:        InputBorder.none,
          enabledBorder: widget.isNavActive
              ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                  color: AppColor.primary, width: 1.2))
              : InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:   BorderSide(color: activeColor, width: 1.4),
          ),
        ),
      ),
    );
  }
}