// Updated on 2026-10-02 09:49 AM
// =============================================================
// sidebar_widget.dart — WAREHOUSE app shell (Stitch "Improved Sidebar")
//
//   • Default COLLAPSED 72px rail  ⇄  Expanded 248px (chevron button)
//   • Search menu (Ctrl/Cmd + K) — Enter = pehla match kholo
//   • Groups: OVERVIEW · INVENTORY · PURCHASING · FINANCE · ADMIN
//   • Footer: sync status (unsynced count) + user card + logout
//   • Reports: main sidebar chhupa, full-width shell (pehle jaisa)
//   • Dashboard "Needs attention" → dashboardNavRequestProvider se screen
//   • Cash request card har screen ke top-right (pehle jaisa)
// =============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/widget/app_logo_widget.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/screens/assign_stock_screen.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/screens/login_screen.dart';
import 'package:jan_ghani_final/features/warehouse/category/presentation/screens/all_category_screen.dart';
import 'package:jan_ghani_final/features/warehouse/company/presentation/screens/all_company_screen.dart';
import 'package:jan_ghani_final/features/warehouse/employee/presentation/screens/salary_tracking_screen.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/presentation/screens/inventory_balance_screen.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/presentation/screens/linked_stores_screen.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/screens/purchase_order_screen.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/screens/all_supplier_screen/all_supplier_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_cash_requests/data/model/warehouse_cash_request_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_cash_requests/presentation/provider/warehouse_cash_requests_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_cash_requests/presentation/widget/cash_request_dialog.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/provider/warehouse_dashboard_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/screens/warehouse_dashboard_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_expense/presentation/screens/warehouse_expense_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/presentation/screens/warehouse_finance_screen/warehouse_finance_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/presentation/screens/warehouse_reports_shell.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/screen/warehouse_stock_inventory_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_user/data/model/user_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_user/presentation/screens/user_screen.dart';

import 'nav_tile_widget.dart';
import 'sidebar_sync_status_provider.dart';

const _kBg = Color(0xFFF8F8F8);

const double _kExpandedW  = 248;
const double _kCollapsedW = 72;

// Groups (is order mein dikhte hain)
const _gOverview   = 'OVERVIEW';
const _gInventory  = 'INVENTORY';
const _gPurchasing = 'PURCHASING';
const _gFinance    = 'FINANCE';
const _gAdmin      = 'ADMIN';
const _groupOrder  = [_gOverview, _gInventory, _gPurchasing, _gFinance, _gAdmin];

class NavItem {
  final IconData icon;
  final String   label;
  final Widget   screen;
  final String   group;

  const NavItem({
    required this.icon,
    required this.label,
    required this.screen,
    this.group = _gOverview,
  });
}

class SideBar extends ConsumerStatefulWidget {
  const SideBar({super.key});

  @override
  ConsumerState<SideBar> createState() => _SideBarState();
}

class _SideBarState extends ConsumerState<SideBar> {
  int  _index     = -1;      // -1 = home (pehla non-Reports item)
  bool _collapsed = true;   // default band (rail)
  String _query   = '';

  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _syncTimer;

