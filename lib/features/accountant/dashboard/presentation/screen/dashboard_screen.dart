import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';
import 'package:jan_ghani_final/core/widget/app_logo_widget.dart';
import 'package:jan_ghani_final/features/accountant/investment/presentation/screen/investment_screen.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/screen/login_screen.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/providers/accountant_auth_providers.dart';
import 'package:jan_ghani_final/features/accountant/accountant_all_warehouses/presentation/screen/accountant_all_warehouses_screen.dart';
import 'package:jan_ghani_final/features/accountant/accountant_inventory_review/presentation/screen/accountant_inventory_review_screen.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/presentation/screen/installment_dashboard_screen.dart';

import '../../../authentication/presentation/providers/accoutant_session_provider.dart';
import '../../../branch_reports/accountant_branch/presentation/screen/accountant_branch_screen.dart';
import '../../../branch_reports/customer_report/data/datasource/customer_report_datasource.dart';
import '../../../branch_reports/customer_report/presentation/screen/customer_report_screen.dart';
import 'package:jan_ghani_final/features/branch/inventory_management/presentation/screen/inventory_counting_screen.dart';
import '../../data/model/dashboard_model.dart';
import '../provider/dashboard_provider.dart';


// ── Role-based nav config ─────────────────────────────────────────────────────
class _NavItem {
  /// `assets/branch_icons/` ka SVG file name (bina folder / bina `.svg`).
  final String icon;
  final String label;
  final List<String> allowedRoles;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.allowedRoles,
  });
}

const List<_NavItem> _allNavItems = [
  _NavItem(
    icon: 'sidebar_icons/dashboard',
    label: 'Dashboard',
    allowedRoles: ['owner', 'accountant'],
  ),
  _NavItem(
    icon: 'ic_cash_registration',
    label: 'Branch',
    allowedRoles: ['owner', 'accountant', 'manager'],
  ),
  _NavItem(
    icon: 'sidebar_icons/branch_stock',
    label: 'Warehouse',
    allowedRoles: ['owner', 'accountant', 'warehouse_manager'],
  ),
  _NavItem(
    icon: 'ic_sale_price_trend',
    label: 'Inventory Review',
    allowedRoles: ['owner'],
  ),
  _NavItem(
    icon: 'ic_sale_price_trend',
    label: 'Investment',
    allowedRoles: ['owner', 'accountant'],
  ),
];

// ── Shared logout ────────────────────────────────────────────────────────────
Future<void> _confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Logout'),
      content: const Text('Kya aap logout karna chahte hain?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColor.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
  if (ok != true) return;

  await ref.read(accountantAuthNotifierProvider.notifier).logout();
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AccountantLoginScreen()),
      (_) => false,
    );
  }
}

// ── Balance reveal (bank-style hide) ─────────────────────────────────────────
final _balanceRevealedProvider = StateProvider.autoDispose<bool>((_) => false);

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good Morning,';
  if (h < 17) return 'Good Afternoon,';
  return 'Good Evening,';
}

Widget _screenByLabel(String label) {
  return switch (label) {
    'Dashboard'        => const _DashboardBody(),
    'Branch'           => BranchScreen(),
    'Warehouse'        => const AccountantAllWarehousesScreen(),
    'Inventory Review' => const AccountantInventoryReviewScreen(),
    'Investment'       => const AccountantInvestmentScreen(),
    _                  => const _DashboardBody(),
  };
}

// ── Main Screen ───────────────────────────────────────────────────────────────
class AccountantDashboardScreen extends ConsumerStatefulWidget {
  const AccountantDashboardScreen({super.key});

  @override
  ConsumerState<AccountantDashboardScreen> createState() =>
      _AccountantDashboardScreenState();
}

