import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/service/session/accountant_session.dart';
import 'package:jan_ghani_final/features/accountant/branch_transaction/presentation/screen/branch_transaction_screen.dart';
import 'package:jan_ghani_final/features/accountant/investment/presentation/screen/investment_screen.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/screen/login_screen.dart';
import '../../../warehouse_transaction/presentationpresentation/screen/warehouse_transaction_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(accountantSessionDataProvider);
    final accountantId = sessionAsync.asData?.value?['id'] as String? ?? '';

    final screens = [
      const _DashboardBody(),
      AccountantBranchTransactionScreen(accountantId: accountantId),
      const AccountantWarehouseTransactionScreen(),
      const AccountantInvestmentScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColor.background,
      body: screens[_selectedIndex],
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_rounded),
              label: 'Branch',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warehouse_rounded),
              label: 'Warehouse',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_rounded),
              label: 'Investment',
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
    final counterAsync = ref.watch(accountantCounterProvider);
    final recentAsync  = ref.watch(recentTransactionsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountantCounterProvider);
          ref.invalidate(recentTransactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning,',
                        style: TextStyle(
                            fontSize: 13, color: AppColor.textMuted),
                      ),
                      sessionAsync.when(
                        data: (s) => Text(
                          s?['name'] ?? 'Accountant',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textDark,
                          ),
                        ),
                        loading: () => const SizedBox(
                          width: 130,
                          height: 26,
                          child: _ShimmerBox(),
                        ),
                        error: (_, __) => const Text('Accountant'),
                      ),
                    ],
                  ),

                  // Logout
                  GestureDetector(
                    onTap: () async {
                      await AccountantSession.clear();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountantLoginScreen(),
                          ),
                              (_) => false,
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColor.primary.withOpacity(0.15),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColor.primary,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Counter Card ──────────────────────────────────────────────
              counterAsync.when(
                data: (counter) => _CounterCard(counter: counter),
                loading: () => const _ShimmerCard(height: 160),
                error: (e, _) => const _ErrorCard(),
              ),

              const SizedBox(height: 24),

              // ── Recent Activity ───────────────────────────────────────────
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textDark,
                ),
              ),
              const SizedBox(height: 12),

              recentAsync.when(
                data: (list) => list.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Koi transaction nahi mili',
                      style: TextStyle(color: AppColor.textMuted),
                    ),
                  ),
                )
                    : Column(
                  children: list
                      .map((tx) => _RecentTile(tx: tx))
                      .toList(),
                ),
                loading: () => Column(
                  children: List.generate(
                    5,
                        (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _ShimmerCard(height: 68),
                    ),
                  ),
                ),
                error: (e, _) => const _ErrorCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Counter Card ──────────────────────────────────────────────────────────────
class _CounterCard extends StatelessWidget {
  final AccountantCounterModel? counter;
  const _CounterCard({required this.counter});

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
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Amount',
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            _fmt(counter?.totalAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Investment',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    _fmt(counter?.totalInvestment),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Recent Tile ───────────────────────────────────────────────────────────────
class _RecentTile extends StatelessWidget {
  final RecentTransactionModel tx;
  const _RecentTile({required this.tx});

  String _fmt(double val) {
    return 'Rs. ${val.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    )}';
  }

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min pehle';
    if (diff.inHours < 24)   return '${diff.inHours} ghante pehle';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isIn = tx.transactionType == 'cash_in';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isIn
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIn
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isIn ? AppColor.cashIn : AppColor.cashOut,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.branchName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColor.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(tx.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '${isIn ? '+' : '-'} ${_fmt(tx.amount)}',
            style: TextStyle(
              fontSize: 14,
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