import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/app_icon.dart';
import '../../../common/export/report_export_button.dart';
import '../../data/service/dashboard_export_sheets.dart';
import '../../../common/filter/report_filter_dialog.dart';
import '../../data/model/accountant_dashboard_model.dart';
import '../provider/accountant_dashboard_provider.dart';
import '../widget/dashboard_stat_card.dart';
import '../widget/dashboard_trend_charts.dart';

class AccountantBranchDashboardScreen extends ConsumerStatefulWidget {
  const AccountantBranchDashboardScreen(
      {required this.branchId, super.key});
  final String branchId;

  @override
  ConsumerState<AccountantBranchDashboardScreen> createState() =>
      _AccountantBranchDashboardScreenState();
}

class _AccountantBranchDashboardScreenState
    extends ConsumerState<AccountantBranchDashboardScreen> {
  final _amtFmt       = NumberFormat('#,##,###', 'en_IN');
  final _dateFmt      = DateFormat('dd MMM yyyy');
  final _timeFmt      = DateFormat('hh:mm a');
  final _fromCtrl     = TextEditingController();
  final _toCtrl       = TextEditingController();
  final _fromTimeCtrl = TextEditingController();
  final _toTimeCtrl   = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(accountantBranchDashboardProvider(widget.branchId));
    _fromCtrl.text     = _dateFmt.format(state.fromDate);
    _toCtrl.text       = _dateFmt.format(state.toDate);
    _fromTimeCtrl.text = _timeFmt.format(state.fromDate);
    _toTimeCtrl.text   = _timeFmt.format(state.toDate);
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _fromTimeCtrl.dispose();
    _toTimeCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final state = ref.read(accountantBranchDashboardProvider(widget.branchId));
    final init  = isFrom ? state.fromDate : state.toDate;
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
    if (picked == null) return;
    final notifier = ref.read(
        accountantBranchDashboardProvider(widget.branchId).notifier);
    final combined = DateTime(
      picked.year, picked.month, picked.day,
      init.hour, init.minute, init.second,
    );
    if (isFrom) {
      _fromCtrl.text = _dateFmt.format(combined);
      notifier.setFromDate(combined);
    } else {
      _toCtrl.text = _dateFmt.format(combined);
      notifier.setToDate(combined);
    }
  }

  Future<void> _pickTime(BuildContext context, bool isFrom) async {
    final state = ref.read(accountantBranchDashboardProvider(widget.branchId));
    final init  = isFrom ? state.fromDate : state.toDate;
    final picked = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(init),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final notifier = ref.read(
        accountantBranchDashboardProvider(widget.branchId).notifier);
    final combined = DateTime(
      init.year, init.month, init.day,
      picked.hour, picked.minute,
    );
    if (isFrom) {
      _fromTimeCtrl.text = _timeFmt.format(combined);
      notifier.setFromDate(combined);
    } else {
      _toTimeCtrl.text = _timeFmt.format(combined);
      notifier.setToDate(combined);
    }
  }

  void _setToday(dynamic notifier) {
    notifier.setToday();
    final now        = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay   = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _fromCtrl.text     = _dateFmt.format(startOfDay);
    _toCtrl.text       = _dateFmt.format(endOfDay);
    _fromTimeCtrl.text = _timeFmt.format(startOfDay);
    _toTimeCtrl.text   = _timeFmt.format(endOfDay);
  }

  void _openFilters() {
    showReportFilterDialog(
      context: context,
      onReset: () => _setToday(
          ref.read(accountantBranchDashboardProvider(widget.branchId).notifier)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              child: _DateField(
                label: 'Start Date',
                controller: _fromCtrl,
                onTap: () => _pickDate(context, true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeField(
                label: 'Start Time',
                controller: _fromTimeCtrl,
                onTap: () => _pickTime(context, true),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _DateField(
                label: 'End Date',
                controller: _toCtrl,
                onTap: () => _pickDate(context, false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeField(
                label: 'End Time',
                controller: _toTimeCtrl,
                onTap: () => _pickTime(context, false),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
        accountantBranchDashboardProvider(widget.branchId));
    final notifier = ref.read(
        accountantBranchDashboardProvider(widget.branchId).notifier);
    final desktop = _isDesktop(context);

    ref.listen<AccountantBranchDashboardState>(
      accountantBranchDashboardProvider(widget.branchId),
          (prev, next) {
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
      },
    );

    final rangeFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF1A1D23)),
        titleSpacing: desktop ? 8 : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:       MainAxisSize.min,
          children: [
            const Text('Branch Dashboard',
              style: TextStyle(
                color:      Color(0xFF1A1D23),
                fontSize:   17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${rangeFmt.format(state.fromDate)}  →  '
                  '${rangeFmt.format(state.toDate)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize:   11,
                color:      Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const AppIcon('ic_filter',
                color: Color(0xFF6B7280), size: 20),
            onPressed: _openFilters,
            tooltip: 'Filters',
          ),
          IconButton(
            icon: const AppIcon('ic_calendar',
                color: Color(0xFF6B7280), size: 20),
            onPressed: () => _setToday(notifier),
            tooltip: 'Today',
          ),
          ReportExportButton(
            fileNamePrefix: 'branch_dashboard',
            enabled: state.data != null,
            loadSheets: () async => DashboardExportSheets.build(
              data: state.data!,
              fromDate: state.fromDate,
              toDate: state.toDate,
            ),
          ),
          IconButton(
            icon: const AppIcon('ic_refresh',
                color: Color(0xFF6B7280), size: 20),
            onPressed: notifier.load,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.data == null
          ? const _EmptyState()
          : RefreshIndicator(
        onRefresh: notifier.load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary Cards (3 per row) ─────────────
              _CardRows(cards: _dashboardCards(state.data!, _fmt)),
              const SizedBox(height: 16),

              // ── Charts ────────────────────────────────
              _ChartsSection(
                state:    state,
                desktop:  desktop,
                onPeriod: notifier.setChartPeriod,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary cards ────────────────────────────────────────────────────────────
List<Widget> _dashboardCards(
  AccountantBranchDashboardModel data,
  String Function(double) fmtAmt,
) {
  final isLoss = data.grossProfit < 0;
  return [
    DashboardStatCard(
      title:     'Total Sale',
      value:     fmtAmt(data.netSale),
      subtitle:  '${fmtAmt(data.totalSale)} sale − '
          '${fmtAmt(data.totalSaleReturn)} return',
      icon:      Icons.bar_chart_rounded,
      iconAsset: 'ic_total_sale',
      color:     const Color(0xFF534AB7),
      bgColor:   const Color(0xFFEEEDFE),
    ),
    DashboardStatCard(
      title:     'Customer Collection',
      value:     fmtAmt(data.installmentSale),
      subtitle:  'Customers se wusooli',
      icon:      Icons.calendar_month_outlined,
      iconAsset: 'ic_installment',
      color:     const Color(0xFF993556),
      bgColor:   const Color(0xFFFBEAF0),
    ),
    DashboardStatCard(
      title:      isLoss ? 'Loss' : 'Profit',
      value:      fmtAmt(data.grossProfit.abs()),
      subtitle:   'Profit & Loss (returns minus)',
      icon:       isLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
      color:      isLoss ? const Color(0xFFDC2626) : const Color(0xFF0F6E56),
      bgColor:    isLoss ? const Color(0xFFFEF2F2) : const Color(0xFFE1F5EE),
      valueColor: isLoss ? const Color(0xFFDC2626) : const Color(0xFF0F6E56),
    ),
    DashboardStatCard(
      title:     'Cash In',
      value:     fmtAmt(data.cashIn),
      icon:      Icons.south_west_rounded,
      iconAsset: 'ic_cash_in',
      color:     const Color(0xFF3B9A5E),
      bgColor:   const Color(0xFFEAF3DE),
    ),
    DashboardStatCard(
      title:     'Cash Out',
      value:     fmtAmt(data.cashOut),
      icon:      Icons.north_east_rounded,
      iconAsset: 'ic_cash_out',
      color:     const Color(0xFFDC2626),
      bgColor:   const Color(0xFFFEF2F2),
    ),
    DashboardStatCard(
      title:     'Total Customer Amount',
      value:     fmtAmt(data.outstandingReceivable),
      subtitle:  'Customers ka baqaya (receivable)',
      icon:      Icons.account_balance_wallet_outlined,
      color:     const Color(0xFF854F0B),
      bgColor:   const Color(0xFFFAEEDA),
    ),
  ];
}

class _CardRows extends StatelessWidget {
  final List<Widget> cards;
  static const _perRow = 3;

  const _CardRows({required this.cards});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += _perRow) {
      final chunk = cards.skip(i).take(_perRow).toList();
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var j = 0; j < _perRow; j++) ...[
              if (j > 0) const SizedBox(width: 12),
              Expanded(child: j < chunk.length ? chunk[j] : const SizedBox()),
            ],
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

// ── Charts: Sales (bar) + Profit (line) ─────────────────────────────────────
class _ChartsSection extends StatelessWidget {
  final AccountantBranchDashboardState        state;
  final bool                                  desktop;
  final void Function(DashboardChart, DashboardTrendPeriod) onPeriod;

  const _ChartsSection({
    required this.state,
    required this.desktop,
    required this.onPeriod,
  });

  @override
  Widget build(BuildContext context) {
    // Har graph ka apna Weekly/Monthly — ek badalne se baqi nahi badalte.
    Widget toggle(DashboardChart c) => TrendPeriodToggle(
        value: state.periodOf(c), onChanged: (p) => onPeriod(c, p));

    final sales = TrendBarChart(
      title:     'Sales (Net)',
      data:      state.trendOf(DashboardChart.sales),
      valueOf:   (p) => p.netSale,
      isLoading: state.isTrendLoading(DashboardChart.sales),
      trailing:  toggle(DashboardChart.sales),
    );
    final profit = TrendLineChart(
      title:     'Profit',
      data:      state.trendOf(DashboardChart.profit),
      valueOf:   (p) => p.profit,
      trailing:  toggle(DashboardChart.profit),
      isLoading: state.isTrendLoading(DashboardChart.profit),
    );
    final credit = TrendBarChart(
      title:     'Credit Sale',
      data:      state.trendOf(DashboardChart.credit),
      valueOf:   (p) => p.creditSale,
      trailing:  toggle(DashboardChart.credit),
      isLoading: state.isTrendLoading(DashboardChart.credit),
      gradient:  const [Color(0xFFB7791F), Color(0xFFF6D79B)],
    );
    final installment = TrendLineChart(
      title:     'Installment Collection',
      data:      state.trendOf(DashboardChart.installment),
      valueOf:   (p) => p.installment,
      trailing:  toggle(DashboardChart.installment),
      isLoading: state.isTrendLoading(DashboardChart.installment),
      color:     const Color(0xFF993556),
    );

    if (!desktop) {
      return Column(children: [
        sales,
        const SizedBox(height: 12),
        profit,
        const SizedBox(height: 12),
        credit,
        const SizedBox(height: 12),
        installment,
      ]);
    }

    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );

    return Column(children: [
      pair(sales, profit),
      const SizedBox(height: 12),
      pair(credit, installment),
    ]);
  }
}

// ── Shared date/time filter fields ──────────────────────────────────────────
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
      Text(
        label,
        style: const TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      AppColor.textSecondary,
        ),
      ),
      const SizedBox(height: 4),
      TextField(
        controller:   controller,
        readOnly:     true,
        onTap:        onTap,
        cursorHeight: 14,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1D23)),
        decoration: InputDecoration(
          prefixIcon: const AppIcon('ic_calendar',
              size: 16, color: AppColor.primary),
          filled:     true,
          fillColor:  AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColor.grey200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: AppColor.primary, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

class _TimeField extends StatelessWidget {
  final String                label;
  final TextEditingController controller;
  final VoidCallback          onTap;

  const _TimeField({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      AppColor.textSecondary,
        ),
      ),
      const SizedBox(height: 4),
      TextField(
        controller:   controller,
        readOnly:     true,
        onTap:        onTap,
        cursorHeight: 14,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1D23)),
        decoration: InputDecoration(
          prefixIcon: const AppIcon('ic_calendar',
              size: 16, color: AppColor.primary),
          filled:     true,
          fillColor:  AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColor.grey200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: AppColor.primary, width: 1.5),
          ),
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
      AppIcon('sidebar_icons/dashboard',
          size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(
        'No data found',
        style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w600,
            color:      Colors.grey.shade500),
      ),
      const SizedBox(height: 6),
      Text(
        'Change date range and refresh',
        style: TextStyle(
            fontSize: 13, color: Colors.grey.shade400),
      ),
    ]),
  );
}