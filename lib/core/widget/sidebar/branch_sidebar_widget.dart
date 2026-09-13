import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jan_ghani_final/core/widget/app_logo_widget.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/branch/branch_stock_damage/presentation/screen/branch_stock_damage_screen.dart';
// import 'package:jan_ghani_final/features/branch/inventory_balance/presentation/screen/branch_inventory_balance_screen.dart'; // hidden until apply_inventory_balance_item RPC migration is run
import 'package:jan_ghani_final/features/branch/branch_stock_inventory/presentation/screen/branch_stock_inventory_screen.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/screen/counter_screen.dart';
import 'package:jan_ghani_final/features/branch/permissions/presentation/provider/permissions_provider.dart';
import 'package:jan_ghani_final/features/branch/permissions/presentation/screen/permissions_screen.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/screen/all_customer_screen.dart';
import 'package:jan_ghani_final/features/branch/customer_account/presentation/screen/customer_account_screen.dart';
import 'package:jan_ghani_final/features/branch/reports/presentation/screen/csr_screen.dart';
import 'package:jan_ghani_final/features/branch/reports/presentation/screen/sale_return_report_screen.dart';
import 'package:jan_ghani_final/features/branch/sale_invoice/presentation/screen/sale_invoice_screen.dart';
import 'package:jan_ghani_final/features/branch/services/presentation/screen/service_screen.dart';
import '../../../features/branch/assign_stock_to_branch/presentation/screen/branch_transfer_list_screen.dart';
import '../../../features/branch/branch_transcation/presentation/screen/branch_transaction_screen.dart';
import '../../../features/branch/cash_counter/presentation/provider/cash_counter_provider.dart';
import '../../../features/branch/cash_counter/presentation/screen/cash_counter_screen.dart';
import '../../../features/branch/cash_counter/presentation/screen/counter_cash_transaction_screen.dart';
import '../../../features/branch/customer_ledger/presentation/screen/all_customer_ledger_screen.dart';
import '../../../features/branch/dashboard/presentation/screen/dashboard_screen.dart';
import '../../../features/branch/reports/presentation/screen/sale_invoice_report_screen.dart';
import '../../../features/branch/store_user/presentation/screen/user_screen.dart';

const _kGrey     = Color(0xFFD3D3D3);
const _kBg       = Color(0xFFF8F8F8);
const _kDark     = Color(0xFF333333);
const _kPrimary  = Color(0xFF6366F1);
const _kMid      = Color(0xFF64748B);
const _kSection  = Color(0xFF94A3B8);

const double _kExpandedW  = 248;
const double _kCollapsedW = 76;

/// permKey → custom SVG icon (assets/icons/). Jis key ka entry yahan
/// nahi, uska Material `NavItem.icon` fallback use hota hai.
const _kSidebarIconDir = 'assets/branch_icons/sidebar_icons';
const _navIconAsset = <String, String>{
  'dashboard':           '$_kSidebarIconDir/dashboard.svg',
  'sale_invoice':        '$_kSidebarIconDir/sale_invoice.svg',
  'customer':            '$_kSidebarIconDir/customer.svg',
  'customer_account':    '$_kSidebarIconDir/customer_account.svg',
  'customer_ledger':     '$_kSidebarIconDir/customer_ledger.svg',
  'cash_counter':        '$_kSidebarIconDir/cash_counter.svg',
  'cash_difference':     '$_kSidebarIconDir/difference.svg',
  'branch_transaction':  '$_kSidebarIconDir/branch_transactions.svg',
  'branch_stock':        '$_kSidebarIconDir/branch_stock.svg',
  'stock_transfer':      '$_kSidebarIconDir/assign_stock_to_my_branch.svg',
  'stock_damage':        '$_kSidebarIconDir/stock_damage.svg',
  'report_sale_invoice': '$_kSidebarIconDir/sale_invoice_report.svg',
  'report_sale_return':  '$_kSidebarIconDir/sale_return_report.svg',
  'report_csr':          '$_kSidebarIconDir/csr_report.svg',
  'users':               '$_kSidebarIconDir/users.svg',
  'permissions':         '$_kSidebarIconDir/permissions.svg',
};

