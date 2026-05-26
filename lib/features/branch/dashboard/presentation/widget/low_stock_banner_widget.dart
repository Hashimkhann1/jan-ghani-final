import 'package:flutter/material.dart';
import '../../data/model/dashboard_model.dart';
import '../screen/dashboard_screen.dart';
import 'banner_row_widget.dart';
import 'counter_badge_widget.dart';

class LowStockBanner extends StatelessWidget {
  final int                outOfStock;
  final int                lowStock;
  final List<LowStockItem> items;
  final VoidCallback       onViewAll;

  const LowStockBanner({
    required this.outOfStock,
    required this.lowStock,
    required this.items,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Stock Alert',
                      style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w700,
                          color:      Color(0xFF1A1D23))),
                ),
                if (outOfStock > 0)
                  CountBadge(
                    label: 'Out: $outOfStock',
                    color: const Color(0xFFEF4444),
                    bg:    const Color(0xFFFEF2F2),
                  ),
                if (outOfStock > 0 && lowStock > 0)
                  const SizedBox(width: 6),
                if (lowStock > 0)
                  CountBadge(
                    label: 'Low: $lowStock',
                    color: const Color(0xFFF59E0B),
                    bg:    const Color(0xFFFFFBEB),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onViewAll,
                  child: const Row(
                    children: [
                      Text('View All',
                          style: TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w600,
                              color:      Color(0xFF185FA5))),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: Color(0xFF185FA5)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Preview rows (max 3)
          ...items.map((item) => BannerRow(item: item)),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
