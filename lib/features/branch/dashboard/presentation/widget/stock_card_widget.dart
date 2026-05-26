import 'package:flutter/material.dart';

import '../../data/model/dashboard_model.dart';
import 'chip_widget.dart';

class StockCard extends StatelessWidget {
  final LowStockItem item;
  const StockCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isOut    = item.status == StockStatus.outOfStock;
    final tagColor = isOut ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final tagBg    = isOut ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final tagLabel = isOut ? 'Out of Stock' : 'Low Stock';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width:  44,
            height: 44,
            decoration: BoxDecoration(
                color: tagBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(
              isOut
                  ? Icons.remove_shopping_cart_outlined
                  : Icons.warning_amber_rounded,
              color: tagColor,
              size:  22,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      Color(0xFF1A1D23)),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  'SKU: ${item.sku}'
                      '${item.barcode != null ? '  •  ${item.barcode}' : ''}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ChipWidget(
                      label: 'Stock: ${item.quantity.toStringAsFixed(0)} ${item.unit}',
                      color: tagColor,
                      bg:    tagBg,
                    ),
                    const SizedBox(width: 6),
                    ChipWidget(
                      label: 'Min: ${item.minStock.toStringAsFixed(0)}',
                      color: const Color(0xFF6B7280),
                      bg:    const Color(0xFFF3F4F6),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Price + Tag
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(tagLabel,
                    style: TextStyle(
                        fontSize:   10,
                        fontWeight: FontWeight.w600,
                        color:      tagColor)),
              ),
              const SizedBox(height: 6),
              Text(
                'Rs ${item.sellingPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      Color(0xFF1A1D23)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
