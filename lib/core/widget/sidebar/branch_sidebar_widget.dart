import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/branch_color.dart';
import 'package:jan_ghani_final/core/config/store_config.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/branch/branch_stock_damage/presentation/screen/branch_stock_damage_screen.dart';
import 'package:jan_ghani_final/features/branch/inventory_balance/presentation/screen/branch_inventory_balance_screen.dart';
import 'package:jan_ghani_final/features/branch/branch_stock_inventory/presentation/screen/branch_stock_inventory_screen.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';
import 'package:jan_ghani_final/features/branch/permissions/presentation/provider/permissions_provider.dart';
import 'package:jan_ghani_final/features/branch/permissions/presentation/screen/permissions_screen.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/screen/all_customer_screen.dart';
import 'package:jan_ghani_final/features/branch/customer_account/presentation/screen/customer_account_screen.dart';
import 'package:jan_ghani_final/features/branch/reports/presentation/screen/csr_screen.dart';
import 'package:jan_ghani_final/features/branch/reports/presentation/screen/pnl_report_screen.dart';
import 'package:jan_ghani_final/features/branch/reports/presentation/screen/product_profit_loss_screen.dart';
import 'package:jan_ghani_final/features/branch/reports/presentation/screen/sale_return_report_screen.dart';
import 'package:jan_ghani_final/features/branch/sale_invoice/presentation/screen/sale_invoice_screen.dart';
import '../../../features/branch/assign_stock_to_branch/presentation/provider/pending_transfer_badge_provider.dart';
import '../../../features/branch/assign_stock_to_branch/presentation/screen/branch_transfer_list_screen.dart';
import '../../../features/branch/return_stock_to_warehouse/presentation/screen/return_stock_screen.dart';
import '../../../features/branch/branch_transcation/presentation/screen/branch_transaction_screen.dart';
import '../../../features/branch/cash_counter/presentation/provider/cash_counter_provider.dart';
import '../../../features/branch/cash_counter/presentation/screen/cash_counter_screen.dart';
import '../../../features/branch/cash_counter/presentation/screen/counter_cash_transaction_screen.dart';
import '../../../features/branch/customer_ledger/presentation/screen/all_customer_ledger_screen.dart';
import '../../../features/branch/dashboard/presentation/screen/dashboard_screen.dart';
import '../../../features/branch/reports/presentation/screen/sale_invoice_report_screen.dart';
import '../../../features/branch/store_user/presentation/screen/user_screen.dart';

const _kBg       = Color(0xFFF8F8F8);
const _kDark     = Color(0xFF333333);

// ── Sidebar (navy) colours ──
const _kSideBg     = BranchColor.navy;
const _kSideActive = BranchColor.slate;
const _kSideHover  = Color(0xFF172746);
const _kSideLine   = Color(0xFF2B3A58);
const _kSideText   = Color(0xFFD1D5DE);
const _kSideMuted  = Color(0xFF848DA0);
const _kAccent     = BranchColor.accent;

const double _kExpandedW  = 248;
const double _kCollapsedW = 76;

// ── NavItem ────────────────────────────────────────────────────
class NavItem {
  final IconData  icon;
  final String    label;
  final Widget    screen;
  final LogicalKeyboardKey? shortcutKey;

  /// Sidebar me is item ke upar dikhne wala group heading
  /// (jaise "Stock", "Accounts"). Lagataar same section ke items ke
  /// beech heading sirf ek baar aati hai. `null` = koi heading nahi.
  final String? section;

  /// Same `group` wale lagataar items ek khulne/band hone wale menu
  /// (jaise "Inventory") ke andar aate hain. `null` = seedha item.
  final String? group;

  /// `PermissionCatalog` module key iss item ko govern karta hai —
  /// `<permKey>.view` granted na ho to yeh item sidebar me nahi dikhta
  /// (Owner hamesha exempt). `null` = kabhi hide nahi hota.
  final String? permKey;

  const NavItem({
    required this.icon,
    required this.label,
    required this.screen,
    this.section,
    this.group,
    this.shortcutKey,
    this.permKey,
  });
}

