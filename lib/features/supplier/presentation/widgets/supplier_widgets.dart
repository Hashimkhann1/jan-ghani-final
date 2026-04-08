// =============================================================
// supplier_widgets.dart
// Reusable small widgets — sirf supplier feature ke liye
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/supplier/domian/supplier_model.dart';

// ─────────────────────────────────────────────────────────────
// STAT CARD — top mein 4 summary numbers dikhata hai
// ─────────────────────────────────────────────────────────────

class SupplierStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const SupplierStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Value + label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize:   18,
                    fontWeight: FontWeight.w700,
                    color:      AppColor.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: AppColor.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER CHIP — All / Active / Inactive tabs
// ─────────────────────────────────────────────────────────────

class SupplierFilterChip extends StatelessWidget {
  final String label;
  final String value;         // 'all' | 'active' | 'inactive'
  final String selectedValue; // current selected filter
  final ValueChanged<String> onTap;

  const SupplierFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:        isSelected ? AppColor.primary : AppColor.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColor.primary : AppColor.grey300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w500,
            color:      isSelected ? AppColor.white : AppColor.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATUS BADGE — Active / Inactive dot ke saath
// ─────────────────────────────────────────────────────────────

class SupplierStatusBadge extends StatelessWidget {
  final bool isActive;

  const SupplierStatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColor.success : AppColor.grey400;
    final bgColor = isActive ? AppColor.successLight : AppColor.grey200;
    final label = isActive ? 'Active' : 'Inactive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Online dot
          Container(
            width:  6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BALANCE BADGE — Due / Clear badge
// supplier_ledger se computed balance dikhata hai
// ─────────────────────────────────────────────────────────────

class SupplierBalanceBadge extends StatelessWidget {
  final SupplierModel supplier;

  const SupplierBalanceBadge({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    // Balance color logic:
    //  hasDue → red (hum ne dena hai supplier ko)
    //  isClear → grey (kuch nahi banta)
    final Color badgeColor;
    if (supplier.hasDue) {
      badgeColor = AppColor.error;
    } else {
      badgeColor = AppColor.grey500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        badgeColor.withOpacity(0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        supplier.balanceLabel,
        style: TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.w600,
          color:      badgeColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTION BUTTON — Edit / Delete hover actions
// ─────────────────────────────────────────────────────────────

class SupplierActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const SupplierActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AVATAR — Supplier naam ka pehla letter
// ─────────────────────────────────────────────────────────────

class SupplierAvatar extends StatelessWidget {
  final String name;

  const SupplierAvatar({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  38,
      height: 38,
      decoration: BoxDecoration(
        color:        AppColor.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color:      AppColor.primary,
          fontSize:   15,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAYMENT TERMS BADGE — credit days dikhata hai
// ─────────────────────────────────────────────────────────────

class PaymentTermsBadge extends StatelessWidget {
  final int days;

  const PaymentTermsBadge({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        AppColor.infoLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$days days',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w500,
          color:      AppColor.info,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE — koi supplier na mile tab
// ─────────────────────────────────────────────────────────────

class SupplierEmptyState extends StatelessWidget {
  final bool isSearching; // search chal rahi hai ya bilkul koi nahi

  const SupplierEmptyState({super.key, required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            size:  56,
            color: AppColor.grey300,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching ? 'Koi supplier nahi mila' : 'Abhi tak koi supplier nahi',
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      AppColor.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSearching
                ? 'Search ya filter change karein'
                : 'New Supplier button se add karein',
            style: TextStyle(fontSize: 13, color: AppColor.textHint),
          ),
        ],
      ),
    );
  }
}