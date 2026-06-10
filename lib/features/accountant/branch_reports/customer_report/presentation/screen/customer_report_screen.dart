import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../data/model/customer_invoice_model.dart';
import '../../data/model/customer_return_model.dart';
import '../../data/model/specific_customer_ledger_model.dart';
import '../provider/customer_report_provider.dart';
import 'package:jan_ghani_final/core/service/session/accountant_session.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/screen/login_screen.dart';

// ─────────────────────────────────────────────────────────────
// Nav config — sirf customer ke 3 tabs
// ─────────────────────────────────────────────────────────────
class _CNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  final Color    color;
  const _CNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}

const List<_CNavItem> _navItems = [
  _CNavItem(
    icon:       Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long_rounded,
    label:      'Sales',
    color:      Color(0xFF10B981),
  ),
  _CNavItem(
    icon:       Icons.assignment_return_outlined,
    activeIcon: Icons.assignment_return_rounded,
    label:      'Returns',
    color:      Color(0xFFEF4444),
  ),
  _CNavItem(
    icon:       Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet_rounded,
    label:      'Ledger',
    color:      Color(0xFFF59E0B),
  ),
];

// ─────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────
class CustomerReportScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;
  final double customerBalance;
  final bool   hideAppBarBack; // customer portal se open ho toh true

  const CustomerReportScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerBalance,
    this.hideAppBarBack = false,
  });

  @override
  ConsumerState<CustomerReportScreen> createState() =>
      _CustomerReportScreenState();
}

class _CustomerReportScreenState extends ConsumerState<CustomerReportScreen> {
  int _selectedIndex = 0;

  final _dateFmt = DateFormat('dd MMM yyyy');
  final _timeFmt = DateFormat('hh:mm a');
  final _amtFmt  = NumberFormat('#,##,###', 'en_IN');

  final _saleFromCtrl = TextEditingController();
  final _saleToCtrl   = TextEditingController();
  final _retFromCtrl  = TextEditingController();
  final _retToCtrl    = TextEditingController();

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

  ({String customerId, String customerName}) get _args => (
  customerId:   widget.customerId,
  customerName: widget.customerName,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sale = ref.read(customerReportInvoiceProvider(_args));
      _saleFromCtrl.text = _dateFmt.format(sale.fromDate);
      _saleToCtrl.text   = _dateFmt.format(sale.toDate);
      final ret = ref.read(customerReportReturnProvider(_args));
      _retFromCtrl.text = _dateFmt.format(ret.fromDate);
      _retToCtrl.text   = _dateFmt.format(ret.toDate);
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
    firstDate:   DateTime(2024),
    lastDate:    DateTime.now(),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: AppColor.primary),
      ),
      child: child!,
    ),
  );

  Widget _buildPage(int index) {
    return switch (index) {
      0 => _SaleTab(
        args:     _args, dateFmt: _dateFmt, timeFmt: _timeFmt,
        fromCtrl: _saleFromCtrl, toCtrl: _saleToCtrl,
        fmt: _fmt, pickDate: _pickDate,
      ),
      1 => _ReturnTab(
        args:     _args, dateFmt: _dateFmt, timeFmt: _timeFmt,
        fromCtrl: _retFromCtrl, toCtrl: _retToCtrl,
        fmt: _fmt, pickDate: _pickDate,
      ),
      2 => _LedgerTab(
        args:    _args, dateFmt: _dateFmt, timeFmt: _timeFmt,
        amtFmt:  _amtFmt, fmt: _fmt,
      ),
      _ => _SaleTab(
        args:     _args, dateFmt: _dateFmt, timeFmt: _timeFmt,
        fromCtrl: _saleFromCtrl, toCtrl: _saleToCtrl,
        fmt: _fmt, pickDate: _pickDate,
      ),
    };
  }

  Future<void> _logout() async {
    await AccountantSession.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AccountantLoginScreen()),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = _isDesktop(context);

    // ── Desktop layout — Sidebar + Content ──────────────────────
    if (desktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: Row(children: [
          _CustomerSidebar(
            customerName:    widget.customerName,
            customerBalance: widget.customerBalance,
            selectedIndex:   _selectedIndex,
            onItemTap:       (i) => setState(() => _selectedIndex = i),
            onLogout:        _logout,
            fmt:             _fmt,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: List.generate(_navItems.length, _buildPage),
            ),
          ),
        ]),
      );
    }

    // ── Mobile layout — AppBar + Bottom Nav ──────────────────────
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildMobileAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_navItems.length, _buildPage),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Mobile AppBar ──────────────────────────────────────────────
  PreferredSizeWidget _buildMobileAppBar() => AppBar(
    backgroundColor:           Colors.white,
    elevation:                 0,
    surfaceTintColor:          Colors.transparent,
    automaticallyImplyLeading: !widget.hideAppBarBack,
    leading: widget.hideAppBarBack
        ? null
        : IconButton(
      icon:      const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A1D23)),
      onPressed: () => Navigator.pop(context),
    ),
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.customerName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1D23))),
      Text(
        _navItems[_selectedIndex].label,
        style: TextStyle(fontSize: 11, color: _navItems[_selectedIndex].color),
      ),
    ]),
    actions: [
      if (widget.hideAppBarBack)
        IconButton(
          icon:    const Icon(Icons.logout_rounded, size: 20, color: AppColor.primary),
          tooltip: 'Logout',
          onPressed: _logout,
        ),
      Container(
        margin:  const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:        AppColor.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.person_outline_rounded, size: 18, color: AppColor.primary),
      ),
    ],
  );

  // ── Mobile Bottom Nav ──────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color:     Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item     = _navItems[i];
              final isActive = _selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: AnimatedContainer(
                    duration:  const Duration(milliseconds: 200),
                    curve:     Curves.easeInOut,
                    padding:   const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:        isActive ? item.color.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          key:   ValueKey(isActive),
                          size:  22,
                          color: isActive ? item.color : AppColor.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(item.label, style: TextStyle(
                        fontSize:   10,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color:      isActive ? item.color : AppColor.textHint,
                      )),
                    ]),
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

