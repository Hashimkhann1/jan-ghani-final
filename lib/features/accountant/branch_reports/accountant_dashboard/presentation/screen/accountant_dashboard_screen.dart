import '../../../common/action/report_refresh_button.dart';
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
import '../widget/insights_section.dart';
import '../widget/top_products_section.dart';

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

  // Filter dialog ka draft — "Apply" dabane par hi data load hota hai.
  late DateTime _dFrom, _dTo;

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
    final init = isFrom ? _dFrom : _dTo;
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
    final combined = DateTime(
      picked.year, picked.month, picked.day,
      init.hour, init.minute, init.second,
    );
    if (isFrom) {
      _fromCtrl.text = _dateFmt.format(combined);
      _dFrom = combined;
    } else {
      _toCtrl.text = _dateFmt.format(combined);
      _dTo = combined;
    }
  }

  Future<void> _pickTime(BuildContext context, bool isFrom) async {
    final init = isFrom ? _dFrom : _dTo;
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
    final combined = DateTime(
      init.year, init.month, init.day,
      picked.hour, picked.minute,
    );
    if (isFrom) {
      _fromTimeCtrl.text = _timeFmt.format(combined);
      _dFrom = combined;
    } else {
      _toTimeCtrl.text = _timeFmt.format(combined);
      _dTo = combined;
    }
  }

  void _setToday(dynamic notifier) {
    notifier.setToday();
    _dFrom = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _dTo   = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59);
    final now        = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay   = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _fromCtrl.text     = _dateFmt.format(startOfDay);
    _toCtrl.text       = _dateFmt.format(endOfDay);
    _fromTimeCtrl.text = _timeFmt.format(startOfDay);
    _toTimeCtrl.text   = _timeFmt.format(endOfDay);
  }

  void _openFilters() {
    final st = ref.read(accountantBranchDashboardProvider(widget.branchId));
    _dFrom = st.fromDate;
    _dTo   = st.toDate;
    _fromCtrl.text     = _dateFmt.format(_dFrom);
    _toCtrl.text       = _dateFmt.format(_dTo);
    _fromTimeCtrl.text = _timeFmt.format(_dFrom);
    _toTimeCtrl.text   = _timeFmt.format(_dTo);
    showReportFilterDialog(
      context: context,
      onApply: () => ref
          .read(accountantBranchDashboardProvider(widget.branchId).notifier)
          .setRange(_dFrom, _dTo),
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
          ReportFilterButton(onPressed: _openFilters),
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
          ReportRefreshButton(onPressed: notifier.load),
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
              _CardRows(
                  cards:  _dashboardCards(state.data!, _fmt),
                  perRow: desktop ? 3 : 2),
              const SizedBox(height: 16),

              // ── Charts ────────────────────────────────
              _ChartsSection(
                state:    state,
                desktop:  desktop,
                onPeriod: notifier.setChartPeriod,
              ),
              const SizedBox(height: 12),
              TopProductsSection(
                branchId: widget.branchId,
                endDate:  state.toDate,
                desktop:  desktop,
              ),
              const SizedBox(height: 16),
              InsightsSection(
                branchId: widget.branchId,
                endDate:  state.toDate,
                desktop:  desktop,
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
          '${fmtAmt(data.totalSaleReturn)} return\n'
          'Profit: ${fmtAmt(data.grossProfit - data.pmgProfit - data.digitalProfit)}',
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
      title:      isLoss ? 'Total Loss' : 'Total Profit',
      value:      fmtAmt(data.grossProfit.abs()),
      subtitle:   'Physical + Pull PMG + Digital',
      icon:       isLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
      color:      isLoss ? const Color(0xFFDC2626) : const Color(0xFF0F6E56),
      bgColor:    isLoss ? const Color(0xFFFEF2F2) : const Color(0xFFE1F5EE),
      valueColor: isLoss ? const Color(0xFFDC2626) : const Color(0xFF0F6E56),
    ),
    DashboardStatCard(
      title:     'Pull PMG',
      value:     fmtAmt(data.pmgSale),
      subtitle:  'Profit: ${fmtAmt(data.pmgProfit)}',
      icon:      Icons.swap_vert_rounded,
      color:     const Color(0xFF0369A1),
      bgColor:   const Color(0xFFE0F2FE),
    ),
    DashboardStatCard(
      title:     'Digital Services',
      value:     fmtAmt(data.digitalSale),
      subtitle:  'Profit: ${fmtAmt(data.digitalProfit)}',
      icon:      Icons.phone_android_rounded,
      color:     const Color(0xFF6D28D9),
      bgColor:   const Color(0xFFEDE9FE),
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
  final int perRow;

  const _CardRows({required this.cards, this.perRow = 3});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += perRow) {
      final chunk = cards.skip(i).take(perRow).toList();
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var j = 0; j < perRow; j++) ...[
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

    TrendBarChart bar(String t, DashboardChart c,
            double Function(DashboardTrendPoint) f, List<Color> g) =>
        TrendBarChart(
          title:     t,
          data:      state.trendOf(c),
          valueOf:   f,
          trailing:  toggle(c),
          isLoading: state.isTrendLoading(c),
          gradient:  g,
        );
    TrendLineChart line(String t, DashboardChart c,
            double Function(DashboardTrendPoint) f, Color col) =>
        TrendLineChart(
          title:     t,
          data:      state.trendOf(c),
          valueOf:   f,
          trailing:  toggle(c),
          isLoading: state.isTrendLoading(c),
          color:     col,
        );
    const pmgCol = Color(0xFF0369A1), digCol = Color(0xFF6D28D9);
    final pmgSale = bar('Pull PMG Sale', DashboardChart.pmgSale,
        (p) => p.pmgSale, const [pmgCol, Color(0xFF7DD3FC)]);
    final pmgProfit = line('Pull PMG Profit', DashboardChart.pmgProfit,
        (p) => p.pmgProfit, pmgCol);
    final digSale = bar('Digital Services Sale', DashboardChart.digitalSale,
        (p) => p.digitalSale, const [digCol, Color(0xFFC4B5FD)]);
    final digProfit = line('Digital Services Profit',
        DashboardChart.digitalProfit, (p) => p.digitalProfit, digCol);

    if (!desktop) {
      return Column(children: [
        sales,
        const SizedBox(height: 12),
        profit,
        const SizedBox(height: 12),
        credit,
        const SizedBox(height: 12),
        installment,
        const SizedBox(height: 12),
        pmgSale,
        const SizedBox(height: 12),
        pmgProfit,
        const SizedBox(height: 12),
        digSale,
        const SizedBox(height: 12),
        digProfit,
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
      const SizedBox(height: 12),
      pair(pmgSale, pmgProfit),
      const SizedBox(height: 12),
      pair(digSale, digProfit),
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