import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../data/model/accountant_profit_loss_model.dart';
import '../provider/accountant_profit_loss_provider.dart';


// ✅ Smart qty formatter — 0.5 → "0.50", 3 → "3"
String _fmtQty(double q) =>
    q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

class PnlReportScreen extends ConsumerStatefulWidget {
  const PnlReportScreen({super.key});

  @override
  ConsumerState<PnlReportScreen> createState() => _PnlReportScreenState();
}

class _PnlReportScreenState extends ConsumerState<PnlReportScreen>
    with SingleTickerProviderStateMixin {
  final _dateFmt  = DateFormat('dd MMM yyyy');
  final _dayFmt   = DateFormat('EEE, dd MMM');
  final _timeFmt  = DateFormat('hh:mm a');
  final _amtFmt   = NumberFormat('#,##,###', 'en_IN');
  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    final state = ref.read(pnlReportProvider);
    _fromCtrl.text = _dateFmt.format(state.fromDate);
    _toCtrl.text   = _dateFmt.format(state.toDate);
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final state = ref.read(pnlReportProvider);
    final init  = isFrom ? state.fromDate : state.toDate;
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
      final n = ref.read(pnlReportProvider.notifier);
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
    final state    = ref.watch(pnlReportProvider);
    final notifier = ref.read(pnlReportProvider.notifier);

    ref.listen<PnlReportState>(pnlReportProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.errorMessage!),
          backgroundColor: AppColor.error,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'OK', textColor: Colors.white,
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
        title: const Text('Profit & Loss',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D23))),
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

        // ── Body ──────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.summary == null
              ? const _EmptyState()
              : _PnlBody(
            summary: state.summary!,
            dayFmt:  _dayFmt,
            timeFmt: _timeFmt,
            fmtAmt:  _fmt,
            tabCtrl: _tabCtrl,
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  P&L Body
// ═══════════════════════════════════════════════════════════

class _PnlBody extends StatelessWidget {
  final PnlSummary              summary;
  final DateFormat              dayFmt;
  final DateFormat              timeFmt;
  final String Function(double) fmtAmt;
  final TabController           tabCtrl;

  const _PnlBody({
    required this.summary,
    required this.dayFmt,
    required this.timeFmt,
    required this.fmtAmt,
    required this.tabCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      // ── Summary Card ────────────────────────────────────
      Container(
        color:   Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(children: [

          // 4 stat chips
          Row(children: [
            _StatChip(
              label: 'Sale Profit',
              value: fmtAmt(summary.grossSaleProfit),
              color: AppColor.success,
              icon:  Icons.trending_up_rounded,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Return Loss',
              value: fmtAmt(summary.grossReturnProfit),
              color: AppColor.error,
              icon:  Icons.trending_down_rounded,
            ),
          ]),

          const SizedBox(height: 10),

          // Net Profit highlight
          _NetProfitBanner(
            netProfit:     summary.netProfit,
            profitMargin:  summary.profitMargin,
            totalInvoices: summary.totalInvoices,
            totalReturns:  summary.totalReturns,
            fmtAmt:        fmtAmt,
          ),
        ]),
      ),

      Container(height: 1, color: const Color(0xFFE5E7EB)),

      // ── Tabs ────────────────────────────────────────────
      Container(
        color: Colors.white,
        child: TabBar(
          controller:       tabCtrl,
          labelColor:       AppColor.primary,
          unselectedLabelColor: AppColor.textSecondary,
          indicatorColor:   AppColor.primary,
          indicatorWeight:  2,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Daily Breakdown'),
            Tab(text: 'Invoices'),
          ],
        ),
      ),

      // ── Tab Views ────────────────────────────────────────
      Expanded(
        child: TabBarView(
          controller: tabCtrl,
          children: [
            _DailyTab(
              daily:  summary.daily,
              dayFmt: dayFmt,
              fmtAmt: fmtAmt,
            ),
            _InvoicesTab(
              invoices: summary.invoices,
              timeFmt:  timeFmt,
              fmtAmt:   fmtAmt,
            ),
          ],
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
//  Net Profit Banner
// ═══════════════════════════════════════════════════════════

class _NetProfitBanner extends StatelessWidget {
  final double              netProfit;
  final double              profitMargin;
  final int                 totalInvoices;
  final int                 totalReturns;
  final String Function(double) fmtAmt;

  const _NetProfitBanner({
    required this.netProfit,
    required this.profitMargin,
    required this.totalInvoices,
    required this.totalReturns,
    required this.fmtAmt,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = netProfit >= 0;
    final color    = isProfit ? AppColor.success : AppColor.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
          begin:  Alignment.centerLeft,
          end:    Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(
                isProfit
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14, color: color,
              ),
              const SizedBox(width: 4),
              Text(
                isProfit ? 'Net Profit' : 'Net Loss',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: color),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              fmtAmt(netProfit.abs()),
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900,
                  color: color),
            ),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _InfoBadge(
              label: '${profitMargin.toStringAsFixed(1)}% margin',
              color: color,
            ),
            const SizedBox(height: 6),
            Text(
              '$totalInvoices invoices  •  $totalReturns returns',
              style: const TextStyle(
                  fontSize: 10, color: AppColor.textHint),
            ),
          ]),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Daily Tab
// ═══════════════════════════════════════════════════════════

class _DailyTab extends StatelessWidget {
  final List<PnlDaySummary>     daily;
  final DateFormat              dayFmt;
  final String Function(double) fmtAmt;

  const _DailyTab({
    required this.daily,
    required this.dayFmt,
    required this.fmtAmt,
  });

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return const _EmptyState();
    return ListView.separated(
      padding:          const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount:        daily.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _DayCard(
          day: daily[i], dayFmt: dayFmt, fmtAmt: fmtAmt),
    );
  }
}

class _DayCard extends StatelessWidget {
  final PnlDaySummary           day;
  final DateFormat              dayFmt;
  final String Function(double) fmtAmt;

  const _DayCard({
    required this.day,
    required this.dayFmt,
    required this.fmtAmt,
  });

  @override
  Widget build(BuildContext context) {
    final net      = day.netProfit;
    final isProfit = net >= 0;
    final color    = isProfit ? AppColor.success : AppColor.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color:        AppColor.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(dayFmt.format(day.date),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColor.primary)),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.add_circle_outline,
                    size: 11, color: AppColor.success),
                const SizedBox(width: 4),
                Text('Sale: ${fmtAmt(day.saleProfit)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColor.success,
                        fontWeight: FontWeight.w600)),
              ]),
              if (day.returnProfit > 0) ...[
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.remove_circle_outline,
                      size: 11, color: AppColor.error),
                  const SizedBox(width: 4),
                  Text('Return: ${fmtAmt(day.returnProfit)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColor.error,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ],
          ),
        ),

        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Net',
              style: const TextStyle(
                  fontSize: 10, color: AppColor.textHint)),
          const SizedBox(height: 2),
          Text(fmtAmt(net.abs()),
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: color)),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Invoices Tab
// ═══════════════════════════════════════════════════════════

