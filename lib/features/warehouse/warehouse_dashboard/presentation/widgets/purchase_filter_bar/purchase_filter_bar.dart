import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/domain/warehouse_dashboard_models.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/provider/warehouse_dashboard_provider.dart';


class PurchaseFilterBar extends ConsumerWidget {
  const PurchaseFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(warehouseDashboardProvider);
    final notifier = ref.read(warehouseDashboardProvider.notifier);
    final active   = state.activeFilter;

    return Row(
      children: [
        // ── Filter chips ──────────────────────────────────
        _FilterChip(
          label:    'Today',
          isActive: active == PurchaseDateFilter.today,
          onTap:    () => notifier.applyFilter(PurchaseDateFilter.today),
        ),
        const SizedBox(width: 6),
        _FilterChip(
          label:    'This Week',
          isActive: active == PurchaseDateFilter.thisWeek,
          onTap:    () => notifier.applyFilter(PurchaseDateFilter.thisWeek),
        ),
        const SizedBox(width: 6),
        _FilterChip(
          label:    'This Month',
          isActive: active == PurchaseDateFilter.thisMonth,
          onTap:    () => notifier.applyFilter(PurchaseDateFilter.thisMonth),
        ),
        const SizedBox(width: 6),
        _FilterChip(
          label:    'Last 3 Months',
          isActive: active == PurchaseDateFilter.last3Months,
          onTap:    () => notifier.applyFilter(PurchaseDateFilter.last3Months),
        ),
        const SizedBox(width: 6),

        // ── Custom date picker ────────────────────────────
        _CustomDateChip(
          isActive:   active == PurchaseDateFilter.custom,
          dateFrom:   state.customFrom,
          dateTo:     state.customTo,
          onSelected: (from, to) => notifier.applyCustomRange(from, to),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER CHIP
// ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String   label;
  final bool     isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColor.primary
              : AppColor.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColor.warning
                : AppColor.grey200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color: isActive
                ? AppColor.white
                : AppColor.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CUSTOM DATE CHIP — date picker opens karta hai
// ─────────────────────────────────────────────────────────────

class _CustomDateChip extends StatelessWidget {
  final bool      isActive;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final void Function(DateTime from, DateTime to) onSelected;

  const _CustomDateChip({
    required this.isActive,
    required this.dateFrom,
    required this.dateTo,
    required this.onSelected,
  });

  String get _label {
    if (isActive && dateFrom != null && dateTo != null) {
      final fmt = DateFormat('dd MMM');
      return '${fmt.format(dateFrom!)} - ${fmt.format(dateTo!)}';
    }
    return 'Custom';
  }

  Future<void> _pickRange(BuildContext context) async {
    // ← showDateRangePicker — ek saath From aur To pick hoga
    final picked = await showDateRangePicker(
      context:            context,
      firstDate:          DateTime(2024),
      lastDate:           DateTime.now(),
      initialDateRange:   dateFrom != null && dateTo != null
          ? DateTimeRange(start: dateFrom!, end: dateTo!)
          : null,
      helpText:           'Date range select karo',
      saveText:           'Apply',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary:   AppColor.primary,
              onPrimary: AppColor.white,
              surface:   AppColor.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    onSelected(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickRange(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColor.primary
              : AppColor.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColor.primary
                : AppColor.grey200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size:  12,
              color: isActive ? AppColor.white : AppColor.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              _label,
              style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColor.white : AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}