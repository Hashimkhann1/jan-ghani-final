import 'package:flutter/material.dart';
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

// ── NavItem — icon based ─────────────────────────────────────
class NavItem {
  final IconData icon;
  final String   label;
  final Widget   screen;

  const NavItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}

// ── Cashier Items ────────────────────────────────────────────
final _cashierItems = <NavItem>[
  NavItem(icon: Icons.dashboard_rounded,              label: 'Dashboard',    screen: const DashboardScreen()),
  NavItem(icon: Icons.point_of_sale_rounded,          label: 'Sale Invoice', screen: const SaleInvoiceScreen()),
  NavItem(icon: Icons.people_alt_rounded,             label: 'Customer',     screen: const AllCustomerScreen()),
  NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Ledger',       screen: const CounterCustomerLedgerScreen()),
  NavItem(icon: Icons.savings_rounded,                label: 'Cash Counter', screen: const CashCounterScreen()),
  NavItem(icon: Icons.receipt_long_rounded,           label: 'Transactions', screen: const CounterCashTransactionScreen()),
  NavItem(icon: Icons.inventory_2_rounded,            label: 'Stock',        screen: const BranchStockInventoryScreen()),
];

// ── Manager Items ─────────────────────────────────────────────
final _managerItems = <NavItem>[
  NavItem(icon: Icons.dashboard_rounded,              label: 'Dashboard',      screen: const DashboardScreen()),
  NavItem(icon: Icons.manage_accounts_rounded,        label: 'Users',          screen: const AllUserScreen()),
  NavItem(icon: Icons.people_alt_rounded,             label: 'Customer',       screen: const AllCustomerScreen()),
  NavItem(icon: Icons.money_off_rounded,              label: 'Expense',        screen: const AllExpenseScreen()),
  NavItem(icon: Icons.account_balance_wallet_rounded, label: 'All Ledger',     screen: const AllCustomerLedgerScreen()),
  NavItem(icon: Icons.swap_horiz_rounded,             label: 'Transactions',   screen: const AllCashTransactionScreen()),
  NavItem(icon: Icons.savings_rounded,                label: 'Cash Counter',   screen: const CashCounterScreen()),
  NavItem(icon: Icons.store_rounded,                  label: 'Store Summary',  screen: const StoreSummaryScreen()),
  NavItem(icon: Icons.inventory_2_rounded,            label: 'Branch Stock',   screen: const BranchStockInventoryScreen()),
  NavItem(icon: Icons.local_shipping_rounded,         label: 'Accountant Transactions',   screen: const AccountantTransactionScreen()),
  NavItem(icon: Icons.point_of_sale_rounded,          label: 'Counter',        screen: const AllCounterScreen()),
  NavItem(icon: Icons.bar_chart_rounded,              label: 'Invoice Report', screen: const SaleInvoiceListScreen()),
];

class BranchSideBar extends ConsumerStatefulWidget {
  const BranchSideBar({super.key});

  @override
  ConsumerState<BranchSideBar> createState() => _SideBarState();
}

class _SideBarState extends ConsumerState<BranchSideBar> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  int _index = 0;

  List<NavItem> _getItems(String role) {
    switch (role) {
      case 'cashier':
      case 'stock_officer':
        return _cashierItems;
      default:
        return _managerItems;
    }
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
                    elevation: 0,
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

          // ── Sidebar ─────────────────────────────────────
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
                      return _NavTile(
                        icon:       items[i].icon,
                        label:      items[i].label,
                        isSelected: isSelected,
                        onTap:      () => _onTap(i, items),
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

          // ── Body — Navigator ──────────────────────────────
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
}

// ── Nav Tile ─────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     isSelected;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width:   double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
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
            ],
          ),
        ),
      ),
    );
  }
}