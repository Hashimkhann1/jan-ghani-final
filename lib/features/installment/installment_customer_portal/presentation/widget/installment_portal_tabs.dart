import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/providers/accoutant_session_provider.dart';
import 'package:jan_ghani_final/features/installment/installment_customer_detail/domain/customer_detail_helpers.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';
import 'package:jan_ghani_final/features/installment/installment_plan_detail/domain/installment_schedule_item.dart';

// Customer ke installment tabs (Home / Schedule / History / Empty).
// Portal shell (bottom nav + Invoices) lib/features/customer mein hai — woh
// yeh widgets use karta hai. Data database se (installment_customer / plan /
// schedule / payment) — provider: installment_dashboard_provider.dart.

const _ink = Color(0xFF16201B);
const _muted = Color(0xFF5A6660);
const _line = Color(0xFFE2E5DE);
const _green = Color(0xFF0F5C3F);
const _greenSoft = Color(0xFFE3F0E8);
const _greenDeep = Color(0xFF0B4A32);
const _amberSoft = Color(0xFFFBEBD0);
const _amberInk = Color(0xFF6B3A06);
const _amber = Color(0xFF8A4B08);
const _greySoft = Color(0xFFEEF0EA);
const _redSoft = Color(0xFFFDE4E4);
const _red = Color(0xFFB3261E);

String _rs(num v) => 'Rs. ${NumberFormat('#,##0').format(v.round())}';


// ── Shared bits ──────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: child,
      );
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Chip(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
      );
}

Widget _kv(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k,
              style: const TextStyle(
                  color: _muted, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(v,
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

class _Title extends StatelessWidget {
  final String title;
  final String sub;
  const _Title(this.title, this.sub);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(
                  fontSize: 13, color: _muted, fontWeight: FontWeight.w500)),
        ],
      );
}