// ══════════════════════════════════════════════════════════════
// Desktop Sidebar — accountant sidebar jaisa pattern
// ══════════════════════════════════════════════════════════════
class _CustomerSidebar extends StatelessWidget {
  final String   customerName;
  final double   customerBalance;
  final int      selectedIndex;
  final void Function(int) onItemTap;
  final VoidCallback onLogout;
  final String Function(double) fmt;

  const _CustomerSidebar({
    required this.customerName,
    required this.customerBalance,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onLogout,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final hasBalance = customerBalance > 0;
    final balColor   = hasBalance ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      width: 220,
      color: Colors.white,
      child: Column(children: [

        // ── Brand / Customer info ────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color:        AppColor.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  customerName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.textDark),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                // Customer badge
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color:        AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Customer',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColor.primary)),
                ),
              ]),
            ),
          ]),
        ),

        // ── Balance card ────────────────────────────────────────
        Container(
          margin:  const EdgeInsets.fromLTRB(12, 14, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:        balColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: balColor.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(
              hasBalance ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              size: 18, color: balColor,
            ),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hasBalance ? 'Outstanding' : 'Clear',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: balColor)),
              Text(fmt(customerBalance.abs()),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: balColor),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),

        // ── Nav items ────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              children: _navItems.asMap().entries.map((entry) {
                final i    = entry.key;
                final item = entry.value;
                return _SidebarItem(
                  icon:    item.icon,
                  label:   item.label,
                  color:   item.color,
                  active:  selectedIndex == i,
                  onTap:   () => onItemTap(i),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Logout ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: _SidebarItem(
            icon:   Icons.logout_rounded,
            label:  'Logout',
            color:  const Color(0xFFEF4444),
            active: false,
            onTap:  onLogout,
          ),
        ),
      ]),
    );
  }
}

// ── Sidebar Item ──────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final bool     active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:   double.infinity,
        margin:  const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        active ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: active ? color : AppColor.textMuted),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
            fontSize:   14,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color:      active ? color : AppColor.textMuted,
          )),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1 — Sales
// ══════════════════════════════════════════════════════════════
class _SaleTab extends ConsumerWidget {
  final ({String customerId, String customerName}) args;
  final DateFormat dateFmt; final DateFormat timeFmt;
  final TextEditingController fromCtrl; final TextEditingController toCtrl;
  final String Function(double) fmt;
  final Future<DateTime?> Function(DateTime) pickDate;