class _AccountantDashboardScreenState
    extends ConsumerState<AccountantDashboardScreen> {
  int _selectedIndex = 0;

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

  List<_NavItem> _filteredItems(String role) {
    return _allNavItems
        .where((item) => item.allowedRoles.contains(role))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: .user se access karo
    final user = ref.watch(currentUserProvider);

    final customerToken = user?.customerToken;
    if (customerToken != null && customerToken.isNotEmpty) {
      return _CustomerPortal(customerId: customerToken);
    }

    final desktop  = _isDesktop(context);
    final role     = user?.role ?? 'accountant';
    final navItems = _filteredItems(role);

    if (role == 'manager') {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: desktop
            ? Row(
          children: [
            _Sidebar(
              selectedIndex: 0,
              navItems:      navItems,
              role:          role,
              onItemTap:     (_) {},
            ),
            const Expanded(child: BranchScreen()),
          ],
        )
            : const BranchScreen(),
      );
    }

    // Inventory counter → seedha inventory counting screen (uske store ka)
    if (role == 'inventory_counter') {
      return InventoryCountingScreen(storeId: user?.branchId);
    }

    // Kisi role ke liye koi nav item na ho to crash se bachao (empty list guard)
    if (navItems.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
        body: Center(
          child: Text(
            'Is role ke liye koi screen available nahi',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final safeIndex = _selectedIndex < navItems.length ? _selectedIndex : 0;

    if (desktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: Row(
          children: [
            _Sidebar(
              selectedIndex: safeIndex,
              navItems:      navItems,
              role:          role,
              onItemTap:     (i) => setState(() => _selectedIndex = i),
            ),
            Expanded(child: _screenByLabel(navItems[safeIndex].label)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: _screenByLabel(navItems[safeIndex].label),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: navItems.asMap().entries.map((entry) {
                final i      = entry.key;
                final item   = entry.value;
                final active = i == safeIndex;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selectedIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColor.primary.withValues(alpha: 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            item.icon,
                            size: 22,
                            color: active
                                ? AppColor.primary
                                : AppColor.textMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: active
                                  ? AppColor.primary
                                  : AppColor.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Customer Portal
// ══════════════════════════════════════════════════════════════
class _CustomerPortal extends ConsumerStatefulWidget {
  final String customerId;
  const _CustomerPortal({required this.customerId});

  @override
  ConsumerState<_CustomerPortal> createState() => _CustomerPortalState();
}

class _CustomerPortalState extends ConsumerState<_CustomerPortal> {
  String?  _customerName;
  double   _customerBalance = 0;
  bool     _loading         = true;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final ds  = CustomerReportDatasource();
    final row = await ds.getCustomerInfo(widget.customerId);
    if (!mounted) return;
    setState(() {
      _customerName    = row?['name']    as String? ?? 'Customer';
      _customerBalance = row?['balance'] as double? ?? 0.0;
      _loading         = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return CustomerReportScreen(
      customerId:      widget.customerId,
      customerName:    _customerName ?? 'Customer',
      customerBalance: _customerBalance,
      hideAppBarBack:  true,
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────
class _Sidebar extends ConsumerWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final String role;
  final ValueChanged<int> onItemTap;

  const _Sidebar({
    required this.selectedIndex,
    required this.navItems,
    required this.role,
    required this.onItemTap,
  });

  String _roleLabel(String role) => switch (role) {
    'owner'             => 'Owner',
    'manager'           => 'Branch Manager',
    'accountant'        => 'Accountant',
    'cashier'           => 'Cashier',
    'warehouse_manager' => 'Warehouse Manager',
    'customer'          => 'Customer',
    _                   => role,
  };

  Color _roleColor(String role) => switch (role) {
    'owner'             => const Color(0xFF6C63FF),
    'manager'           => const Color(0xFF1D9E75),
    'accountant'        => const Color(0xFF378ADD),
    'warehouse_manager' => const Color(0xFFBA7517),
    _                   => AppColor.textMuted,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 236,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFEDEDF2))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEDEDF2))),
            ),
            child: Row(
              children: [
                const AppLogo(size: 40, radius: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jan Ghani',
                          style: TextStyle(
                              fontSize:   15,
                              fontWeight: FontWeight.w700,
                              color:      AppColor.textDark)),
                      Container(
                        margin:  const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:        _roleColor(role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _roleLabel(role),
                          style: TextStyle(
                              fontSize:   10,
                              fontWeight: FontWeight.w700,
                              color:      _roleColor(role)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text('MENU',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColor.textHint)),
                  ),
                  ...navItems.asMap().entries.map((entry) {
                    final item = entry.value;
                    return _SidebarItem(
                      icon:   item.icon,
                      label:  item.label,
                      active: selectedIndex == entry.key,
                      onTap:  () => onItemTap(entry.key),
                    );
                  }),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEDEDF2))),
            ),
            child: _SidebarItem(
              icon:   'ic_clear',
              label:  'Logout',
              active: false,
              danger: true,
              onTap:  () => _confirmAndLogout(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar Item ──────────────────────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  /// `assets/branch_icons/` ka SVG file name.
  final String   icon;
  final String   label;
  final bool     active;
  final bool     danger;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = danger
        ? AppColor.error
        : active
            ? AppColor.primary
            : AppColor.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width:   double.infinity,
          margin:  const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            color: active
                ? AppColor.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                width: 3,
                color: active ? AppColor.primary : Colors.transparent,
              ),
            ),
          ),
          child: Row(children: [
            AppIcon(icon, size: 20, color: fg),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize:   14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color:      fg,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Dashboard Body ────────────────────────────────────────────────────────────
class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ FIXED: currentUserProvider use karo
    final user        = ref.watch(currentUserProvider);
    final amountAsync = ref.watch(janghaniAmountProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);
    final desktop     = MediaQuery.of(context).size.width >= 800;

    final displayName = user?.fullName ?? 'User';
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'U';

    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFEDEDF2))),
          ),
          padding: EdgeInsets.fromLTRB(
              desktop ? 28 : 20, 14, desktop ? 28 : 12, 14),
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(),
                        style: const TextStyle(
                            fontSize: 13, color: AppColor.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize:   20,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'logout') _confirmAndLogout(context, ref);
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColor.textDark)),
                        Text(user?.email ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: AppColor.textMuted)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(children: const [
                      AppIcon('ic_clear', size: 18, color: AppColor.error),
                      SizedBox(width: 10),
                      Text('Logout',
                          style: TextStyle(color: AppColor.error)),
                    ]),
                  ),
                ],
                child: CircleAvatar(
                  radius:          20,
                  backgroundColor: AppColor.primary.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(janghaniAmountProvider);
              ref.invalidate(recentTransactionsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(desktop ? 28 : 20),
              child: desktop
                  ? _DesktopContent(
                  amountAsync: amountAsync,
                  recentAsync: recentAsync,
                  canRevealBalance: user?.role == 'accountant')
                  : _MobileContent(
                  amountAsync: amountAsync,
                  recentAsync: recentAsync,
                  canRevealBalance: user?.role == 'accountant'),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Money format + derived stats ─────────────────────────────────────────────
String _money(num? v, {bool decimals = false}) {
  final n = (v ?? 0).toDouble();
  final s = decimals ? n.toStringAsFixed(2) : n.toStringAsFixed(0);
  final parts = s.split('.');
  parts[0] = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return 'Rs. ${parts.join('.')}';
}

class _TxStats {
  final double cashIn;
  final double cashOut;
  final int count;
  const _TxStats(this.cashIn, this.cashOut, this.count);
  double get net => cashIn - cashOut;

  factory _TxStats.from(List<RecentTransactionModel> list) {
    double i = 0, o = 0;
    for (final t in list) {
      if (t.transactionType == 'cash_in') {
        i += t.amount;
      } else {
        o += t.amount;
      }
    }
    return _TxStats(i, o, list.length);
  }
}

// ── Desktop Content ───────────────────────────────────────────────────────────
class _DesktopContent extends StatelessWidget {
  final AsyncValue<JanghaniAmountModel?> amountAsync;
  final AsyncValue<List<RecentTransactionModel>> recentAsync;
  final bool canRevealBalance;
  const _DesktopContent({
    required this.amountAsync,
    required this.recentAsync,
    required this.canRevealBalance,
  });

  @override
  Widget build(BuildContext context) {
    final stats = recentAsync.asData?.value == null
        ? null
        : _TxStats.from(recentAsync.asData!.value);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            amountAsync.when(
              data:    (a) => _CashCard(amount: a, canReveal: canRevealBalance),
              loading: () => const _ShimmerCard(height: 168),
              error:   (_, __) => const _ErrorCard(),
            ),
            const SizedBox(height: 18),
            _StatRow(stats: stats),
            const SizedBox(height: 18),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 3,
                      child: _TransactionsPanel(recentAsync: recentAsync)),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: _CashFlowPanel(stats: stats)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile Content ────────────────────────────────────────────────────────────
class _MobileContent extends StatelessWidget {
  final AsyncValue<JanghaniAmountModel?> amountAsync;
  final AsyncValue<List<RecentTransactionModel>> recentAsync;
  final bool canRevealBalance;
  const _MobileContent({
    required this.amountAsync,
    required this.recentAsync,
    required this.canRevealBalance,
  });

  @override
  Widget build(BuildContext context) {
    final stats = recentAsync.asData?.value == null
        ? null
        : _TxStats.from(recentAsync.asData!.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        amountAsync.when(
          data:    (a) => _CashCard(amount: a, canReveal: canRevealBalance),
          loading: () => const _ShimmerCard(height: 176),
          error:   (_, __) => const _ErrorCard(),
        ),
        const SizedBox(height: 16),
        _StatRow(stats: stats, wrap: true),
        const SizedBox(height: 16),
        _CashFlowPanel(stats: stats),
        const SizedBox(height: 16),
        _TransactionsPanel(recentAsync: recentAsync),
      ],
    );
  }
}

// ── Stat Row ──────────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final _TxStats? stats;
  final bool wrap;
  const _StatRow({required this.stats, this.wrap = false});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        label: 'Cash In',
        value: stats == null ? '—' : _money(stats!.cashIn),
        icon: 'ic_cash_in',
        color: AppColor.cashIn,
      ),
      _StatCard(
        label: 'Cash Out',
        value: stats == null ? '—' : _money(stats!.cashOut),
        icon: 'ic_cash_out',
        color: AppColor.cashOut,
      ),
      _StatCard(
        label: 'Net Flow',
        value: stats == null ? '—' : _money(stats!.net),
        icon: 'ic_bank_net',
        color: AppColor.primary,
      ),
      _StatCard(
        label: 'Transactions',
        value: stats == null ? '—' : '${stats!.count}',
        icon: 'ic_transfer',
        color: const Color(0xFF378ADD),
      ),
    ];

    if (wrap) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: cards,
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color  color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(color: const Color(0xFFEDEDF2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: AppIcon(icon, size: 17, color: color)),
        ),
        const SizedBox(height: 12),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColor.textMuted)),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textDark)),
        ),
      ],
    ),
  );
}

