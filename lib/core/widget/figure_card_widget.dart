import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';

class SummaryCard extends StatelessWidget {
  final String    title;
  final String    value;
  final IconData  icon;
  final Color     color;

  /// Diya jaye to Material [icon] ki jagah `assets/branch_icons/<iconAsset>.svg`
  /// render hota hai (card ke `color` se tinted).
  final String?   iconAsset;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.icon = Icons.circle,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: iconAsset != null
                  ? AppIcon(iconAsset!, color: color, size: 20)
                  : Icon(icon, color: color, size: 20),
            ),
           Column(
             children: [
               Text(
                 value,
                 style: TextStyle(
                   fontSize: 22,
                   fontWeight: FontWeight.w800,
                   color: const Color(0xFF1A1D23),
                 ),
               ),
               // const SizedBox(height: 2),
               Text(
                 title,
                 style: const TextStyle(
                   fontSize: 11,
                   color: Color(0xFF9CA3AF),
                   fontWeight: FontWeight.w500,
                 ),
               ),
             ],
           )
          ],
        ),
      ),
    );
  }
}