// ── NavItem ────────────────────────────────────────────────────
class NavItem {
  final IconData  icon;
  final String    label;
  final Widget    screen;
  final LogicalKeyboardKey? shortcutKey;

  /// Sidebar me is item ke upar dikhne wala uppercase group heading
  /// (jaise "PARTIES", "REPORTS"). Lagataar same section ke items ke
  /// beech heading sirf ek baar aati hai. `null` = koi heading nahi.
  final String? section;

  /// `PermissionCatalog` module key iss item ko govern karta hai —
  /// `<permKey>.view` granted na ho to yeh item sidebar me nahi dikhta
  /// (Owner hamesha exempt). `null` = kabhi hide nahi hota.
  final String? permKey;

  const NavItem({
    required this.icon,
    required this.label,
    required this.screen,
    this.section,
    this.shortcutKey,
    this.permKey,
  });
}

// ── Cashier Items ──────────────────────────────────────────────
// Cashier gets: Sale Invoice, Customer, Customer Account, Customer Ledger,
// Cash Counter, Assign Stock to My Branch, Branch Stock (read-only),
// Customer Ledger Report.
// Alt+S=Sale Invoice, Alt+C=Customer, Alt+A=Customer Account, Alt+L=Ledger,
// Alt+X=Cash Counter, Alt+I=Branch Stock, Alt+G=Customer Ledger Report
final _cashierItems = <NavItem>[
  NavItem(
    icon: Icons.point_of_sale_rounded, label: 'Sale Invoice',
    screen: const SaleInvoiceScreen(),
    section: 'SALES',
    shortcutKey: LogicalKeyboardKey.keyS,
    permKey: 'sale_invoice',
  ),
  NavItem(
    icon: Icons.people_alt_rounded, label: 'Customer',
    screen: const AllCustomerScreen(),
    section: 'PARTIES',
    shortcutKey: LogicalKeyboardKey.keyC,
    permKey: 'customer',
  ),
  NavItem(
    icon: Icons.people_alt_rounded, label: 'Customer account',
    screen: const CustomerAccountScreen(),
    section: 'PARTIES',
    shortcutKey: LogicalKeyboardKey.keyA,
    permKey: 'customer_account',
  ),
  NavItem(
    icon: Icons.account_balance_wallet_rounded, label: 'Customer Ledger',
    screen: const CounterCustomerLedgerScreen(),
    section: 'PARTIES',
    shortcutKey: LogicalKeyboardKey.keyL,
    permKey: 'customer_ledger',
  ),
  NavItem(
    icon: Icons.savings_rounded, label: 'Cash Counter',
    screen: const CashCounterScreen(),
    section: 'CASH',
    shortcutKey: LogicalKeyboardKey.keyX,
    permKey: 'cash_counter',
  ),
  NavItem(
    icon: Icons.inventory_2_rounded, label: 'Branch Stock',
    screen: const BranchStockInventoryScreen(),
    section: 'INVENTORY',
    shortcutKey: LogicalKeyboardKey.keyI,
    permKey: 'branch_stock',
  ),
  NavItem(
    icon: Icons.local_shipping_rounded, label: 'Assign Stock to My Branch',
    screen: const BranchTransferListScreen(),
    section: 'INVENTORY',
    permKey: 'stock_transfer',
  ),
  NavItem(
    icon: Icons.bar_chart_rounded, label: 'Customer Ledger Report',
    screen: const CsrScreen(),
    section: 'REPORTS',
    shortcutKey: LogicalKeyboardKey.keyG,
    permKey: 'report_csr',
  ),
];

