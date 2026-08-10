import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
        backgroundColor: const Color(0xFFF1F3F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1D23),
          elevation: 0,
          title: const Text(
            'Pareto Report  (80 / 20)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: notifier.load,
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: const Color(0xFF2563EB),
            indicatorWeight: 3,
            labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Products'),
              Tab(text: 'Top Customers'),
              Tab(text: 'Pending Balance'),
            ],
          ),
        ),
        body: Column(
          children: [
            // ── Date Filter Bar ──────────────────────────
            _DateFilterBar(
              startDate: state.startDate,
              endDate:   state.endDate,
              onChanged: notifier.setDateRange,
            ),

            // ── Content ──────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
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
            primary: Color(0xFF2563EB),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          backgroundColor: const Color(0xFFEFF6FF),
          side: const BorderSide(color: Color(0xFF2563EB), width: 0.8),
          labelStyle: const TextStyle(color: Color(0xFF2563EB)),
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
          border:       Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color:        const Color(0xFFF8FAFF),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF2563EB)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500)),
                Text(_dateFmt.format(date),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade500),
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
            _StatBarItem('Total Sale',  _fmt(summary.totalRevenue),  const Color(0xFF2563EB)),
            _StatBarItem('Revenue',     _fmt(summary.paretoRevenue), const Color(0xFF16A34A)),
            _StatBarItem('Profit',      _fmt(summary.paretoProfit),  const Color(0xFFD97706)),
          ],
        ),
        _ParetoLabel(
          label:
          'Top ${summary.paretoProductCount} products → ${_pct(summary.paretoRevenue, summary.totalRevenue)}% revenue  •  ${_pct(summary.paretoProfit, summary.totalProfit)}% profit',
          color: const Color(0xFF2563EB),
        ),
        Expanded(
          child: isWide
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
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF1E3A5F),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
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
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p      = products[i];
                final revPct = summary.totalRevenue > 0
                    ? p.totalRevenue / summary.totalRevenue * 100 : 0.0;
                final profPct = summary.totalProfit > 0
                    ? p.totalProfit / summary.totalProfit * 100 : 0.0;

                return Container(
                  decoration: BoxDecoration(
                    color: i.isEven ? const Color(0xFFEFF6FF) : Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                      left: const BorderSide(color: Color(0xFF2563EB), width: 3),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(children: [
                    _Td('${i + 1}', flex: 1, bold: true, color: const Color(0xFF2563EB)),
                    _Td(p.productName, flex: 5, bold: true),
                    _Td(p.sku, flex: 3, color: Colors.grey.shade600, fontSize: 12),
                    _Td(_fmt(p.totalRevenue), flex: 3, align: TextAlign.right,
                        bold: true, color: const Color(0xFF16A34A)),
                    _Td('${revPct.toStringAsFixed(1)}%', flex: 2,
                        align: TextAlign.right, color: Colors.grey.shade600, fontSize: 12),
                    _Td(_fmt(p.totalProfit), flex: 3, align: TextAlign.right,
                        bold: true,
                        color: p.totalProfit >= 0 ? const Color(0xFF16A34A) : Colors.red.shade600),
                    _Td('${profPct.toStringAsFixed(1)}%', flex: 2,
                        align: TextAlign.right, color: Colors.grey.shade600, fontSize: 12),
                    _Td(p.totalQty.toInt().toString(), flex: 2, align: TextAlign.right),
                  ]),
                );
              },
            ),
          ),
        ],
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
          color: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
          title: p.productName,
          subtitle: p.sku,
          progress: (p.totalRevenue / (summary.totalRevenue > 0 ? summary.totalRevenue : 1)).clamp(0.0, 1.0),
          stats: [
            _StatItem('Revenue', _fmt(p.totalRevenue), const Color(0xFF16A34A)),
            _StatItem('Profit',  _fmt(p.totalProfit),
                p.totalProfit >= 0 ? const Color(0xFF16A34A) : Colors.red.shade600),
            _StatItem('Qty',     p.totalQty.toInt().toString(), Colors.grey.shade700),
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
            _StatBarItem('Total Sales', _fmt(summary.totalSalesAmount),  const Color(0xFF16A34A)),
            _StatBarItem('Top 20% Sales', _fmt(summary.paretoSalesAmount), const Color(0xFF0891B2)),
          ],
        ),
        _ParetoLabel(
          label:
          'Top ${summary.paretoSalesCustomerCount} customers → ${_pct(summary.paretoSalesAmount, summary.totalSalesAmount)}% of total sales',
          color: const Color(0xFF16A34A),
        ),
        Expanded(
          child: isWide
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
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF14532D),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              _Th('#',          flex: 1),
              _Th('Customer',   flex: 5),
              _Th('Phone',      flex: 3),
              _Th('Total Sales',flex: 4, align: TextAlign.right),
              _Th('Share %',    flex: 2, align: TextAlign.right),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, i) {
                final c   = customers[i];
                final pct = summary.totalSalesAmount > 0
                    ? c.totalSales / summary.totalSalesAmount * 100 : 0.0;

                return Container(
                  decoration: BoxDecoration(
                    color: i.isEven ? const Color(0xFFF0FDF4) : Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                      left: const BorderSide(color: Color(0xFF16A34A), width: 3),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(children: [
                    _Td('${i + 1}', flex: 1, bold: true, color: const Color(0xFF16A34A)),
                    _Td(c.customerName, flex: 5, bold: true),
                    _Td(c.phone.isEmpty ? '—' : c.phone, flex: 3,
                        color: Colors.grey.shade600, fontSize: 12),
                    _Td(_fmt(c.totalSales), flex: 4, align: TextAlign.right,
                        bold: true, color: const Color(0xFF16A34A)),
                    _Td('${pct.toStringAsFixed(1)}%', flex: 2,
                        align: TextAlign.right, color: Colors.grey.shade600, fontSize: 12),
                  ]),
                );
              },
            ),
          ),
        ],
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
          color:   const Color(0xFF16A34A),
          bgColor: const Color(0xFFF0FDF4),
          title:   c.customerName,
          subtitle: c.phone.isEmpty ? null : c.phone,
          progress: (c.totalSales / (summary.totalSalesAmount > 0 ? summary.totalSalesAmount : 1)).clamp(0.0, 1.0),
          stats: [
            _StatItem('Sales', _fmt(c.totalSales), const Color(0xFF16A34A)),
            _StatItem('Share', '${pct.toStringAsFixed(1)}%', const Color(0xFF0891B2)),
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
            _StatBarItem('Total Pending',   _fmt(summary.totalBalanceAmount),  const Color(0xFFDC2626)),
            _StatBarItem('Top 20% Balance', _fmt(summary.paretoBalanceAmount), const Color(0xFFEA580C)),
          ],
        ),
        _ParetoLabel(
          label:
          'Top ${summary.paretoBalanceCustomerCount} customers → ${_pct(summary.paretoBalanceAmount, summary.totalBalanceAmount)}% pending balance',
          color: const Color(0xFFDC2626),
        ),
        Expanded(
          child: isWide
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
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF7F1D1D),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              _Th('#',             flex: 1),
              _Th('Customer',      flex: 5),
              _Th('Phone',         flex: 3),
              _Th('Type',          flex: 2, align: TextAlign.center),
              _Th('Balance',       flex: 3, align: TextAlign.right),
              _Th('Credit Limit',  flex: 3, align: TextAlign.right),
              _Th('Share %',       flex: 2, align: TextAlign.right),
              _Th('',              flex: 2),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, i) {
                final c   = customers[i];
                final pct = summary.totalBalanceAmount > 0
                    ? c.balance / summary.totalBalanceAmount * 100 : 0.0;

                return Container(
                  decoration: BoxDecoration(
                    color: i.isEven ? const Color(0xFFFFF1F2) : Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                      left: const BorderSide(color: Color(0xFFDC2626), width: 3),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(children: [
                    _Td('${i + 1}', flex: 1, bold: true, color: const Color(0xFFDC2626)),
                    _Td(c.customerName, flex: 5, bold: true),
                    _Td(c.phone.isEmpty ? '—' : c.phone, flex: 3,
                        color: Colors.grey.shade600, fontSize: 12),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.customerType == 'credit'
                                ? Colors.blue.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(c.customerType.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: c.customerType == 'credit'
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade600)),
                        ),
                      ),
                    ),
                    _Td(_fmt(c.balance), flex: 3, align: TextAlign.right,
                        bold: true, color: const Color(0xFFDC2626)),
                    _Td(c.creditLimit > 0 ? _fmt(c.creditLimit) : '—', flex: 3,
                        align: TextAlign.right, color: Colors.grey.shade600),
                    _Td('${pct.toStringAsFixed(1)}%', flex: 2,
                        align: TextAlign.right, color: Colors.grey.shade600, fontSize: 12),
                    Expanded(
                      flex: 2,
                      child: c.isCreditLimitExceeded
                          ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7F1D1D),
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
              },
            ),
          ),
        ],
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
          color:   const Color(0xFFDC2626),
          bgColor: const Color(0xFFFFF1F2),
          title:   c.customerName,
          subtitle: c.phone.isEmpty ? null : c.phone,
          progress: (c.balance / (summary.totalBalanceAmount > 0 ? summary.totalBalanceAmount : 1)).clamp(0.0, 1.0),
          stats: [
            _StatItem('Balance', _fmt(c.balance), const Color(0xFFDC2626)),
            if (c.creditLimit > 0)
              _StatItem('Limit', _fmt(c.creditLimit), Colors.grey.shade600),
            _StatItem('Share', '${pct.toStringAsFixed(1)}%', const Color(0xFFEA580C)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      color: color.withOpacity(0.08),
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
      color: const Color(0xFFF1F3F8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: item.color.withOpacity(0.15)),
                boxShadow: const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(height: 2),
                        Text(item.value,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: item.color)),
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:        bgColor,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color,
                  child: Text('$rank',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeDanger ? const Color(0xFF7F1D1D) : color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(badge!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: stats.map((s) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color:        s.color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                      border:       Border.all(color: s.color.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label,
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey.shade500)),
                        const SizedBox(height: 2),
                        Text(s.value,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: s.color)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value:           progress,
                backgroundColor: Colors.grey.shade200,
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
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
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
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color:      color ?? const Color(0xFF1A1D23))),
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
        Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon:  const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}