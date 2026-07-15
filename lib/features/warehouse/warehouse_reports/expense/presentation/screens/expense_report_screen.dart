// =============================================================
// expense_report_screen.dart
//
// Expense Report — responsive (desktop / website / IPA-mobile).
//   1. Top hero card: Total Expense + rozana average, saath date filter
//   2. Category-wise breakdown table (amount, entries, share bar)
//   3. Proportion view — "Har rupya kahan gaya" stacked bar + legend
//
// Data source platform-aware hai (provider): desktop=local, web/IPA=Supabase.
// =============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/expense/data/datasources/expense_report_local_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/expense/presentation/providers/expense_report_provider.dart';

// ─────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────

const _kMonthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
const _kMonthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

// Category colors — sorted index se assign hote hain (modulo cycle).
const _kCatColors = [
  Color(0xFF2F7D6F), // teal
  Color(0xFFB5561F), // rust
  Color(0xFF2C5F8A), // blue
  Color(0xFF6B9B3F), // green
  Color(0xFF7A4E3A), // brown
  Color(0xFF8B6BA8), // purple
  Color(0xFFC79A2E), // gold
  Color(0xFF5B6472), // slate
  Color(0xFF9CA3AF), // grey
  Color(0xFFCF6679), // pink
];

Color _catColor(int i) => _kCatColors[i % _kCatColors.length];

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────

class ExpenseReportScreen extends StatelessWidget {
  const ExpenseReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        children: [
          _TopBar(),
          Expanded(child: _Body()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR (responsive)
// ─────────────────────────────────────────────────────────────

class _TopBar extends ConsumerStatefulWidget {
  const _TopBar();
  @override
  ConsumerState<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<_TopBar> {
  Future<void> _showCustomPicker() async {
    final notifier = ref.read(expenseReportProvider.notifier);
    final st       = ref.read(expenseReportProvider);

    final now       = DateTime.now();
    final firstDate = DateTime(2020);
    final lastDate  = DateTime(now.year, now.month, now.day);

    DateTime clamp(DateTime d) {
      if (d.isBefore(firstDate)) return firstDate;
      if (d.isAfter(lastDate))   return lastDate;
      return d;
    }

    DateTime start =
        clamp(st.dateFrom ?? now.subtract(const Duration(days: 30)));
    DateTime end = clamp(st.dateTo ?? now);
    if (start.isAfter(end)) start = end;

    final picked = await showDateRangePicker(
      context:          context,
      firstDate:        firstDate,
      lastDate:         lastDate,
      initialDateRange: DateTimeRange(start: start, end: end),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      notifier.setCustomRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(expenseReportProvider);
    final notifier = ref.read(expenseReportProvider.notifier);

    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColor.error.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.account_balance_wallet_outlined,
              size: 18, color: AppColor.error),
        ),
        const SizedBox(width: 12),
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expense Report',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary)),
            Text('Category-wise kharcha breakdown',
                style: TextStyle(fontSize: 11, color: AppColor.textSecondary)),
          ],
        ),
      ],
    );

