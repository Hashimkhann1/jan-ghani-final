// lib/features/sale_invoice/presentation/widget/cart_table_header_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/color/app_color.dart';
import '../provider/sale_invoice_provider.dart';

class CartTableHeader extends ConsumerWidget {
  const CartTableHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digital = ref.watch(saleInvoiceProvider.select((s) => s.hasDigital));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Expanded(flex: 1, child: _H(text: '#', textAlign: TextAlign.start)),
        Expanded(flex: 3, child: _H(text: 'Product', textAlign: TextAlign.start)),
        Expanded(flex: 2, child: _H(text: digital ? 'Purchase' : 'Qty')),
        Expanded(flex: 2, child: _H(text: 'Price')),
        Expanded(flex: 2, child: _H(text: 'Tax (Rs)')),
        Expanded(flex: 2, child: _H(text: 'Dis (Rs)')),
        Expanded(flex: 2, child: _H(text: 'Sub Total')),
        const SizedBox(width: 28),
      ]),
    );
  }
}

class _H extends StatelessWidget {
  final String?    text;
  final TextAlign? textAlign;

  const _H({this.text, this.textAlign});

  @override
  Widget build(BuildContext context) => Text(
    text.toString(),
    style: const TextStyle(
      fontSize:   11,    // was 10
      fontWeight: FontWeight.w700,
      color:      AppColor.primary,
      letterSpacing: 0.3,
    ),
    textAlign: textAlign ?? TextAlign.center,
  );
}