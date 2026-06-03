import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../data/model/branch_cash_counter_model.dart';
import '../provider/branch_cash_counter_provider.dart';

class BranchCashCounterReportScreen extends ConsumerStatefulWidget {
  const BranchCashCounterReportScreen({required this.branchId, super.key});
  final String branchId;

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
    final now = DateTime.now();
    _fromCtrl.text = _dateFmt.format(DateTime(now.year, now.month, 1));
    _toCtrl.text   = _dateFmt.format(DateTime(now.year, now.month, now.day));
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final state  = ref.read(branchCashCounterProvider(widget.branchId));
    final init   = isFrom ? state.fromDate : state.toDate;
    final picked = await showDatePicker(
      context:     context,
      initialDate: init,
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final n = ref.read(branchCashCounterProvider(widget.branchId).notifier);
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
    final state    = ref.watch(branchCashCounterProvider(widget.branchId));
    final notifier = ref.read(branchCashCounterProvider(widget.branchId).notifier);

    ref.listen<BranchCashCounterState>(
        branchCashCounterProvider(widget.branchId), (prev, next) {
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
      // Controllers update when loading completes
      if (prev?.isLoading == true && !next.isLoading) {
        _fromCtrl.text = _dateFmt.format(next.fromDate);
        _toCtrl.text   = _dateFmt.format(next.toDate);
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
              _fromCtrl.text = _dateFmt.format(DateTime(n.year, n.month, 1));
              _toCtrl.text   = _dateFmt.format(DateTime(n.year, n.month, n.day));
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
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(children: [

        // ── Date Filters ──────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            Expanded(
              child: _DateField(
                label:      'Start Date',
                controller: _fromCtrl,
                onTap:      () => _pickDate(context, true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateField(
                label:      'End Date',
                controller: _toCtrl,
                onTap:      () => _pickDate(context, false),
              ),
            ),
          ]),
        ),

        // ── Body ──────────────────────────────────────────
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

        // ── Period Summary Card ───────────────────────────
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
                const SizedBox(height: 10),
                _SummaryRow(
                  icon:  Icons.calendar_month_outlined,
                  label: 'Installment',
                  value: fmtAmt(summary.totalInstallment),
                  color: AppColor.primary,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),

                _SummaryRow(
                  icon:  Icons.south_rounded,
                  label: 'Cash In',
                  value: fmtAmt(summary.totalCashIn),
                  color: AppColor.success,
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  icon:  Icons.north_rounded,
                  label: 'Cash Out',
                  value: fmtAmt(summary.totalCashOut),
                  color: AppColor.error,
                  prefix: '- ',
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),

                // Total Sale
                _SummaryRow(
                  icon:  Icons.shopping_cart_outlined,
                  label: 'Total Sale',
                  value: fmtAmt(summary.totalSale),
                  color: AppColor.primary,
                ),
                const SizedBox(height: 10),

                // Total Amount (cash received)
                _SummaryRow(
                  icon:  Icons.account_balance_wallet_outlined,
                  label: 'Total Amount',
                  value: fmtAmt(summary.totalAmount),
                  color: const Color(0xFF8B5CF6),
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
//  Day Card — collapsed + expanded with ALL fields
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

        // ── Collapsed Header ──────────────────────────────
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

              // Quick chips
              Expanded(
                child: Wrap(spacing: 4, runSpacing: 4, children: [
                  if (d.cashSale > 0)
                    _MiniChip(
                        label: 'Cash: ${widget.fmtAmt(d.cashSale)}',
                        color: AppColor.success),
                  if (d.cardSale > 0)
                    _MiniChip(
                        label: 'Card: ${widget.fmtAmt(d.cardSale)}',
                        color: AppColor.info),
                  if (d.creditSale > 0)
                    _MiniChip(
                        label: 'Credit: ${widget.fmtAmt(d.creditSale)}',
                        color: AppColor.warning),
                  if (d.installment > 0)
                    _MiniChip(
                        label: 'Install: ${widget.fmtAmt(d.installment)}',
                        color: AppColor.primary),
                ]),
              ),
              const SizedBox(width: 8),

              // Total Sale
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(widget.fmtAmt(d.totalSale),
                    style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w800,
                        color:      AppColor.primary)),
                const Text('Total Sale',
                    style: TextStyle(
                        fontSize: 9, color: AppColor.textHint)),
              ]),
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

        // ── Expanded Detail — ALL 8 fields ───────────────
        if (_expanded) ...[
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(children: [

              // Sales section
              _DetailRow(
                  icon:  Icons.payments_outlined,
                  label: 'Cash Sale',
                  value: widget.fmtAmt(d.cashSale),
                  color: AppColor.success),
              const SizedBox(height: 8),
              _DetailRow(
                  icon:  Icons.credit_card_outlined,
                  label: 'Card Sale',
                  value: widget.fmtAmt(d.cardSale),
                  color: AppColor.info),
              const SizedBox(height: 8),
              _DetailRow(
                  icon:  Icons.receipt_long_outlined,
                  label: 'Credit Sale',
                  value: widget.fmtAmt(d.creditSale),
                  color: AppColor.warning),
              const SizedBox(height: 8),
              _DetailRow(
                  icon:  Icons.calendar_month_outlined,
                  label: 'Installment',
                  value: widget.fmtAmt(d.installment),
                  color: AppColor.primary),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFE5E7EB)),
              ),

              // Cash movements
              _DetailRow(
                  icon:  Icons.south_rounded,
                  label: 'Cash In',
                  value: widget.fmtAmt(d.cashIn),
                  color: AppColor.success),
              const SizedBox(height: 8),
              _DetailRow(
                  icon:  Icons.north_rounded,
                  label: 'Cash Out',
                  value: widget.fmtAmt(d.cashOut),
                  color: AppColor.error),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFE5E7EB)),
              ),

              // Totals
              _DetailRow(
                  icon:  Icons.shopping_cart_outlined,
                  label: 'Total Sale',
                  value: widget.fmtAmt(d.totalSale),
                  color: AppColor.primary,
                  bold:  true),
              const SizedBox(height: 8),
              _DetailRow(
                  icon:  Icons.account_balance_wallet_outlined,
                  label: 'Total Amount',
                  value: widget.fmtAmt(d.totalAmount),
                  color: const Color(0xFF8B5CF6),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final bool     bold;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize:   12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color:      const Color(0xFF4B5563))),
      ]),
      Text(value,
          style: TextStyle(
              fontSize:   12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
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
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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