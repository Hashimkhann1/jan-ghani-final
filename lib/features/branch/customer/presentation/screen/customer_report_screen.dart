import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/customer_invoice_model.dart';
import '../../data/model/customer_return_model.dart';
import '../../data/model/specific_customer_ledger_model.dart';
import '../provider/customer_report_provider.dart';

class CustomerReportScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;
  final double customerBalance;

  const CustomerReportScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerBalance,
  });

  @override
  ConsumerState<CustomerReportScreen> createState() =>
      _CustomerReportScreenState();
}

class _CustomerReportScreenState extends ConsumerState<CustomerReportScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  final _dateFmt = DateFormat('dd MMM yyyy');
  final _timeFmt = DateFormat('hh:mm a');
  final _amtFmt = NumberFormat('#,##,###', 'en_IN');

  final _saleFromCtrl = TextEditingController();
  final _saleToCtrl = TextEditingController();
  final _retFromCtrl = TextEditingController();
  final _retToCtrl = TextEditingController();

  ({String customerId, String customerName}) get _args => (
  customerId: widget.customerId,
  customerName: widget.customerName,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sale = ref.read(customerReportInvoiceProvider(_args));
      _saleFromCtrl.text = _dateFmt.format(sale.fromDate);
      _saleToCtrl.text = _dateFmt.format(sale.toDate);

      final ret = ref.read(customerReportReturnProvider(_args));
      _retFromCtrl.text = _dateFmt.format(ret.fromDate);
      _retToCtrl.text = _dateFmt.format(ret.toDate);
    });
  }

  @override
  void dispose() {
    _saleFromCtrl.dispose();
    _saleToCtrl.dispose();
    _retFromCtrl.dispose();
    _retToCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  Future<DateTime?> _pickDate(DateTime initial) async => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2024),
    lastDate: DateTime.now(),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: AppColor.primary),
      ),
      child: child!,
    ),
  );

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Sales',
    ),
    _NavItem(
      icon: Icons.assignment_return_outlined,
      activeIcon: Icons.assignment_return_rounded,
      label: 'Returns',
    ),
    _NavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Ledger',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardTab(
        args: _args,
        dateFmt: _dateFmt,
        timeFmt: _timeFmt,
        amtFmt: _amtFmt,
        fmt: _fmt,
        customerName: widget.customerName,
        customerBalance: widget.customerBalance,
      ),
      _SaleTab(
        args: _args,
        dateFmt: _dateFmt,
        timeFmt: _timeFmt,
        fromCtrl: _saleFromCtrl,
        toCtrl: _saleToCtrl,
        fmt: _fmt,
        pickDate: _pickDate,
      ),
      _ReturnTab(
        args: _args,
        dateFmt: _dateFmt,
        timeFmt: _timeFmt,
        fromCtrl: _retFromCtrl,
        toCtrl: _retToCtrl,
        fmt: _fmt,
        pickDate: _pickDate,
      ),
      _LedgerTab(
        args: _args,
        dateFmt: _dateFmt,
        timeFmt: _timeFmt,
        amtFmt: _amtFmt,
        fmt: _fmt,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: Color(0xFF1A1D23)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.customerName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D23),
            ),
          ),
          Text(
            _navItems[_currentIndex].label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColor.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColor.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person_outline_rounded,
              size: 18, color: AppColor.primary),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isActive = _currentIndex == i;

              // Color per tab
              final colors = [
                AppColor.primary,
                const Color(0xFF10B981),
                const Color(0xFFEF4444),
                const Color(0xFFF59E0B),
              ];
              final color = colors[i];

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            key: ValueKey(isActive),
                            size: 22,
                            color: isActive ? color : AppColor.textHint,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive ? color : AppColor.textHint,
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
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