// ── Stock Officer Items ──────────────────────────────────────────
// Alt+D=Dashboard, Alt+S=Sale Invoice, Alt+C=Customer,
// Alt+A=Customer Account, Alt+L=Ledger, Alt+X=Cash Counter,
// Alt+T=Transactions, Alt+I=Stock, Alt+R=Sale Report
final _stockOfficerItems = <NavItem>[
  NavItem(
    icon: Icons.dashboard_outlined, label: 'Dashboard',
    screen: const DashboardScreen(),
    shortcutKey: LogicalKeyboardKey.keyD,
    permKey: 'dashboard',
  ),
  NavItem(
    icon: Icons.receipt_long_outlined, label: 'Sale Invoice',
    screen: const SaleInvoiceScreen(),
    shortcutKey: LogicalKeyboardKey.keyS,
    section: 'Counter',
    permKey: 'sale_invoice',
  ),
  NavItem(
    icon: Icons.inventory_2_outlined, label: 'Stock',
    screen: const BranchStockInventoryScreen(),
    shortcutKey: LogicalKeyboardKey.keyI,
    section: 'Stock',
    group: 'Inventory',
    permKey: 'branch_stock',
  ),
  NavItem(
    icon: Icons.report_gmailerrorred_outlined, label: 'Stock Damage',
    screen: const BranchStockDamageScreen(),
    section: 'Stock',
    group: 'Inventory',
    permKey: 'stock_damage',
  ),
  NavItem(
    icon: Icons.sync_alt_rounded, label: 'Stock Balance Requests',
    screen: const BranchInventoryBalanceScreen(),
    section: 'Stock',
    group: 'Inventory',
    permKey: 'inventory_balance',
  ),
  NavItem(
    icon: Icons.local_shipping_outlined, label: 'Assign Stock to My Branch',
    screen: const BranchTransferListScreen(),
    section: 'Stock',
    permKey: 'stock_transfer',
  ),
  NavItem(
    icon: Icons.undo_rounded, label: 'Return Stock to Warehouse',
    screen: const ReturnStockScreen(),
    shortcutKey: LogicalKeyboardKey.keyW,
    section: 'Stock',
    permKey: 'stock_return',
  ),
  NavItem(
    icon: Icons.people_alt_outlined, label: 'Customer',
    screen: const AllCustomerScreen(),
    shortcutKey: LogicalKeyboardKey.keyC,
    section: 'Accounts',
    permKey: 'customer',
  ),
  NavItem(
    icon: Icons.account_box_outlined, label: 'Customer account',
    screen: const CustomerAccountScreen(),
    shortcutKey: LogicalKeyboardKey.keyA,
    section: 'Accounts',
    permKey: 'customer_account',
  ),
  NavItem(
    icon: Icons.account_balance_wallet_outlined, label: 'Customer Recovery',
    screen: const CounterCustomerLedgerScreen(),
    shortcutKey: LogicalKeyboardKey.keyL,
    section: 'Accounts',
    permKey: 'customer_ledger',
  ),
  NavItem(
    icon: Icons.savings_outlined, label: 'Cash Counter',
    screen: const CashCounterScreen(),
    shortcutKey: LogicalKeyboardKey.keyX,
    section: 'Accounts',
    permKey: 'cash_counter',
  ),
  NavItem(
    icon: Icons.difference_outlined, label: 'Difference',
    screen: const CounterCashTransactionScreen(),
    shortcutKey: LogicalKeyboardKey.keyT,
    section: 'Accounts',
    permKey: 'cash_difference',
  ),
  NavItem(
    icon: Icons.compare_arrows_rounded, label: 'Branch Assign Balance to Accountant',
    screen: BranchTransactionScreen(),
    section: 'Accounts',
    permKey: 'branch_transaction',
  ),
  NavItem(
    icon: Icons.description_outlined, label: 'Sale Report',
    screen: const SaleInvoiceListScreen(),
    shortcutKey: LogicalKeyboardKey.keyR,
    section: 'Accounts',
    group: 'Reports',
    permKey: 'report_sale_invoice',
  ),
  NavItem(
    icon: Icons.assignment_return_outlined, label: 'Sale Return Report',
    screen: const SaleReturnReportScreen(),
    shortcutKey: LogicalKeyboardKey.keyN,
    section: 'Accounts',
    group: 'Reports',
    permKey: 'report_sale_return',
  ),
  NavItem(
    icon: Icons.menu_book_outlined, label: 'Customer Ledger Report',
    screen: const CsrScreen(),
    shortcutKey: LogicalKeyboardKey.keyG,
    section: 'Accounts',
    group: 'Reports',
    permKey: 'report_csr',
  ),
  NavItem(
    icon: Icons.account_balance_outlined, label: 'Profit & Loss',
    screen: const BranchPnlReportScreen(),
    section: 'Accounts',
    group: 'Reports',
    permKey: 'report_pnl',
  ),
  NavItem(
    icon: Icons.trending_up_rounded, label: 'Product Profit & Loss',
    screen: const BranchProductProfitLossScreen(),
    section: 'Accounts',
    group: 'Reports',
    permKey: 'report_product_pnl',
  ),
];

