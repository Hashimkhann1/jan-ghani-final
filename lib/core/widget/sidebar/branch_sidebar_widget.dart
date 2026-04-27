// lib/core/layout/branch_side_bar.dart (ya jo bhi path hai)
// ── Alt+Key navigation shortcuts added ──

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/branch/accountant_transaction/presentation/screen/accountant_transaction_screen.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/branch/branch_stock_inventory/presentation/screen/branch_stock_inventory_screen.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/screen/counter_screen.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/screen/all_customer_screen.dart';
import 'package:jan_ghani_final/features/branch/customer_ledger/presentation/screen/all_customer_ledger_screen.dart';
import 'package:jan_ghani_final/features/branch/customer_ledger/presentation/screen/counter_customer_ledger_screen.dart';
import 'package:jan_ghani_final/features/branch/expense/presentation/screen/all_expense_screen.dart';
import 'package:jan_ghani_final/features/branch/sale_invoice/presentation/screen/sale_invoice_screen.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/screens/assign_stock_screen.dart';
import '../../../features/branch/assign_stock_to_branch/presentation/screen/branch_transfer_list_screen.dart';
import '../../../features/branch/cash_counter/presentation/screen/all_cash_transaction_screen.dart';
import '../../../features/branch/cash_counter/presentation/screen/cash_counter_screen.dart';
import '../../../features/branch/cash_counter/presentation/screen/counter_cash_transaction_screen.dart';
import '../../../features/branch/cash_store/presentation/screen/store_summary_screen.dart';
import '../../../features/branch/dashboard/presentation/screen/dashboard_screen.dart';
import '../../../features/branch/sale_invoice/presentation/screen/sale_invoice_list_screen.dart';
import '../../../features/branch/store_user/presentation/screen/user_screen.dart';

const _kGrey    = Color(0xFFD3D3D3);
const _kBg      = Color(0xFFF8F8F8);
const _kDark    = Color(0xFF333333);
const _kPrimary = Color(0xFF6366F1);

// ── NavItem ────────────────────────────────────────────────────
class NavItem {
  final IconData  icon;
  final String    label;
  final Widget    screen;
  final LogicalKeyboardKey? shortcutKey; // Alt+Key

  const NavItem({
    required this.icon,
    required this.label,
    required this.screen,
    this.shortcutKey,
  });
}

// ── Cashier Items ──────────────────────────────────────────────
// Alt+D=Dashboard, Alt+S=Sale Invoice, Alt+C=Customer,
// Alt+L=Ledger,   Alt+X=Cash Counter, Alt+T=Transactions, Alt+I=Stock
final _cashierItems = <NavItem>[
  NavItem(
    icon: Icons.dashboard_rounded, label: 'Dashboard',
    screen: const DashboardScreen(),
    shortcutKey: LogicalKeyboardKey.keyD,
  ),
  NavItem(
    icon: Icons.point_of_sale_rounded, label: 'Sale Invoice',
    screen: const SaleInvoiceScreen(),
    shortcutKey: LogicalKeyboardKey.keyS,
  ),
  NavItem(
    icon: Icons.people_alt_rounded, label: 'Customer',
    screen: const AllCustomerScreen(),
    shortcutKey: LogicalKeyboardKey.keyC,
  ),
  NavItem(
    icon: Icons.account_balance_wallet_rounded, label: 'Ledger',
    screen: const CounterCustomerLedgerScreen(),
    shortcutKey: LogicalKeyboardKey.keyL,
  ),
  NavItem(
    icon: Icons.savings_rounded, label: 'Cash Counter',
    screen: const CashCounterScreen(),
    shortcutKey: LogicalKeyboardKey.keyX,
  ),
  NavItem(
    icon: Icons.receipt_long_rounded, label: 'Transactions',
    screen: const CounterCashTransactionScreen(),
    shortcutKey: LogicalKeyboardKey.keyT,
  ),
  NavItem(
    icon: Icons.inventory_2_rounded, label: 'Stock',
    screen: const BranchStockInventoryScreen(),
    shortcutKey: LogicalKeyboardKey.keyI,
  ),
];

