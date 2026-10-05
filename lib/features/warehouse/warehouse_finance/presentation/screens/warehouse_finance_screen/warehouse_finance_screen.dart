// Updated on 2026-10-05 06:26 PM
// =============================================================
// warehouse_finance_screen.dart
// Stitch "Jan Ghani — Finance" design:
// Header (refresh · Cash Requests + badge · Cash In) · Cash-in-hand
// hero + 3 KPI cards · selected period strip (in / out / net + out
// breakdown) · toolbar (search, type tabs + counts, date range) ·
// din-wise grouped transactions table · footer (in/out/net + pager)
// Period math: reversal = cash OUT se minus (cash in NAHI) — S15 rule
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/domain/warehouse_finance_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/presentation/provider/warehouse_finance_provider/warehouse_finance_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/presentation/widgets/cash_in_dialog.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_cash_requests/presentation/provider/warehouse_cash_requests_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_cash_requests/presentation/screen/warehouse_cash_requests_screen.dart';

String _fmt(double v) => 'Rs ${v.pkrFormat}';

/// Signed amount — "+Rs 1,000" / "−Rs 1,000"
String _signed(double v) =>
    '${v < 0 ? '−' : '+'}Rs ${v.abs().pkrFormat}';

String _fmtShort(DateTime d) => DateFormat('dd MMM').format(d);
String _fmtDay(DateTime d)   => DateFormat('dd MMM yyyy').format(d);

