


import 'package:flutter/material.dart';

import '../../data/model/dashboard_model.dart';

class BannerRow extends StatelessWidget {
  final LowStockItem item;
  const BannerRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isOut = item.status == StockStatus.outOfStock;
    final tagColor = isOut ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final tagBg    = isOut ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width:  8,
            height: 8,
            decoration:
            BoxDecoration(color: tagColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.name,
                style: const TextStyle(
                    fontSize:   12,
                    color:      Color(0xFF374151),
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            'Qty: ${item.quantity.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      tagColor),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: tagBg, borderRadius: BorderRadius.circular(5)),
            child: Text(
              isOut ? 'Out' : 'Low',
              style: TextStyle(
                  fontSize:   9,
                  fontWeight: FontWeight.w700,
                  color:      tagColor),
            ),
          ),
        ],
      ),
    );
  }
}
