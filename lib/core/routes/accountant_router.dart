// Accountant web app ka router (sirf web — main.dart mein kIsWeb par use hota hai).
// Paths: lib/core/routes/accountant_paths.dart
//
// Login / role ke hisaab se redirect yahin hota hai — screens khud
// login/dashboard par Navigator.push nahi karti.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accountant/accountant_all_orders/presentation/screen/accountant_all_orders_screen.dart';
import '../../features/accountant/accountant_all_warehouses/presentation/screen/accountant_all_warehouses_screen.dart';
import '../../features/accountant/accountant_cash_transfer/presentation/screen/cash_transfers_screen.dart';
import '../../features/accountant/accountant_inventory_review/presentation/screen/accountant_inventory_review_screen.dart';
import '../../features/accountant/accountant_stock_transfer_record/presentation/screen/accountant_stock_transfer_record_screen.dart';
import '../../features/accountant/accountant_warehouse_dashboard/presentation/screen/accountant_warehouse_dashboard_screen.dart';
import '../../features/accountant/accountant_warehouse_finance/presentation/screen/accountant_warehouse_finance_screen.dart';
import '../../features/accountant/accountant_warehouse_inventory/presentation/screen/accountant_warehouse_inventory_screen.dart';
import '../../features/accountant/authentication/domain/entities/accountant_user_entity.dart';
import '../../features/accountant/authentication/presentation/providers/accoutant_session_provider.dart';
import '../../features/accountant/authentication/presentation/screen/login_screen.dart';
import '../../features/accountant/branch_reports/accountant_branch/presentation/screen/accountant_branch_screen.dart';
import '../../features/accountant/branch_reports/branch_report_list_screen.dart';
import '../../features/accountant/dashboard/presentation/screen/dashboard_screen.dart';
import '../../features/accountant/investment/presentation/screen/investment_screen.dart';
import '../../features/accountant/supplier/presentation/screen/all_supplier_screen.dart';
import '../../features/accountant/supplier/presentation/screen/supplier_detail_screen.dart';
import '../../features/branch/inventory_management/presentation/screen/inventory_counting_screen.dart';
import '../../features/website/presentation/screen/website_screen.dart';
import '../../features/warehouse/employee/presentation/screens/salary_tracking_screen.dart';
import '../../features/warehouse/warehouse_reports/inventory/presentation/providers/inventory_report_provider.dart'
    show reportsWarehouseIdProvider;
import '../../features/warehouse/warehouse_reports/presentation/screens/warehouse_reports_shell.dart';
import '../color/app_color.dart';
import 'accountant_paths.dart';

final _rootKey  = GlobalKey<NavigatorState>(debugLabel: 'accRoot');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'accShell');

// ── Role → kaun se sidebar tabs ─────────────────────────────────────────────
const Map<String, List<String>> _tabRoles = {
  AccPaths.dashboard:       ['owner', 'accountant'],
  AccPaths.branches:        ['owner', 'accountant', 'manager'],
  AccPaths.warehouses:      ['owner', 'accountant', 'warehouse_manager'],
  AccPaths.cashTransfers:   ['owner', 'accountant', 'warehouse_manager'],
  AccPaths.inventoryReview: ['owner'],
  AccPaths.investment:      ['owner', 'accountant'],
};

bool _hasToken(AccountantUserEntity u) =>
    (u.customerToken ?? '').isNotEmpty;

/// Login ke baad user ka pehla screen (website ka "My Account" bhi yahi).
String accountantHomeFor(AccountantUserEntity u) {
  if (_hasToken(u)) return AccPaths.customer(u.customerToken!);
  if (u.role == 'inventory_counter') return AccPaths.inventoryCount;
  for (final e in _tabRoles.entries) {
    if (e.value.contains(u.role)) return e.key;
  }
  // Koi tab nahi — dashboard shell "koi screen available nahi" dikhata hai.
  return AccPaths.dashboard;
}

bool _isAllowed(AccountantUserEntity u, String path) {
  if (_hasToken(u)) return path == AccPaths.customer(u.customerToken!);
  if (u.role == 'inventory_counter') return path == AccPaths.inventoryCount;
  final tab = '/${Uri.parse(path).pathSegments.firstOrNull ?? ''}';
  return _tabRoles[tab]?.contains(u.role) ?? false;
}