// ── Stock Officer Items ──────────────────────────────────────────
// Alt+D=Dashboard, Alt+S=Sale Invoice, Alt+C=Customer,
// Alt+A=Customer Account, Alt+L=Ledger, Alt+X=Cash Counter,
// Alt+T=Transactions, Alt+I=Stock, Alt+R=Sale Report
final _stockOfficerItems = <NavItem>[
  NavItem(
    icon: Icons.dashboard_rounded, label: 'Dashboard',
    screen: const DashboardScreen(),
    section: 'MAIN',
    shortcutKey: LogicalKeyboardKey.keyD,
    permKey: 'dashboard',
  ),
  NavItem(
    icon: Icons.point_of_sale_rounded, label: 'Sale Invoice',
    screen: const SaleInvoiceScreen(),
    section: 'SALES',
    shortcutKey: LogicalKeyboardKey.keyS,
    permKey: 'sale_invoice',
  ),
  // NavItem(
  //   icon: Icons.point_of_sale_rounded, label: 'Service',
  //   screen: const ServiceScreen(),
  //   shortcutKey: LogicalKeyboardKey.keyS,
  // ),
  NavItem(
    icon: Icons.people_alt_rounded, label: 'Customer',
    screen: const AllCustomerScreen(),
    section: 'PARTIES',
    shortcutKey: LogicalKeyboardKey.keyC,
    permKey: 'customer',
  ),
  NavItem(
    icon: Icons.people_alt_rounded, label: 'Customer account',
    screen: const CustomerAccountScreen(),
    section: 'PARTIES',
    shortcutKey: LogicalKeyboardKey.keyA,
    permKey: 'customer_account',
  ),
  NavItem(
    icon: Icons.account_balance_wallet_rounded, label: 'Customer Ledger',
    screen: const CounterCustomerLedgerScreen(),
    section: 'PARTIES',
    shortcutKey: LogicalKeyboardKey.keyL,
    permKey: 'customer_ledger',
  ),
  NavItem(
    icon: Icons.savings_rounded, label: 'Cash Counter',
    screen: const CashCounterScreen(),
    section: 'CASH',
    shortcutKey: LogicalKeyboardKey.keyX,
    permKey: 'cash_counter',
  ),
  NavItem(
    icon: Icons.receipt_long_rounded, label: 'Difference',
    screen: const CounterCashTransactionScreen(),
    section: 'CASH',
    shortcutKey: LogicalKeyboardKey.keyT,
    permKey: 'cash_difference',
  ),
  NavItem(
    icon: Icons.local_shipping_rounded, label: 'Branch Assign Balance to Accountant',
    screen: BranchTransactionScreen(),
    section: 'CASH',
    permKey: 'branch_transaction',
  ),
  NavItem(
    icon: Icons.inventory_2_rounded, label: 'Stock',
    screen: const BranchStockInventoryScreen(),
    section: 'INVENTORY',
    shortcutKey: LogicalKeyboardKey.keyI,
    permKey: 'branch_stock',
  ),
  NavItem(
    icon: Icons.local_shipping_rounded, label: 'Assign Stock to My Branch',
    screen: const BranchTransferListScreen(),
    section: 'INVENTORY',
    permKey: 'stock_transfer',
  ),
  NavItem(
    icon: Icons.local_shipping_rounded, label: 'Stock Damage',
    screen: const BranchStockDamageScreen(),
    section: 'INVENTORY',
    permKey: 'stock_damage',
  ),
  // NavItem(
  //   icon: Icons.sync_alt_rounded, label: 'Stock Balance Requests',
  //   screen: const BranchInventoryBalanceScreen(),
  //   section: 'INVENTORY',
  //   permKey: 'inventory_balance',
  // ), // hidden until apply_inventory_balance_item RPC migration is run
  NavItem(
    icon: Icons.bar_chart_rounded, label: 'Sale Report',
    screen: const SaleInvoiceListScreen(),
    section: 'REPORTS',
    shortcutKey: LogicalKeyboardKey.keyR,
    permKey: 'report_sale_invoice',
  ),
  NavItem(
    icon: Icons.local_shipping_rounded, label: 'Sale Return Report',
    screen: const SaleReturnReportScreen(),
    section: 'REPORTS',
    shortcutKey: LogicalKeyboardKey.keyN,
    permKey: 'report_sale_return',
  ),
  NavItem(
    icon: Icons.bar_chart_rounded, label: 'Customer Ledger Report',
    screen: const CsrScreen(),
    section: 'REPORTS',
    shortcutKey: LogicalKeyboardKey.keyG,
    permKey: 'report_csr',
  ),
];