// ── Panel scaffold ───────────────────────────────────────────────────────────
class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(18),
      border:       Border.all(color: const Color(0xFFEDEDF2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w700,
                color:      AppColor.textDark)),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

// ── Transactions Panel ────────────────────────────────────────────────────────
class _TransactionsPanel extends StatelessWidget {
  final AsyncValue<List<RecentTransactionModel>> recentAsync;
  const _TransactionsPanel({required this.recentAsync});

  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Transaction History',
    child: recentAsync.when(
      data: (list) => list.isEmpty
          ? const _EmptyState(
              icon: 'ic_transfer', text: 'No transactions yet')
          : Column(
              children: [
                for (final tx in list) _RecentTile(tx: tx),
              ],
            ),
      loading: () => Column(
        children: List.generate(
            4,
            (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: _ShimmerCard(height: 58),
                )),
      ),
      error: (_, __) => const _ErrorCard(),
    ),
  );
}

// ── Cash Flow Panel (recent activity insight) ────────────────────────────────
class _CashFlowPanel extends StatelessWidget {
  final _TxStats? stats;
  const _CashFlowPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return _Panel(
      title: 'Recent Cash Flow',
      child: s == null
          ? const _EmptyState(icon: 'ic_bank_net', text: 'No data available')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _flowRow('Cash In', _money(s.cashIn), AppColor.cashIn),
                const SizedBox(height: 12),
                _flowRow('Cash Out', _money(s.cashOut), AppColor.cashOut),
                const SizedBox(height: 16),
                _bar(s),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Flow',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textDark)),
                      Text(_money(s.net),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: s.net >= 0
                                  ? AppColor.cashIn
                                  : AppColor.cashOut)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _flowRow(String label, String value, Color color) => Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColor.textMuted))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textDark)),
        ],
      );

  Widget _bar(_TxStats s) {
    final total = s.cashIn + s.cashOut;
    final inFlex = total == 0 ? 1 : (s.cashIn / total * 1000).round();
    final outFlex = total == 0 ? 1 : (s.cashOut / total * 1000).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          Expanded(
              flex: inFlex == 0 ? 1 : inFlex,
              child: Container(height: 10, color: AppColor.cashIn)),
          Expanded(
              flex: outFlex == 0 ? 1 : outFlex,
              child: Container(
                  height: 10,
                  color: AppColor.cashOut.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColor.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: AppIcon(icon, size: 20, color: AppColor.grey400)),
          ),
          const SizedBox(height: 10),
          Text(text,
              style: const TextStyle(
                  fontSize: 13, color: AppColor.textMuted)),
        ],
      ),
    ),
  );
}