// ══════════════════════════════════════════════════════════════
// TAB 0 — Dashboard
// ══════════════════════════════════════════════════════════════
class _DashboardTab extends ConsumerWidget {
  final ({String customerId, String customerName}) args;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final NumberFormat amtFmt;
  final String Function(double) fmt;
  final String customerName;
  final double customerBalance;

  const _DashboardTab({
    required this.args,
    required this.dateFmt,
    required this.timeFmt,
    required this.amtFmt,
    required this.fmt,
    required this.customerName,
    required this.customerBalance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleState = ref.watch(customerReportInvoiceProvider(args));
    final last10 = saleState.invoices.take(10).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(customerReportInvoiceProvider(args).notifier).load();
        await ref.read(customerReportLedgerProvider(args).notifier).load();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ── Greeting ──────────────────────────────────────────
          _GreetingCard(customerName: customerName),
          const SizedBox(height: 16),

          _OutstandingCard(
            balance: customerBalance,
            fmt: fmt,
            isLoading: false,
          ),
          const SizedBox(height: 20),

          // ── Quick Stats ───────────────────────────────────────
          Row(children: [
            Expanded(
              child: _QuickStatCard(
                label: 'Total Sales',
                value: fmt(saleState.totalSale),
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickStatCard(
                label: 'Invoices',
                value: '${saleState.invoiceCount}',
                icon: Icons.receipt_long_rounded,
                color: AppColor.primary,
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Last 10 Sales ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Sales',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D23),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${last10.length} records',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (saleState.isLoading)
            const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ))
          else if (last10.isEmpty)
            const _EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No recent sales',
            )
          else
            ...last10.map((inv) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DashboardSaleCard(
                inv: inv,
                dateFmt: dateFmt,
                timeFmt: timeFmt,
              ),
            )),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String customerName;
  const _GreetingCard({required this.customerName});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primary,
            AppColor.primary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.waving_hand_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting + '!',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('dd MMM').format(DateTime.now()),
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                DateFormat('yyyy').format(DateTime.now()),
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w800),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _OutstandingCard extends StatelessWidget {
  final double balance;
  final String Function(double) fmt;
  final bool isLoading;

  const _OutstandingCard({
    required this.balance,
    required this.fmt,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final hasBalance = balance > 0;
    final color = hasBalance ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final label = hasBalance ? 'Outstanding Balance' : 'No Outstanding';
    final icon = hasBalance
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                isLoading
                    ? Container(
                  width: 120,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
                    : Text(
                  fmt(balance.abs()),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hasBalance ? 'Due' : 'Clear',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColor.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSaleCard extends StatelessWidget {
  final CustomerInvoiceModel inv;
  final DateFormat dateFmt;
  final DateFormat timeFmt;

  const _DashboardSaleCard({
    required this.inv,
    required this.dateFmt,
    required this.timeFmt,
  });

  @override
  Widget build(BuildContext context) {
    final isCash = inv.paymentType.contains('cash');
    final isCredit = inv.paymentType.contains('credit');
    final badgeColor = isCredit
        ? const Color(0xFFF59E0B)
        : isCash
        ? const Color(0xFF10B981)
        : AppColor.info;
    final badgeLabel = isCredit ? 'Credit' : isCash ? 'Cash' : 'Card';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 20, color: AppColor.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      inv.invoiceNo,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary,
                      ),
                    ),
                    Text(
                      inv.grandTotalLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D23),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                color: badgeColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${inv.items.length} items',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColor.textHint,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${dateFmt.format(inv.invoiceDate)}  ${timeFmt.format(inv.invoiceDate)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColor.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1 — Sales
// ══════════════════════════════════════════════════════════════
class _SaleTab extends ConsumerWidget {
  final ({String customerId, String customerName}) args;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final TextEditingController fromCtrl;
  final TextEditingController toCtrl;
  final String Function(double) fmt;
  final Future<DateTime?> Function(DateTime) pickDate;

  const _SaleTab({
    required this.args,
    required this.dateFmt,
    required this.timeFmt,
    required this.fromCtrl,
    required this.toCtrl,
    required this.fmt,
    required this.pickDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerReportInvoiceProvider(args));
    final notifier =
    ref.read(customerReportInvoiceProvider(args).notifier);
    final invoices = state.filtered;

    return Column(
      children: [
        // ── Filters ──────────────────────────────────────────────
        _FilterBar(
          fromCtrl: fromCtrl,
          toCtrl: toCtrl,
          activeColor: const Color(0xFF10B981),
          onFromTap: () async {
            final p = await pickDate(state.fromDate);
            if (p != null) {
              fromCtrl.text = dateFmt.format(p);
              notifier.setDateRange(p, state.toDate);
            }
          },
          onToTap: () async {
            final p = await pickDate(state.toDate);
            if (p != null) {
              toCtrl.text = dateFmt.format(p);
              notifier.setDateRange(state.fromDate, p);
            }
          },
          onToday: () {
            notifier.setToday();
            final today = DateTime.now();
            final d = DateTime(today.year, today.month, today.day);
            fromCtrl.text = dateFmt.format(d);
            toCtrl.text = dateFmt.format(d);
          },
        ),

        // ── Summary ──────────────────────────────────────────────
        _SummaryBar(
          tiles: [
            _SummaryTileData(
              label: 'Invoices',
              value: '${state.invoiceCount}',
              color: AppColor.primary,
              icon: Icons.receipt_long_outlined,
            ),
            _SummaryTileData(
              label: 'Total',
              value: fmt(state.totalSale),
              color: const Color(0xFF10B981),
              icon: Icons.payments_outlined,
            ),
            _SummaryTileData(
              label: 'Cash',
              value: fmt(state.cashSale),
              color: AppColor.info,
              icon: Icons.money_outlined,
            ),
            _SummaryTileData(
              label: 'Credit',
              value: fmt(state.creditSale),
              color: const Color(0xFFF59E0B),
              icon: Icons.credit_card_outlined,
            ),
          ],
        ),

        // ── List ─────────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : invoices.isEmpty
              ? const _EmptyState(
            icon: Icons.receipt_long_outlined,
            message: 'No sales found',
          )
              : RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: invoices.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (_, i) => _SaleCard(
                inv: invoices[i],
                dateFmt: dateFmt,
                timeFmt: timeFmt,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 2 — Returns
// ══════════════════════════════════════════════════════════════
class _ReturnTab extends ConsumerWidget {
  final ({String customerId, String customerName}) args;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final TextEditingController fromCtrl;
  final TextEditingController toCtrl;
  final String Function(double) fmt;
  final Future<DateTime?> Function(DateTime) pickDate;

  const _ReturnTab({
    required this.args,
    required this.dateFmt,
    required this.timeFmt,
    required this.fromCtrl,
    required this.toCtrl,
    required this.fmt,
    required this.pickDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerReportReturnProvider(args));
    final notifier =
    ref.read(customerReportReturnProvider(args).notifier);
    final returns = state.returns;
    final summary = state.summary;

    return Column(
      children: [
        // ── Filters ──────────────────────────────────────────────
        _FilterBar(
          fromCtrl: fromCtrl,
          toCtrl: toCtrl,
          activeColor: const Color(0xFFEF4444),
          onFromTap: () async {
            final p = await pickDate(state.fromDate);
            if (p != null) {
              fromCtrl.text = dateFmt.format(p);
              notifier.setFromDate(p);
            }
          },
          onToTap: () async {
            final p = await pickDate(state.toDate);
            if (p != null) {
              toCtrl.text = dateFmt.format(p);
              notifier.setToDate(p);
            }
          },
          onToday: () {
            notifier.setToday();
            final today = DateTime.now();
            final d = DateTime(today.year, today.month, today.day);
            fromCtrl.text = dateFmt.format(d);
            toCtrl.text = dateFmt.format(d);
          },
        ),

        // ── Summary ──────────────────────────────────────────────
        _SummaryBar(
          tiles: [
            _SummaryTileData(
              label: 'Returns',
              value: '${summary.totalReturns}',
              color: AppColor.primary,
              icon: Icons.assignment_return_outlined,
            ),
            _SummaryTileData(
              label: 'Total',
              value: fmt(summary.totalAmount),
              color: const Color(0xFFEF4444),
              icon: Icons.payments_outlined,
            ),
            _SummaryTileData(
              label: 'Qty',
              value: summary.totalQuantity.toStringAsFixed(0),
              color: const Color(0xFFF59E0B),
              icon: Icons.inventory_2_outlined,
            ),
            _SummaryTileData(
              label: 'Discount',
              value: fmt(summary.totalDiscount),
              color: const Color(0xFF10B981),
              icon: Icons.discount_outlined,
            ),
          ],
        ),

        // ── List ─────────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : returns.isEmpty
              ? const _EmptyState(
            icon: Icons.assignment_return_outlined,
            message: 'No returns found',
          )
              : RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: returns.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (_, i) => _ReturnCard(
                ret: returns[i],
                dateFmt: dateFmt,
                timeFmt: timeFmt,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 3 — Ledger
// ══════════════════════════════════════════════════════════════
class _LedgerTab extends ConsumerWidget {
  final ({String customerId, String customerName}) args;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final NumberFormat amtFmt;
  final String Function(double) fmt;

  const _LedgerTab({
    required this.args,
    required this.dateFmt,
    required this.timeFmt,
    required this.amtFmt,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerReportLedgerProvider(args));
    final notifier =
    ref.read(customerReportLedgerProvider(args).notifier);

    return Column(
      children: [
        // ── Summary ──────────────────────────────────────────────
        _SummaryBar(
          tiles: [
            _SummaryTileData(
              label: 'Records',
              value: '${state.ledger.length}',
              color: AppColor.primary,
              icon: Icons.receipt_long_outlined,
            ),
            _SummaryTileData(
              label: 'Total Paid',
              value: fmt(state.totalPaid),
              color: const Color(0xFF10B981),
              icon: Icons.payments_outlined,
            ),
            _SummaryTileData(
              label: 'Balance',
              value: fmt(state.currentBalance),
              color: state.currentBalance > 0
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),

        // ── List ─────────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.ledger.isEmpty
              ? const _EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            message: 'No ledger records found',
          )
              : RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: state.ledger.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (_, i) => _LedgerRow(
                entry: state.ledger[i],
                dateFmt: dateFmt,
                timeFmt: timeFmt,
                amtFmt: amtFmt,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Shared Filter Bar
// ══════════════════════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  final TextEditingController fromCtrl;
  final TextEditingController toCtrl;
  final Color activeColor;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onToday;

  const _FilterBar({
    required this.fromCtrl,
    required this.toCtrl,
    required this.activeColor,
    required this.onFromTap,
    required this.onToTap,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _DateField(
              label: 'Start',
              controller: fromCtrl,
              onTap: onFromTap,
              accentColor: activeColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DateField(
              label: 'End',
              controller: toCtrl,
              onTap: onToTap,
              accentColor: activeColor,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 68,
            child: OutlinedButton(
              onPressed: onToday,
              style: OutlinedButton.styleFrom(
                foregroundColor: activeColor,
                side: BorderSide(color: activeColor),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child:
              const Text('Today', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Shared Summary Bar
// ══════════════════════════════════════════════════════════════
class _SummaryTileData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryTileData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class _SummaryBar extends StatelessWidget {
  final List<_SummaryTileData> tiles;

  const _SummaryBar({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
      child: Row(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 36,
                color: const Color(0xFFE5E7EB),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
            Expanded(child: _StatTile(data: tiles[i])),
          ]
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final _SummaryTileData data;

  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: data.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(data.icon, size: 15, color: data.color),
      ),
      const SizedBox(height: 5),
      Text(
        data.value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: data.color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 2),
      Text(
        data.label,
        style: const TextStyle(
            fontSize: 9, color: AppColor.textHint),
      ),
    ],
  );
}

// ══════════════════════════════════════════════════════════════
// Sale Card
// ══════════════════════════════════════════════════════════════
class _SaleCard extends StatefulWidget {
  final CustomerInvoiceModel inv;
  final DateFormat dateFmt;
  final DateFormat timeFmt;

  const _SaleCard({
    required this.inv,
    required this.dateFmt,
    required this.timeFmt,
  });

  @override
  State<_SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<_SaleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final inv = widget.inv;
    final isCash = inv.paymentType.contains('cash');
    final isCredit = inv.paymentType.contains('credit');
    final badgeColor = isCredit
        ? const Color(0xFFF59E0B)
        : isCash
        ? const Color(0xFF10B981)
        : AppColor.info;
    final badgeLabel = isCredit ? 'Credit' : isCash ? 'Cash' : 'Card';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        size: 20, color: AppColor.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              inv.invoiceNo,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColor.primary,
                              ),
                            ),
                            Text(
                              inv.grandTotalLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1D23),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _Badge(
                                    label: badgeLabel,
                                    color: badgeColor),
                                const SizedBox(width: 6),
                                Text(
                                  '${inv.items.length} items',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColor.textHint,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${widget.dateFmt.format(inv.invoiceDate)}  ${widget.timeFmt.format(inv.invoiceDate)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColor.textHint),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 20, color: AppColor.grey400),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded ──────────────────────────────────────────
          if (_expanded) ...[
            Container(height: 1, color: const Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  const _ItemTableHeader(),
                  const SizedBox(height: 6),
                  ...inv.items.map(
                        (item) => _ItemRow(
                      productName: item.productName,
                      qty: item.qtyLabel,
                      price: item.priceLabel,
                      total: item.totalLabel,
                    ),
                  ),
                  if (inv.totalDiscount > 0) ...[
                    const Divider(height: 12, color: Color(0xFFE5E7EB)),
                    _TotalRow(
                      label: 'Discount',
                      value: '- ${inv.discountLabel}',
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                  const Divider(height: 12, color: Color(0xFFE5E7EB)),
                  _TotalRow(
                    label: 'Grand Total',
                    value: inv.grandTotalLabel,
                    color: const Color(0xFF10B981),
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Return Card
// ══════════════════════════════════════════════════════════════
class _ReturnCard extends StatefulWidget {
  final CustomerReturnInvoice ret;
  final DateFormat dateFmt;
  final DateFormat timeFmt;

  const _ReturnCard({
    required this.ret,
    required this.dateFmt,
    required this.timeFmt,
  });

  @override
  State<_ReturnCard> createState() => _ReturnCardState();
}

class _ReturnCardState extends State<_ReturnCard> {
  bool _expanded = false;

  Color get _refundColor {
    switch (widget.ret.refundType) {
      case 'card':
        return AppColor.info;
      case 'credit':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ret = widget.ret;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                        Icons.assignment_return_rounded,
                        size: 20,
                        color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ret.returnNo,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            Text(
                              'Rs ${ret.grandTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1D23),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _Badge(
                                  label: ret.paymentLabel,
                                  color: _refundColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${ret.items.length} items',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColor.textHint,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${widget.dateFmt.format(ret.returnDate)}  ${widget.timeFmt.format(ret.returnDate)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColor.textHint),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 20, color: AppColor.grey400),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Container(height: 1, color: const Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  const _ItemTableHeader(),
                  const SizedBox(height: 6),
                  ...ret.items.map(
                        (item) => _ItemRow(
                      productName: item.productName,
                      qty: item.quantity.toStringAsFixed(0),
                      price: 'Rs ${item.price.toStringAsFixed(0)}',
                      total:
                      'Rs ${item.totalAmount.toStringAsFixed(0)}',
                    ),
                  ),
                  if (ret.totalDiscount > 0) ...[
                    const Divider(height: 12, color: Color(0xFFE5E7EB)),
                    _TotalRow(
                      label: 'Discount',
                      value:
                      '- Rs ${ret.totalDiscount.toStringAsFixed(0)}',
                      color: const Color(0xFF10B981),
                    ),
                  ],
                  const Divider(height: 12, color: Color(0xFFE5E7EB)),
                  _TotalRow(
                    label: 'Grand Total',
                    value: 'Rs ${ret.grandTotal.toStringAsFixed(0)}',
                    color: const Color(0xFFEF4444),
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Ledger Row
// ══════════════════════════════════════════════════════════════
class _LedgerRow extends StatelessWidget {
  final SpecificCustomerLedgerModel entry;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final NumberFormat amtFmt;

  const _LedgerRow({
    required this.entry,
    required this.dateFmt,
    required this.timeFmt,
    required this.amtFmt,
  });

  String _fmt(double v) => 'Rs ${amtFmt.format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final color = isPayment
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final icon = isPayment
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final label = isPayment ? 'Payment' : 'Credit';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Badge(label: label, color: color),
                        if (entry.notes != null &&
                            entry.notes!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            entry.notes!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColor.textHint),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isPayment
                          ? '- ${_fmt(entry.payAmount)}'
                          : '+ ${_fmt(entry.payAmount)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: const Color(0xFFF5F5F5)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${dateFmt.format(entry.createdAt)}  ${timeFmt.format(entry.createdAt)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColor.textHint),
                    ),
                    Row(
                      children: [
                        Text(
                          _fmt(entry.previousAmount),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColor.textSecondary),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 12, color: AppColor.textHint),
                        ),
                        Text(
                          _fmt(entry.newAmount),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: entry.newAmount > 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Shared Small Widgets
// ══════════════════════════════════════════════════════════════
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

class _ItemTableHeader extends StatelessWidget {
  const _ItemTableHeader();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(flex: 3, child: _IH(text: 'Product')),
      Expanded(flex: 1, child: _IH(text: 'Qty')),
      Expanded(flex: 2, child: _IH(text: 'Price')),
      Expanded(flex: 2, child: _IH(text: 'Total', right: true)),
    ],
  );
}

class _ItemRow extends StatelessWidget {
  final String productName;
  final String qty;
  final String price;
  final String total;

  const _ItemRow({
    required this.productName,
    required this.qty,
    required this.price,
    required this.total,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            productName,
            style: const TextStyle(
                fontSize: 12, color: AppColor.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            qty,
            style: const TextStyle(
                fontSize: 12, color: AppColor.textSecondary),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            price,
            style: const TextStyle(
                fontSize: 12, color: AppColor.textSecondary),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            total,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColor.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: bold ? 13 : 12,
          fontWeight:
          bold ? FontWeight.w700 : FontWeight.w500,
          color: AppColor.textPrimary,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: bold ? 14 : 12,
          fontWeight:
          bold ? FontWeight.w800 : FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}

class _DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;
  final Color accentColor;

  const _DateField({
    required this.label,
    required this.controller,
    required this.onTap,
    this.accentColor = AppColor.primary,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    readOnly: true,
    onTap: onTap,
    cursorHeight: 14,
    style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
          fontSize: 11, color: AppColor.textSecondary),
      prefixIcon: Icon(Icons.calendar_today_outlined,
          size: 14, color: accentColor),
      filled: true,
      fillColor: AppColor.grey100,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
        const BorderSide(color: AppColor.grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: accentColor),
      ),
    ),
  );
}

class _IH extends StatelessWidget {
  final String text;
  final bool right;
  const _IH({required this.text, this.right = false});

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: right ? TextAlign.right : TextAlign.left,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: AppColor.textHint,
      letterSpacing: 0.3,
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon,
                size: 36, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    ),
  );
}