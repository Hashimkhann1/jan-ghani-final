// Updated on 2026-10-05 03:52 PM
// =============================================================
// warehouse_expense_screen.dart
// Stitch "Jan Ghani — Expenses" design:
// Header · 4 KPI cards · "Har rupya kahan gaya" strip · toolbar
// (search, head chips + counts, date range) · din-wise grouped table
// (date, head, description, added by, amount, ⋮) · footer (total,
// avg/day, pagination)
// ⋮ menu: Detail · Edit (Salary rows par band — Salary screen se)
// Delete jaan-bujh kar NAHI — repo ka delete cash entry wapas nahi karta
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_expense/domain/warehouse_expense_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_expense/presentation/provider/warehouse_expense_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_expense/presentation/widgets/add_expense_dialog.dart';


final _rupeeFormat = NumberFormat('#,##0', 'en_PK');
String _fmt(double v) => 'Rs ${_rupeeFormat.format(v)}';

String _fmtShort(DateTime d) => DateFormat('dd MMM').format(d);
String _fmtDay(DateTime d)   => DateFormat('dd MMM yyyy').format(d);

DateTime _dayOf(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Salary expense Salary screen (salary payment) se judi hoti hai —
/// yahan se edit karne par salary record aur expense alag ho jate
bool _isSalary(WarehouseExpenseModel e) => e.expenseHead == 'Salary';

// ── Head ka rang + icon ──────────────────────────────────────
Color _headColor(String head) {
  switch (head.toLowerCase()) {
    case 'salary':      return AppColor.primary;
    case 'rent':        return AppColor.info;
    case 'bills':       return AppColor.warningDark;
    case 'transport':   return AppColor.success;
    case 'grocery':     return AppColor.secondaryDark;
    case 'feed':        return AppColor.secondaryDark;
    case 'bike fuel':   return AppColor.success;
    case 'maintenance': return AppColor.grey600;
    case 'wawra':       return AppColor.grey600;
    default:            return AppColor.primaryDark;
  }
}

IconData _headIcon(String head) {
  switch (head.toLowerCase()) {
    case 'salary':      return Icons.person_outline_rounded;
    case 'rent':        return Icons.home_outlined;
    case 'bills':       return Icons.bolt_rounded;
    case 'transport':   return Icons.local_shipping_outlined;
    case 'grocery':     return Icons.shopping_cart_outlined;
    case 'feed':        return Icons.restaurant_outlined;
    case 'bike fuel':   return Icons.local_gas_station_outlined;
    case 'maintenance': return Icons.build_outlined;
    case 'wawra':       return Icons.cleaning_services_outlined;
    default:            return Icons.receipt_outlined;
  }
}

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────
class WarehouseExpenseScreen extends ConsumerWidget {
  const WarehouseExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(warehouseExpenseProvider);

    return Scaffold(
      backgroundColor: AppColor.grey100,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            isLoading: state.isLoading,
            onRefresh: () =>
                ref.read(warehouseExpenseProvider.notifier).loadData(),
            onAddExpense: () => AddExpenseDialog.show(
              context,
              onConfirm: ({
                required String expenseHead,
                required double amount,
                String? description,
                String? userId,
                String? userName,
              }) {
                ref.read(warehouseExpenseProvider.notifier).addExpense(
                  expenseHead: expenseHead,
                  amount:      amount,
                  description: description,
                  userId:      userId,
                  userName:    userName,
                );
              },
            ),
          ),
          Expanded(
            child: state.isLoading && state.expenses.isEmpty
                ? const Center(child: CircularProgressIndicator(
                color: AppColor.primary))
                : state.errorMessage != null && state.expenses.isEmpty
                ? _ErrorView(
              message: state.errorMessage!,
              onRetry: () => ref
                  .read(warehouseExpenseProvider.notifier)
                  .loadData(),
            )
                : _Body(state: state, ref: ref),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool         isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onAddExpense;

  const _Header({
    required this.isLoading,
    required this.onRefresh,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color:  AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.receipt_long_outlined,
                size: 20, color: AppColor.primary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expenses',
                    style: TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.textPrimary)),
                Text('Warehouse ke sab kharche track karein',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color:    AppColor.textSecondary)),
              ],
            ),
          ),
          Tooltip(
            message: 'Refresh',
            child: InkWell(
              onTap:        onRefresh,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border:       Border.all(color: AppColor.grey300),
                ),
                child: isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColor.primary),
                )
                    : const Icon(Icons.refresh_rounded,
                    size: 18, color: AppColor.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onAddExpense,
            icon:  const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              minimumSize:   Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BODY — cards + strip + toolbar fixed, table expand
// ─────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final WarehouseExpenseState state;
  final WidgetRef             ref;
  const _Body({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(warehouseExpenseProvider.notifier);

    // Head breakdown — loaded list (date + search) par, head filter se pehle
    final byHead = <String, ({double amount, int count})>{};
    for (final e in state.expenses) {
      final cur = byHead[e.expenseHead];
      byHead[e.expenseHead] = (
        amount: (cur?.amount ?? 0) + e.amount,
        count:  (cur?.count  ?? 0) + 1,
      );
    }
    final heads = byHead.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatsRow(state: state, heads: heads),
          const SizedBox(height: 16),
          if (heads.isNotEmpty) ...[
            _BreakdownStrip(
              heads:      heads,
              total:      state.filteredTotal,
              selected:   state.filterHead,
              onSelect:   notifier.onHeadChanged,
            ),
            const SizedBox(height: 16),
          ],
          _Toolbar(
            state:       state,
            heads:       heads,
            onSearch:    notifier.onSearchChanged,
            onHead:      notifier.onHeadChanged,
            onDateRange: notifier.onDateRangeChanged,
            onDateReset: notifier.resetDateRange,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _ExpenseTable(
              state:      state,
              onPage:     notifier.onPageChanged,
              onPageSize: notifier.onPageSizeChanged,
              onView:     (e) => _ExpenseDetailDialog.show(context, e),
              onEdit: (expense) => AddExpenseDialog.show(
                context,
                existing: expense,
                onConfirm: ({
                  required String expenseHead,
                  required double amount,
                  String? description,
                  String? userId,
                  String? userName,
                }) {
                  notifier.updateExpense(
                    id:                expense.id,
                    cashTransactionId: expense.cashTransactionId,
                    expenseHead:       expenseHead,
                    amount:            amount,
                    description:       description,
                    userId:            userId,
                    userName:          userName,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATS ROW — 4 cards
// ─────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final WarehouseExpenseState state;
  final List<MapEntry<String, ({double amount, int count})>> heads;
  const _StatsRow({required this.state, required this.heads});

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Period
    final from = state.fromDate, to = state.toDate;
    final periodSub = '${state.expenses.length} entries'
        '${from != null && to != null ? ' · ${_fmtShort(from)} – ${_fmtShort(to)}' : ''}';

    // Aaj ki entries — sirf jab range mein aaj shamil ho
    final rangeHasToday = to == null || !to.isBefore(today);
    final todayCount = state.expenses
        .where((e) => _dayOf(e.expenseDate) == today).length;
    final todaySub = rangeHasToday ? '$todayCount entries aaj' : 'Aaj ka kharcha';

    // This month vs last month
    final String monthSub;
    final Color  monthColor;
    if (stats.lastMonthTotal <= 0) {
      monthSub   = 'Pichle mahine koi kharcha nahi';
      monthColor = AppColor.textSecondary;
    } else {
      final pct = ((stats.thisMonthTotal - stats.lastMonthTotal) * 100 /
          stats.lastMonthTotal).round();
      monthSub   = '${pct >= 0 ? '↑' : '↓'} ${pct.abs()}% vs last month';
      // Kam kharcha = acha (green), zyada = laal
      monthColor = pct > 0 ? AppColor.error : AppColor.success;
    }

    // Top head
    final top = heads.isEmpty ? null : heads.first;
    final total = state.filteredTotal;
    final topPct = (top == null || total <= 0)
        ? 0 : (top.value.amount * 100 / total).round();

    return Row(
      children: [
        _StatCard(
          label:    'Selected Period',
          value:    _fmt(total),
          subtitle: periodSub,
          icon:     Icons.date_range_outlined,
          color:    AppColor.primary,
        ),
        const SizedBox(width: 14),
        _StatCard(
          label:    'Today',
          value:    _fmt(stats.todayTotal),
          subtitle: todaySub,
          icon:     Icons.schedule_rounded,
          color:    AppColor.info,
        ),
        const SizedBox(width: 14),
        _StatCard(
          label:    'This Month',
          value:    _fmt(stats.thisMonthTotal),
          subtitle: monthSub,
          icon:     Icons.show_chart_rounded,
          color:    AppColor.success,
          subtitleColor: monthColor,
        ),
        const SizedBox(width: 14),
        _StatCard(
          label:    'Top Head',
          value:    top?.key ?? '—',
          subtitle: top == null
              ? 'Is period mein koi kharcha nahi'
              : '${_fmt(top.value.amount)} · $topPct% of period',
          icon:     Icons.pie_chart_outline_rounded,
          color:    AppColor.warning,
          subtitleColor: AppColor.warningDark,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final String   subtitle;
  final IconData icon;
  final Color    color;
  final Color?   subtitleColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color:        AppColor.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: AppColor.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize:      11,
                          fontWeight:    FontWeight.w600,
                          letterSpacing: 0.6,
                          color:         AppColor.textSecondary)),
                ),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit:       BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(
                      fontSize:   22,
                      fontWeight: FontWeight.w700,
                      color:      AppColor.textPrimary)),
            ),
            const SizedBox(height: 2),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w500,
                    color:      subtitleColor ?? color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// "HAR RUPYA KAHAN GAYA" — proportion bar + clickable legend
// ─────────────────────────────────────────────────────────────
class _BreakdownStrip extends StatelessWidget {
  final List<MapEntry<String, ({double amount, int count})>> heads;
  final double                total;
  final String?               selected;
  final ValueChanged<String?> onSelect;

  const _BreakdownStrip({
    required this.heads,
    required this.total,
    required this.selected,
    required this.onSelect,
  });

  static const _maxSegments = 5; // baqi "Others"

  @override
  Widget build(BuildContext context) {
    final shown  = heads.take(_maxSegments).toList();
    final others = heads.skip(_maxSegments)
        .fold(0.0, (sum, e) => sum + e.value.amount);

    final segments = <({String? head, String label, double amount, Color color})>[
      for (final e in shown)
        (head: e.key, label: e.key, amount: e.value.amount,
         color: _headColor(e.key)),
      if (others > 0)
        (head: null, label: 'Others', amount: others, color: AppColor.grey400),
    ];

    String pct(double a) =>
        total <= 0 ? '0%' : '${(a * 100 / total).round()}%';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('HAR RUPYA KAHAN GAYA',
                  style: TextStyle(
                      fontSize:      11,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: 0.6,
                      color:         AppColor.textSecondary)),
              const SizedBox(width: 6),
              const Text('(head-wise breakdown)',
                  style: TextStyle(fontSize: 11, color: AppColor.textHint)),
              const Spacer(),
              Text.rich(TextSpan(
                style: const TextStyle(
                    fontSize: 12, color: AppColor.textSecondary),
                children: [
                  const TextSpan(text: 'Total: '),
                  TextSpan(text: _fmt(total),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color:      AppColor.textPrimary)),
                ],
              )),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (var i = 0; i < segments.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: (segments[i].amount * 100).round().clamp(1, 1 << 30),
                      child: Container(color: segments[i].color),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing:    8,
            runSpacing: 6,
            children: [
              for (final seg in segments)
                _LegendChip(
                  color:    seg.color,
                  label:    seg.label,
                  value:    '${_fmt(seg.amount)} (${pct(seg.amount)})',
                  selected: seg.head != null && seg.head == selected,
                  // Others par click — filter nahi (kai heads)
                  onTap: seg.head == null
                      ? null
                      : () => onSelect(seg.head == selected ? null : seg.head),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color         color;
  final String        label;
  final String        value;
  final bool          selected;
  final VoidCallback? onTap;

  const _LegendChip({
    required this.color,
    required this.label,
    required this.value,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : AppColor.surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
              color: selected ? color.withOpacity(0.5) : AppColor.grey200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 7, height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color:      AppColor.textPrimary)),
            const SizedBox(width: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, color: AppColor.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOOLBAR — search · head chips (scroll) · date range
// ─────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final WarehouseExpenseState state;
  final List<MapEntry<String, ({double amount, int count})>> heads;
  final ValueChanged<String>  onSearch;
  final ValueChanged<String?> onHead;
  final void Function(DateTime from, DateTime to) onDateRange;
  final VoidCallback          onDateReset;

  const _Toolbar({
    required this.state,
    required this.heads,
    required this.onSearch,
    required this.onHead,
    required this.onDateRange,
    required this.onDateReset,
  });

  @override
  Widget build(BuildContext context) {
    // Chips: count ke hisaab se; selected head hamesha dikhe
    final byCount = [...heads]
      ..sort((a, b) => b.value.count.compareTo(a.value.count));
    final selected = state.filterHead;
    final hasSelected = selected == null ||
        byCount.any((e) => e.key == selected);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Row(
        children: [
          SizedBox(width: 300, child: _SearchBar(onChanged: onSearch)),
          const SizedBox(width: 12),
          Container(width: 1, height: 28, color: AppColor.grey200),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _HeadChip(
                    label:    'All',
                    count:    state.expenses.length,
                    selected: selected == null,
                    onTap:    () => onHead(null),
                  ),
                  if (!hasSelected)
                    _HeadChip(
                      label:    selected,
                      count:    0,
                      selected: true,
                      onTap:    () => onHead(null),
                    ),
                  for (final e in byCount)
                    _HeadChip(
                      label:    e.key,
                      count:    e.value.count,
                      selected: e.key == selected,
                      onTap:    () => onHead(e.key == selected ? null : e.key),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _DateRangeField(
            from:      state.fromDate ?? DateTime.now(),
            to:        state.toDate   ?? DateTime.now(),
            onChanged: onDateRange,
            onReset:   onDateReset,
          ),
        ],
      ),
    );
  }
}

class _HeadChip extends StatelessWidget {
  final String       label;
  final int          count;
  final bool         selected;
  final VoidCallback onTap;

  const _HeadChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color:        selected ? AppColor.primary : AppColor.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? AppColor.primary : AppColor.grey300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize:   12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AppColor.white : AppColor.textPrimary,
                  )),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColor.white.withOpacity(0.22) : AppColor.grey100,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text('$count',
                    style: TextStyle(
                      fontSize:   10.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColor.white : AppColor.textSecondary,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEARCH BAR — head ya description (server-side)
// ─────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        onChanged: (q) {
          widget.onChanged(q);
          setState(() {});
        },
        style: const TextStyle(
            fontSize: 13, color: AppColor.textPrimary),
        decoration: InputDecoration(
          hintText:  'Head ya description se search...',
          hintStyle: const TextStyle(
              fontSize: 13, color: AppColor.textHint),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: AppColor.grey500),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            onPressed: () {
              _controller.clear();
              widget.onChanged('');
              setState(() {});
            },
          )
              : null,
          filled:    true,
          fillColor: AppColor.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.grey300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.grey300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppColor.primary, width: 1.5)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATE RANGE FIELD (default: last 30 din) — ✕ = wapas default
// ─────────────────────────────────────────────────────────────
class _DateRangeField extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final void Function(DateTime from, DateTime to) onChanged;
  final VoidCallback onReset;

  const _DateRangeField({
    required this.from,
    required this.to,
    required this.onChanged,
    required this.onReset,
  });

  bool get _isDefault {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _dayOf(to) == today &&
        _dayOf(from) == today.subtract(const Duration(days: 29));
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context:          context,
      initialDateRange: DateTimeRange(start: from, end: to),
      firstDate:        DateTime(2020),
      lastDate:         DateTime(now.year, now.month, now.day),
      helpText:         'Select date range',
      saveText:         'Apply',
    );
    if (picked != null) onChanged(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    final custom = !_isDefault;
    return InkWell(
      onTap:        () => _pick(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height:  40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: custom
              ? AppColor.primary.withOpacity(0.05) : AppColor.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: custom
                  ? AppColor.primary.withOpacity(0.5) : AppColor.grey300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColor.textSecondary),
            const SizedBox(width: 8),
            Text('${_fmtDay(from)} – ${_fmtDay(to)}',
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color: custom ? AppColor.primary : AppColor.textPrimary,
                )),
            const SizedBox(width: 6),
            if (custom)
              Tooltip(
                message: 'Last 30 din par wapas',
                child: InkWell(
                  onTap:        onReset,
                  borderRadius: BorderRadius.circular(10),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColor.primary),
                ),
              )
            else
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColor.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EXPENSE TABLE — din-wise groups + pagination
// ─────────────────────────────────────────────────────────────
const int    _kColDate   = 2;
const int    _kColHead   = 3;
const int    _kColDesc   = 4;
const int    _kColBy     = 2;
const int    _kColAmount = 2;
const double _kColAction = 64;

class _ExpenseTable extends StatefulWidget {
  final WarehouseExpenseState               state;
  final ValueChanged<int>                   onPage;
  final ValueChanged<int>                   onPageSize;
  final void Function(WarehouseExpenseModel) onView;
  final void Function(WarehouseExpenseModel) onEdit;

  const _ExpenseTable({
    required this.state,
    required this.onPage,
    required this.onPageSize,
    required this.onView,
    required this.onEdit,
  });

  @override
  State<_ExpenseTable> createState() => _ExpenseTableState();
}

class _ExpenseTableState extends State<_ExpenseTable> {
  static const double _minWidth = 900;
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st      = widget.state;
    final visible = st.visibleExpenses;

    // Har din ka total + count (poori filtered list se, sirf page nahi)
    final dayTotals = <DateTime, ({double amount, int count})>{};
    for (final e in visible) {
      final d   = _dayOf(e.expenseDate);
      final cur = dayTotals[d];
      dayTotals[d] = (
        amount: (cur?.amount ?? 0) + e.amount,
        count:  (cur?.count  ?? 0) + 1,
      );
    }

    // Pagination
    final pageCount = visible.isEmpty
        ? 1 : ((visible.length - 1) ~/ st.pageSize) + 1;
    final page  = st.page.clamp(0, pageCount - 1);
    final start = page * st.pageSize;
    final end   = (start + st.pageSize).clamp(0, visible.length);
    final rows  = visible.isEmpty
        ? const <WarehouseExpenseModel>[] : visible.sublist(start, end);

    // Flat list: day header + rows
    final items = <Object>[];
    DateTime? lastDay;
    for (final e in rows) {
      final d = _dayOf(e.expenseDate);
      if (d != lastDay) {
        items.add(d);
        lastDay = d;
      }
      items.add(e);
    }

    return Container(
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = constraints.maxWidth >= _minWidth
                      ? constraints.maxWidth
                      : _minWidth;
                  return Scrollbar(
                    controller:      _hScroll,
                    thumbVisibility: constraints.maxWidth < _minWidth,
                    child: SingleChildScrollView(
                      controller:      _hScroll,
                      scrollDirection: Axis.horizontal,
                      physics:         const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          children: [
                            const _TableHeader(),
                            Expanded(
                              child: items.isEmpty
                                  ? _EmptyState()
                                  : ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (_, i) {
                                  final it = items[i];
                                  if (it is DateTime) {
                                    final t = dayTotals[it]!;
                                    return _DaySeparator(
                                        day: it,
                                        total: t.amount,
                                        count: t.count);
                                  }
                                  final e = it as WarehouseExpenseModel;
                                  return _ExpenseRow(
                                    key:     ValueKey(e.id),
                                    expense: e,
                                    onView:  () => widget.onView(e),
                                    onEdit:  _isSalary(e)
                                        ? null
                                        : () => widget.onEdit(e),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _TableFooter(
              visible:    visible,
              shown:      rows.length,
              start:      start,
              page:       page,
              pageCount:  pageCount,
              pageSize:   st.pageSize,
              from:       st.fromDate,
              to:         st.toDate,
              onPage:     widget.onPage,
              onPageSize: widget.onPageSize,
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height:  44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color:  Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: const Row(
        children: [
          Expanded(flex: _kColDate,   child: _HCell('DATE')),
          Expanded(flex: _kColHead,   child: _HCell('EXPENSE HEAD')),
          Expanded(flex: _kColDesc,   child: _HCell('DESCRIPTION')),
          Expanded(flex: _kColBy,     child: _HCell('ADDED BY')),
          Expanded(flex: _kColAmount, child: _HCell('AMOUNT', align: TextAlign.right)),
          SizedBox(width: _kColAction,
              child: _HCell('ACTIONS', align: TextAlign.right)),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  final String    text;
  final TextAlign align;
  const _HCell(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: align,
      style: const TextStyle(
          fontSize:      11,
          fontWeight:    FontWeight.w600,
          letterSpacing: 0.6,
          color:         AppColor.textSecondary));
}

// ── Din ka separator: "AAJ · 05 OCT 2026 (3) — Day Total" ─────
class _DaySeparator extends StatelessWidget {
  final DateTime day;
  final double   total;
  final int      count;

  const _DaySeparator({
    required this.day,
    required this.total,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prefix = day == today
        ? 'AAJ · '
        : day == today.subtract(const Duration(days: 1)) ? 'KAL · ' : '';
    final isToday = day == today;

    return Container(
      height:  36,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color:  Color(0xFFF8FAFC),
        border: Border(
          top:    BorderSide(color: AppColor.grey200),
          bottom: BorderSide(color: AppColor.grey200),
        ),
      ),
      child: Row(
        children: [
          Container(width: 7, height: 7,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday ? AppColor.info : AppColor.grey500)),
          const SizedBox(width: 8),
          Text('$prefix${_fmtDay(day).toUpperCase()}',
              style: const TextStyle(
                  fontSize:      11.5,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.5,
                  color:         AppColor.textPrimary)),
          const SizedBox(width: 8),
          Text('($count ${count == 1 ? 'expense' : 'expenses'})',
              style: const TextStyle(
                  fontSize: 11, color: AppColor.textHint)),
          const Spacer(),
          Text.rich(TextSpan(
            style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
            children: [
              const TextSpan(text: 'Day Total: '),
              TextSpan(text: _fmt(total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color:      AppColor.textPrimary)),
            ],
          )),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatefulWidget {
  final WarehouseExpenseModel expense;
  final VoidCallback          onView;
  final VoidCallback?         onEdit; // null = Salary row (edit band)

  const _ExpenseRow({
    super.key,
    required this.expense,
    required this.onView,
    required this.onEdit,
  });

  @override
  State<_ExpenseRow> createState() => _ExpenseRowState();
}

class _ExpenseRowState extends State<_ExpenseRow> {
  bool _hover = false;

  @override
  void deactivate() {
    _hover = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final e      = widget.expense;
    final color  = _headColor(e.expenseHead);
    final salary = _isSalary(e);
    final by     = (e.createdByName?.trim().isNotEmpty ?? false)
        ? e.createdByName!.trim() : null;

    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      cursor:          SystemMouseCursors.click,
      onEnter: (_) { if (mounted) setState(() => _hover = true);  },
      onExit:  (_) { if (mounted) setState(() => _hover = false); },
      child: GestureDetector(
        onTap: widget.onView,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height:   60,
          padding:  const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: _hover
                ? AppColor.primary.withOpacity(0.03) : Colors.transparent,
            border: const Border(
                bottom: BorderSide(color: AppColor.grey100)),
          ),
          child: Row(
            children: [
              // Date + time
              Expanded(
                flex: _kColDate,
                child: Column(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fmtDay(e.expenseDate.toLocal()),
                        style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.textPrimary)),
                    Text(DateFormat('h:mm a').format(e.createdAt.toLocal()),
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColor.textSecondary)),
                  ],
                ),
              ),

              // Head
              Expanded(
                flex: _kColHead,
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(_headIcon(e.expenseHead),
                          size: 15, color: color),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(e.expenseHead,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
                              color:      AppColor.textPrimary)),
                    ),
                    if (salary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:        AppColor.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColor.primary.withOpacity(0.3)),
                        ),
                        child: const Text('SALARY',
                            style: TextStyle(
                                fontSize:      9.5,
                                fontWeight:    FontWeight.w700,
                                letterSpacing: 0.5,
                                color:         AppColor.primary)),
                      ),
                    ],
                  ],
                ),
              ),

              // Description
              Expanded(
                flex: _kColDesc,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    (e.description?.trim().isNotEmpty ?? false)
                        ? e.description!.trim() : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: AppColor.textPrimary),
                  ),
                ),
              ),

              // Added by
              Expanded(
                flex: _kColBy,
                child: by == null
                    ? const Text('—',
                    style: TextStyle(color: AppColor.textHint))
                    : Row(
                  children: [
                    _InitialsAvatar(name: by),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(by,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color:    AppColor.textSecondary)),
                    ),
                  ],
                ),
              ),

              // Amount
              Expanded(
                flex: _kColAmount,
                child: Text(_fmt(e.amount),
                    textAlign: TextAlign.right,
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.error)),
              ),

              // ⋮
              SizedBox(
                width: _kColAction,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _RowMenu(
                    salary: salary,
                    onView: widget.onView,
                    onEdit: widget.onEdit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final ini = parts.isEmpty
        ? '?'
        : parts.length == 1
        ? parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase()
        : '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(ini,
          style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColor.primary)),
    );
  }
}

// ── ⋮ menu: Detail · Edit ─────────────────────────────────────
class _RowMenu extends StatelessWidget {
  final bool          salary;
  final VoidCallback  onView;
  final VoidCallback? onEdit;

  const _RowMenu({
    required this.salary,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip:     'Actions',
      offset:      const Offset(0, 38),
      color:       AppColor.surface,
      constraints: const BoxConstraints(minWidth: 200),
      icon: const Icon(Icons.more_vert_rounded,
          size: 20, color: AppColor.grey600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColor.grey200)),
      onSelected: (v) {
        if (v == 'view') onView();
        if (v == 'edit') onEdit?.call();
      },
      itemBuilder: (_) => [
        const PopupMenuItem<String>(
          value:  'view',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.visibility_outlined,
                  size: 17, color: AppColor.textSecondary),
              SizedBox(width: 12),
              Text('Detail dekhein',
                  style: TextStyle(fontSize: 13.5, color: AppColor.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value:   'edit',
          height:  salary ? 48 : 40,
          enabled: onEdit != null,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 17,
                  color: onEdit != null
                      ? AppColor.textSecondary : AppColor.grey400),
              const SizedBox(width: 12),
              Column(
                mainAxisSize:       MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit karein',
                      style: TextStyle(
                          fontSize: 13.5,
                          color: onEdit != null
                              ? AppColor.textPrimary : AppColor.grey400)),
                  if (salary)
                    const Text('Salary screen se badlein',
                        style: TextStyle(
                            fontSize: 11, color: AppColor.textHint)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Footer: count · total + avg/day · pagination ─────────────
class _TableFooter extends StatelessWidget {
  final List<WarehouseExpenseModel> visible;
  final int               shown;
  final int               start;
  final int               page;
  final int               pageCount;
  final int               pageSize;
  final DateTime?         from;
  final DateTime?         to;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;

  const _TableFooter({
    required this.visible,
    required this.shown,
    required this.start,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.from,
    required this.to,
    required this.onPage,
    required this.onPageSize,
  });

  @override
  Widget build(BuildContext context) {
    final total = visible.fold(0.0, (s, e) => s + e.amount);
    final days  = (from != null && to != null)
        ? _dayOf(to!).difference(_dayOf(from!)).inDays + 1
        : visible.map((e) => _dayOf(e.expenseDate)).toSet().length;
    final avg = days <= 0 ? 0.0 : total / days;

    const muted = TextStyle(fontSize: 12.5, color: AppColor.textSecondary);
    const bold  = TextStyle(fontSize: 12.5,
        fontWeight: FontWeight.w700, color: AppColor.textPrimary);

    final countText = Text.rich(TextSpan(style: muted, children: [
      const TextSpan(text: 'Showing '),
      TextSpan(
          text: visible.isEmpty ? '0' : '${start + 1}–${start + shown}',
          style: bold),
      const TextSpan(text: ' of '),
      TextSpan(text: '${visible.length}', style: bold),
      const TextSpan(text: ' expenses'),
    ]));

    final summary = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color:        AppColor.grey100,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Text.rich(TextSpan(style: muted, children: [
        const TextSpan(text: 'Total '),
        TextSpan(text: _fmt(total), style: bold),
        const TextSpan(text: '   ·   Avg/day '),
        TextSpan(text: _fmt(avg), style: bold),
      ])),
    );

    final pager = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Show:', style: muted),
        const SizedBox(width: 8),
        PopupMenuButton<int>(
          tooltip:    'Rows per page',
          onSelected: onPageSize,
          color:      AppColor.surface,
          itemBuilder: (_) => [
            for (final n in const [25, 50, 100])
              CheckedPopupMenuItem<int>(
                value:   n,
                checked: n == pageSize,
                child:   Text('$n', style: const TextStyle(fontSize: 13)),
              ),
          ],
          child: Container(
            height:  32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border:       Border.all(color: AppColor.grey300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$pageSize', style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: AppColor.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        _PageBtn(
          icon:  Icons.chevron_left_rounded,
          onTap: page > 0 ? () => onPage(page - 1) : null,
        ),
        for (final p in _pages())
          p == -1
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('…', style: muted),
          )
              : _PageBtn(
            label:    '${p + 1}',
            selected: p == page,
            onTap:    () => onPage(p),
          ),
        _PageBtn(
          icon:  Icons.chevron_right_rounded,
          onTap: page < pageCount - 1 ? () => onPage(page + 1) : null,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColor.grey200))),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 1000) {
            return Row(
              children: [
                countText,
                const Spacer(),
                summary,
                const Spacer(),
                pager,
              ],
            );
          }
          return SizedBox(
            width: double.infinity,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing:            16,
              runSpacing:         8,
              children: [countText, summary, pager],
            ),
          );
        },
      ),
    );
  }

  /// 1 … (page-1) page (page+1) … last — -1 = ellipsis
  List<int> _pages() {
    if (pageCount <= 7) return List.generate(pageCount, (i) => i);
    final set = <int>{0, pageCount - 1, page - 1, page, page + 1}
      ..removeWhere((p) => p < 0 || p >= pageCount);
    final sorted = set.toList()..sort();
    final out = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) out.add(-1);
      out.add(sorted[i]);
    }
    return out;
  }
}

class _PageBtn extends StatelessWidget {
  final String?       label;
  final IconData?     icon;
  final bool          selected;
  final VoidCallback? onTap;

  const _PageBtn({
    this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          constraints: const BoxConstraints(minWidth: 32),
          height:      32,
          padding:     const EdgeInsets.symmetric(horizontal: 8),
          alignment:   Alignment.center,
          decoration: BoxDecoration(
            color:        selected ? AppColor.primary : AppColor.surface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
                color: selected ? AppColor.primary : AppColor.grey300),
          ),
          child: icon != null
              ? Icon(icon, size: 18,
              color: disabled ? AppColor.grey400 : AppColor.textPrimary)
              : Text(label!,
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColor.white : AppColor.textPrimary)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DETAIL DIALOG — read-only
// ─────────────────────────────────────────────────────────────
class _ExpenseDetailDialog extends StatelessWidget {
  final WarehouseExpenseModel expense;
  const _ExpenseDetailDialog({required this.expense});

  static void show(BuildContext context, WarehouseExpenseModel e) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) => _ExpenseDetailDialog(expense: e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e     = expense;
    final color = _headColor(e.expenseHead);

    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColor.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                    color:      AppColor.textPrimary)),
          ),
        ],
      ),
    );

    return Dialog(
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(_headIcon(e.expenseHead),
                        size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(e.expenseHead,
                        style: const TextStyle(
                            fontSize:   17,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textPrimary)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: AppColor.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color:        AppColor.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(_fmt(e.amount),
                    style: const TextStyle(
                        fontSize:   24,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.error)),
              ),
              const SizedBox(height: 12),
              line('Expense date', _fmtDay(e.expenseDate.toLocal())),
              line('Entry time',
                  DateFormat('dd MMM yyyy · h:mm a').format(e.createdAt.toLocal())),
              line('Description',
                  (e.description?.trim().isNotEmpty ?? false)
                      ? e.description!.trim() : '—'),
              line('Added by', e.createdByName ?? '—'),
              line('Cash entry',
                  e.cashTransactionId != null
                      ? 'Cash in hand se minus hui'
                      : 'Linked cash entry nahi'),
              if (_isSalary(e))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:        AppColor.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Yeh salary payment ka kharcha hai — badalna ho to '
                          'Salary screen se karein.',
                      style: TextStyle(fontSize: 12, color: AppColor.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 40, color: AppColor.grey400),
          SizedBox(height: 12),
          Text('Koi expense nahi mili',
              style: TextStyle(
                  color: AppColor.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ERROR VIEW
// ─────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColor.error, size: 48),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppColor.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary, elevation: 0),
            onPressed: onRetry,
            child: const Text('Dobara Try Karo',
                style: TextStyle(color: AppColor.white)),
          ),
        ],
      ),
    );
  }
}