// ── Manager Items ──────────────────────────────────────────────
// Alt+D=Dashboard, Alt+U=Users, Alt+S=Sale Invoice, Alt+C=Customer,
// Alt+A=Customer Account, Alt+L=Ledger, Alt+T=Difference,
// Alt+X=Cash Counter, Alt+I=Branch Stock, Alt+R=Sale Invoice Report,
// Alt+N=Sale Return Report, Alt+G=Customer Ledger Report
final _managerItems = <NavItem>[
  NavItem(
    icon: Icons.dashboard_rounded, label: 'Dashboard',
    screen: const DashboardScreen(),
    section: 'MAIN',
    shortcutKey: LogicalKeyboardKey.keyD,
    permKey: 'dashboard',
  ),
  NavItem(
    icon: Icons.point_of_sale_rounded, label: 'Sale Invoice',
    screen: const SaleInvoiceScreen(),
    section: 'SALES',
    shortcutKey: LogicalKeyboardKey.keyS,
    permKey: 'sale_invoice',
  ),
  // NavItem(
  //   icon: Icons.point_of_sale_rounded, label: 'Service',
  //   screen: const ServiceScreen(),
  //   shortcutKey: LogicalKeyboardKey.keyS,
  // ),
  NavItem(
    icon: Icons.people_alt_rounded, label: 'Customer',
    screen: const AllCustomerScreen(),
    section: 'PARTIES',
    shortcutKey: LogicalKeyboardKey.keyC,
    permKey: 'customer',
  ),
  NavItem(
    icon: Icons.people_alt_rounded, label: 'Customer account',
    screen: const CustomerAccountScreen(),
    section: 'PARTIES',
    shortcutKey: LogicalKeyboardKey.keyA,
    permKey: 'customer_account',
  ),
  NavItem(
    icon: Icons.account_balance_wallet_rounded, label: 'Customer Ledger',
    screen: const CounterCustomerLedgerScreen(),
    section: 'PARTIES',
    shortcutKey: LogicalKeyboardKey.keyL,
    permKey: 'customer_ledger',
  ),
  NavItem(
    icon: Icons.receipt_long_rounded, label: 'Difference',
    screen: const CounterCashTransactionScreen(),
    section: 'CASH',
    shortcutKey: LogicalKeyboardKey.keyT,
    permKey: 'cash_difference',
  ),
  NavItem(
    icon: Icons.savings_rounded, label: 'Cash Counter',
    screen: const CashCounterScreen(),
    section: 'CASH',
    shortcutKey: LogicalKeyboardKey.keyX,
    permKey: 'cash_counter',
  ),
  NavItem(
    icon: Icons.local_shipping_rounded, label: 'Branch Transactions',
    screen: BranchTransactionScreen(),
    section: 'CASH',
    permKey: 'branch_transaction',
  ),
  NavItem(
    icon: Icons.inventory_2_rounded, label: 'Branch Stock',
    screen: const BranchStockInventoryScreen(),
    section: 'INVENTORY',
    shortcutKey: LogicalKeyboardKey.keyI,
    permKey: 'branch_stock',
  ),
  NavItem(
    icon: Icons.local_shipping_rounded, label: 'Assign Stock to My Branch',
    screen: const BranchTransferListScreen(),
    section: 'INVENTORY',
    permKey: 'stock_transfer',
  ),
  // NavItem(
  //   icon: Icons.point_of_sale_rounded, label: 'Counter',
  //   screen: const AllCounterScreen(),
  // ),
  NavItem(
    icon: Icons.local_shipping_rounded, label: 'Stock Damage',
    screen: const BranchStockDamageScreen(),
    section: 'INVENTORY',
    permKey: 'stock_damage',
  ),
  // NavItem(
  //   icon: Icons.sync_alt_rounded, label: 'Stock Balance Requests',
  //   screen: const BranchInventoryBalanceScreen(),
  //   section: 'INVENTORY',
  //   permKey: 'inventory_balance',
  // ), // hidden until apply_inventory_balance_item RPC migration is run
  NavItem(
    icon: Icons.bar_chart_rounded, label: 'Sale Invoice Report',
    screen: const SaleInvoiceListScreen(),
    section: 'REPORTS',
    shortcutKey: LogicalKeyboardKey.keyR,
    permKey: 'report_sale_invoice',
  ),
  NavItem(
    icon: Icons.bar_chart_rounded, label: 'Sale Return Report',
    screen: const SaleReturnReportScreen(),
    section: 'REPORTS',
    shortcutKey: LogicalKeyboardKey.keyN,
    permKey: 'report_sale_return',
  ),
  NavItem(
    icon: Icons.bar_chart_rounded, label: 'Customer Ledger Report',
    screen: const CsrScreen(),
    section: 'REPORTS',
    shortcutKey: LogicalKeyboardKey.keyG,
    permKey: 'report_csr',
  ),
  NavItem(
    icon: Icons.manage_accounts_rounded, label: 'Users',
    screen: const AllUserScreen(),
    section: 'ADMINISTRATION',
    shortcutKey: LogicalKeyboardKey.keyU,
    permKey: 'users',
  ),
  NavItem(
    icon: Icons.verified_user_rounded, label: 'Permissions',
    screen: const PermissionsScreen(),
    section: 'ADMINISTRATION',
    shortcutKey: LogicalKeyboardKey.keyP,
    permKey: 'permissions',
  ),
];