// ── Manager Items ──────────────────────────────────────────────
// Alt+D=Dashboard, Alt+U=Users, Alt+S=Sale Invoice, Alt+C=Customer,
// Alt+A=Customer Account, Alt+L=Ledger, Alt+T=Difference,
// Alt+X=Cash Counter, Alt+I=Branch Stock, Alt+R=Sale Invoice Report,
// Alt+N=Sale Return Report, Alt+G=Customer Ledger Report
final _managerItems = <NavItem>[
  NavItem(
    icon: Icons.dashboard_outlined, label: 'Dashboard',
    screen: const DashboardScreen(),
    shortcutKey: LogicalKeyboardKey.keyD,
    permKey: 'dashboard',
  ),
  NavItem(
    icon: Icons.receipt_long_outlined, label: 'Sale Invoice',
    screen: const SaleInvoiceScreen(),
    shortcutKey: LogicalKeyboardKey.keyS,
    section: 'Counter',
    permKey: 'sale_invoice',
  ),
  NavItem(
    icon: Icons.inventory_2_outlined, label: 'Branch Stock',
    screen: const BranchStockInventoryScreen(),
    shortcutKey: LogicalKeyboardKey.keyI,
    section: 'Stock',
    group: 'Inventory',
    permKey: 'branch_stock',
  ),
  NavItem(
    icon: Icons.report_gmailerrorred_outlined, label: 'Stock Damage',
    screen: const BranchStockDamageScreen(),
    section: 'Stock',
    group: 'Inventory',
    permKey: 'stock_damage',
  ),
  NavItem(
    icon: Icons.sync_alt_rounded, label: 'Stock Balance Requests',
    screen: const BranchInventoryBalanceScreen(),
    section: 'Stock',
    group: 'Inventory',
    permKey: 'inventory_balance',
  ),
  NavItem(
    icon: Icons.local_shipping_outlined, label: 'Assign Stock to My Branch',
    screen: const BranchTransferListScreen(),
    section: 'Stock',
    permKey: 'stock_transfer',
  ),
  NavItem(
    icon: Icons.undo_rounded, label: 'Return Stock to Warehouse',
    screen: const ReturnStockScreen(),
    shortcutKey: LogicalKeyboardKey.keyW,
    section: 'Stock',
    permKey: 'stock_return',
  ),
  NavItem(
    icon: Icons.people_alt_outlined, label: 'Customer',
    screen: const AllCustomerScreen(),
    shortcutKey: LogicalKeyboardKey.keyC,
    section: 'Accounts',
    permKey: 'customer',
  ),
  NavItem(
    icon: Icons.account_box_outlined, label: 'Customer account',
    screen: const CustomerAccountScreen(),
    shortcutKey: LogicalKeyboardKey.keyA,
    section: 'Accounts',
    permKey: 'customer_account',
  ),
  NavItem(
    icon: Icons.account_balance_wallet_outlined, label: 'Customer Recovery',
    screen: const CounterCustomerLedgerScreen(),
    shortcutKey: LogicalKeyboardKey.keyL,
    section: 'Accounts',
    permKey: 'customer_ledger',
  ),
  NavItem(
    icon: Icons.savings_outlined, label: 'Cash Counter',
    screen: const CashCounterScreen(),
    shortcutKey: LogicalKeyboardKey.keyX,
    section: 'Accounts',
    permKey: 'cash_counter',
  ),
  NavItem(
    icon: Icons.difference_outlined, label: 'Difference',
    screen: const CounterCashTransactionScreen(),
    shortcutKey: LogicalKeyboardKey.keyT,
    section: 'Accounts',
    permKey: 'cash_difference',
  ),
  NavItem(
    icon: Icons.compare_arrows_rounded, label: 'Branch Transactions',
    screen: BranchTransactionScreen(),
    section: 'Accounts',
    permKey: 'branch_transaction',
  ),
  NavItem(
    icon: Icons.description_outlined, label: 'Sale Invoice Report',
    screen: const SaleInvoiceListScreen(),
    shortcutKey: LogicalKeyboardKey.keyR,
    section: 'Accounts',
    group: 'Reports',
    permKey: 'report_sale_invoice',
  ),
  NavItem(
    icon: Icons.assignment_return_outlined, label: 'Sale Return Report',
    screen: const SaleReturnReportScreen(),
    shortcutKey: LogicalKeyboardKey.keyN,
    section: 'Accounts',
    group: 'Reports',
    permKey: 'report_sale_return',
  ),
  NavItem(
    icon: Icons.menu_book_outlined, label: 'Customer Ledger Report',
    screen: const CsrScreen(),
    shortcutKey: LogicalKeyboardKey.keyG,
    section: 'Accounts',
    group: 'Reports',
    permKey: 'report_csr',
  ),
  NavItem(
    icon: Icons.account_balance_outlined, label: 'Profit & Loss',
    screen: const BranchPnlReportScreen(),
    section: 'Accounts',
    group: 'Reports',
    permKey: 'report_pnl',
  ),
  NavItem(
    icon: Icons.trending_up_rounded, label: 'Product Profit & Loss',
    screen: const BranchProductProfitLossScreen(),
    section: 'Accounts',
    group: 'Reports',
    permKey: 'report_product_pnl',
  ),
  NavItem(
    icon: Icons.manage_accounts_outlined, label: 'Users',
    screen: const AllUserScreen(),
    shortcutKey: LogicalKeyboardKey.keyU,
    section: 'Shop',
    permKey: 'users',
  ),
  NavItem(
    icon: Icons.verified_user_outlined, label: 'Permissions',
    screen: const PermissionsScreen(),
    shortcutKey: LogicalKeyboardKey.keyP,
    section: 'Shop',
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

  /// User ne jo groups khol rakhe hain (Inventory / Reports).
  final _openGroups = <String>{};

  List<NavItem> _baseItems(String role) {
    switch (role) {
      case 'stock_officer':
        return _stockOfficerItems;
      default:
        // store_manager, store_owner & cashier. Cashier ko bhi poori list
        // milti hai — kya dikhega yeh sirf `_visibleItems` ka permission
        // filter tay karta hai (role defaults `PermissionCatalog` me hain),
        // warna Permissions screen se di gayi Dashboard / Reports wagera
        // ki permission sidebar me kabhi nazar nahi aati.
        return _managerItems;
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
    // Shortcut / snackbar se khula item apne group ke andar nazar aaye.
    final group = items[i].group;
    if (group != null) setState(() => _openGroups.add(group));
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

  void _showIncomingTransfer(PendingTransferState t, List<NavItem> items) {
    final idx = items.indexWhere((i) => i.screen is BranchTransferListScreen);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      width: 420,
      duration: const Duration(seconds: 8),
      backgroundColor: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(children: [
        const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New stock assigned',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              Text(
                '${t.incomingUnits} units'
                '${t.incomingNumber != null ? ' • ${t.incomingNumber}' : ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ]),
      action: idx < 0
          ? null
          : SnackBarAction(
              label: 'VIEW',
              textColor: const Color(0xFF93C5FD),
              onPressed: () => _onTap(idx, items),
            ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth      = ref.watch(authProvider);
    final perms     = ref.watch(permissionsProvider);
    final items     = _visibleItems(auth, perms);
    final safeIndex = _index < items.length ? _index : 0;

    ref.listen<PendingTransferState>(pendingTransferBadgeProvider, (prev, next) {
      if (prev == null || next.incomingSeq == prev.incomingSeq) return;
      _showIncomingTransfer(next, items);
    });

    return Scaffold(
      backgroundColor: _kBg,
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve:    Curves.easeInOut,
            width:    _collapsed ? _kCollapsedW : _kExpandedW,
            color:    _kSideBg,
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
                // ── Header: shop + counter + collapse toggle ────
                _header(auth),

                // ── Nav Items ──────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _buildNavRows(items, safeIndex),
                  ),
                ),

                // ── Footer: user + logout ──────────────────────
                _footer(auth),
              ],
                ),
              ),
            ),
          ),

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

  Widget _header(AuthState auth) {
    final counters = ref.watch(counterProvider).counters;
    final counter  = counters.where((c) => c.id == auth.counterId).firstOrNull;
    // Counter assign na ho to role dikhao.
    final subtitle = counter?.counterName ?? auth.user?.roleLabel ?? '';

    if (_collapsed) {
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Column(
          children: [
            const Icon(Icons.storefront_outlined,
                size: 26, color: Colors.white),
            const SizedBox(height: 6),
            _sideButton(Icons.chevron_right_rounded, 'Sidebar kholein',
                () => setState(() => _collapsed = false)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined,
                  size: 24, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(StoreConfig.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.w800,
                        color:      Colors.white)),
              ),
              _sideButton(Icons.chevron_left_rounded, 'Sidebar chhota karein',
                  () => setState(() => _collapsed = true)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _kAccent)),
        ],
      ),
    );
  }

  Widget _footer(AuthState auth) {
    final name = auth.fullName.isEmpty ? auth.username : auth.fullName;
    final logout = _sideButton(
        Icons.logout_rounded, 'Logout', () => _confirmLogout(context));

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kSideLine)),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: _collapsed ? 8 : 16, vertical: 12),
      child: _collapsed
          ? Column(
              children: [_avatar(auth), const SizedBox(height: 8), logout],
            )
          : Row(
              children: [
                _avatar(auth),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize:   14,
                              fontWeight: FontWeight.w700,
                              color:      Colors.white)),
                      Text(auth.user?.roleLabel ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: _kSideMuted)),
                    ],
                  ),
                ),
                logout,
              ],
            ),
    );
  }

  Widget _sideButton(IconData icon, String tooltip, VoidCallback onTap) =>
      IconButton(
        visualDensity: VisualDensity.compact,
        splashRadius:  18,
        tooltip:       tooltip,
        icon:          Icon(icon, size: 20, color: _kSideText),
        onPressed:     onTap,
      );

  Widget _avatar(AuthState auth) {
    final src = auth.fullName.isEmpty ? auth.username : auth.fullName;
    final letter = src.trim().isEmpty ? '?' : src.trim()[0].toUpperCase();
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:        _kSideActive,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(letter,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white)),
    );
  }

  /// Nav list ke rows banata hai — har naye `section` par ek heading
  /// (expanded me text, collapsed me patli divider line) aur har naye
  /// `group` par khulne/band hone wala parent row.
  List<Widget> _buildNavRows(List<NavItem> items, int safeIndex) {
    final pending = ref.watch(pendingTransferBadgeProvider);
    final rows = <Widget>[];
    String? lastSection;
    String? lastGroup;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];

      if (item.section != null && item.section != lastSection) {
        if (_collapsed) {
          if (i != 0) {
            rows.add(Container(
              height: 1,
              margin: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              color: _kSideLine,
            ));
          }
        } else {
          rows.add(Padding(
            padding: EdgeInsets.fromLTRB(20, i == 0 ? 6 : 16, 12, 6),
            child: Text(
              item.section!,
              style: const TextStyle(fontSize: 12, color: _kSideMuted),
            ),
          ));
        }
      }
      lastSection = item.section ?? lastSection;

      final group = item.group;
      // Chhoti sidebar mein parent row nahi — saare icons seedhe dikhte hain.
      if (!_collapsed && group != null && group != lastGroup) {
        final open = _openGroups.contains(group);
        final children = items.where((e) => e.group == group);
        final hasPending = pending.count > 0 &&
            children.any((e) => e.screen is BranchTransferListScreen);
        rows.add(_NavTile(
          icon: group == 'Reports'
              ? Icons.bar_chart_rounded
              : Icons.inventory_2_outlined,
          label: group,
          // Band group ke andar wali screen khuli ho to parent highlight.
          isSelected: !open && items[safeIndex].group == group,
          collapsed: false,
          // Band group mein bhi pending transfer ka badge nazar aaye.
          badgeCount: !open && hasPending ? pending.count : 0,
          expanded: open,
          onTap: () => setState(() =>
              open ? _openGroups.remove(group) : _openGroups.add(group)),
        ));
      }
      lastGroup = group;

      if (!_collapsed && group != null && !_openGroups.contains(group)) {
        continue;
      }

      final shortcut = item.shortcutKey;
      final isTransfer = item.screen is BranchTransferListScreen;
      rows.add(_NavTile(
        badgeCount: isTransfer ? pending.count : 0,
        badgeTooltip: isTransfer && pending.count > 0
            ? '${pending.count} pending • ${pending.units} units'
            : null,
        icon:       item.icon,
        label:      item.label,
        isSelected: safeIndex == i,
        collapsed:  _collapsed,
        indented:   !_collapsed && group != null,
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
  final String     label;
  final bool       isSelected;
  final bool       collapsed;
  final bool       indented;

  /// Sirf group ke parent row par set hota hai (chevron dikhane ke liye).
  final bool?      expanded;
  final String?    shortcutHint;
  final int        badgeCount;
  final String?    badgeTooltip;
  final VoidCallback onTap;

  const _NavTile({
    this.badgeCount = 0,
    this.badgeTooltip,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.collapsed,
    required this.onTap,
    this.indented = false,
    this.expanded,
    this.shortcutHint,
  });

  String get _badgeText => badgeCount > 99 ? '99+' : '$badgeCount';

  Widget _badge() => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        constraints: const BoxConstraints(minWidth: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(_badgeText,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      );

  @override
  Widget build(BuildContext context) {
    final fg = isSelected ? Colors.white : _kSideText;

    final Widget content = collapsed
        ? Center(
            child: badgeCount > 0
                ? Badge(
                    label: Text(_badgeText),
                    backgroundColor: const Color(0xFFEF4444),
                    child: Icon(icon, size: 22, color: fg),
                  )
                : Icon(icon, size: 22, color: fg))
        : Row(
            children: [
              Icon(icon, size: indented ? 18 : 20, color: fg),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:   indented ? 13 : 14,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
              if (badgeCount > 0) _badge(),
              if (expanded != null)
                Icon(
                  expanded!
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: fg,
                ),
            ],
          );

    final tile = Material(
      color: isSelected ? _kSideActive : Colors.transparent,
      child: InkWell(
        onTap:      onTap,
        hoverColor: _kSideHover,
        child: Container(
          height: 44,
          // Selected item ke left par sunehri patti. Baaqi items par bhi
          // utni hi (transparent) jagah taake text hile nahi.
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: isSelected ? _kAccent : Colors.transparent,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            left:  collapsed ? 0 : (indented ? 33 : 17),
            right: collapsed ? 3 : 14,
          ),
          child: content,
        ),
      ),
    );

    // Group parent par tooltip ki zaroorat nahi.
    if (expanded != null) return tile;

    return Tooltip(
      message: badgeTooltip ??
          (shortcutHint != null ? '$label  ($shortcutHint)' : label),
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 500),
      child: tile,
    );
  }
}
