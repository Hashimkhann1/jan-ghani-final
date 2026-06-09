import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/service/session/accountant_session.dart';
import 'package:jan_ghani_final/features/accountant/investment/presentation/screen/investment_screen.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/screen/login_screen.dart';
import 'package:jan_ghani_final/features/accountant/accountant_all_warehouses/presentation/screen/accountant_all_warehouses_screen.dart';
import '../../../branch_reports/accountant_branch/presentation/screen/accountant_branch_screen.dart';
import '../../data/model/dashboard_model.dart';
import '../provider/dashboard_provider.dart';

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

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.store_rounded, label: 'Branch'),
    _NavItem(icon: Icons.warehouse_rounded, label: 'Warehouse'),
    _NavItem(icon: Icons.trending_up_rounded, label: 'Investment'),
  ];

  Widget _buildScreen(int index) {
    return switch (index) {
      0 => const _DashboardBody(),
      1 => BranchScreen(),
      2 => const AccountantAllWarehousesScreen(),
      3 => const AccountantInvestmentScreen(),
      _ => const _DashboardBody(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final desktop = _isDesktop(context);

    if (desktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: Row(
          children: [
            _Sidebar(
              selectedIndex: _selectedIndex,
              navItems: _navItems,
              onItemTap: (i) => setState(() => _selectedIndex = i),
            ),
            Expanded(child: _buildScreen(_selectedIndex)),
          ],
        ),
      );
    }

    return Scaffold(
      body: _buildScreen(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          selectedItemColor: AppColor.primary,
          unselectedItemColor: AppColor.textMuted,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: _navItems
              .map((e) => BottomNavigationBarItem(
            icon: Icon(e.icon),
            label: e.label,
          ))
              .toList(),
        ),
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> navItems; // ✅ fixed
  final ValueChanged<int> onItemTap;

  const _Sidebar({
    required this.selectedIndex,
    required this.navItems,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          // ── Brand ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jan Ghani',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textDark,
                      ),
                    ),
                    Text(
                      'POS System',
                      style: TextStyle(fontSize: 11, color: AppColor.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Nav items ──────────────────────────────────────────
          Expanded(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                children: navItems.asMap().entries.map((entry) { // ✅ navItems
                  final item = entry.value;
                  return _SidebarItem(
                    icon: item.icon,
                    label: item.label,
                    active: selectedIndex == entry.key,
                    onTap: () => onItemTap(entry.key),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Logout ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: _SidebarItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              active: false,
              onTap: () async {
                await AccountantSession.clear();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AccountantLoginScreen()),
                        (_) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar Item ──────────────────────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColor.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: active ? AppColor.primary : AppColor.textMuted),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                color: active ? AppColor.primary : AppColor.textMuted,
              ),
            ),
          ],
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
    final sessionAsync = ref.watch(accountantSessionDataProvider);
    final amountAsync = ref.watch(janghaniAmountProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);
    final desktop = MediaQuery.of(context).size.width >= 800;

    return Column(
      children: [
        // ── Top bar ────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: desktop ? 28 : 20,
            vertical: 14,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good Morning,',
                      style:
                      TextStyle(fontSize: 13, color: AppColor.textMuted)),
                  sessionAsync.when(
                    data: (s) => Text(
                      s?['name'] ?? 'Accountant',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textDark,
                      ),
                    ),
                    loading: () => const SizedBox(
                        width: 120, height: 24, child: _ShimmerBox()),
                    error: (_, __) => const Text('Accountant'),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  await AccountantSession.clear();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AccountantLoginScreen()),
                          (_) => false,
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColor.primary.withOpacity(0.15),
                  child: const Icon(Icons.person_rounded,
                      color: AppColor.primary, size: 22),
                ),
              ),
            ],
          ),
        ),

        // ── Scrollable content ─────────────────────────────────────
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
              )
                  : _MobileContent(
                amountAsync: amountAsync,
                recentAsync: recentAsync,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Desktop Content ───────────────────────────────────────────────────────────
class _DesktopContent extends StatelessWidget {
  final AsyncValue<JanghaniAmountModel?> amountAsync;
  final AsyncValue<List<RecentTransactionModel>> recentAsync;

  const _DesktopContent({
    required this.amountAsync,
    required this.recentAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        amountAsync.when(
          data: (a) => _CashCard(amount: a),
          loading: () => const _ShimmerCard(height: 120),
          error: (_, __) => const _ErrorCard(),
        ),
        const SizedBox(height: 20),
        Row(
          children: const [
            Expanded(
                child: _StatCard(
                    label: 'Total Sale',
                    icon: Icons.receipt_rounded,
                    iconColor: AppColor.primary)),
            SizedBox(width: 14),
            Expanded(
                child: _StatCard(
                    label: 'Cash Received',
                    icon: Icons.payments_rounded,
                    iconColor: Color(0xFF1D9E75))),
            SizedBox(width: 14),
            Expanded(
                child: _StatCard(
                    label: 'Card Received',
                    icon: Icons.credit_card_rounded,
                    iconColor: Color(0xFF378ADD))),
            SizedBox(width: 14),
            Expanded(
                child: _StatCard(
                    label: 'Sale Returns',
                    icon: Icons.keyboard_return_rounded,
                    iconColor: Color(0xFFE24B4A))),
          ],
        ),
        const SizedBox(height: 24),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _TransactionsPanel(recentAsync: recentAsync)),
              const SizedBox(width: 20),
              const Expanded(child: _BranchStatusPanel()),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Mobile Content ────────────────────────────────────────────────────────────
class _MobileContent extends StatelessWidget {
  final AsyncValue<JanghaniAmountModel?> amountAsync;
  final AsyncValue<List<RecentTransactionModel>> recentAsync;

  const _MobileContent({
    required this.amountAsync,
    required this.recentAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        amountAsync.when(
          data: (a) => _CashCard(amount: a),
          loading: () => const _ShimmerCard(height: 130),
          error: (_, __) => const _ErrorCard(),
        ),
        const SizedBox(height: 24),
        _TransactionsPanel(recentAsync: recentAsync),
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColor.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Rs. 0',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColor.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transactions Panel ────────────────────────────────────────────────────────
class _TransactionsPanel extends StatelessWidget {
  final AsyncValue<List<RecentTransactionModel>> recentAsync;

  const _TransactionsPanel({required this.recentAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transaction History',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textDark)),
          const SizedBox(height: 16),
          recentAsync.when(
            data: (list) => list.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Koi transaction nahi mili',
                    style: TextStyle(color: AppColor.textMuted)),
              ),
            )
                : Column(
              children:
              list.map((tx) => _RecentTile(tx: tx)).toList(),
            ),
            loading: () => Column(
              children: List.generate(
                4,
                    (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: _ShimmerCard(height: 60),
                ),
              ),
            ),
            error: (_, __) => const _ErrorCard(),
          ),
        ],
      ),
    );
  }
}

// ── Branch Status Panel ───────────────────────────────────────────────────────
class _BranchStatusPanel extends StatelessWidget {
  const _BranchStatusPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Branch Status',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textDark)),
          SizedBox(height: 16),
          Text('Branch data yahan aayegi...',
              style: TextStyle(fontSize: 13, color: AppColor.textMuted)),
        ],
      ),
    );
  }
}