class _InvoicesTab extends StatelessWidget {
  final List<PnlInvoice>        invoices;
  final DateFormat              timeFmt;
  final String Function(double) fmtAmt;

  const _InvoicesTab({
    required this.invoices,
    required this.timeFmt,
    required this.fmtAmt,
  });

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) return const _EmptyState();
    return ListView.separated(
      padding:          const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount:        invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) =>
          _InvoicePnlCard(inv: invoices[i], timeFmt: timeFmt, fmtAmt: fmtAmt),
    );
  }
}

class _InvoicePnlCard extends StatefulWidget {
  final PnlInvoice              inv;
  final DateFormat              timeFmt;
  final String Function(double) fmtAmt;

  const _InvoicePnlCard({
    required this.inv,
    required this.timeFmt,
    required this.fmtAmt,
  });

  @override
  State<_InvoicePnlCard> createState() => _InvoicePnlCardState();
}

class _InvoicePnlCardState extends State<_InvoicePnlCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final inv      = widget.inv;
    final isReturn = inv.isReturn;
    final profit   = inv.totalProfit;
    final isProfit = profit >= 0;

    final accentColor = isReturn ? AppColor.error : AppColor.primary;
    final profitColor = isProfit ? AppColor.success : AppColor.error;

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: [

        // ── Header ───────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [

              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color:        accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isReturn
                      ? Icons.assignment_return_outlined
                      : Icons.receipt_outlined,
                  size: 18, color: accentColor,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Text(inv.invoiceNo,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: accentColor)),
                          if (isReturn) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color:        AppColor.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Return',
                                  style: TextStyle(
                                      fontSize: 9, fontWeight: FontWeight.w700,
                                      color: AppColor.error)),
                            ),
                          ],
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:        profitColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: profitColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${isProfit ? '+' : '-'} ${widget.fmtAmt(profit.abs())}',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800,
                                color: profitColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            inv.customerName ?? 'Walk In',
                            style: const TextStyle(
                                fontSize: 11, color: AppColor.textSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          widget.timeFmt.format(inv.date),
                          style: const TextStyle(
                              fontSize: 10, color: AppColor.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns:    _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down,
                    size: 20, color: AppColor.grey400),
              ),
            ]),
          ),
        ),

        // ── Expanded: per-item breakdown ─────────────────
        if (_expanded) ...[
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [

              // Items header
              const Row(children: [
                Expanded(flex: 3, child: _IH(text: 'Product')),
                Expanded(flex: 2, child: _IH(text: 'Formula',     right: false)),
                Expanded(flex: 2, child: _IH(text: 'Profit/Item', right: true)),
              ]),
              const SizedBox(height: 6),

              ...inv.items.map((item) {
                final itemProfit = item.profit;
                final iP = itemProfit >= 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          flex: 3,
                          child: Text(item.productName,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Expanded(
                          flex: 2,
                          // ✅ FIX: Sahi formula display
                          // (sale - cost) × qty - discount
                          // PEHLE: (sale - cost - discount) × qty  ❌
                          child: Text(
                            '(${item.salePrice.toStringAsFixed(0)}'
                                ' - ${item.costPrice.toStringAsFixed(0)})'
                                ' × ${_fmtQty(item.quantity)}'
                                '${item.discount > 0 ? ' - ${item.discount.toStringAsFixed(0)}' : ''}',
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColor.textHint),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${iP ? '+' : '-'} Rs ${itemProfit.abs().toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: iP
                                    ? AppColor.success
                                    : AppColor.error),
                          ),
                        ),
                      ]),
                    ],
                  ),
                );
              }),

              // Total row
              const Divider(height: 16, color: Color(0xFFE5E7EB)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isReturn ? 'Return Loss' : 'Invoice Profit',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${profit >= 0 ? '+' : '-'} ${widget.fmtAmt(profit.abs())}',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: profitColor),
                  ),
                ],
              ),
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
          horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColor.textHint)),
            ],
          ),
        ),
      ]),
    ),
  );
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _InfoBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: color)),
  );
}

class _DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _DateField({
    required this.label, required this.controller, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColor.textSecondary)),
      const SizedBox(height: 4),
      TextField(
        controller: controller, readOnly: true, onTap: onTap,
        cursorHeight: 14,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppColor.primary),
          filled: true, fillColor: AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
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

class _IH extends StatelessWidget {
  final String text;
  final bool   right;
  const _IH({required this.text, this.right = false});

  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: AppColor.textHint, letterSpacing: 0.3));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.analytics_outlined,
          size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text('Koi data nahi mila',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: Colors.grey.shade500)),
      const SizedBox(height: 6),
      Text('Date range change karein',
          style: TextStyle(
              fontSize: 13, color: Colors.grey.shade400)),
    ]),
  );
}