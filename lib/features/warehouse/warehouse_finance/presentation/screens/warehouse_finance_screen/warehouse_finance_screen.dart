// =============================================================
// warehouse_finance_screen.dart
// Warehouse Finance — redesigned to match app UI style
// =============================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/domain/warehouse_finance_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/presentation/provider/warehouse_finance_provider/warehouse_finance_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/presentation/widgets/cash_in_dialog.dart';

final _rupeeFormat = NumberFormat('#,##0', 'en_PK');
String _fmt(double v) => 'Rs. ${_rupeeFormat.format(v)}';

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────
class WarehouseFinanceScreen extends ConsumerWidget {
  const WarehouseFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(warehouseFinanceProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        children: [
          _Header(
            isLoading: state.isLoading,
            onRefresh: () =>
                ref.read(warehouseFinanceProvider.notifier).loadData(),
          ),
          Expanded(
            child: state.isLoading && state.finance == null
                ? const Center(
                child: CircularProgressIndicator(
                    color: AppColor.primary))
                : state.errorMessage != null && state.finance == null
                ? _ErrorView(
              message: state.errorMessage!,
              onRetry: () => ref
                  .read(warehouseFinanceProvider.notifier)
                  .loadData(),
            )
                : _Body(state: state, ref: ref),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────
class _Header extends ConsumerWidget {
  final bool         isLoading;
  final VoidCallback onRefresh;
  const _Header({required this.isLoading, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColor.surface,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warehouse Finance',
                  style: TextStyle(
                    fontSize:   22,
                    fontWeight: FontWeight.w700,
                    color:      AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cash flow aur transactions manage karo',
                  style: TextStyle(
                      fontSize: 13, color: AppColor.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: isLoading
                ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColor.primary))
                : const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showCashInDialog(context, ref),
            style: TextButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 18, color: AppColor.white),
                SizedBox(width: 6),
                Text('Cash In',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColor.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCashInDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => CashInDialog(
        onConfirm: ({
          required double amount,
          String? notes,
          String? userId,
          String? userName,
        }) {
          ref.read(warehouseFinanceProvider.notifier).addCashIn(
            amount:   amount,
            notes:    notes,
            userId:   userId,
            userName: userName,
          );
        },
      )
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final WarehouseFinanceState state;
  final WidgetRef             ref;
  const _Body({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColor.primary,
      onRefresh: () =>
          ref.read(warehouseFinanceProvider.notifier).loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            _TopStatsRow(state: state),
            const SizedBox(height: 16),


            // Transactions heading
            Row(
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.w700,
                    color:      AppColor.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${state.filteredTransactions.length} entries',
                  style: const TextStyle(
                      fontSize: 13, color: AppColor.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter tabs
            _FilterTabs(
              activeFilter:    state.activeFilter,
              onFilterChanged: (f) => ref
                  .read(warehouseFinanceProvider.notifier)
                  .onFilterChanged(f),
            ),
            const SizedBox(height: 12),

            // Table
            _TransactionsTable(
                transactions: state.filteredTransactions),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP STATS ROW
// ─────────────────────────────────────────────────────────────
class _TopStatsRow extends StatelessWidget {
  final WarehouseFinanceState state;
  const _TopStatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final cashInHand = state.finance?.cashInHand ?? 0;
    final todayIn    = state.summary?.todayCashIn ?? 0;
    final todayOut   = state.summary?.todayCashOut ?? 0;
    final suppliersOutstanding   = state.summary?.totalSupplierDue ?? 0;

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _StatCard(
            icon:       Icons.account_balance_wallet_rounded,
            iconColor:  AppColor.primary,
            label:      'Cash In Hand',
            value:      _fmt(cashInHand),
            valueColor: AppColor.primary,
            isLarge:    true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon:       Icons.arrow_downward_rounded,
            iconColor:  AppColor.success,
            label:      'Aaj Cash In',
            value:      _fmt(todayIn),
            valueColor: AppColor.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon:       Icons.arrow_upward_rounded,
            iconColor:  AppColor.error,
            label:      'Aaj Cash Out',
            value:      _fmt(todayOut),
            valueColor: AppColor.error,
          ),
        ),

        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon:       CupertinoIcons.creditcard,
            iconColor:  AppColor.error,
            label:      'Suppliers Outstanding',
            value:      suppliersOutstanding.toString(),
            valueColor: AppColor.error,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   value;
  final Color    valueColor;
  final bool     isLarge;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColor.grey200),
        boxShadow: [
          BoxShadow(
            color:      AppColor.shadow,
            blurRadius: 4,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width:  isLarge ? 48 : 40,
            height: isLarge ? 48 : 40,
            decoration: BoxDecoration(
              color:        iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: iconColor, size: isLarge ? 24 : 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color:    AppColor.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize:   isLarge ? 22 : 16,
                    fontWeight: FontWeight.w700,
                    color:      valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER TABS
// ─────────────────────────────────────────────────────────────
class _FilterTabs extends StatelessWidget {
  final String                activeFilter;
  final void Function(String) onFilterChanged;

  const _FilterTabs({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  static const _tabs = [
    {'key': 'all',              'label': 'All'},
    {'key': 'cash_in',         'label': 'Cash In'},
    // {'key': 'purchase',        'label': 'Purchase'},
    {'key': 'supplier_payment','label': 'Supplier Pay'},
    {'key': 'expense',         'label': 'Expense'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.map((tab) {
          final isActive = activeFilter == tab['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onFilterChanged(tab['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColor.primary
                      : AppColor.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive
                        ? AppColor.primary
                        : AppColor.grey300,
                  ),
                ),
                child: Text(
                  tab['label']!,
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? AppColor.white
                        : AppColor.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TRANSACTIONS TABLE
// ─────────────────────────────────────────────────────────────
class _TransactionsTable extends StatelessWidget {
  final List<CashTransactionModel> transactions;
  const _TransactionsTable({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColor.grey200),
        boxShadow: [
          BoxShadow(
              color:      AppColor.shadow,
              blurRadius: 4,
              offset:     const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColor.grey100,
              borderRadius: BorderRadius.only(
                topLeft:  Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: _HCell('Date / Type')),
                Expanded(flex: 3, child: _HCell('Notes')),
                Expanded(flex: 2, child: _HCell('Amount')),
                Expanded(flex: 2, child: _HCell('Balance After')),
                Expanded(flex: 2, child: _HCell('Balance Before')),
                Expanded(flex: 2, child: _HCell('Entry By')),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColor.divider),

          // Rows
          transactions.isEmpty
              ? _EmptyState()
              : ListView.separated(
            shrinkWrap: true,
            physics:    const NeverScrollableScrollPhysics(),
            itemCount:  transactions.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColor.divider),
            itemBuilder: (_, i) => _TRow(tx: transactions[i]),
          ),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  final String text;
  const _HCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize:   12,
        fontWeight: FontWeight.w600,
        color:      AppColor.textSecondary,
      ),
    );
  }
}

class _TRow extends StatelessWidget {
  final CashTransactionModel tx;
  const _TRow({required this.tx});

  static Color _color(String t) {
    switch (t) {
      case 'cash_in':          return AppColor.success;
      case 'purchase':         return AppColor.primary;
      case 'supplier_payment': return AppColor.warning;
      case 'expense':          return AppColor.error;
      default:                 return AppColor.info;
    }
  }

  static IconData _icon(String t) {
    switch (t) {
      case 'cash_in':          return Icons.arrow_downward_rounded;
      case 'purchase':         return Icons.shopping_cart_outlined;
      case 'supplier_payment': return Icons.people_outline_rounded;
      case 'expense':          return Icons.receipt_outlined;
      default:                 return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color    = _color(tx.entryType);
    final isCashIn = tx.isCashIn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [

          // ── Date / Type ──────────────────────────────
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:        color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(_icon(tx.entryType),
                          color: color, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tx.entryTypeDisplay,
                        style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a')
                      .format(tx.createdAt.toLocal()),
                  style: const TextStyle(
                      fontSize: 11, color: AppColor.textSecondary),
                ),
              ],
            ),
          ),

          // ── Notes ────────────────────────────────────
          Expanded(
            flex: 3,
            child: Text(
              tx.notes ?? '—',
              style: const TextStyle(
                  fontSize: 13, color: AppColor.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Amount badge ──────────────────────────────
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isCashIn
                      ? AppColor.successLight
                      : AppColor.errorLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isCashIn ? '+' : '-'} ${_fmt(tx.amount)}',
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color: isCashIn ? AppColor.success : AppColor.error,
                  ),
                ),
              ),
            ),
          ),

          // ── Balance After ─────────────────────────────
          Expanded(
            flex: 2,
            child: Text(
              "${_fmt(tx.cashInHandAfter)}",
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                // Minus ho toh red dikhao
                color: tx.cashInHandAfter < 0
                    ? AppColor.error
                    : AppColor.textPrimary,
              ),
            ),
          ),

          // ── Balance After ─────────────────────────────
          Expanded(
            flex: 2,
            child: Text(
              "${_fmt(tx.cashInHandBefore)}",
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                // Minus ho toh red dikhao
                color: tx.cashInHandAfter < 0
                    ? AppColor.error
                    : AppColor.textPrimary,
              ),
            ),
          ),

          // ── Entry By ──────────────────────────────────
          Expanded(
            flex: 2,
            child: Text(
              tx.createdByName ?? '—',
              style: const TextStyle(
                  fontSize: 13, color: AppColor.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),

        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 40, color: AppColor.grey400),
            SizedBox(height: 12),
            Text('Koi transaction nahi mili',
                style: TextStyle(
                    color: AppColor.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ERROR VIEW
// ─────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorView(
      {required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColor.error, size: 48),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: AppColor.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                elevation: 0),
            onPressed: onRetry,
            child: const Text('Dobara Try Karo',
                style: TextStyle(color: AppColor.white)),
          ),
        ],
      ),
    );
  }
}