// ── BranchSideBar ──────────────────────────────────────────────
class BranchSideBar extends ConsumerStatefulWidget {
  const BranchSideBar({super.key});

  @override
  ConsumerState<BranchSideBar> createState() => _SideBarState();
}

class _SideBarState extends ConsumerState<BranchSideBar> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  int   _index        = 0;
  bool  _collapsed    = false;
  bool  _showTooltip  = false;
  OverlayEntry? _tooltipOverlay;

  List<NavItem> _baseItems(String role) {
    switch (role) {
      case 'cashier':
        return _cashierItems;
      case 'stock_officer':
        return _stockOfficerItems;
      default:
        return _managerItems; // store_manager & store_owner
    }
  }

  /// Role ki base list ko logged-in user ke actual granted permissions
  /// se filter karta hai. Owner hamesha exempt (full access).
  List<NavItem> _visibleItems(AuthState auth, PermissionsState perms) {
    final base = _baseItems(auth.role);
    if (auth.isOwner) return base;
    return base.where((item) {
      if (item.permKey == null) return true;
      return perms.isGranted(auth.userId, auth.role, '${item.permKey}.view');
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = ref.read(authProvider);

      // Sidebar ke permission-based filtering ke liye zaroori — is user
      // ne agar apni koi customization save ki hai to woh yahan load ho.
      ref.read(permissionsProvider.notifier).loadForStore(auth.storeId);

      // App open hote hi — agar is user ke saath ek counter assign hai — us
      // counter ka aaj ka row khud-ba-khud ban jaye (opening = kal ka net
      // amount), taake manually check karke type na karna pare. Idempotent
      // hai (fn_create_next_day_counter already-registered ko silently
      // skip karta hai), isliye baar-baar login/restart pe safe hai.
      if (auth.counterId != null) {
        ref.read(cashCounterProvider.notifier).autoRegisterTodayIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _tooltipOverlay?.remove();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;

    final alt = pressed.contains(LogicalKeyboardKey.altLeft) ||
        pressed.contains(LogicalKeyboardKey.altRight);

    if (!alt) return false;
    if (event is! KeyDownEvent) return false;

    final auth  = ref.read(authProvider);
    final perms = ref.read(permissionsProvider);
    final items = _visibleItems(auth, perms);

    for (int i = 0; i < items.length; i++) {
      if (items[i].shortcutKey == event.logicalKey) {
        _onTap(i, items);
        _showShortcutFeedback(items[i].label);
        return true;
      }
    }

    return false;
  }

  void _showShortcutFeedback(String label) {
    _tooltipOverlay?.remove();
    _tooltipOverlay = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 20, left: 0, right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:        _kDark.withOpacity(0.88),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.keyboard_alt_outlined,
                      size: 14, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text('Navigating to $label',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_tooltipOverlay!);
    Future.delayed(const Duration(milliseconds: 1000), () {
      _tooltipOverlay?.remove();
      _tooltipOverlay = null;
    });
  }

  void _onTap(int i, List<NavItem> items) {
    if (_index == i) return;
    setState(() => _index = i);
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => items[i].screen),
          (_) => false,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Logout Account?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Do you want to log out?',
            style: TextStyle(fontSize: 13)),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: Color(0xFF6B7280))),
                ),
              ),
              Flexible(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation:       0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(authProvider.notifier).logout();
                  },
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth      = ref.watch(authProvider);
    final perms     = ref.watch(permissionsProvider);
    final items     = _visibleItems(auth, perms);
    final safeIndex = _index < items.length ? _index : 0;

    return Scaffold(
      backgroundColor: _kBg,
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve:    Curves.easeInOut,
            width:    _collapsed ? _kCollapsedW : _kExpandedW,
            color:    Colors.white,
            // Width animate hone ke doraan content ko uski FINAL width par
            // hi layout do (OverflowBox) aur bahar nikla hissa clip kar do —
            // warna intermediate frames me RenderFlex overflow aata hai.
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth:  _collapsed ? _kCollapsedW : _kExpandedW,
                maxWidth:  _collapsed ? _kCollapsedW : _kExpandedW,
                child: Column(
              children: [
                // ── Header: logo + title + collapse toggle ──────
                Container(
                  height: 60,
                  width:  double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: _collapsed ? 0 : 14),
                  decoration: const BoxDecoration(
                    color:  Colors.white,
                    border: Border(bottom: BorderSide(color: _kGrey)),
                  ),
                  child: Row(
                    mainAxisAlignment: _collapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      const AppLogo(size: 34, radius: 9),
                      if (!_collapsed) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment:  MainAxisAlignment.center,
                            children: [
                              const Text('POS',
                                  style: TextStyle(
                                      fontSize:   15,
                                      fontWeight: FontWeight.w800,
                                      color:      _kDark,
                                      letterSpacing: 1)),
                              Text(auth.user?.roleLabel ?? '',
                                  style: const TextStyle(
                                      fontSize:   10,
                                      color:      Color(0xFF2563EB),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          splashRadius:  18,
                          icon: const Icon(Icons.chevron_left_rounded,
                              size: 22, color: _kMid),
                          onPressed: () =>
                              setState(() => _collapsed = true),
                        ),
                      ],
                    ],
                  ),
                ),

                if (_collapsed)
                  Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      splashRadius:  18,
                      icon: const Icon(Icons.chevron_right_rounded,
                          size: 22, color: _kMid),
                      onPressed: () => setState(() => _collapsed = false),
                    ),
                  ),

                // ── Nav Items ──────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _buildNavRows(items, safeIndex),
                  ),
                ),

                // ── Footer: user + logout ──────────────────────
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _kGrey)),
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: _collapsed ? 8 : 12, vertical: 10),
                  child: _collapsed
                      ? Column(
                          children: [
                            _avatar(auth),
                            const SizedBox(height: 8),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              splashRadius:  18,
                              tooltip: 'Logout',
                              icon: const Icon(Icons.logout_rounded,
                                  size: 20, color: Color(0xFFEF4444)),
                              onPressed: () => _confirmLogout(context),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            _avatar(auth),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.fullName.isEmpty
                                        ? auth.username
                                        : auth.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize:   13,
                                        fontWeight: FontWeight.w700,
                                        color:      _kDark),
                                  ),
                                  Text(
                                    auth.username,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11, color: _kMid),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              splashRadius:  18,
                              tooltip: 'Logout',
                              icon: const Icon(Icons.logout_rounded,
                                  size: 20, color: Color(0xFFEF4444)),
                              onPressed: () => _confirmLogout(context),
                            ),
                          ],
                        ),
                ),
              ],
                ),
              ),
            ),
          ),

          Container(width: 1, color: _kGrey),

          // ── Body ──────────────────────────────────────────────
          Expanded(
            child: Navigator(
              key: _navigatorKey,
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => items[safeIndex].screen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(AuthState auth) {
    final src = auth.fullName.isEmpty ? auth.username : auth.fullName;
    final letter = src.isEmpty ? '?' : src.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 16,
      backgroundColor: _kPrimary.withOpacity(0.12),
      child: Text(letter,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: _kPrimary)),
    );
  }

  /// Nav list ke rows banata hai — har naye `section` par ek heading
  /// (expanded me uppercase text, collapsed me patli divider line).
  List<Widget> _buildNavRows(List<NavItem> items, int safeIndex) {
    final rows = <Widget>[];
    String? lastSection;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];

      if (item.section != null && item.section != lastSection) {
        if (_collapsed) {
          if (i != 0) {
            rows.add(Container(
              height: 1,
              margin: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              color: _kGrey.withOpacity(0.7),
            ));
          }
        } else {
          rows.add(Padding(
            padding: EdgeInsets.fromLTRB(18, i == 0 ? 6 : 16, 12, 6),
            child: Text(
              item.section!,
              style: const TextStyle(
                fontSize:      11,
                fontWeight:    FontWeight.w700,
                color:         _kSection,
                letterSpacing: 0.8,
              ),
            ),
          ));
        }
      }
      lastSection = item.section ?? lastSection;

      final shortcut = items[i].shortcutKey;
      rows.add(_NavTile(
        icon:       items[i].icon,
        iconAsset:  _navIconAsset[items[i].permKey],
        label:      items[i].label,
        isSelected: safeIndex == i,
        collapsed:  _collapsed,
        shortcutHint: shortcut != null ? '⌥${_keyLabel(shortcut)}' : null,
        onTap: () => _onTap(i, items),
      ));
    }
    return rows;
  }

  String _keyLabel(LogicalKeyboardKey key) {
    final map = {
      LogicalKeyboardKey.keyA: 'A', LogicalKeyboardKey.keyB: 'B',
      LogicalKeyboardKey.keyC: 'C', LogicalKeyboardKey.keyD: 'D',
      LogicalKeyboardKey.keyE: 'E', LogicalKeyboardKey.keyF: 'F',
      LogicalKeyboardKey.keyG: 'G', LogicalKeyboardKey.keyH: 'H',
      LogicalKeyboardKey.keyI: 'I', LogicalKeyboardKey.keyJ: 'J',
      LogicalKeyboardKey.keyK: 'K', LogicalKeyboardKey.keyL: 'L',
      LogicalKeyboardKey.keyM: 'M', LogicalKeyboardKey.keyN: 'N',
      LogicalKeyboardKey.keyO: 'O', LogicalKeyboardKey.keyP: 'P',
      LogicalKeyboardKey.keyQ: 'Q', LogicalKeyboardKey.keyR: 'R',
      LogicalKeyboardKey.keyS: 'S', LogicalKeyboardKey.keyT: 'T',
      LogicalKeyboardKey.keyU: 'U', LogicalKeyboardKey.keyV: 'V',
      LogicalKeyboardKey.keyW: 'W', LogicalKeyboardKey.keyX: 'X',
      LogicalKeyboardKey.keyY: 'Y', LogicalKeyboardKey.keyZ: 'Z',
    };
    return map[key] ?? '?';
  }
}