// ── Cash Card ─────────────────────────────────────────────────────────────────
class _CashCard extends ConsumerWidget {
  final JanghaniAmountModel? amount;

  /// Sirf `accountant` role hi balance dekh sakta hai (bank-style hide).
  final bool canReveal;

  const _CashCard({required this.amount, required this.canReveal});

  static const _mask = '••••••••';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revealed = canReveal && ref.watch(_balanceRevealedProvider);
    String show(double? v) => revealed ? _money(v, decimals: true) : _mask;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5B54E8), AppColor.primary, Color(0xFF8A83FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -50,
                child: _circle(170, 0.10),
              ),
              Positioned(
                right: 30,
                bottom: -80,
                child: _circle(150, 0.08),
              ),
              Positioned(
                right: 20,
                top: 24,
                child: AppIcon('ic_cash_registration',
                    size: 76, color: Colors.white.withValues(alpha: 0.14)),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Cash in Hand',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2)),
                        ),
                        if (canReveal)
                          _EyeButton(
                            revealed: revealed,
                            onTap: () => ref
                                .read(_balanceRevealedProvider.notifier)
                                .update((v) => !v),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: AppIcon('ic_custom_access',
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.7)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(show(amount?.cashInHand),
                          style: const TextStyle(
                            color:         Colors.white,
                            fontSize:      34,
                            fontWeight:    FontWeight.w800,
                            letterSpacing: -1,
                          )),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon('ic_custom_access',
                                  size: 12,
                                  color: Colors.white
                                      .withValues(alpha: 0.9)),
                              const SizedBox(width: 5),
                              Text('Reserved  ${show(amount?.cashReserved)}',
                                  style: const TextStyle(
                                    color:      Colors.white,
                                    fontSize:   12,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      AppIcon('ic_bank_net',
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.65)),
                      const SizedBox(width: 6),
                      Text('Janghani Net Amount',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _circle(double d, double opacity) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

class _EyeButton extends StatelessWidget {
  final bool revealed;
  final VoidCallback onTap;
  const _EyeButton({required this.revealed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Opacity(
            opacity: revealed ? 1 : 0.55,
            child: const AppIcon('ic_view', size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ── Recent Tile ───────────────────────────────────────────────────────────────
class _RecentTile extends StatelessWidget {
  final RecentTransactionModel tx;
  const _RecentTile({required this.tx});

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours   < 24) return '${diff.inHours} hr ago';
    if (diff.inDays    < 7)  return '${diff.inDays} d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isIn = tx.transactionType == 'cash_in';
    final color = isIn ? AppColor.cashIn : AppColor.cashOut;
    return Container(
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFEDEDF2)),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: AppIcon(
              isIn ? 'ic_cash_in' : 'ic_cash_out',
              size: 18,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tx.branchName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize:   13,
                      color:      AppColor.textDark)),
              const SizedBox(height: 2),
              Text(_formatDate(tx.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColor.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${isIn ? '+' : '−'} ${_money(tx.amount)}',
          style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w800,
              color:      color),
        ),
      ]),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────
class _ShimmerCard extends StatelessWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
        color:        Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16)),
  );
}

// ── Error Card ────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color:        const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(12)),
    child: const Row(children: [
      AppIcon('ic_rejected', color: Colors.red, size: 18),
      SizedBox(width: 8),
      Expanded(
        child: Text('Data could not load — pull to refresh',
            style: TextStyle(color: Colors.red, fontSize: 13)),
      ),
    ]),
  );
}