// ── Cash Card ─────────────────────────────────────────────────────────────────
class _CashCard extends StatelessWidget {
  final JanghaniAmountModel? amount;
  const _CashCard({required this.amount});

  String _fmt(double? val) {
    if (val == null) return 'Rs. 0';
    return 'Rs. ${val.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cash in Hand',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 13)),
                const SizedBox(height: 6),
                Text(_fmt(amount?.cashInHand),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    )),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white.withOpacity(0.6), size: 13),
                  const SizedBox(width: 5),
                  Text('Janghani Net Amount',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ]),
              ],
            ),
          ),
          Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white.withOpacity(0.15), size: 80),
        ],
      ),
    );
  }
}

// ── Recent Tile ───────────────────────────────────────────────────────────────
class _RecentTile extends StatelessWidget {
  final RecentTransactionModel tx;
  const _RecentTile({required this.tx});

  String _fmt(double val) => 'Rs. ${val.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  )}';

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min pehle';
    if (diff.inHours < 24) return '${diff.inHours} ghante pehle';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isIn = tx.transactionType == 'cash_in';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isIn
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIn
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isIn ? AppColor.cashIn : AppColor.cashOut,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.branchName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColor.textDark)),
                Text(_formatDate(tx.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColor.textMuted)),
              ],
            ),
          ),
          Text(
            '${isIn ? '+' : '-'} ${_fmt(tx.amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isIn ? AppColor.cashIn : AppColor.cashOut,
            ),
          ),
        ],
      ),
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
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

// ── Error Card ────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEBEB),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Data load nahi hua — pull to refresh karein',
            style: TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

// ── Nav Item Model ────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}