  // ── Screens (ek hi instance — role lists share karti hain) ─
  static const _dashboard = NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard',
      screen: WarehouseDashboardScreen(), group: _gOverview);
  static const _reports   = NavItem(icon: Icons.bar_chart_rounded, label: 'Reports',
      screen: SizedBox.shrink(), group: _gOverview);
  static const _stock     = NavItem(icon: Icons.inventory_2_outlined, label: 'Stock',
      screen: WarehouseStockInventoryScreen(), group: _gInventory);
  static const _assign    = NavItem(icon: Icons.move_to_inbox_outlined, label: 'Assign Stock',
      screen: AssignStockScreen(), group: _gInventory);
  static const _balance   = NavItem(icon: Icons.rule_folder_outlined, label: 'Inventory Balance',
      screen: InventoryBalanceScreen(), group: _gInventory);
  static const _category  = NavItem(icon: Icons.category_outlined, label: 'Category',
      screen: AllCategoryScreen(), group: _gInventory);
  static const _company   = NavItem(icon: Icons.business_outlined, label: 'Company',
      screen: AllCompanyScreen(), group: _gInventory);
  static const _po        = NavItem(icon: Icons.receipt_long_outlined, label: 'Purchase Order',
      screen: PurchaseOrderScreen(), group: _gPurchasing);
  static const _supplier  = NavItem(icon: Icons.local_shipping_outlined, label: 'Supplier',
      screen: AllSupplierScreen(), group: _gPurchasing);
  static const _finance   = NavItem(icon: Icons.account_balance_wallet_outlined, label: 'Finance',
      screen: WarehouseFinanceScreen(), group: _gFinance);
  static const _expense   = NavItem(icon: Icons.money_off_outlined, label: 'Expense',
      screen: WarehouseExpenseScreen(), group: _gFinance);
  static const _salary    = NavItem(icon: Icons.badge_outlined, label: 'Salary',
      screen: SalaryTrackingScreen(), group: _gFinance);
  static const _user      = NavItem(icon: Icons.person_outline, label: 'User',
      screen: AllUserScreen(), group: _gAdmin);
  late final NavItem _linkStores = NavItem(icon: Icons.store_outlined, label: 'Link Stores',
      screen: LinkedStoresScreen(warehouseId: AppConfig.warehouseId), group: _gAdmin);

  // ── Role-wise menus (group order mein) ────────────────────
  late final List<NavItem> _warehouseManager = [
    _dashboard, _reports,
    _stock, _assign, _balance, _category, _company,
    _po, _supplier,
    _finance, _expense, _salary,
    _linkStores, _user,
  ];

  late final List<NavItem> _allOthers = [
    _reports,
    _stock, _balance, _category, _company,
    _po, _supplier,
    _finance, _expense, _salary,
  ];

  late final List<NavItem> _dataEntry = [
    _stock, _category, _company,
    _supplier,
    _finance, _expense, _salary,
  ];

  List<NavItem> _getItemsByRole(String? role) {
    switch (role) {
      case 'data_entry':        return _dataEntry;
      case 'warehouse_manager': return _warehouseManager;
      default:                  return _allOthers;
    }
  }

  // Login ke baad / Reports se wapsi par — pehla item jo Reports nahi
  int _homeIndex(List<NavItem> items) {
    final i = items.indexWhere((it) => it.label != 'Reports');
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    // Sync status har minute taaza
    _syncTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) ref.invalidate(sidebarSyncStatusProvider);
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _select(int i) {
    setState(() {
      _index = i;
      _query = '';
      _searchCtrl.clear();
    });
    _searchFocus.unfocus();
  }

  void _focusSearch() {
    if (_collapsed) setState(() => _collapsed = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Accountant se aayi pending cash request → warehouse ki KISI bhi screen ke
  // top-right corner par non-blocking card (user peeche navigate kar sakta hai).
  // Dedicated Cash Requests screen par suppress (wahan pehle se cards hain).
  Widget _wrapWithCashCard(Widget child) {
    final async = ref.watch(pendingCashRequestsProvider);
    final onCashScreen = ref.watch(cashRequestsScreenActiveProvider);
    final list = async.valueOrNull ?? const <WarehouseCashRequestModel>[];
    final req = (list.isEmpty || onCashScreen) ? null : list.first;

    return Stack(
      children: [
        child,
        if (req != null)
          Positioned(
            top: 16,
            right: 16,
            child: SizedBox(
              width: 380,
              child: CashRequestCard(
                key: ValueKey(req.id),
                request: req,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user  = ref.watch(authProvider).user;
    final items = _getItemsByRole(user?.role);

    // Dashboard ke "Needs attention" tiles / links → us label wali screen
    ref.listen<String?>(dashboardNavRequestProvider, (_, label) {
      if (label == null) return;
      final i = items.indexWhere((it) => it.label == label);
      if (i >= 0) _select(i);
      ref.read(dashboardNavRequestProvider.notifier).state = null;
    });

    // Sync status (Reports par bhi watch — provider zinda rahe)
    final sync = ref.watch(sidebarSyncStatusProvider).valueOrNull;

    final current     = (_index < 0 || _index >= items.length)
        ? _homeIndex(items) : _index;
    final currentItem = items[current];

    // Reports screen: no main sidebar — full width shell
    if (currentItem.label == 'Reports') {
      return _wrapWithCashCard(Scaffold(
        backgroundColor: _kBg,
        body: WarehouseReportsShell(
          onBack: () => setState(() => _index = -1),
        ),
      ));
    }

    final target = _collapsed ? _kCollapsedW : _kExpandedW;

    // Normal layout: sidebar + content
    return _wrapWithCashCard(Scaffold(
      backgroundColor: _kBg,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): _focusSearch,
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true):    _focusSearch,
        },
        child: Focus(
          autofocus: true,
          child: Row(
            children: [
              // Animated width — OverflowBox + SizedBox + Clip.hardEdge
              // (animation ke dauran overflow errors se bachne ka pattern)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: target,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color:  AppColor.surface,
                  border: Border(right: BorderSide(color: AppColor.grey200)),
                ),
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth:  target,
                  maxWidth:  target,
                  child: SizedBox(
                    width: target,
                    child: _collapsed
                        ? _buildRail(items, current, sync, user)
                        : _buildPanel(items, current, sync, user),
                  ),
                ),
              ),
              Expanded(child: currentItem.screen),
            ],
          ),
        ),
      ),
    ));
  }

  // ═════════════════════════════════════════════════════════
  // EXPANDED PANEL (248px)
  // ═════════════════════════════════════════════════════════
  Widget _buildPanel(List<NavItem> items, int current,
      SidebarSyncStatus? sync, UserModel? user) {
    final q = _query.trim().toLowerCase();

    final children = <Widget>[];
    for (final g in _groupOrder) {
      final inGroup = <int>[
        for (var i = 0; i < items.length; i++)
          if (items[i].group == g &&
              (q.isEmpty || items[i].label.toLowerCase().contains(q))) i,
      ];
      if (inGroup.isEmpty) continue;
      children.add(Padding(
        padding: EdgeInsets.fromLTRB(12, children.isEmpty ? 4 : 16, 12, 6),
        child: Text(g,
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColor.textSecondary, letterSpacing: 0.8,
            )),
      ));
      for (final i in inGroup) {
        children.add(NavTile(
          item:     items[i],
          selected: i == current,
          onTap:    () => _select(i),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──────────────────────────────────────────
        Container(
          height: 64,
          padding: const EdgeInsets.only(left: 16, right: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColor.grey200)),
          ),
          child: Row(
            children: [
              const AppLogo(size: 40, radius: 10),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jan Ghani',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        )),
                    Text(
                      AppConfig.warehouseCode.isEmpty
                          ? 'Warehouse'
                          : 'Warehouse · ${AppConfig.warehouseCode}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColor.textSecondary),
                    ),
                  ],
                ),
              ),
              _IconBtn(
                icon:    Icons.chevron_left_rounded,
                tooltip: 'Collapse',
                onTap:   () => setState(() => _collapsed = true),
              ),
            ],
          ),
        ),

        // ── Search ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              focusNode:  _searchFocus,
              onChanged:  (v) => setState(() => _query = v),
              onSubmitted: (_) {
                // Enter → pehla match kholo
                final qq = _query.trim().toLowerCase();
                if (qq.isEmpty) return;
                final i = items.indexWhere(
                    (it) => it.label.toLowerCase().contains(qq));
                if (i >= 0) _select(i);
              },
              style: const TextStyle(fontSize: 13, color: AppColor.textPrimary),
              decoration: InputDecoration(
                hintText:  'Search menu…',
                hintStyle: const TextStyle(fontSize: 13, color: AppColor.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColor.textSecondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () => setState(() {
                          _query = '';
                          _searchCtrl.clear();
                        }),
                      )
                    : const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: _KeyHint(text: 'Ctrl K'),
                      ),
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                filled:         true,
                fillColor:      AppColor.grey100,
                isDense:        true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:   BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColor.primary, width: 1.2),
                ),
              ),
            ),
          ),
        ),

        // ── Menu ────────────────────────────────────────────
        Expanded(
          child: children.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Koi menu nahi mila',
                      style: TextStyle(fontSize: 13, color: AppColor.textSecondary)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: children,
                ),
        ),

        // ── Footer: sync + user ─────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColor.grey200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SyncStatus(
                sync:      sync,
                onRefresh: () => ref.invalidate(sidebarSyncStatusProvider),
              ),
              const SizedBox(height: 10),
              _UserCard(user: user, onLogout: _logout),
            ],
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  // COLLAPSED RAIL (72px)
  // ═════════════════════════════════════════════════════════
  Widget _buildRail(List<NavItem> items, int current,
      SidebarSyncStatus? sync, UserModel? user) {
    final children = <Widget>[];
    for (final g in _groupOrder) {
      final inGroup = [
        for (var i = 0; i < items.length; i++) if (items[i].group == g) i,
      ];
      if (inGroup.isEmpty) continue;
      if (children.isNotEmpty) {
        children.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Divider(height: 1, color: AppColor.grey200),
        ));
      }
      for (final i in inGroup) {
        children.add(NavTile(
          item:      items[i],
          selected:  i == current,
          collapsed: true,
          onTap:     () => _select(i),
        ));
      }
    }

    final unsynced = sync?.unsynced ?? 0;

    return Column(
      children: [
        Container(
          height: 64,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColor.grey200)),
          ),
          alignment: Alignment.center,
          child: const AppLogo(size: 40, radius: 10),
        ),
        const SizedBox(height: 8),
        _IconBtn(
          icon:    Icons.chevron_right_rounded,
          tooltip: 'Expand (Ctrl K = search)',
          onTap:   () => setState(() => _collapsed = false),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: children,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColor.grey200)),
          ),
          child: Column(
            children: [
              Tooltip(
                message: sync == null
                    ? 'Sync status maloom nahi'
                    : unsynced == 0 ? 'Synced' : '$unsynced unsynced',
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sync == null
                        ? AppColor.grey400
                        : unsynced == 0 ? AppColor.success : AppColor.error,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PopupMenuButton<String>(
                tooltip: user?.fullName ?? '',
                offset: const Offset(60, -40),
                onSelected: (v) { if (v == 'logout') _logout(); },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(children: [
                      Icon(Icons.logout_rounded, size: 18, color: AppColor.error),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ]),
                  ),
                ],
                child: _Avatar(name: user?.fullName ?? ''),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SMALL PARTS
// ─────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColor.grey200),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColor.textSecondary),
        ),
      ),
    );
  }
}

