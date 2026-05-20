import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../data/datasource/branch_cash_counter_datasource.dart';
import '../../data/model/branch_cash_counter_model.dart';
import '../provider/branch_cash_counter_provider.dart';

class BranchCashCounterReportScreen extends ConsumerStatefulWidget {
  const BranchCashCounterReportScreen({super.key});

  @override
  ConsumerState<BranchCashCounterReportScreen> createState() =>
      _BranchCashCounterReportScreenState();
}

class _BranchCashCounterReportScreenState
    extends ConsumerState<BranchCashCounterReportScreen> {
  final _dateFmt  = DateFormat('dd MMM yyyy');
  final _dayFmt   = DateFormat('EEE, dd MMM');
  final _amtFmt   = NumberFormat('#,##,###', 'en_IN');
  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(branchCashCounterProvider);
    _fromCtrl.text = _dateFmt.format(state.fromDate);
    _toCtrl.text   = _dateFmt.format(state.toDate);
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final state  = ref.read(branchCashCounterProvider);
    final init   = isFrom ? state.fromDate : state.toDate;
    final picked = await showDatePicker(
      context:     context,
      initialDate: init,
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
          const ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final n = ref.read(branchCashCounterProvider.notifier);
      if (isFrom) {
        _fromCtrl.text = _dateFmt.format(picked);
        n.setFromDate(picked);
      } else {
        _toCtrl.text = _dateFmt.format(picked);
        n.setToDate(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(branchCashCounterProvider);
    final notifier = ref.read(branchCashCounterProvider.notifier);

    ref.listen<BranchCashCounterState>(
        branchCashCounterProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.errorMessage!),
          backgroundColor: AppColor.error,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label:     'OK',
            textColor: Colors.white,
            onPressed: notifier.clearError,
          ),
        ));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Cash Counter Report',
            style: TextStyle(
                fontSize:   17,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF1A1D23))),
        actions: [
          IconButton(
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
          ),
          TextButton(
            onPressed: () {
              notifier.setThisMonth();
              final n = DateTime.now();
              _fromCtrl.text =
                  _dateFmt.format(DateTime(n.year, n.month, 1));
              _toCtrl.text = _dateFmt
                  .format(DateTime(n.year, n.month, n.day));
            },
            child: const Text('Month'),
          ),
          TextButton(
            onPressed: () {
              notifier.setToday();
              final d = DateTime.now();
              final c = DateTime(d.year, d.month, d.day);
              _fromCtrl.text = _dateFmt.format(c);
              _toCtrl.text   = _dateFmt.format(c);
            },
            child: const Text('Today'),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
          Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(children: [

        // ── Date Filters ────────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            Expanded(
              child: _DateField(
                label: 'Start Date', controller: _fromCtrl,
                onTap: () => _pickDate(context, true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateField(
                label: 'End Date', controller: _toCtrl,
                onTap: () => _pickDate(context, false),
              ),
            ),
          ]),
        ),

        // ── Body ────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.summary == null || state.summary!.days.isEmpty
              ? const _EmptyState()
              : _CounterBody(
            summary: state.summary!,
            dayFmt:  _dayFmt,
            fmtAmt:  _fmt,
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Body
// ═══════════════════════════════════════════════════════════

class _CounterBody extends StatelessWidget {
  final BranchCashCounterSummary summary;
  final DateFormat               dayFmt;
  final String Function(double)  fmtAmt;

  const _CounterBody({
    required this.summary,
    required this.dayFmt,
    required this.fmtAmt,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [

        // ── Top summary chips ─────────────────────────────
        Row(children: [
          _StatChip(
            label: 'Cash Sale',
            value: fmtAmt(summary.totalCashSale),
            color: AppColor.success,
            icon:  Icons.payments_outlined,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Card Sale',
            value: fmtAmt(summary.totalCardSale),
            color: AppColor.info,
            icon:  Icons.credit_card_outlined,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Credit Sale',
            value: fmtAmt(summary.totalCreditSale),
            color: AppColor.warning,
            icon:  Icons.receipt_long_outlined,
          ),
        ]),

        const SizedBox(height: 12),

        // ── Full Summary Card ─────────────────────────────
        Container(
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color:      Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset:     const Offset(0, 2)),
            ],
          ),
          child: Column(children: [

            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
              child: Row(children: [
                const Icon(Icons.point_of_sale_outlined,
                    size: 18, color: AppColor.primary),
                const SizedBox(width: 8),
                const Text('Period Summary',
                    style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.primary)),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [

                _SummaryRow(
                  icon:  Icons.payments_outlined,
                  label: 'Cash Sale',
                  value: fmtAmt(summary.totalCashSale),
                  color: AppColor.success,
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  icon:  Icons.credit_card_outlined,
                  label: 'Card Sale',
                  value: fmtAmt(summary.totalCardSale),
                  color: AppColor.info,
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  icon:  Icons.receipt_long_outlined,
                  label: 'Credit Sale',
                  value: fmtAmt(summary.totalCreditSale),
                  color: AppColor.warning,
                ),
                if (summary.totalInstallment > 0) ...[
                  const SizedBox(height: 10),
                  _SummaryRow(
                    icon:  Icons.calendar_month_outlined,
                    label: 'Installment',
                    value: fmtAmt(summary.totalInstallment),
                    color: AppColor.primary,
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),

                if (summary.totalCashIn > 0) ...[
                  _SummaryRow(
                    icon:  Icons.south_rounded,
                    label: 'Cash In',
                    value: fmtAmt(summary.totalCashIn),
                    color: AppColor.success,
                  ),
                  const SizedBox(height: 10),
                ],
                if (summary.totalCashOut > 0) ...[
                  _SummaryRow(
                    icon:  Icons.north_rounded,
                    label: 'Cash Out',
                    value: fmtAmt(summary.totalCashOut),
                    color: AppColor.error,
                    prefix: '- ',
                  ),
                  const SizedBox(height: 10),
                ],

                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),

                // Total Sale
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Sale',
                        style: TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.w700,
                            color:      Color(0xFF1A1D23))),
                    Text(
                      fmtAmt(summary.totalSale),
                      style: const TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.w900,
                          color:      AppColor.primary),
                    ),
                  ],
                ),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Daily Breakdown ───────────────────────────────
        const Text('Daily Breakdown',
            style: TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF1A1D23))),
        const SizedBox(height: 10),

        ...summary.days.map((d) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _DayCard(day: d, dayFmt: dayFmt, fmtAmt: fmtAmt),
        )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Day Card
// ═══════════════════════════════════════════════════════════

class _DayCard extends StatefulWidget {
  final BranchCashCounterDay    day;
  final DateFormat              dayFmt;
  final String Function(double) fmtAmt;

  const _DayCard({
    required this.day,
    required this.dayFmt,
    required this.fmtAmt,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.day;

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset:     const Offset(0, 2)),
        ],
      ),
      child: Column(children: [

        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(children: [

              // Date badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color:        AppColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.dayFmt.format(d.date),
                    style: const TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.primary)),
              ),
              const SizedBox(width: 10),

              // Payment chips
              Expanded(
                child: Wrap(spacing: 4, runSpacing: 4, children: [
                  if (d.cashSale > 0)
                    _MiniChip(
                        label:
                        'Cash: ${widget.fmtAmt(d.cashSale)}',
                        color: AppColor.success),
                  if (d.cardSale > 0)
                    _MiniChip(
                        label:
                        'Card: ${widget.fmtAmt(d.cardSale)}',
                        color: AppColor.info),
                  if (d.creditSale > 0)
                    _MiniChip(
                        label:
                        'Credit: ${widget.fmtAmt(d.creditSale)}',
                        color: AppColor.warning),
                ]),
              ),
              const SizedBox(width: 8),

              // Total
              Text(widget.fmtAmt(d.totalSale),
                  style: const TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w800,
                      color:      AppColor.primary)),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns:    _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down,
                    size: 18, color: AppColor.grey400),
              ),
            ]),
          ),
        ),

        // ── Expanded detail ─────────────────────────────
        if (_expanded) ...[
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(children: [
              _DetailRow(
                  label: 'Cash Sale',
                  value: widget.fmtAmt(d.cashSale),
                  color: AppColor.success),
              const SizedBox(height: 6),
              _DetailRow(
                  label: 'Card Sale',
                  value: widget.fmtAmt(d.cardSale),
                  color: AppColor.info),
              const SizedBox(height: 6),
              _DetailRow(
                  label: 'Credit Sale',
                  value: widget.fmtAmt(d.creditSale),
                  color: AppColor.warning),
              if (d.installment > 0) ...[
                const SizedBox(height: 6),
                _DetailRow(
                    label: 'Installment',
                    value: widget.fmtAmt(d.installment),
                    color: AppColor.primary),
              ],
              if (d.cashIn > 0 || d.cashOut > 0) ...[
                const Divider(
                    height: 14, color: Color(0xFFE5E7EB)),
                if (d.cashIn > 0)
                  _DetailRow(
                      label: 'Cash In',
                      value: widget.fmtAmt(d.cashIn),
                      color: AppColor.success),
                if (d.cashOut > 0) ...[
                  const SizedBox(height: 6),
                  _DetailRow(
                      label: 'Cash Out',
                      value: widget.fmtAmt(d.cashOut),
                      color: AppColor.error),
                ],
              ],
              const Divider(
                  height: 14, color: Color(0xFFE5E7EB)),
              _DetailRow(
                  label: 'Total Sale',
                  value: widget.fmtAmt(d.totalSale),
                  color: AppColor.primary,
                  bold:  true),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Shared Widgets
// ═══════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  final String   label;
  final String   value;
  final Color    color;
  final IconData icon;

  const _StatChip({
    required this.label, required this.value,
    required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset:     const Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w800,
                color:      color),
            maxLines:  1,
            overflow:  TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColor.textHint)),
      ]),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final String   prefix;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color:    Color(0xFF4B5563))),
      ]),
      Text('$prefix$value',
          style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w700,
              color:      color)),
    ],
  );
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color  color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize:   9,
            fontWeight: FontWeight.w600,
            color:      color)),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final bool   bold;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: TextStyle(
              fontSize:   12,
              fontWeight:
              bold ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF4B5563))),
      Text(value,
          style: TextStyle(
              fontSize:   12,
              fontWeight:
              bold ? FontWeight.w800 : FontWeight.w600,
              color: color)),
    ],
  );
}

class _DateField extends StatelessWidget {
  final String                label;
  final TextEditingController controller;
  final VoidCallback          onTap;

  const _DateField({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      AppColor.textSecondary)),
      const SizedBox(height: 4),
      TextField(
        controller:   controller,
        readOnly:     true,
        onTap:        onTap,
        cursorHeight: 14,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppColor.primary),
          filled:    true,
          fillColor: AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:   BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: AppColor.grey200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppColor.primary, width: 1.5)),
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.point_of_sale_outlined,
          size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text('Koi data nahi mila',
          style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      Colors.grey.shade500)),
      const SizedBox(height: 6),
      Text('Date range change karein',
          style: TextStyle(
              fontSize: 13, color: Colors.grey.shade400)),
    ]),
  );
}