    final filters = Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FilterPill(
          label:    'Overall',
          selected: state.filterMode == ExpenseDateFilterMode.overall,
          onTap:    notifier.setOverall,
        ),
        _FilterPill(
          label:    'This Month',
          selected: state.filterMode == ExpenseDateFilterMode.currentMonth,
          onTap:    notifier.setCurrentMonth,
        ),
        _CustomPill(state: state, onTap: _showCustomPicker),
        _RefreshBtn(onTap: notifier.refresh),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color:  AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          // Wide → title + filters ek row mein. Narrow → do rows (stack).
          if (c.maxWidth >= 620) {
            return Row(
              children: [
                title,
                const Spacer(),
                filters,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 10),
              filters,
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseReportProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColor.error, size: 36),
            const SizedBox(height: 12),
            const Text('Data load nahi hua',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(state.error!,
                  style: const TextStyle(
                      fontSize: 11, color: AppColor.textSecondary),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ref.read(expenseReportProvider.notifier).refresh(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Retry',
                    style: TextStyle(
                        color: AppColor.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

    final summary    = state.summary;
    final categories = state.categories;
    final total = summary?.totalAmount ??
        categories.fold<double>(0, (s, c) => s + c.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Total Expense hero
              _TotalExpenseCard(
                state: state,
                summary: summary,
                categories: categories,
                total: total,
              ),
              const SizedBox(height: 16),

              // 2. Category-wise breakdown
              if (categories.isEmpty)
                _EmptyBox()
              else ...[
                _CategoryBreakdown(categories: categories, total: total),
                const SizedBox(height: 16),

                // 3. Proportion view
                _ProportionView(categories: categories, total: total),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 1. TOTAL EXPENSE HERO CARD
// ─────────────────────────────────────────────────────────────

class _TotalExpenseCard extends StatelessWidget {
  final ExpenseReportState  state;
  final ExpenseReportSummary? summary;
  final List<ExpenseCategoryRow> categories;
  final double total;
  const _TotalExpenseCard({
    required this.state,
    required this.summary,
    required this.categories,
    required this.total,
  });

  String get _title {
    switch (state.filterMode) {
      case ExpenseDateFilterMode.currentMonth:
        final m = state.dateFrom;
        return m == null
            ? 'TOTAL EXPENSE'
            : 'TOTAL ${_kMonthsFull[m.month - 1].toUpperCase()} EXPENSE';
      case ExpenseDateFilterMode.overall:
        return 'TOTAL EXPENSE (OVERALL)';
      case ExpenseDateFilterMode.custom:
        final f = state.dateFrom, t = state.dateTo;
        if (f == null || t == null) return 'TOTAL EXPENSE';
        return 'TOTAL EXPENSE · ${f.day} ${_kMonthsShort[f.month - 1]} – '
            '${t.day} ${_kMonthsShort[t.month - 1]}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final avg     = summary?.dailyAverage ?? 0;
    final days    = summary?.activeDays ?? 0;
    final entries = summary?.entryCount ?? 0;
    final pct     = summary?.changePct;

    final top      = categories.isNotEmpty ? categories.first : null;
    final topShare = (top != null && total > 0) ? top.amount / total * 100 : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey200),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 560 && days > 0;

          // ── LEFT: title + bada amount + rozana average ──────
          final left = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColor.textSecondary,
                  )),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'PKR ',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textSecondary),
                      ),
                      TextSpan(
                        text: total.pkrFormat,
                        style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: AppColor.textPrimary,
                            letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (days > 0)
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: AppColor.textSecondary),
                    children: [
                      const TextSpan(text: 'Rozana average ≈  '),
                      TextSpan(
                        text: 'PKR ${avg.pkrFormat}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColor.success),
                      ),
                      const TextSpan(text: '  / active day'),
                    ],
                  ),
                )
              else
                const Text('Is period mein koi kharcha nahi',
                    style: TextStyle(fontSize: 13, color: AppColor.textHint)),
            ],
          );

          // ── RIGHT: entries·days + comparison + sabse zyada ──
          Column meta(CrossAxisAlignment align) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: align,
                children: [
                  Text('$entries entries  ·  $days active days',
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textSecondary)),
                  if (pct != null) ...[
                    const SizedBox(height: 8),
                    _ComparisonChip(pct: pct),
                  ],
                  if (top != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(color: _catColor(0)),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 13, color: AppColor.textSecondary),
                            children: [
                              const TextSpan(text: 'Sabse zyada:  '),
                              TextSpan(
                                text: top.head,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.textPrimary),
                              ),
                              TextSpan(
                                  text:
                                      '  — ${topShare.toStringAsFixed(1)}%'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: left),
                const SizedBox(width: 20),
                meta(CrossAxisAlignment.end),
              ],
            );
          }
          // Narrow (mobile) → stack: left, phir meta neeche
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              if (days > 0) ...[
                const SizedBox(height: 16),
                meta(CrossAxisAlignment.start),
              ],
            ],
          );
        },
      ),
    );
  }
}

// vs-last-period comparison chip. Expense UP = kharcha barha (red/warning),
// DOWN = kharcha kam (green).
class _ComparisonChip extends StatelessWidget {
  final double pct;
  const _ComparisonChip({required this.pct});

  @override
  Widget build(BuildContext context) {
    final up    = pct >= 0;
    final color = up ? AppColor.error : AppColor.success;
    final icon  = up
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text('${pct.abs().toStringAsFixed(1)}%  vs pichla period',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2. CATEGORY-WISE BREAKDOWN
// ─────────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final List<ExpenseCategoryRow> categories;
  final double total;
  const _CategoryBreakdown({required this.categories, required this.total});

  @override
  Widget build(BuildContext context) {
    final totalEntries = categories.fold<int>(0, (s, c) => s + c.entries);

    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey200),
      ),
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 640;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BREAKDOWN',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColor.success)),
              const SizedBox(height: 4),
              const Text('Category-wise kharcha',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary)),
              const SizedBox(height: 16),

              if (wide) _wideHeader(),
              if (wide) const Divider(height: 16, color: AppColor.grey200),

              ...List.generate(categories.length, (i) {
                final row = categories[i];
                final share = total > 0 ? row.amount / total * 100 : 0.0;
                return wide
                    ? _WideRow(row: row, share: share, color: _catColor(i))
                    : _NarrowRow(row: row, share: share, color: _catColor(i));
              }),

              const Divider(height: 20, color: AppColor.grey300),
              // TOTAL row
              _TotalRow(
                total: total,
                entries: totalEntries,
                wide: wide,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _wideHeader() {
    return Row(
      children: const [
        Expanded(flex: 4, child: _HCell('EXPENSE HEAD')),
        Expanded(
            flex: 3,
            child: _HCell('AMOUNT (PKR)', align: TextAlign.right)),
        Expanded(
            flex: 2, child: _HCell('ENTRIES', align: TextAlign.center)),
        Expanded(
            flex: 4,
            child: _HCell('SHARE OF TOTAL', align: TextAlign.right)),
      ],
    );
  }
}

class _HCell extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _HCell(this.text, {this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: align,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColor.textSecondary));
}