DateTime _dayOf(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

bool _isReversal(CashTransactionModel t) =>
    t.entryType == 'supplier_payment_reversal';

// ── Type ka rang / icon / label ──────────────────────────────
Color _typeColor(String t) {
  switch (t) {
    case 'cash_in':                   return AppColor.success;
    case 'supplier_payment':          return AppColor.primary;
    case 'supplier_payment_reversal': return AppColor.info;
    case 'purchase':                  return AppColor.primaryDark;
    case 'expense':                   return AppColor.warningDark;
    case 'salary':                    return AppColor.info;
    default:                          return AppColor.grey600;
  }
}

IconData _typeIcon(String t) {
  switch (t) {
    case 'cash_in':                   return Icons.south_west_rounded;
    case 'supplier_payment':          return Icons.groups_outlined;
    case 'supplier_payment_reversal': return Icons.undo_rounded;
    case 'purchase':                  return Icons.shopping_cart_outlined;
    case 'expense':                   return Icons.receipt_long_outlined;
    case 'salary':                    return Icons.person_outline_rounded;
    default:                          return Icons.swap_horiz_rounded;
  }
}

String _typeLabel(CashTransactionModel t) {
  switch (t.entryType) {
    case 'supplier_payment':          return 'Supplier Pay';
    case 'supplier_payment_reversal': return 'Reversal';
    default:                          return t.entryTypeDisplay;
  }
}

/// Main line + optional second line (supplier txn: naam upar, note neeche)
(String, String?) _detail(CashTransactionModel tx) {
  final note = tx.notes?.trim() ?? '';
  final sup  = tx.supplierName?.trim() ?? '';
  final isSupplierTx = tx.entryType == 'supplier_payment' || _isReversal(tx);
  if (isSupplierTx && sup.isNotEmpty) {
    if (note.isEmpty || note.toLowerCase() == sup.toLowerCase()) {
      return (sup, null);
    }
    return (sup, note);
  }
  return (note.isEmpty ? '—' : note, null);
}

/// Period totals — reversal cash OUT ko kam karta hai (S15)
class _Totals {
  double cashIn = 0, outGross = 0, reversal = 0;
  double supplier = 0, expense = 0, salary = 0, purchase = 0, other = 0;
  int    count = 0;

  double get cashOut => outGross - reversal;
  double get net     => cashIn - cashOut;

  void add(CashTransactionModel t) {
    count++;
    switch (t.entryType) {
      case 'cash_in':                   cashIn   += t.amount; return;
      case 'supplier_payment_reversal': reversal += t.amount;
                                        supplier -= t.amount; return;
      case 'supplier_payment':          supplier += t.amount; break;
      case 'expense':                   expense  += t.amount; break;
      case 'salary':                    salary   += t.amount; break;
      case 'purchase':                  purchase += t.amount; break;
      default:                          other    += t.amount;
    }
    outGross += t.amount;
  }

  static _Totals of(Iterable<CashTransactionModel> list) {
    final t = _Totals();
    for (final x in list) {
      t.add(x);
    }
    return t;
  }
}

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────
class WarehouseFinanceScreen extends ConsumerWidget {
  const WarehouseFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(warehouseFinanceProvider);

    return Scaffold(
      backgroundColor: AppColor.grey100,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            isLoading: state.isLoading,
            onRefresh: () =>
                ref.read(warehouseFinanceProvider.notifier).loadData(),
          ),
          Expanded(
            child: state.isLoading && state.finance == null
                ? const Center(
                child: CircularProgressIndicator(
                    color: AppColor.primary))
                : state.errorMessage != null && state.finance == null
                ? _ErrorView(
              message: state.errorMessage!,
              onRetry: () => ref
                  .read(warehouseFinanceProvider.notifier)
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
class _Header extends ConsumerWidget {
  final bool         isLoading;
  final VoidCallback onRefresh;
  const _Header({required this.isLoading, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingCashRequestsProvider);
    final count   = pending.asData?.value.length ?? 0;

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
            child: const Icon(Icons.account_balance_outlined,
                size: 20, color: AppColor.primary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Finance',
                    style: TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.textPrimary)),
                Text('Cash flow aur transactions manage karein',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, color: AppColor.textSecondary)),
              ],
            ),
          ),
          // Refresh
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
          // Cash Requests (accountant se aayi cash) + badge
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WarehouseCashRequestsScreen(),
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.textPrimary,
              side: const BorderSide(color: AppColor.grey300),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 16),
              minimumSize:   Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.move_to_inbox_outlined, size: 18),
                const SizedBox(width: 8),
                const Text('Cash Requests',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color:        AppColor.error,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text('$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color:      AppColor.white,
                            fontSize:   11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _showCashInDialog(context, ref),
            icon:  const Icon(Icons.add_rounded, size: 18),
            label: const Text('Cash In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.success,
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

  void _showCashInDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => CashInDialog(
        onConfirm: ({
          required double amount,
          String? notes,
          String? userId,
          String? userName,
        }) {
          ref.read(warehouseFinanceProvider.notifier).addCashIn(
            amount:   amount,
            notes:    notes,
            userId:   userId,
            userName: userName,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final WarehouseFinanceState state;
  final WidgetRef             ref;
  const _Body({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(warehouseFinanceProvider.notifier);
    final period   = _Totals.of(state.transactions);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopStatsRow(state: state),
          const SizedBox(height: 14),
          _PeriodStrip(
            totals: period,
            from:   state.fromDate,
            to:     state.toDate,
          ),
          const SizedBox(height: 14),
          _Toolbar(
            state:       state,
            onSearch:    notifier.onSearchChanged,
            onFilter:    notifier.onFilterChanged,
            onDateRange: notifier.onDateRangeChanged,
            onDateReset: notifier.resetDateRange,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _TransactionsTable(
              state:      state,
              onPage:     notifier.onPageChanged,
              onPageSize: notifier.onPageSizeChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP STATS — Cash in hand hero + 3 cards
// ─────────────────────────────────────────────────────────────
class _TopStatsRow extends StatelessWidget {
  final WarehouseFinanceState state;
  const _TopStatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final cashInHand = state.finance?.cashInHand ?? 0;
    final todayIn    = state.summary?.todayCashIn ?? 0;
    final todayOut   = state.summary?.todayCashOut ?? 0;
    final supDue     = state.summary?.totalSupplierDue ?? 0;

    // Aaj ki entries — loaded list se, sirf jab range mein aaj ho
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final to    = state.toDate;
    final rangeHasToday = to == null || !to.isBefore(today);
    int inCount = 0, outCount = 0;
    for (final t in state.transactions) {
      if (_dayOf(t.createdAt) != today) continue;
      if (t.entryType == 'cash_in') {
        inCount++;
      } else {
        outCount++;
      }
    }

    // Last entry — list newest-first (repo ORDER BY created_at DESC)
    final last = state.transactions.isEmpty ? null : state.transactions.first;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: _HeroCard(
              cashInHand: cashInHand,
              lastEntry:  last?.createdAt,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: _StatCard(
              label:    'Aaj Cash In',
              value:    _fmt(todayIn),
              subtitle: rangeHasToday ? '$inCount ${inCount == 1 ? 'entry' : 'entries'}' : 'Aaj',
              icon:     Icons.south_west_rounded,
              color:    AppColor.success,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: _StatCard(
              label:    'Aaj Cash Out',
              value:    _fmt(todayOut),
              subtitle: rangeHasToday ? '$outCount ${outCount == 1 ? 'entry' : 'entries'}' : 'Aaj',
              icon:     Icons.north_east_rounded,
              color:    AppColor.error,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: _StatCard(
              label:    'Suppliers Outstanding',
              value:    _fmt(supDue),
              subtitle: supDue > 0 ? 'Suppliers ko dena hai' : 'Koi baqaya nahi',
              icon:     Icons.credit_card_outlined,
              color:    AppColor.warning,
              subtitleColor: AppColor.warningDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final double    cashInHand;
  final DateTime? lastEntry;
  const _HeroCard({required this.cashInHand, required this.lastEntry});

  @override
  Widget build(BuildContext context) {
    final negative = cashInHand < 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color:        AppColor.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:  MainAxisAlignment.center,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('CASH IN HAND',
                    style: TextStyle(
                        fontSize:      11.5,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 0.6,
                        color:         AppColor.primary)),
              ),
              Icon(Icons.account_balance_wallet_outlined,
                  size: 18, color: AppColor.primary),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit:       BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(_fmt(cashInHand),
                style: TextStyle(
                    fontSize:   30,
                    fontWeight: FontWeight.w800,
                    color: negative ? AppColor.error : AppColor.textPrimary)),
          ),
          const SizedBox(height: 4),
          Text(
            lastEntry == null
                ? 'Is period mein koi entry nahi'
                : 'Last entry: ${DateFormat('dd MMM yyyy, h:mm a').format(lastEntry!.toLocal())}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12.5, color: AppColor.textSecondary),
          ),
        ],
      ),
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
    return Container(
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
          const Spacer(),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w500,
                  color:      subtitleColor ?? color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PERIOD STRIP — in · out · net · out-breakdown bar
// ─────────────────────────────────────────────────────────────
class _PeriodStrip extends StatelessWidget {
  final _Totals   totals;
  final DateTime? from;
  final DateTime? to;

  const _PeriodStrip({
    required this.totals,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    final t   = totals;
    final net = t.net;

    // Out breakdown (reversal supplier mein se minus ho chuki)
    final parts = <({String label, double amount, Color color})>[
      if (t.supplier > 0) (label: 'Supplier', amount: t.supplier, color: AppColor.primary),
      if (t.expense  > 0) (label: 'Expense',  amount: t.expense,  color: AppColor.warningDark),
      if (t.salary   > 0) (label: 'Salary',   amount: t.salary,   color: AppColor.info),
      if (t.purchase > 0) (label: 'Purchase', amount: t.purchase, color: AppColor.primaryDark),
      if (t.other    > 0) (label: 'Other',    amount: t.other,    color: AppColor.grey400),
    ];
    final partsTotal = parts.fold(0.0, (s, p) => s + p.amount);

    Widget stat(String label, String value, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5, color: AppColor.textSecondary)),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ],
    );

    Widget divider() => Container(
        width: 1, height: 22, color: AppColor.grey200,
        margin: const EdgeInsets.symmetric(horizontal: 16));

    return Container(
      height:  58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: LayoutBuilder(builder: (context, c) {
        // Choti chaurai par breakdown bar chhupao (overflow se bachao)
        final showParts = partsTotal > 0 && c.maxWidth >= 1080;
        return Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppColor.textSecondary),
          const SizedBox(width: 8),
          Text(
            'SELECTED PERIOD'
                '${from != null && to != null ? ' · ${_fmtShort(from!)} – ${_fmtShort(to!)}' : ''}',
            style: const TextStyle(
                fontSize:      11.5,
                fontWeight:    FontWeight.w700,
                letterSpacing: 0.5,
                color:         AppColor.textPrimary),
          ),
          const Spacer(),
          stat('Cash In',  _fmt(t.cashIn),  AppColor.success),
          divider(),
          stat('Cash Out', _fmt(t.cashOut), AppColor.error),
          divider(),
          stat('Net', _signed(net),
              net < 0 ? AppColor.error : AppColor.success),
          if (showParts) ...[
            const SizedBox(width: 24),
            SizedBox(
              width: 220,
              child: Column(
                mainAxisAlignment:  MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 7,
                      child: Row(
                        children: [
                          for (var i = 0; i < parts.length; i++) ...[
                            if (i > 0) const SizedBox(width: 2),
                            Expanded(
                              flex: (parts[i].amount * 100).round().clamp(1, 1 << 30),
                              child: Container(color: parts[i].color),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    parts.map((p) =>
                    '${p.label} ${(p.amount * 100 / partsTotal).round()}%')
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColor.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOOLBAR — search · type tabs · date range
// ─────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final WarehouseFinanceState state;
  final ValueChanged<String>  onSearch;
  final ValueChanged<String>  onFilter;
  final void Function(DateTime from, DateTime to) onDateRange;
  final VoidCallback          onDateReset;

  const _Toolbar({
    required this.state,
    required this.onSearch,
    required this.onFilter,
    required this.onDateRange,
    required this.onDateReset,
  });

  static const _tabs = [
    ('All',          'all'),
    ('Cash In',      'cash_in'),
    ('Supplier Pay', 'supplier_payment'),
    ('Expense',      'expense'),
    ('Salary',       'salary'),
  ];

  @override
  Widget build(BuildContext context) {
    // Counts — search ke baad (tab se pehle); Supplier Pay mein reversals bhi
    final base   = state.searchedTransactions;
    final counts = <String, int>{'all': base.length};
    for (final t in base) {
      final k = _isReversal(t) ? 'supplier_payment' : t.entryType;
      counts[k] = (counts[k] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: _SearchBar(
                initial: state.searchQuery, onChanged: onSearch),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color:        AppColor.grey100,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (label, key) in _tabs)
                        _TypeTab(
                          label:    label,
                          count:    counts[key] ?? 0,
                          selected: state.activeFilter == key,
                          onTap:    () => onFilter(key),
                        ),
                    ],
                  ),
                ),
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

class _TypeTab extends StatelessWidget {
  final String       label;
  final int          count;
  final bool         selected;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? AppColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text('$label $count',
            style: TextStyle(
              fontSize:   12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColor.white : AppColor.textPrimary,
            )),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final String               initial;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.initial, required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller =
  TextEditingController(text: widget.initial);

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
        style: const TextStyle(fontSize: 13, color: AppColor.textPrimary),
        decoration: InputDecoration(
          hintText:  'Notes, supplier, entry by se search...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
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
// DATE RANGE FIELD (default last 30 din) — custom par ✕ = reset
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
      lastDate:         DateTime(now.year, now.month, now.day), // aaj tak
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
// TRANSACTIONS TABLE — din-wise groups + pagination
// ─────────────────────────────────────────────────────────────
const int _kColDate    = 2;
const int _kColType    = 3;
const int _kColDetail  = 4;
const int _kColAmount  = 2;
const int _kColBalance = 2;
const int _kColBy      = 2;

class _TransactionsTable extends StatefulWidget {
  final WarehouseFinanceState state;
  final ValueChanged<int>     onPage;
  final ValueChanged<int>     onPageSize;

  const _TransactionsTable({
    required this.state,
    required this.onPage,
    required this.onPageSize,
  });

  @override
  State<_TransactionsTable> createState() => _TransactionsTableState();
}

class _TransactionsTableState extends State<_TransactionsTable> {
  static const double _minWidth = 940;
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st      = widget.state;
    final visible = st.filteredTransactions;

    // Har din ka in/out — poori filtered list se
    final dayTotals = <DateTime, _Totals>{};
    for (final t in visible) {
      dayTotals.putIfAbsent(_dayOf(t.createdAt), () => _Totals()).add(t);
    }

    // Pagination
    final pageCount = visible.isEmpty
        ? 1 : ((visible.length - 1) ~/ st.pageSize) + 1;
    final page  = st.page.clamp(0, pageCount - 1);
    final start = page * st.pageSize;
    final end   = (start + st.pageSize).clamp(0, visible.length);
    final rows  = visible.isEmpty
        ? const <CashTransactionModel>[] : visible.sublist(start, end);

    final items = <Object>[];
    DateTime? lastDay;
    for (final t in rows) {
      final d = _dayOf(t.createdAt);
      if (d != lastDay) {
        items.add(d);
        lastDay = d;
      }
      items.add(t);
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
                                  ? const _EmptyState()
                                  : ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (_, i) {
                                  final it = items[i];
                                  if (it is DateTime) {
                                    return _DaySeparator(
                                        day: it, totals: dayTotals[it]!);
                                  }
                                  final tx = it as CashTransactionModel;
                                  return _TRow(key: ValueKey(tx.id), tx: tx);
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
          Expanded(flex: _kColDate,    child: _HCell('DATE')),
          Expanded(flex: _kColType,    child: _HCell('TYPE')),
          Expanded(flex: _kColDetail,  child: _HCell('DETAIL / NOTES')),
          Expanded(flex: _kColAmount,  child: _HCell('AMOUNT', align: TextAlign.right)),
          Expanded(flex: _kColBalance, child: _HCell('BALANCE', align: TextAlign.right)),
          SizedBox(width: 24),
          Expanded(flex: _kColBy,      child: _HCell('ENTRY BY')),
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

// ── "AAJ · 05 OCT 2026 (4 entries) — In +Rs · Out −Rs" ────────
class _DaySeparator extends StatelessWidget {
  final DateTime day;
  final _Totals  totals;
  const _DaySeparator({required this.day, required this.totals});

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prefix = day == today
        ? 'AAJ · '
        : day == today.subtract(const Duration(days: 1)) ? 'KAL · ' : '';

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
                  color: day == today ? AppColor.success : AppColor.grey500)),
          const SizedBox(width: 8),
          Text('$prefix${_fmtDay(day).toUpperCase()}',
              style: const TextStyle(
                  fontSize:      11.5,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.5,
                  color:         AppColor.textPrimary)),
          const SizedBox(width: 8),
          Text('(${totals.count} ${totals.count == 1 ? 'entry' : 'entries'})',
              style: const TextStyle(fontSize: 11, color: AppColor.textHint)),
          const Spacer(),
          Text.rich(TextSpan(
            style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
            children: [
              const TextSpan(text: 'In '),
              TextSpan(text: '+${_fmt(totals.cashIn)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColor.success)),
              const TextSpan(text: '  ·  Out '),
              TextSpan(text: '−${_fmt(totals.cashOut)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColor.error)),
            ],
          )),
        ],
      ),
    );
  }
}

class _TRow extends StatefulWidget {
  final CashTransactionModel tx;
  const _TRow({super.key, required this.tx});

  @override
  State<_TRow> createState() => _TRowState();
}

class _TRowState extends State<_TRow> {
  bool _hover = false;

  @override
  void deactivate() {
    _hover = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final tx       = widget.tx;
    final color    = _typeColor(tx.entryType);
    final inflow   = tx.isCashIn;
    final reversal = _isReversal(tx);
    final (main, sub) = _detail(tx);
    final by = (tx.createdByName?.trim().isNotEmpty ?? false)
        ? tx.createdByName!.trim() : null;

    return MouseRegion(
      onEnter: (_) { if (mounted) setState(() => _hover = true);  },
      onExit:  (_) { if (mounted) setState(() => _hover = false); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height:   58,
        padding:  const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _hover
              ? AppColor.primary.withOpacity(0.03) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AppColor.grey100)),
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
                  Text(_fmtDay(tx.createdAt.toLocal()),
                      style: const TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      AppColor.textPrimary)),
                  Text(DateFormat('h:mm a').format(tx.createdAt.toLocal()),
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColor.textSecondary)),
                ],
              ),
            ),

            // Type
            Expanded(
              flex: _kColType,
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(_typeIcon(tx.entryType), size: 15, color: color),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(_typeLabel(tx),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.textPrimary)),
                  ),
                  if (reversal) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color:        AppColor.infoLight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColor.info.withOpacity(0.35)),
                      ),
                      child: const Text('REVERSAL',
                          style: TextStyle(
                              fontSize:      8.5,
                              fontWeight:    FontWeight.w700,
                              letterSpacing: 0.4,
                              color:         AppColor.info)),
                    ),
                  ],
                ],
              ),
            ),

            // Detail / notes
            Expanded(
              flex: _kColDetail,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(main,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColor.textPrimary)),
                    if (sub != null)
                      Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColor.textSecondary)),
                  ],
                ),
              ),
            ),

            // Amount (signed)
            Expanded(
              flex: _kColAmount,
              child: Text(
                '${inflow ? '+' : '−'}${_fmt(tx.amount)}',
                textAlign: TextAlign.right,
                maxLines:  1,
                overflow:  TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w700,
                    color: reversal
                        ? AppColor.info
                        : (inflow ? AppColor.success : AppColor.error)),
              ),
            ),

            // Balance after + pehle
            Expanded(
              flex: _kColBalance,
              child: Column(
                mainAxisAlignment:  MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmt(tx.cashInHandAfter),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize:   13.5,
                          fontWeight: FontWeight.w700,
                          // Minus ho toh red dikhao
                          color: tx.cashInHandAfter < 0
                              ? AppColor.error : AppColor.textPrimary)),
                  Text('pehle ${_fmt(tx.cashInHandBefore)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColor.textHint)),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Entry by
            Expanded(
              flex: _kColBy,
              child: by == null
                  ? const Text('—', style: TextStyle(color: AppColor.textHint))
                  : Row(
                children: [
                  _InitialsAvatar(name: by),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(by,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColor.textSecondary)),
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
        color:        AppColor.grey100,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(ini,
          style: const TextStyle(
              fontSize:   9.5,
              fontWeight: FontWeight.w700,
              color:      AppColor.textPrimary)),
    );
  }
}

// ── Footer: count · in/out/net · pagination ──────────────────
class _TableFooter extends StatelessWidget {
  final List<CashTransactionModel> visible;
  final int               shown;
  final int               start;
  final int               page;
  final int               pageCount;
  final int               pageSize;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;

  const _TableFooter({
    required this.visible,
    required this.shown,
    required this.start,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.onPage,
    required this.onPageSize,
  });

  @override
  Widget build(BuildContext context) {
    final t = _Totals.of(visible);

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
      const TextSpan(text: ' transactions'),
    ]));

    final summary = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color:        AppColor.grey100,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Text.rich(TextSpan(style: muted, children: [
        const TextSpan(text: 'In '),
        TextSpan(text: '+${_fmt(t.cashIn)}',
            style: bold.copyWith(color: AppColor.success)),
        const TextSpan(text: '   ·   Out '),
        TextSpan(text: '−${_fmt(t.cashOut)}',
            style: bold.copyWith(color: AppColor.error)),
        const TextSpan(text: '   ·   Net '),
        TextSpan(text: _signed(t.net),
            style: bold.copyWith(
                color: t.net < 0 ? AppColor.error : AppColor.success)),
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
          if (c.maxWidth >= 1050) {
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 40, color: AppColor.grey400),
          SizedBox(height: 12),
          Text('Koi transaction nahi mili',
              style: TextStyle(color: AppColor.textSecondary, fontSize: 14)),
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
