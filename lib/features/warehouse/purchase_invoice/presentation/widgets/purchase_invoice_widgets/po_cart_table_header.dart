// =============================================================
// po_cart_table_header.dart
// Columns: Product | Qty | Purchase Price | Sale Price | Margin | Tax | Dis | Sub Total
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

class PoCartTableHeader extends StatelessWidget {
  const PoCartTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        AppColor.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3,
              child: _H(text: 'Product',
                  textAlign: TextAlign.start)),
          Expanded(flex: 2, child: _H(text: 'Qty')),
          Expanded(flex: 2,
              child: _H(text: 'Purchase Price')),
          Expanded(flex: 2,
              child: _H(text: 'Sale Price', isPurple: true)),
          SizedBox(width: 40,
              child: _H(text: 'Margin')),
          Expanded(flex: 2, child: _H(text: 'Tax (Rs)')),
          Expanded(flex: 2, child: _H(text: 'Dis (Rs)')),
          Expanded(flex: 2, child: _H(text: 'Sub Total')),
          SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String?    text;
  final TextAlign? textAlign;
  final bool       isPurple;

  const _H({this.text, this.textAlign, this.isPurple = false});

  @override
  Widget build(BuildContext context) => Text(
        text.toString(),
        style: TextStyle(
          fontSize:      10,
          fontWeight:    FontWeight.w700,
          color: isPurple
              ? const Color(0xFF534AB7) : AppColor.primary,
          letterSpacing: 0.3,
        ),
        textAlign: textAlign ?? TextAlign.center,
      );
}