  const _SaleTab({
    required this.args, required this.dateFmt, required this.timeFmt,
    required this.fromCtrl, required this.toCtrl,
    required this.fmt, required this.pickDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(customerReportInvoiceProvider(args));
    final notifier = ref.read(customerReportInvoiceProvider(args).notifier);
    final invoices = state.filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(children: [
        _FilterBar(
          fromCtrl:    fromCtrl,
          toCtrl:      toCtrl,
          activeColor: const Color(0xFF10B981),
          onFromTap: () async {
            final p = await pickDate(state.fromDate);
            if (p != null) { fromCtrl.text = dateFmt.format(p); notifier.setDateRange(p, state.toDate); }
          },
          onToTap: () async {
            final p = await pickDate(state.toDate);
            if (p != null) { toCtrl.text = dateFmt.format(p); notifier.setDateRange(state.fromDate, p); }
          },
          onToday: () {
            notifier.setToday();
            final d = DateTime.now(); final t = DateTime(d.year, d.month, d.day);
            fromCtrl.text = dateFmt.format(t); toCtrl.text = dateFmt.format(t);
          },
        ),

        _SummaryBar(tiles: [
          _SummaryTileData(label: 'Invoices', value: '\${state.invoiceCount}', color: AppColor.primary,        icon: Icons.receipt_long_outlined),
          _SummaryTileData(label: 'Total',    value: fmt(state.totalSale),    color: const Color(0xFF10B981), icon: Icons.payments_outlined),
          _SummaryTileData(label: 'Cash',     value: fmt(state.cashSale),     color: const Color(0xFF6366F1), icon: Icons.money_outlined),
          _SummaryTileData(label: 'Credit',   value: fmt(state.creditSale),   color: const Color(0xFFF59E0B), icon: Icons.credit_card_outlined),
        ]),

        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : invoices.isEmpty
              ? const _EmptyState(icon: Icons.receipt_long_outlined, message: 'No sales found')
              : RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding:          const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount:        invoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder:      (_, i) => _SaleCard(inv: invoices[i], dateFmt: dateFmt, timeFmt: timeFmt),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 2 — Returns
// ══════════════════════════════════════════════════════════════
class _ReturnTab extends ConsumerWidget {
  final ({String customerId, String customerName}) args;
  final DateFormat dateFmt; final DateFormat timeFmt;
  final TextEditingController fromCtrl; final TextEditingController toCtrl;
  final String Function(double) fmt;
  final Future<DateTime?> Function(DateTime) pickDate;

  const _ReturnTab({
    required this.args, required this.dateFmt, required this.timeFmt,
    required this.fromCtrl, required this.toCtrl,
    required this.fmt, required this.pickDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(customerReportReturnProvider(args));
    final notifier = ref.read(customerReportReturnProvider(args).notifier);
    final summary  = state.summary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(children: [
        _FilterBar(
          fromCtrl:    fromCtrl,
          toCtrl:      toCtrl,
          activeColor: const Color(0xFFEF4444),
          onFromTap: () async {
            final p = await pickDate(state.fromDate);
            if (p != null) { fromCtrl.text = dateFmt.format(p); notifier.setFromDate(p); }
          },
          onToTap: () async {
            final p = await pickDate(state.toDate);
            if (p != null) { toCtrl.text = dateFmt.format(p); notifier.setToDate(p); }
          },
          onToday: () {
            notifier.setToday();
            final d = DateTime.now(); final t = DateTime(d.year, d.month, d.day);
            fromCtrl.text = dateFmt.format(t); toCtrl.text = dateFmt.format(t);
          },
        ),

        _SummaryBar(tiles: [
          _SummaryTileData(label: 'Returns',  value: summary.totalReturns.toString(),         color: AppColor.primary,        icon: Icons.assignment_return_outlined),
          _SummaryTileData(label: 'Total',    value: fmt(summary.totalAmount),                 color: const Color(0xFFEF4444), icon: Icons.payments_outlined),
          _SummaryTileData(label: 'Qty',      value: summary.totalQuantity.toStringAsFixed(0), color: const Color(0xFFF59E0B), icon: Icons.inventory_2_outlined),
          _SummaryTileData(label: 'Discount', value: fmt(summary.totalDiscount),               color: const Color(0xFF10B981), icon: Icons.discount_outlined),
        ]),

        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.returns.isEmpty
              ? const _EmptyState(icon: Icons.assignment_return_outlined, message: 'No returns found')
              : RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding:          const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount:        state.returns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder:      (_, i) => _ReturnCard(ret: state.returns[i], dateFmt: dateFmt, timeFmt: timeFmt),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 3 — Ledger
// ══════════════════════════════════════════════════════════════
class _LedgerTab extends ConsumerWidget {
  final ({String customerId, String customerName}) args;
  final DateFormat dateFmt; final DateFormat timeFmt; final NumberFormat amtFmt;
  final String Function(double) fmt;

  const _LedgerTab({
    required this.args, required this.dateFmt, required this.timeFmt,
    required this.amtFmt, required this.fmt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(customerReportLedgerProvider(args));
    final notifier = ref.read(customerReportLedgerProvider(args).notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(children: [
        _SummaryBar(tiles: [
          _SummaryTileData(label: 'Records',    value: state.ledger.length.toString(), color: AppColor.primary,        icon: Icons.receipt_long_outlined),
          _SummaryTileData(label: 'Total Paid', value: fmt(state.totalPaid),           color: const Color(0xFF10B981), icon: Icons.payments_outlined),
          _SummaryTileData(
            label: 'Balance', value: fmt(state.currentBalance),
            color: state.currentBalance > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            icon:  Icons.account_balance_wallet_outlined,
          ),
        ]),

        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.ledger.isEmpty
              ? const _EmptyState(icon: Icons.account_balance_wallet_outlined, message: 'No ledger records found')
              : RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding:          const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount:        state.ledger.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder:      (_, i) => _LedgerRow(
                entry: state.ledger[i], dateFmt: dateFmt, timeFmt: timeFmt, amtFmt: amtFmt,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Sale Card
// ══════════════════════════════════════════════════════════════
class _SaleCard extends StatefulWidget {
  final CustomerInvoiceModel inv; final DateFormat dateFmt; final DateFormat timeFmt;
  const _SaleCard({required this.inv, required this.dateFmt, required this.timeFmt});
  @override State<_SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<_SaleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final inv      = widget.inv;
    final isCash   = inv.paymentType.contains('cash');
    final isCredit = inv.paymentType.contains('credit');
    final badgeColor = isCredit ? const Color(0xFFF59E0B) : isCash ? const Color(0xFF10B981) : AppColor.info;
    final badgeLabel = isCredit ? 'Credit' : isCash ? 'Cash' : 'Card';

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow:    [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        InkWell(
          onTap:        () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColor.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_long_rounded, size: 20, color: AppColor.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(inv.invoiceNo,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.primary)),
                  Text(inv.grandTotalLabel,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1D23))),
                ]),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    _Badge(label: badgeLabel, color: badgeColor),
                    const SizedBox(width: 6),
                    Text('${inv.items.length} items', style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
                  ]),
                  Text('${widget.dateFmt.format(inv.invoiceDate)}  ${widget.timeFmt.format(inv.invoiceDate)}',
                      style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
                ]),
              ])),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0, duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColor.grey400),
              ),
            ]),
          ),
        ),

        if (_expanded) ...[
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              const _ItemTableHeader(),
              const SizedBox(height: 6),
              ...inv.items.map((item) => _ItemRow(
                productName: item.productName,
                qty:         item.qtyLabel,
                salePrice:   item.salePriceLabel,
                total:       item.totalLabel,
              )),
              if (inv.totalDiscount > 0) ...[
                const Divider(height: 12, color: Color(0xFFE5E7EB)),
                _TotalRow(label: 'Discount', value: '- ${inv.discountLabel}', color: const Color(0xFFF59E0B)),
              ],
              const Divider(height: 12, color: Color(0xFFE5E7EB)),
              _TotalRow(label: 'Grand Total', value: inv.grandTotalLabel, color: const Color(0xFF10B981), bold: true),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Return Card
// ══════════════════════════════════════════════════════════════
class _ReturnCard extends StatefulWidget {
  final CustomerReturnInvoice ret; final DateFormat dateFmt; final DateFormat timeFmt;
  const _ReturnCard({required this.ret, required this.dateFmt, required this.timeFmt});
  @override State<_ReturnCard> createState() => _ReturnCardState();
}

class _ReturnCardState extends State<_ReturnCard> {
  bool _expanded = false;

  Color get _refundColor => switch (widget.ret.refundType) {
    'card'   => AppColor.info,
    'credit' => const Color(0xFFF59E0B),
    _        => const Color(0xFF10B981),
  };

  @override
  Widget build(BuildContext context) {
    final ret = widget.ret;
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow:    [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        InkWell(
          onTap:        () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.assignment_return_rounded, size: 20, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(ret.returnNo,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                  Text('Rs ${ret.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1D23))),
                ]),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    _Badge(label: ret.paymentLabel, color: _refundColor),
                    const SizedBox(width: 6),
                    Text('${ret.items.length} items', style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
                  ]),
                  Text('${widget.dateFmt.format(ret.returnDate)}  ${widget.timeFmt.format(ret.returnDate)}',
                      style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
                ]),
              ])),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0, duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColor.grey400),
              ),
            ]),
          ),
        ),

        if (_expanded) ...[
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              const _ItemTableHeader(),
              const SizedBox(height: 6),
              ...ret.items.map((item) => _ItemRow(
                productName: item.productName,
                qty:         item.qtyLabel,
                salePrice:   item.salePriceLabel,
                total:       'Rs ${item.totalAmount.toStringAsFixed(0)}',
              )),
              if (ret.totalDiscount > 0) ...[
                const Divider(height: 12, color: Color(0xFFE5E7EB)),
                _TotalRow(label: 'Discount', value: '- Rs ${ret.totalDiscount.toStringAsFixed(0)}', color: const Color(0xFF10B981)),
              ],
              const Divider(height: 12, color: Color(0xFFE5E7EB)),
              _TotalRow(label: 'Grand Total', value: 'Rs ${ret.grandTotal.toStringAsFixed(0)}', color: const Color(0xFFEF4444), bold: true),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Ledger Row
// ══════════════════════════════════════════════════════════════
class _LedgerRow extends StatelessWidget {
  final SpecificCustomerLedgerModel entry;
  final DateFormat dateFmt; final DateFormat timeFmt; final NumberFormat amtFmt;
  const _LedgerRow({required this.entry, required this.dateFmt, required this.timeFmt, required this.amtFmt});

  String _fmt(double v) => 'Rs ${amtFmt.format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final color     = isPayment ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon      = isPayment ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final label     = isPayment ? 'Payment' : 'Credit';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow:    [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Badge(label: label, color: color),
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(entry.notes!, style: const TextStyle(fontSize: 11, color: AppColor.textHint)),
              ],
            ]),
            Text(isPayment ? '- ${_fmt(entry.payAmount)}' : '+ ${_fmt(entry.payAmount)}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          ]),
          const SizedBox(height: 10),
          Container(height: 1, color: const Color(0xFFF5F5F5)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${dateFmt.format(entry.createdAt)}  ${timeFmt.format(entry.createdAt)}',
                style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
            Row(children: [
              Text(_fmt(entry.previousAmount), style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child:   Icon(Icons.arrow_forward_rounded, size: 12, color: AppColor.textHint),
              ),
              Text(_fmt(entry.newAmount), style: TextStyle(
                fontSize:   11, fontWeight: FontWeight.w700,
                color: entry.newAmount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              )),
            ]),
          ]),
        ])),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Shared Widgets