// ── Nav Tile ──────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData   icon;
  final String?    iconAsset;
  final String     label;
  final bool       isSelected;
  final bool       collapsed;
  final String?    shortcutHint;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.collapsed,
    required this.onTap,
    this.iconAsset,
    this.shortcutHint,
  });

  Widget _icon(Color fg, double size) => iconAsset != null
      ? UnconstrainedBox(
          child: SizedBox(
            width:  size,
            height: size,
            child: SvgPicture.asset(
              iconAsset!,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
            ),
          ),
        )
      : Icon(icon, size: size, color: fg);

  @override
  Widget build(BuildContext context) {
    final fg = isSelected ? _kPrimary : _kMid;

    final Widget content = collapsed
        ? Center(child: _icon(fg, 22))
        : Row(
            children: [
              _icon(fg, 20),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected ? _kPrimary : _kDark,
                  ),
                ),
              ),
              if (shortcutHint != null)
                Text(
                  shortcutHint!,
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? _kPrimary
                        : _kSection,
                  ),
                ),
            ],
          );

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 12 : 10, vertical: 2),
      child: Tooltip(
        message: shortcutHint != null ? '$label  ($shortcutHint)' : label,
        preferBelow: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:        onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:   double.infinity,
              padding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 0 : 12, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected
                    ? _kPrimary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}