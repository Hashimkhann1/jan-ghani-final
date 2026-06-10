// =============================================================
// linked_store_product_row.dart
// Single product row — linked store inventory list ke liye.
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/inventory/data/models/linked_store_product_model.dart';

class LinkedStoreProductRow extends StatelessWidget {
  final LinkedStoreProduct product;
  final bool isLast;
  const LinkedStoreProductRow({super.key, required this.product, this.isLast = false});

  static String _qty(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final p = product;

    final String badge;
    final Color color;
    final Color bg;
    if (p.isOut) {
      badge = 'Out';  color = AppColor.error;   bg = AppColor.errorLight;
    } else if (p.isLow) {
      badge = 'Low';  color = AppColor.warning; bg = AppColor.warningLight;
    } else {
      badge = 'OK';   color = AppColor.success;  bg = AppColor.successLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Row(
        children: [
          // Name + SKU
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.productName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('SKU: ${p.sku ?? '—'}',
                    style: const TextStyle(fontSize: 10, color: AppColor.textHint),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Stock / Min
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: _qty(p.stock),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                    TextSpan(text: p.unit == null ? '' : ' ${p.unit}',
                        style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
                  ]),
                ),
                const SizedBox(height: 2),
                Text('Min: ${_qty(p.minStock)}',
                    style: const TextStyle(fontSize: 9, color: AppColor.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Sale price
          Expanded(
            flex: 3,
            child: Text('Rs ${p.salePrice.pkrFormat}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
          ),
          const SizedBox(width: 8),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Text(badge,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}