// ══════════════════════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  final TextEditingController fromCtrl; final TextEditingController toCtrl;
  final Color        activeColor;
  final VoidCallback onFromTap; final VoidCallback onToTap; final VoidCallback onToday;

  const _FilterBar({
    required this.fromCtrl, required this.toCtrl, required this.activeColor,
    required this.onFromTap, required this.onToTap, required this.onToday,
  });

  @override
  Widget build(BuildContext context) => Container(
    color:   Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    child: Row(children: [
      Expanded(child: _DateField(label: 'Start', controller: fromCtrl, onTap: onFromTap, accentColor: activeColor)),
      const SizedBox(width: 10),
      Expanded(child: _DateField(label: 'End',   controller: toCtrl,   onTap: onToTap,   accentColor: activeColor)),
      const SizedBox(width: 10),
      SizedBox(
        width: 68,
        child: OutlinedButton(
          onPressed: onToday,
          style: OutlinedButton.styleFrom(
            foregroundColor: activeColor, side: BorderSide(color: activeColor),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
            shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Today', style: TextStyle(fontSize: 11)),
        ),
      ),
    ]),
  );
}

class _SummaryTileData {
  final String label; final String value; final Color color; final IconData icon;
  const _SummaryTileData({required this.label, required this.value, required this.color, required this.icon});
}