String? _redirect(Ref ref, GoRouterState state) {
  final session = ref.read(sessionProvider);
  final path    = state.uri.path;

  // Session SharedPrefs se restore ho raha hai — splash par ruko, URL yaad rakho.
  if (session.isRestoring) {
    if (path == AccPaths.splash) return null;
    return Uri(path: AccPaths.splash,
        queryParameters: {'from': state.uri.toString()}).toString();
  }

  final current = state.uri.toString();
  var desired = current;
  if (path == AccPaths.splash || path == AccPaths.login) {
    desired = state.uri.queryParameters['from'] ?? '/';
  }
  final desiredPath = Uri.parse(desired).path;
  final user = session.user;

  // Website sirf logged-out ke liye — login user ko seedha apna account.
  if (user == null && desiredPath == AccPaths.home) {
    return desired == current ? null : desired;
  }

  if (user == null) {
    if (path == AccPaths.login) return null;
    // Login ke baad wapas usi screen par aane ke liye `from` rakho.
    final keepFrom = desiredPath != AccPaths.login &&
        desiredPath != AccPaths.splash;
    return Uri(path: AccPaths.login,
        queryParameters: keepFrom ? {'from': desired} : null).toString();
  }

  final home = accountantHomeFor(user);
  if (desiredPath == AccPaths.home ||
      desiredPath == AccPaths.login ||
      desiredPath == AccPaths.splash ||
      (desiredPath != home && !_isAllowed(user, desiredPath))) {
    desired = home;
  }
  return desired == current ? null : desired;
}

/// Session (login/logout/restore) badle to router redirect dobara chalaye.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen<SessionState>(sessionProvider, (prev, next) {
      if (prev?.isRestoring != next.isRestoring || prev?.user != next.user) {
        notifyListeners();
      }
    });
  }
}

Page<void> _noAnim(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

String _p(GoRouterState s, String key) =>
    Uri.decodeComponent(s.pathParameters[key]!);

String? _q(GoRouterState s, String key) => s.uri.queryParameters[key];

final accountantRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AccPaths.splash,
    refreshListenable: refresh,
    redirect: (_, state) => _redirect(ref, state),
    errorBuilder: (_, __) => const _NotFoundScreen(),
    routes: [
      GoRoute(
        path: AccPaths.home,
        pageBuilder: (_, s) => _noAnim(s, const WebsiteScreen()),
      ),
      GoRoute(
        path: AccPaths.splash,
        pageBuilder: (_, s) => _noAnim(s, const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        )),
      ),
      GoRoute(
        path: AccPaths.login,
        pageBuilder: (_, s) => _noAnim(s, const AccountantLoginScreen()),
      ),
      GoRoute(
        path: '${AccPaths.customerPrefix}/:customerId',
        pageBuilder: (_, s) => _noAnim(
            s, AccountantCustomerPortal(customerId: _p(s, 'customerId'))),
      ),
      GoRoute(
        path: AccPaths.inventoryCount,
        pageBuilder: (_, s) {
          // storeId session ki branch — screen khud bhi fallback karti hai.
          return _noAnim(s, Consumer(
            builder: (_, ref, __) => InventoryCountingScreen(
                storeId: ref.watch(currentBranchIdProvider)),
          ));
        },
      ),
      GoRoute(
        path: AccPaths.cashTransfers,
        builder: (_, __) => const AccountantCashTransfersScreen(),
      ),

      // ── Sidebar wala shell (Dashboard / Branch / Warehouse / ...) ──
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => AccountantDashboardScreen(child: child),
        routes: [
          GoRoute(
            path: AccPaths.dashboard,
            pageBuilder: (_, s) => _noAnim(s, const AccountantDashboardBody()),
          ),
          GoRoute(
            path: AccPaths.branches,
            pageBuilder: (_, s) => _noAnim(s, const BranchScreen()),
            routes: [
              GoRoute(
                parentNavigatorKey: _rootKey,
                path: ':branchId',
                builder: (_, s) =>
                    BranchReportListScreen(branchId: _p(s, 'branchId')),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootKey,
                    path: ':report',
                    // Desktop par report badalne se page wahi rahe (sidebar
                    // scroll / state na jaye) — is liye key branch ki.
                    pageBuilder: (_, s) => NoTransitionPage<void>(
                      key: ValueKey('branch-report-${s.pathParameters['branchId']}'),
                      child: BranchReportListScreen(
                        branchId: _p(s, 'branchId'),
                        report:   s.pathParameters['report'],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AccPaths.warehouses,
            pageBuilder: (_, s) =>
                _noAnim(s, const AccountantAllWarehousesScreen()),
            routes: [
              GoRoute(
                parentNavigatorKey: _rootKey,
                path: ':warehouseId',
                builder: (_, s) => AccountantWarehouseDashboardScreen(
                  warehouseId:   _p(s, 'warehouseId'),
                  warehouseName: _q(s, 'name') ?? 'Warehouse',
                ),
                routes: _warehouseSubRoutes,
              ),
            ],
          ),
          GoRoute(
            path: AccPaths.inventoryReview,
            pageBuilder: (_, s) =>
                _noAnim(s, const AccountantInventoryReviewScreen()),
          ),
          GoRoute(
            path: AccPaths.investment,
            pageBuilder: (_, s) =>
                _noAnim(s, const AccountantInvestmentScreen()),
          ),
        ],
      ),
    ],
  );
});