class _KeyHint extends StatelessWidget {
  final String text;
  const _KeyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(5),
        border:       Border.all(color: AppColor.grey300),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: AppColor.textSecondary)),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape:  BoxShape.circle,
        color:  AppColor.primary.withOpacity(0.10),
        border: Border.all(color: AppColor.primary.withOpacity(0.25)),
      ),
      alignment: Alignment.center,
      child: Text(_initials,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppColor.primary)),
    );
  }
}

class _SyncStatus extends StatelessWidget {
  final SidebarSyncStatus? sync;
  final VoidCallback onRefresh;
  const _SyncStatus({required this.sync, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final b       = sync;
    final unknown = b == null;
    final ok      = !unknown && b.unsynced == 0;

    final color = unknown ? AppColor.textSecondary
                : ok      ? AppColor.success : AppColor.error;
    final bg    = unknown ? AppColor.grey100
                : ok      ? AppColor.successLight : AppColor.errorLight;

    String ago() {
      final m = DateTime.now().difference(b!.checkedAt).inMinutes;
      return m < 1 ? 'abhi' : '${m}m ago';
    }

    final text = unknown
        ? 'Sync status maloom nahi'
        : ok ? 'Synced · ${ago()}' : '${b.unsynced} unsynced · ${ago()}';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ),
          Tooltip(
            message: 'Dobara check karo',
            child: InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.refresh_rounded, size: 16, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel?   user;
  final VoidCallback onLogout;
  const _UserCard({required this.user, required this.onLogout});

  static String _roleLabel(String? r) {
    switch (r) {
      case 'warehouse_manager': return 'Manager';
      case 'warehouse_owner':   return 'Owner';
      case 'warehouse_staff':   return 'Staff';
      case 'data_entry':        return 'Data Entry';
      default:                  return r ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? '';
    final role = _roleLabel(user?.role);
    final code = AppConfig.warehouseCode;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Row(
        children: [
          _Avatar(name: name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'User' : name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary)),
                Text(code.isEmpty ? role : '$role · $code',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColor.textSecondary)),
              ],
            ),
          ),
          Tooltip(
            message: 'Logout',
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.logout_rounded,
                    size: 18, color: AppColor.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
