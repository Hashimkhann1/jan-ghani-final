import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../data/model/pareto_report_model.dart';
import '../provider/pareto_report_provider.dart';

const _kWideBreakpoint = 900.0;

// ── Helpers ───────────────────────────────────────────────
final _amtFmt  = NumberFormat('#,##,###', 'en_IN');
final _dateFmt = DateFormat('dd MMM yyyy');
String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';
String _pct(double part, double total) =>
    total > 0 ? (part / total * 100).toStringAsFixed(1) : '0.0';

// ═══════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════
class ParetoReportScreen extends ConsumerWidget {
  final String branchId;
  const ParetoReportScreen({super.key, required this.branchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(paretoReportProvider(branchId));
    final notifier = ref.read(paretoReportProvider(branchId).notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor:  Colors.white,
          elevation:        0,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Pareto Report (80/20)',
            style: TextStyle(
              fontSize:   17,
              fontWeight: FontWeight.w700,
              color:      Color(0xFF1A1D23),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColor.textSecondary),
              tooltip: 'Refresh',
              onPressed: notifier.load,
            ),
            const SizedBox(width: 4),
          ],
          bottom: const _ParetoTabBar(),
        ),
        body: Column(
          children: [
            // ── Date Filter Bar ──────────────────────────
            _DateFilterBar(
              startDate: state.startDate,
              endDate:   state.endDate,
              onChanged: notifier.setDateRange,
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // ── Content ──────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
                  : state.errorMessage != null
                  ? _ErrorView(
                message: state.errorMessage!,
                onRetry: notifier.load,
              )
                  : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide =
                      constraints.maxWidth >= _kWideBreakpoint;
                  return TabBarView(
                    children: [
                      _ProductTab(
                        products: state.data.products,
                        summary:  state.data.summary,
                        isWide:   isWide,
                      ),
                      _CustomerSalesTab(
                        customers: state.data.salesCustomers,
                        summary:   state.data.summary,
                        isWide:    isWide,
                      ),
                      _CustomerBalanceTab(
                        customers: state.data.balanceCustomers,
                        summary:   state.data.summary,
                        isWide:    isWide,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB BAR — pill segmented control, each tab keeps its own accent
// color (matches the Products / Customers / Balance color coding
// used throughout the rest of the report) instead of a single flat
// underline indicator.
// ═══════════════════════════════════════════════════════════
class _TabSpec {
  final IconData icon;
  final String   label;
  final Color    color;
  const _TabSpec(this.icon, this.label, this.color);
}

const _paretoTabs = [
  _TabSpec(Icons.inventory_2_outlined, 'Products', AppColor.primary),
  _TabSpec(Icons.people_outline_rounded, 'Customers', AppColor.success),
  _TabSpec(Icons.account_balance_wallet_outlined, 'Balance', AppColor.error),
];

class _ParetoTabBar extends StatefulWidget implements PreferredSizeWidget {
  const _ParetoTabBar();

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  State<_ParetoTabBar> createState() => _ParetoTabBarState();
}

class _ParetoTabBarState extends State<_ParetoTabBar> {
  TabController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = DefaultTabController.of(context);
    if (c != _controller) {
      _controller?.removeListener(_onTick);
      _controller = c..addListener(_onTick);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return Container(
      color:   Colors.white,
      height:  62,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color:        AppColor.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(_paretoTabs.length, (i) {
            final spec     = _paretoTabs[i];
            final selected = controller.index == i;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap:    () => controller.animateTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve:    Curves.easeOut,
                  margin:   const EdgeInsets.symmetric(horizontal: 2),
                  padding:  const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:        selected ? spec.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: selected
                        ? [
                      BoxShadow(
                        color:      spec.color.withOpacity(0.35),
                        blurRadius: 8,
                        offset:     const Offset(0, 3),
                      ),
                    ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(spec.icon,
                          size:  15,
                          color: selected ? Colors.white : AppColor.textSecondary),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          spec.label,
                          maxLines:  1,
                          overflow:  TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize:   12,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                            color:      selected ? Colors.white : AppColor.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DATE FILTER BAR
// ═══════════════════════════════════════════════════════════
class _DateFilterBar extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime, DateTime) onChanged;

  const _DateFilterBar({
    required this.startDate,
    required this.endDate,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context, bool isStart) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:      context,
      initialDate:  isStart ? startDate : endDate,
      firstDate:    DateTime(2020),
      lastDate:     now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColor.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    if (isStart) {
      onChanged(picked, picked.isAfter(endDate) ? picked : endDate);
    } else {
      onChanged(picked.isBefore(startDate) ? picked : startDate, picked);
    }
  }

  void _applyQuick(String range) {
    final now = DateTime.now();
    DateTime start;
    switch (range) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        start = now.subtract(const Duration(days: 6));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        break;
      case '3months':
        start = DateTime(now.year, now.month - 2, 1);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = DateTime(now.year, now.month, 1);
    }
    onChanged(start, now);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kWideBreakpoint;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: isWide
          ? Row(
        children: [
          // Date pickers
          _DatePickerField(
            label: 'From',
            date:  startDate,
            icon:  Icons.calendar_today_outlined,
            onTap: () => _pick(context, true),
          ),
          const SizedBox(width: 10),
          _DatePickerField(
            label: 'To',
            date:  endDate,
            icon:  Icons.calendar_month_outlined,
            onTap: () => _pick(context, false),
          ),
          const SizedBox(width: 16),
          // Quick filters
          ..._quickChips(context),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'From',
                  date:  startDate,
                  icon:  Icons.calendar_today_outlined,
                  onTap: () => _pick(context, true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DatePickerField(
                  label: 'To',
                  date:  endDate,
                  icon:  Icons.calendar_month_outlined,
                  onTap: () => _pick(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _quickChips(context)),
          ),
        ],
      ),
    );
  }

  List<Widget> _quickChips(BuildContext context) {
    final chips = [
      ('today',   'Today'),
      ('week',    'This Week'),
      ('month',   'This Month'),
      ('3months', '3 Months'),
      ('year',    'This Year'),
    ];
    return chips.map((c) {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ActionChip(
          label: Text(c.$2,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          backgroundColor: AppColor.primary.withOpacity(0.06),
          side: BorderSide(color: AppColor.primary.withOpacity(0.3)),
          labelStyle: const TextStyle(color: AppColor.primary),
          onPressed: () => _applyQuick(c.$1),
        ),
      );
    }).toList();
  }
}

class _DatePickerField extends StatelessWidget {
  final String   label;
  final DateTime date;
  final IconData icon;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border:       Border.all(color: AppColor.grey200),
          borderRadius: BorderRadius.circular(8),
          color:        AppColor.grey100,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColor.primary),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        color: AppColor.textHint,
                        fontWeight: FontWeight.w600)),
                Text(_dateFmt.format(date),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23))),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, size: 18, color: AppColor.textHint),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 1 — Products  (sirf TOP 20%)
// ═══════════════════════════════════════════════════════════
class _ProductTab extends StatelessWidget {
  final List<ParetoProductModel> products;
  final ParetoReportSummary      summary;
  final bool                     isWide;

  const _ProductTab({
    required this.products,
    required this.summary,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SimpleStatsBar(
          items: [
            _StatBarItem('Total Sale', _fmt(summary.totalRevenue),  AppColor.primary),
            _StatBarItem('Revenue',    _fmt(summary.paretoRevenue), AppColor.success),
            _StatBarItem('Profit',     _fmt(summary.paretoProfit),  AppColor.warning),
          ],
        ),
        _ParetoLabel(
          label:
          'Top ${summary.paretoProductCount} products → ${_pct(summary.paretoRevenue, summary.totalRevenue)}% revenue  •  ${_pct(summary.paretoProfit, summary.totalProfit)}% profit',
          color: AppColor.primary,
        ),
        Expanded(
          child: products.isEmpty
              ? const _EmptyState(
            icon:     Icons.inventory_2_outlined,
            message:  'No products found',
            subtitle: 'Try a different date range',
          )
              : isWide
              ? _ProductWebTable(products: products, summary: summary)
              : _ProductMobileList(products: products, summary: summary),
        ),
      ],
    );
  }
}

class _ProductWebTable extends StatelessWidget {
  final List<ParetoProductModel> products;
  final ParetoReportSummary      summary;

  const _ProductWebTable({required this.products, required this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF5F6FA),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Row(children: [
                _Th('#',        flex: 1),
                _Th('Product',  flex: 5),
                _Th('SKU',      flex: 3),
                _Th('Revenue',  flex: 3, align: TextAlign.right),
                _Th('Rev %',    flex: 2, align: TextAlign.right),
                _Th('Profit',   flex: 3, align: TextAlign.right),
                _Th('Profit %', flex: 2, align: TextAlign.right),
                _Th('Qty',      flex: 2, align: TextAlign.right),
              ]),
            ),
            ...products.asMap().entries.map((entry) {
              final i      = entry.key;
              final p      = entry.value;
              final revPct = summary.totalRevenue > 0
                  ? p.totalRevenue / summary.totalRevenue * 100 : 0.0;
              final profPct = summary.totalProfit > 0
                  ? p.totalProfit / summary.totalProfit * 100 : 0.0;

              return Container(
                decoration: BoxDecoration(
                  color: i.isEven ? const Color(0xFFF9FAFB) : Colors.white,
                  border: const Border(
                    top: BorderSide(color: Color(0xFFF1F2F5)),
                    left: BorderSide(color: AppColor.primary, width: 3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(children: [
                  _Td('${i + 1}', flex: 1, bold: true, color: AppColor.primary),
                  _Td(p.productName, flex: 5, bold: true),
                  _Td(p.sku, flex: 3, color: AppColor.textSecondary, fontSize: 12),
                  _Td(_fmt(p.totalRevenue), flex: 3, align: TextAlign.right,
                      bold: true, color: AppColor.success),
                  _Td('${revPct.toStringAsFixed(1)}%', flex: 2,
                      align: TextAlign.right, color: AppColor.textSecondary, fontSize: 12),
                  _Td(_fmt(p.totalProfit), flex: 3, align: TextAlign.right,
                      bold: true,
                      color: p.totalProfit >= 0 ? AppColor.success : AppColor.error),
                  _Td('${profPct.toStringAsFixed(1)}%', flex: 2,
                      align: TextAlign.right, color: AppColor.textSecondary, fontSize: 12),
                  _Td(p.totalQty.toInt().toString(), flex: 2, align: TextAlign.right),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ProductMobileList extends StatelessWidget {
  final List<ParetoProductModel> products;
  final ParetoReportSummary      summary;

  const _ProductMobileList({required this.products, required this.summary});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p      = products[i];
        final revPct = summary.totalRevenue > 0
            ? p.totalRevenue / summary.totalRevenue * 100 : 0.0;

        return _MobileCard(
          rank:  i + 1,
          color: AppColor.primary,
          bgColor: AppColor.primary.withOpacity(0.05),
          title: p.productName,
          subtitle: p.sku,
          progress: (p.totalRevenue / (summary.totalRevenue > 0 ? summary.totalRevenue : 1)).clamp(0.0, 1.0),
          stats: [
            _StatItem('Revenue', _fmt(p.totalRevenue), AppColor.success),
            _StatItem('Profit',  _fmt(p.totalProfit),
                p.totalProfit >= 0 ? AppColor.success : AppColor.error),
            _StatItem('Qty',     p.totalQty.toInt().toString(), AppColor.textSecondary),
          ],
          badge: '${revPct.toStringAsFixed(1)}% of revenue',
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 2 — Customer Sales  (sirf TOP 20%)
// ═══════════════════════════════════════════════════════════
class _CustomerSalesTab extends StatelessWidget {
  final List<ParetoCustomerSalesModel> customers;
  final ParetoReportSummary            summary;
  final bool                           isWide;

  const _CustomerSalesTab({
    required this.customers,
    required this.summary,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SimpleStatsBar(
          items: [
            _StatBarItem('Total Sales',   _fmt(summary.totalSalesAmount),  AppColor.success),
            _StatBarItem('Top 20% Sales', _fmt(summary.paretoSalesAmount), AppColor.info),
          ],
        ),
        _ParetoLabel(
          label:
          'Top ${summary.paretoSalesCustomerCount} customers → ${_pct(summary.paretoSalesAmount, summary.totalSalesAmount)}% of total sales',
          color: AppColor.success,
        ),
        Expanded(
          child: customers.isEmpty
              ? const _EmptyState(
            icon:     Icons.people_outline_rounded,
            message:  'No customers found',
            subtitle: 'Try a different date range',
          )
              : isWide
              ? _CustSalesWebTable(customers: customers, summary: summary)
              : _CustSalesMobileList(customers: customers, summary: summary),
        ),
      ],
    );
  }
}

class _CustSalesWebTable extends StatelessWidget {
  final List<ParetoCustomerSalesModel> customers;
  final ParetoReportSummary            summary;

  const _CustSalesWebTable({required this.customers, required this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF5F6FA),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Row(children: [
                _Th('#',           flex: 1),
                _Th('Customer',    flex: 5),
                _Th('Phone',       flex: 3),
                _Th('Total Sales', flex: 4, align: TextAlign.right),
                _Th('Share %',     flex: 2, align: TextAlign.right),
              ]),
            ),
            ...customers.asMap().entries.map((entry) {
              final i   = entry.key;
              final c   = entry.value;
              final pct = summary.totalSalesAmount > 0
                  ? c.totalSales / summary.totalSalesAmount * 100 : 0.0;

              return Container(
                decoration: BoxDecoration(
                  color: i.isEven ? const Color(0xFFF9FAFB) : Colors.white,
                  border: const Border(
                    top: BorderSide(color: Color(0xFFF1F2F5)),
                    left: BorderSide(color: AppColor.success, width: 3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(children: [
                  _Td('${i + 1}', flex: 1, bold: true, color: AppColor.success),
                  _Td(c.customerName, flex: 5, bold: true),
                  _Td(c.phone.isEmpty ? '—' : c.phone, flex: 3,
                      color: AppColor.textSecondary, fontSize: 12),
                  _Td(_fmt(c.totalSales), flex: 4, align: TextAlign.right,
                      bold: true, color: AppColor.success),
                  _Td('${pct.toStringAsFixed(1)}%', flex: 2,
                      align: TextAlign.right, color: AppColor.textSecondary, fontSize: 12),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CustSalesMobileList extends StatelessWidget {
  final List<ParetoCustomerSalesModel> customers;
  final ParetoReportSummary            summary;

  const _CustSalesMobileList({required this.customers, required this.summary});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: customers.length,
      itemBuilder: (context, i) {
        final c   = customers[i];
        final pct = summary.totalSalesAmount > 0
            ? c.totalSales / summary.totalSalesAmount * 100 : 0.0;

        return _MobileCard(
          rank:    i + 1,
          color:   AppColor.success,
          bgColor: AppColor.success.withOpacity(0.05),
          title:   c.customerName,
          subtitle: c.phone.isEmpty ? null : c.phone,
          progress: (c.totalSales / (summary.totalSalesAmount > 0 ? summary.totalSalesAmount : 1)).clamp(0.0, 1.0),
          stats: [
            _StatItem('Sales', _fmt(c.totalSales), AppColor.success),
            _StatItem('Share', '${pct.toStringAsFixed(1)}%', AppColor.info),
          ],
          badge: '${pct.toStringAsFixed(1)}% of total',
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 3 — Pending Balance  (sirf TOP 20%)
// ═══════════════════════════════════════════════════════════
class _CustomerBalanceTab extends StatelessWidget {
  final List<ParetoCustomerBalanceModel> customers;
  final ParetoReportSummary              summary;
  final bool                             isWide;

  const _CustomerBalanceTab({
    required this.customers,
    required this.summary,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SimpleStatsBar(
          items: [
            _StatBarItem('Total Pending',   _fmt(summary.totalBalanceAmount),  AppColor.error),
            _StatBarItem('Top 20% Balance', _fmt(summary.paretoBalanceAmount), AppColor.warning),
          ],
        ),
        _ParetoLabel(
          label:
          'Top ${summary.paretoBalanceCustomerCount} customers → ${_pct(summary.paretoBalanceAmount, summary.totalBalanceAmount)}% pending balance',
          color: AppColor.error,
        ),
        Expanded(
          child: customers.isEmpty
              ? const _EmptyState(
            icon:     Icons.account_balance_wallet_outlined,
            message:  'No pending balances',
            subtitle: 'Try a different date range',
          )
              : isWide
              ? _CustBalWebTable(customers: customers, summary: summary)
              : _CustBalMobileList(customers: customers, summary: summary),
        ),
      ],
    );
  }
}

class _CustBalWebTable extends StatelessWidget {
  final List<ParetoCustomerBalanceModel> customers;
  final ParetoReportSummary              summary;

  const _CustBalWebTable({required this.customers, required this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF5F6FA),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Row(children: [
                _Th('#',            flex: 1),
                _Th('Customer',     flex: 5),
                _Th('Phone',        flex: 3),
                _Th('Type',         flex: 2, align: TextAlign.center),
                _Th('Balance',      flex: 3, align: TextAlign.right),
                _Th('Credit Limit', flex: 3, align: TextAlign.right),
                _Th('Share %',      flex: 2, align: TextAlign.right),
                _Th('',             flex: 2),
              ]),
            ),
            ...customers.asMap().entries.map((entry) {
              final i   = entry.key;
              final c   = entry.value;
              final pct = summary.totalBalanceAmount > 0
                  ? c.balance / summary.totalBalanceAmount * 100 : 0.0;

              return Container(
                decoration: BoxDecoration(
                  color: i.isEven ? const Color(0xFFF9FAFB) : Colors.white,
                  border: const Border(
                    top: BorderSide(color: Color(0xFFF1F2F5)),
                    left: BorderSide(color: AppColor.error, width: 3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(children: [
                  _Td('${i + 1}', flex: 1, bold: true, color: AppColor.error),
                  _Td(c.customerName, flex: 5, bold: true),
                  _Td(c.phone.isEmpty ? '—' : c.phone, flex: 3,
                      color: AppColor.textSecondary, fontSize: 12),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.customerType == 'credit'
                              ? AppColor.info.withOpacity(0.1)
                              : AppColor.grey100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(c.customerType.toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: c.customerType == 'credit'
                                    ? AppColor.info
                                    : AppColor.textSecondary)),
                      ),
                    ),
                  ),
                  _Td(_fmt(c.balance), flex: 3, align: TextAlign.right,
                      bold: true, color: AppColor.error),
                  _Td(c.creditLimit > 0 ? _fmt(c.creditLimit) : '—', flex: 3,
                      align: TextAlign.right, color: AppColor.textSecondary),
                  _Td('${pct.toStringAsFixed(1)}%', flex: 2,
                      align: TextAlign.right, color: AppColor.textSecondary, fontSize: 12),
                  Expanded(
                    flex: 2,
                    child: c.isCreditLimitExceeded
                        ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColor.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('LIMIT ×',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                        : const SizedBox(),
                  ),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CustBalMobileList extends StatelessWidget {
  final List<ParetoCustomerBalanceModel> customers;
  final ParetoReportSummary              summary;

  const _CustBalMobileList({required this.customers, required this.summary});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: customers.length,
      itemBuilder: (context, i) {
        final c   = customers[i];
        final pct = summary.totalBalanceAmount > 0
            ? c.balance / summary.totalBalanceAmount * 100 : 0.0;

        return _MobileCard(
          rank:    i + 1,
          color:   AppColor.error,
          bgColor: AppColor.error.withOpacity(0.05),
          title:   c.customerName,
          subtitle: c.phone.isEmpty ? null : c.phone,
          progress: (c.balance / (summary.totalBalanceAmount > 0 ? summary.totalBalanceAmount : 1)).clamp(0.0, 1.0),
          stats: [
            _StatItem('Balance', _fmt(c.balance), AppColor.error),
            if (c.creditLimit > 0)
              _StatItem('Limit', _fmt(c.creditLimit), AppColor.textSecondary),
            _StatItem('Share', '${pct.toStringAsFixed(1)}%', AppColor.warning),
          ],
          badge: c.isCreditLimitExceeded ? 'LIMIT ×' : '${pct.toStringAsFixed(1)}%',
          badgeDanger: c.isCreditLimitExceeded,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Shared Widgets
// ═══════════════════════════════════════════════════════════

class _ParetoLabel extends StatelessWidget {
  final String label;
  final Color  color;
  const _ParetoLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withOpacity(0.07),
      child: Row(
        children: [
          Icon(Icons.star_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// Simple horizontal stats bar
class _StatBarItem {
  final String label;
  final String value;
  final Color  color;
  const _StatBarItem(this.label, this.value, this.color);
}

class _SimpleStatsBar extends StatelessWidget {
  final List<_StatBarItem> items;
  const _SimpleStatsBar({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F6FA),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:        item.color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: item.color.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color:        item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(Icons.circle, size: 8, color: item.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label,
                            style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(item.value,
                              maxLines: 1,
                              style: TextStyle(
                                  fontSize:   14,
                                  fontWeight: FontWeight.w800,
                                  color:      item.color)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Mobile reusable card
class _StatItem {
  final String label;
  final String value;
  final Color  color;
  const _StatItem(this.label, this.value, this.color);
}

class _MobileCard extends StatelessWidget {
  final int          rank;
  final Color        color;
  final Color        bgColor;
  final String       title;
  final String?      subtitle;
  final double       progress;
  final List<_StatItem> stats;
  final String?      badge;
  final bool         badgeDanger;

  const _MobileCard({
    required this.rank,
    required this.color,
    required this.bgColor,
    required this.title,
    this.subtitle,
    required this.progress,
    required this.stats,
    this.badge,
    this.badgeDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset:     const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width:  32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text('$rank',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1D23)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 11, color: AppColor.textHint)),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeDanger ? AppColor.error : color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(badge!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: stats.map((s) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color:        s.color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(7),
                      border:       Border.all(color: s.color.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label,
                            style: const TextStyle(
                                fontSize: 9, color: AppColor.textHint)),
                        const SizedBox(height: 2),
                        Text(s.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize:   11,
                                fontWeight: FontWeight.w700,
                                color:      s.color)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value:           progress,
                backgroundColor: AppColor.grey200,
                valueColor:      AlwaysStoppedAnimation<Color>(color),
                minHeight:       5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Web table helpers
class _Th extends StatelessWidget {
  final String    text;
  final int       flex;
  final TextAlign align;
  const _Th(this.text, {required this.flex, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(text,
        textAlign: align,
        style: const TextStyle(
            color:         AppColor.textHint,
            fontSize:      10,
            fontWeight:    FontWeight.w700,
            letterSpacing: 0.3)),
  );
}

class _Td extends StatelessWidget {
  final String    text;
  final int       flex;
  final TextAlign align;
  final bool      bold;
  final Color?    color;
  final double    fontSize;

  const _Td(this.text, {
    required this.flex,
    this.align    = TextAlign.left,
    this.bold     = false,
    this.color,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(text,
        textAlign: align,
        style: TextStyle(
            fontSize:   fontSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            color:      color ?? const Color(0xFF1A1D23))),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   message;
  final String   subtitle;
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w600,
            color:      Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 48, color: AppColor.error),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColor.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon:  const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