/// Schedule / History par plan badalne ke chips (sirf jab 1 se zyada plans hon).
class InstallmentPlanPicker extends StatelessWidget {
  final InstallmentCustomer customer;
  final int index;
  final ValueChanged<int> onPick;
  final Widget child;
  const InstallmentPlanPicker({
    required this.customer,
    required this.index,
    required this.onPick,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (customer.plans.length < 2) return child;
    return Column(
      children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            scrollDirection: Axis.horizontal,
            itemCount: customer.plans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ChoiceChip(
              label: Text(customer.plans[i].product),
              selected: i == index,
              onSelected: (_) => onPick(i),
              selectedColor: _greenSoft,
              labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: i == index ? _greenDeep : _muted),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

// ── Home ─────────────────────────────────────────────────────────────────────
class InstallmentHomeTab extends StatelessWidget {
  final InstallmentCustomer customer;
  final VoidCallback onLogout;

  /// Customer ka avatar aur naam (customer feature se) — na milne par mock naam.
  final Widget? avatar;
  final String? displayName;
  const InstallmentHomeTab({
    required this.customer,
    required this.onLogout,
    this.avatar,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final next = c.nextDuePlan;
    final due = c.nextDueDate;
    final days = due == null
        ? null
        : DateTime(due.year, due.month, due.day)
            .difference(DateTime.now().copyWith(
                hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0))
            .inDays;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      children: [
        Row(
          children: [
            if (avatar != null) ...[avatar!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assalam o Alaikum',
                      style: TextStyle(
                          fontSize: 13,
                          color: _muted,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(displayName ?? c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, color: _muted, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              color: _green, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Remaining Balance',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFCFE6D8))),
              const SizedBox(height: 14),
              Text(_rs(c.totalRemaining),
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5)),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: c.progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF2F7A5A),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Paid ${_rs(c.totalPaid)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE3F0E8))),
                  Text('Total ${_rs(c.totalPayable)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE3F0E8))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          child: next == null
              ? const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: _green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('All installments are paid. Thank you!',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Next Installment',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        if (days != null)
                          days < 0
                              ? _Chip('Overdue by ${-days} days', _redSoft, _red)
                              : _Chip(
                                  days == 0 ? 'Due today' : 'Due in $days days',
                                  _amberSoft,
                                  _amber),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_rs(next.nextAmount),
                                style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                                'Installment ${next.nextDue?.number ?? next.paidCount + 1} of ${next.totalCount}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: _muted,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Due date',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _muted,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(planDetailDmy(due!),
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        for (final p in c.plans) ...[
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.plans.length > 1 ? 'Your Items' : 'Your Item',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                _kv('Item', p.product),
                const Divider(height: 12, color: _line),
                if (p.advance > 0) _kv('Advance paid', _rs(p.advance)),
                _kv('Monthly installment', _rs(p.monthlyAmount)),
                _kv('Installments left',
                    '${p.totalCount - p.paidCount} of ${p.totalCount}'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Schedule ─────────────────────────────────────────────────────────────────
class InstallmentScheduleTab extends StatelessWidget {
  final InstallmentPlan plan;
  const InstallmentScheduleTab({required this.plan});

  @override
  Widget build(BuildContext context) {
    final items = buildScheduleFromPlan(plan);
    final paidAmt = plan.paidAmount;
    final left = plan.totalCount - plan.paidCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      children: [
        _Title('Installment Schedule',
            '${plan.product} · ${plan.totalCount} monthly installments'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Stat('Paid', _rs(paidAmt),
                  '${plan.paidCount} installment${plan.paidCount == 1 ? '' : 's'}',
                  _greenSoft, _green, _greenDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat('Remaining', _rs(plan.remaining),
                  '$left installment${left == 1 ? '' : 's'}',
                  _amberSoft, _amber, _amberInk),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _ScheduleRow(
                  item: items[i],
                  overdue: items[i].isOverdue,
                  last: i == items.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value, sub;
  final Color bg, labelFg, valueFg;
  const _Stat(this.label, this.value, this.sub, this.bg, this.labelFg,
      this.valueFg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: labelFg)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: valueFg)),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, color: valueFg)),
          ],
        ),
      );
}

class _ScheduleRow extends StatelessWidget {
  final InstallmentScheduleItem item;
  final bool overdue;
  final bool last;
  const _ScheduleRow(
      {required this.item, required this.overdue, required this.last});

  @override
  Widget build(BuildContext context) {
    final paid = item.status == ScheduleStatus.paid;
    final isDue = item.status == ScheduleStatus.due;
    final dotBg = paid ? _green : (isDue ? (overdue ? _redSoft : _amberSoft) : _greySoft);
    final dotFg = paid ? Colors.white : (isDue ? (overdue ? _red : _amberInk) : _muted);
    final chipBg = paid ? _greenSoft : (isDue ? (overdue ? _redSoft : _amberSoft) : _greySoft);
    final chipFg = paid ? _greenDeep : (isDue ? (overdue ? _red : _amberInk) : const Color(0xFF4A5650));
    final label = paid ? 'Paid' : (isDue ? (overdue ? 'Overdue' : 'Next') : 'Upcoming');

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFEEF0EA))),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: dotBg, shape: BoxShape.circle),
            child: Text('${item.number}',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: dotFg)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(planDetailDmy(item.dueDate),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(
                    item.isPartial
                        ? '${_rs(item.paidAmount)} paid of ${_rs(item.amount)}'
                        : _rs(item.amount),
                    style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _Chip(label, chipBg, chipFg),
        ],
      ),
    );
  }
}

// ── History ──────────────────────────────────────────────────────────────────
class InstallmentHistoryTab extends StatelessWidget {
  final InstallmentCustomer customer;
  final InstallmentPlan plan;
  const InstallmentHistoryTab({required this.customer, required this.plan});

  @override
  Widget build(BuildContext context) {
    final paid = plan.payments; // naye pehle (advance + qiston ki payments)
    final totalPaid = paid.fold<double>(0, (s, p) => s + p.amount);
    final next = plan.nextDueDate;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      children: [
        const _Title('Payment History', 'All payments received by Jan Ghani'),
        const SizedBox(height: 16),
        _Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total paid so far',
                      style: TextStyle(
                          fontSize: 12,
                          color: _muted,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(_rs(totalPaid),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Remaining',
                      style: TextStyle(
                          fontSize: 12,
                          color: _muted,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(_rs(plan.remaining),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _amber)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: paid.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No payments yet',
                        style: TextStyle(
                            color: _muted, fontWeight: FontWeight.w600)),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < paid.length; i++)
                      Container(
                        constraints: const BoxConstraints(minHeight: 72),
                        decoration: BoxDecoration(
                          border: i == paid.length - 1
                              ? null
                              : const Border(
                                  bottom: BorderSide(color: Color(0xFFEEF0EA))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                  color: _greenSoft, shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded,
                                  color: _green, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      paid[i].isAdvance
                                          ? 'Advance'
                                          : 'Installment ${paid[i].installmentNumber ?? ''}'.trim(),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(planDetailDmy(paid[i].paidAt.toLocal()),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: _muted,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            Text(_rs(paid[i].amount),
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        if (next != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: _amberSoft, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next payment',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _amberInk)),
                const SizedBox(height: 4),
                Text(
                    '${_rs(plan.nextAmount)} is due on ${planDetailDmy(next)}. Please pay at the shop.',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _amberInk)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Empty ────────────────────────────────────────────────────────────────────
class InstallmentEmptyTab extends ConsumerWidget {
  final int tab;
  final VoidCallback onLogout;
  final Widget? avatar;
  final String? displayName;
  const InstallmentEmptyTab({
    required this.tab,
    required this.onLogout,
    this.avatar,
    this.displayName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name =
        displayName ?? ref.watch(currentUserProvider)?.fullName ?? '';
    final (title, sub, icon) = switch (tab) {
      0 => ('Home', 'Your installment summary will appear here',
          Icons.home_outlined),
      1 => ('Installment Schedule', 'Your monthly installments will appear here',
          Icons.calendar_month_outlined),
      _ => ('Payment History', 'Your payments will appear here',
          Icons.history_rounded),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      children: [
        Row(
          children: [
            if (tab == 0 && avatar != null) ...[
              avatar!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: tab == 0 && name.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assalam o Alaikum',
                            style: TextStyle(
                                fontSize: 13,
                                color: _muted,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(name,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _ink)),
                      ],
                    )
                  : _Title(title, sub),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, color: _muted, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Icon(icon, size: 56, color: _muted.withValues(alpha: 0.6)),
        const SizedBox(height: 16),
        const Text('No installment plan yet',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 6),
        const Text(
            'Visit your nearest branch to start an installment plan.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _muted,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