final List<RouteBase> _warehouseSubRoutes = [
  GoRoute(
    parentNavigatorKey: _rootKey,
    path: 'finance',
    builder: (_, s) => AccountantWarehouseFinanceScreen(
      warehouseId:   _p(s, 'warehouseId'),
      warehouseName: _q(s, 'name') ?? 'Warehouse',
    ),
  ),
  GoRoute(
    parentNavigatorKey: _rootKey,
    path: 'suppliers',
    builder: (_, s) =>
        AccountantAllSupplierScreen(warehouseId: _p(s, 'warehouseId')),
    routes: [
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: ':supplierId',
        builder: (_, s) => AccountantSupplierDetailScreen(
          supplierId:         _p(s, 'supplierId'),
          supplierName:       _q(s, 'supplier') ?? 'Supplier',
          companyName:        _q(s, 'company'),
          phone:              _q(s, 'phone') ?? '',
          outstandingBalance: double.tryParse(_q(s, 'balance') ?? '') ?? 0,
        ),
      ),
    ],
  ),
  GoRoute(
    parentNavigatorKey: _rootKey,
    path: 'inventory',
    builder: (_, s) =>
        AccountantWarehouseInventoryScreen(warehouseId: _p(s, 'warehouseId')),
  ),
  GoRoute(
    parentNavigatorKey: _rootKey,
    path: 'orders',
    builder: (_, s) =>
        AccountantAllOrdersScreen(warehouseId: _p(s, 'warehouseId')),
  ),
  GoRoute(
    parentNavigatorKey: _rootKey,
    path: 'stock-transfers',
    builder: (_, s) =>
        AccountantStockTransferRecordScreen(warehouseId: _p(s, 'warehouseId')),
  ),
  GoRoute(
    parentNavigatorKey: _rootKey,
    path: 'cash-transfers',
    builder: (_, s) =>
        AccountantCashTransfersScreen(warehouseId: _p(s, 'warehouseId')),
  ),
  GoRoute(
    parentNavigatorKey: _rootKey,
    path: 'reports',
    builder: (_, s) => _WarehouseReportsPage(warehouseId: _p(s, 'warehouseId')),
  ),
  GoRoute(
    parentNavigatorKey: _rootKey,
    path: 'salary',
    // ColoredBox — status bar wali patti bhi safed (SafeArea gap)
    builder: (_, s) => ColoredBox(
      color: AppColor.surface,
      child: SafeArea(
        child: SalaryTrackingScreen(
          remoteWarehouseId: _p(s, 'warehouseId'),
          warehouseName:     _q(s, 'name'),
        ),
      ),
    ),
  ),
];

// ── Warehouse reports: SELECTED warehouse ka data (config-id nahi) ──────────
// Provider set hone ke baad hi shell dikhao, taake refresh par bhi sahi
// warehouse ka data aaye.
class _WarehouseReportsPage extends ConsumerStatefulWidget {
  final String warehouseId;
  const _WarehouseReportsPage({required this.warehouseId});

  @override
  ConsumerState<_WarehouseReportsPage> createState() =>
      _WarehouseReportsPageState();
}

class _WarehouseReportsPageState extends ConsumerState<_WarehouseReportsPage> {
  @override
  void initState() {
    super.initState();
    if (ref.read(reportsWarehouseIdProvider) != widget.warehouseId) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(reportsWarehouseIdProvider.notifier).state = widget.warehouseId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(reportsWarehouseIdProvider) == widget.warehouseId;
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: !ready
            ? const Center(child: CircularProgressIndicator())
            : WarehouseReportsShell(
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go(AccPaths.warehouse(widget.warehouseId,
                        name: GoRouterState.of(context).uri.queryParameters['name'])),
                backLabel: 'Back',
                backIcon: Icons.arrow_back_rounded,
              ),
      ),
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Page nahi mila',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go(AccPaths.home),
              child: const Text('Home'),
            ),
          ],
        ),
      ),
    );
  }
}