class _SummaryBar extends StatelessWidget {
  final List<_SummaryTileData> tiles;
  const _SummaryBar({required this.tiles});

  @override
  Widget build(BuildContext context) => Container(
    color:   Colors.white,
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
    child: Row(children: [
      for (int i = 0; i < tiles.length; i++) ...[
        if (i > 0) Container(width: 1, height: 36, color: const Color(0xFFE5E7EB), margin: const EdgeInsets.symmetric(horizontal: 4)),
        Expanded(child: _StatTile(data: tiles[i])),
      ],
    ]),
  );
}

class _StatTile extends StatelessWidget {
  final _SummaryTileData data;
  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: data.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(data.icon, size: 15, color: data.color),
    ),
    const SizedBox(height: 5),
    Text(data.value,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: data.color),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    const SizedBox(height: 2),
    Text(data.label, style: const TextStyle(fontSize: 9, color: AppColor.textHint)),
  ]);
}

class _ItemTableHeader extends StatelessWidget {
  const _ItemTableHeader();
  @override
  Widget build(BuildContext context) => const Row(children: [
    Expanded(flex: 3, child: _IH(text: 'Product')),
    Expanded(flex: 1, child: _IH(text: 'Qty')),
    Expanded(flex: 2, child: _IH(text: 'Price')),
    Expanded(flex: 2, child: _IH(text: 'Total', right: true)),
  ]);
}