// ── Manager Items ──────────────────────────────────────────────
final _managerItems = <NavItem>[
  NavItem(
    icon: Icons.dashboard_rounded, label: 'Dashboard',
    screen: const DashboardScreen(),
    shortcutKey: LogicalKeyboardKey.keyD,
  ),
  NavItem(
    icon: Icons.manage_accounts_rounded, label: 'Users',
    screen: const AllUserScreen(),
    shortcutKey: LogicalKeyboardKey.keyU,
  ),
  NavItem(
    icon: Icons.people_alt_rounded, label: 'Customer',
    screen: const AllCustomerScreen(),
    shortcutKey: LogicalKeyboardKey.keyC,
  ),
  NavItem(
    icon: Icons.money_off_rounded, label: 'Expense',
    screen: const AllExpenseScreen(),
    shortcutKey: LogicalKeyboardKey.keyE,
  ),
  NavItem(
    icon: Icons.account_balance_wallet_rounded, label: 'All Ledger',
    screen: const AllCustomerLedgerScreen(),
    shortcutKey: LogicalKeyboardKey.keyL,
  ),
  NavItem(
    icon: Icons.swap_horiz_rounded, label: 'Transactions',
    screen: const AllCashTransactionScreen(),
    shortcutKey: LogicalKeyboardKey.keyT,
  ),
  NavItem(
    icon: Icons.savings_rounded, label: 'Cash Counter',
    screen: const CashCounterScreen(),
    shortcutKey: LogicalKeyboardKey.keyX,
  ),
  NavItem(
    icon: Icons.store_rounded, label: 'Store Summary',
    screen: const StoreSummaryScreen(),
    shortcutKey: LogicalKeyboardKey.keyM,
  ),
  NavItem(
    icon: Icons.inventory_2_rounded, label: 'Branch Stock',
    screen: const BranchStockInventoryScreen(),
    shortcutKey: LogicalKeyboardKey.keyI,
  ),
  NavItem(
    icon: Icons.local_shipping_rounded, label: 'Assign Stock to My Branch',
    screen: const BranchTransferListScreen(),
  ),
  NavItem(
    icon: Icons.local_shipping_rounded, label: 'Accountant Transactions',
    screen: const AccountantTransactionScreen(),
  ),
  NavItem(
    icon: Icons.point_of_sale_rounded, label: 'Counter',
    screen: const AllCounterScreen(),
  ),
  NavItem(
    icon: Icons.bar_chart_rounded, label: 'Invoice Report',
    screen: const SaleInvoiceListScreen(),
    shortcutKey: LogicalKeyboardKey.keyR,
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
  bool  _showTooltip  = false; // Alt hint overlay
  OverlayEntry? _tooltipOverlay;

  List<NavItem> _getItems(String role) {
    switch (role) {
      case 'cashier':
      case 'stock_officer':
        return _cashierItems;
      default:
        return _managerItems;
    }
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _tooltipOverlay?.remove();
    super.dispose();
  }

  // ── Keyboard handler ─────────────────────────────────────────
  bool _onKey(KeyEvent event) {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;

    // Alt key = Option (⌥) on Mac
    final alt = pressed.contains(LogicalKeyboardKey.altLeft) ||
        pressed.contains(LogicalKeyboardKey.altRight);

    if (!alt) return false;
    if (event is! KeyDownEvent) return false;

    final auth  = ref.read(authProvider);
    final items = _getItems(auth.role);

    // Alt+? pressed — find matching nav item
    for (int i = 0; i < items.length; i++) {
      if (items[i].shortcutKey == event.logicalKey) {
        _onTap(i, items);
        _showShortcutFeedback(items[i].label);
        return true;
      }
    }

    return false;
  }

  // ── Feedback toast ───────────────────────────────────────────
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
    final items     = _getItems(auth.role);
    final safeIndex = _index < items.length ? _index : 0;

    return Scaffold(
      backgroundColor: _kBg,
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────────
          Container(
            width: 90,
            color: Colors.white,
            child: Column(
              children: [
                // Logo + Role
                Container(
                  height: 56,
                  width:  double.infinity,
                  decoration: const BoxDecoration(
                    color:  Colors.white,
                    border: Border(bottom: BorderSide(color: _kGrey)),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('POS',
                          style: TextStyle(
                              fontSize:   16,
                              fontWeight: FontWeight.w800,
                              color:      _kDark,
                              letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text(auth.user?.roleLabel ?? '',
                          style: const TextStyle(
                              fontSize:   9,
                              color:      Color(0xFF2563EB),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),

                // Nav Items
                Expanded(
                  child: ListView.builder(
                    padding:   const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final isSelected = safeIndex == i;
                      final shortcut   = items[i].shortcutKey;
                      return _NavTile(
                        icon:        items[i].icon,
                        label:       items[i].label,
                        isSelected:  isSelected,
                        shortcutHint: shortcut != null
                            ? '⌥+${_keyLabel(shortcut)}'
                            : null,
                        onTap: () => _onTap(i, items),
                      );
                    },
                  ),
                ),

                // Logout
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap:        () => _confirmLogout(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width:   double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.logout_rounded,
                              size: 20, color: Color(0xFFEF4444)),
                          SizedBox(height: 4),
                          Text('Logout',
                              style: TextStyle(
                                  fontSize:   9,
                                  color:      Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

  /// LogicalKeyboardKey → readable label
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
  final String?    shortcutHint;  // e.g. "⌥+D"
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.shortcutHint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Tooltip(
        message: shortcutHint != null ? '$label  ($shortcutHint)' : label,
        preferBelow: false,
        child: InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width:   double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _kPrimary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size:  22,
                  color: isSelected ? _kPrimary : const Color(0xFF9CA3AF),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines:  2,
                  overflow:  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:   8,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? _kPrimary : const Color(0xFF9CA3AF),
                  ),
                ),
                // Shortcut hint chip — sirf selected ya hover pe nahi,
                // hamesha show karo (zyada visible)
                if (shortcutHint != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _kPrimary.withOpacity(0.15)
                          : const Color(0xFF9CA3AF).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      shortcutHint!,
                      style: TextStyle(
                        fontSize:   7,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? _kPrimary
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}