// Wide (desktop/web) — table row
class _WideRow extends StatelessWidget {
  final ExpenseCategoryRow row;
  final double share;
  final Color color;
  const _WideRow(
      {required this.row, required this.share, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _Dot(color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(row.head,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(row.amount.pkrFormat,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary)),
          ),
          Expanded(
            flex: 2,
            child: Text('${row.entries}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColor.textSecondary)),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Expanded(child: _ShareBar(share: share, color: color)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 46,
                  child: Text('${share.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textSecondary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Narrow (mobile) — stacked two-line row
class _NarrowRow extends StatelessWidget {
  final ExpenseCategoryRow row;
  final double share;
  final Color color;
  const _NarrowRow(
      {required this.row, required this.share, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Dot(color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(row.head,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary)),
              ),
              const SizedBox(width: 8),
              Text('PKR ${row.amount.pkrFormat}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Row(
              children: [
                Expanded(child: _ShareBar(share: share, color: color)),
                const SizedBox(width: 10),
                Text('${row.entries} entries',
                    style: const TextStyle(
                        fontSize: 11, color: AppColor.textHint)),
                const SizedBox(width: 8),
                Text('${share.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final double total;
  final int entries;
  final bool wide;
  const _TotalRow(
      {required this.total, required this.entries, required this.wide});

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Row(
        children: [
          const Expanded(
            flex: 4,
            child: Text('TOTAL',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary)),
          ),
          Expanded(
            flex: 3,
            child: Text(total.pkrFormat,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColor.success)),
          ),
          Expanded(
            flex: 2,
            child: Text('$entries',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary)),
          ),
          const Expanded(
            flex: 4,
            child: Text('100%',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary)),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Text('TOTAL',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColor.textPrimary)),
        const Spacer(),
        Text('$entries entries',
            style: const TextStyle(fontSize: 11, color: AppColor.textHint)),
        const SizedBox(width: 10),
        Text('PKR ${total.pkrFormat}',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColor.success)),
      ],
    );
  }
}

class _ShareBar extends StatelessWidget {
  final double share; // 0..100
  final Color color;
  const _ShareBar({required this.share, required this.color});

  @override
  Widget build(BuildContext context) {
    final f = (share / 100).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 7,
        color: AppColor.grey200,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: f == 0 ? 0.02 : f, // tiny bhi thora nazar aaye
          child: Container(color: color),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ─────────────────────────────────────────────────────────────
// 3. PROPORTION VIEW — "Har rupya kahan gaya"
// ─────────────────────────────────────────────────────────────

class _ProportionView extends StatelessWidget {
  final List<ExpenseCategoryRow> categories;
  final double total;
  const _ProportionView({required this.categories, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey200),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HAR RUPYA KAHAN GAYA — PROPORTION VIEW',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColor.textSecondary)),
          const SizedBox(height: 14),

          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 26,
              child: Row(
                children: List.generate(categories.length, (i) {
                  final share = total > 0 ? categories[i].amount / total : 0.0;
                  final flex = math.max(1, (share * 1000).round());
                  return Expanded(
                    flex: flex,
                    child: Container(color: _catColor(i)),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(categories.length, (i) {
              final row   = categories[i];
              final share = total > 0 ? row.amount / total * 100 : 0.0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dot(color: _catColor(i)),
                  const SizedBox(width: 6),
                  Text(row.head,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary)),
                  const SizedBox(width: 5),
                  Text('${share.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textSecondary)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────

class _EmptyBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey200),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: AppColor.grey300),
          SizedBox(height: 12),
          Text('Is period mein koi expense nahi',
              style: TextStyle(fontSize: 15, color: AppColor.textHint)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER WIDGETS
// ─────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColor.primary : AppColor.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColor.primary : AppColor.grey200),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColor.white : AppColor.grey600)),
      ),
    );
  }
}

class _CustomPill extends StatelessWidget {
  final ExpenseReportState state;
  final VoidCallback onTap;
  const _CustomPill({required this.state, required this.onTap});

  String get _label {
    if (state.filterMode != ExpenseDateFilterMode.custom ||
        state.dateFrom == null ||
        state.dateTo == null) {
      return 'Custom ▾';
    }
    final f = state.dateFrom!;
    final t = state.dateTo!;
    return '${_kMonthsShort[f.month - 1]} ${f.day} – '
        '${_kMonthsShort[t.month - 1]} ${t.day} ▾';
  }

  @override
  Widget build(BuildContext context) {
    final selected = state.filterMode == ExpenseDateFilterMode.custom;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColor.primary : AppColor.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColor.primary : AppColor.grey200),
        ),
        child: Text(_label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColor.white : AppColor.grey600)),
      ),
    );
  }
}

class _RefreshBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshBtn({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColor.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColor.grey200),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 13, color: AppColor.grey600),
            SizedBox(width: 5),
            Text('Refresh',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColor.grey700)),
          ],
        ),
      ),
    );
  }
}
