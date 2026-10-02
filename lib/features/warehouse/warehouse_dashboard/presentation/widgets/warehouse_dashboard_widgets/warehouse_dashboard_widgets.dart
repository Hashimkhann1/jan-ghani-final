// Updated on 2026-10-02 09:35 AM
// =============================================================
// warehouse_dashboard_widgets.dart
// Dashboard ke reusable small widgets:
//   - DashStatCard       — top 4 summary cards
//   - SectionCard        — card wrapper with header + footer
// (Warehouse reports bhi yahi do widgets use karti hain)
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

// ─────────────────────────────────────────────────────────────
// DASH STAT CARD — top mein 4 cards
// ─────────────────────────────────────────────────────────────

class DashStatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final String?  badge;         // top-right badge text
  final IconData icon;
  final Color    color;
  final double   barPercent;    // 0.0 to 1.0

  const DashStatCard({
    super.key,
    required this.label,
    required this.value,
    this.badge,
    required this.icon,
    required this.color,
    this.barPercent = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppColor.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: AppColor.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 17),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:        color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(badge!,
                        style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w600, color: color)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Value
            Text(value,
                style: TextStyle(fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary)),
            const SizedBox(height: 3),

            // Label
            Text(label,
                style: TextStyle(fontSize: 12,
                    color: AppColor.textSecondary)),
            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value:            barPercent,
                minHeight:        3,
                backgroundColor:  AppColor.grey200,
                valueColor:       AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION CARD — card wrapper with header + optional footer
// ─────────────────────────────────────────────────────────────

class SectionCard extends StatelessWidget {
  final Widget       headerIcon;
  final String       title;
  final Widget?      headerTrailing;
  final List<Widget> children;
  final String?      footerLeft;
  final String?      footerRight;
  final VoidCallback? onFooterRightTap;

  const SectionCard({
    super.key,
    required this.headerIcon,
    required this.title,
    this.headerTrailing,
    required this.children,
    this.footerLeft,
    this.footerRight,
    this.onFooterRightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColor.grey200)),
              ),
              child: Row(
                children: [
                  headerIcon,
                  const SizedBox(width: 8),
                  Text(title,
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary)),
                  const Spacer(),
                  if (headerTrailing != null) headerTrailing!,
                ],
              ),
            ),

            // Content rows
            ...children,

            // Footer
            if (footerLeft != null || footerRight != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppColor.grey100)),
                ),
                child: Row(
                  children: [
                    if (footerLeft != null)
                      Text(footerLeft!,
                          style: TextStyle(fontSize: 11,
                              color: AppColor.textSecondary)),
                    const Spacer(),
                    if (footerRight != null)
                      GestureDetector(
                        onTap: onFooterRightTap,
                        child: Text(footerRight!,
                            style: TextStyle(fontSize: 11,
                                color: AppColor.textSecondary)),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