class _ItemRow extends StatelessWidget {
  final String productName; final String qty; final String salePrice; final String total;
  const _ItemRow({required this.productName, required this.qty, required this.salePrice, required this.total});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(flex: 3, child: Text(productName,
          style: const TextStyle(fontSize: 12, color: AppColor.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      Expanded(flex: 1, child: Text(qty,       style: const TextStyle(fontSize: 12, color: AppColor.textSecondary))),
      Expanded(flex: 2, child: Text(salePrice, style: const TextStyle(fontSize: 12, color: AppColor.textSecondary))),
      Expanded(flex: 2, child: Text(total,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary))),
    ]),
  );
}

class _TotalRow extends StatelessWidget {
  final String label; final String value; final Color color; final bool bold;
  const _TotalRow({required this.label, required this.value, required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
          fontSize: bold ? 13 : 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: AppColor.textPrimary)),
      Text(value, style: TextStyle(
          fontSize: bold ? 14 : 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
    ],
  );
}

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(5),
      border:       Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
  );
}

class _DateField extends StatelessWidget {
  final String label; final TextEditingController controller;
  final VoidCallback onTap; final Color accentColor;
  const _DateField({required this.label, required this.controller, required this.onTap, this.accentColor = AppColor.primary});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, readOnly: true, onTap: onTap, cursorHeight: 14,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      labelText:  label,
      labelStyle: const TextStyle(fontSize: 11, color: AppColor.textSecondary),
      prefixIcon: Icon(Icons.calendar_today_outlined, size: 14, color: accentColor),
      filled:     true, fillColor: AppColor.grey100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColor.grey200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accentColor)),
    ),
  );
}

class _IH extends StatelessWidget {
  final String text; final bool right;
  const _IH({required this.text, this.right = false});

  @override
  Widget build(BuildContext context) => Text(text,
    textAlign: right ? TextAlign.right : TextAlign.left,
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColor.textHint, letterSpacing: 0.3),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, size: 36, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
      ]),
    ),
  );
}