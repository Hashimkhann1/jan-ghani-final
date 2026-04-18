// =============================================================
// warehouse_expense_screen.dart
// Location: features/warehouse_expense/presentation/screens/
//           warehouse_expense_screen/
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_expense/domain/warehouse_expense_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_expense/presentation/provider/warehouse_expense_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_expense/presentation/widgets/add_expense_dialog.dart';


final _rupeeFormat = NumberFormat('#,##0', 'en_PK');
String _fmt(double v) => 'Rs ${_rupeeFormat.format(v)}';

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────
class WarehouseExpenseScreen extends ConsumerWidget {
  const WarehouseExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(warehouseExpenseProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            isLoading: state.isLoading,
            onRefresh: () =>
                ref.read(warehouseExpenseProvider.notifier).loadData(),
            onAddExpense: () => AddExpenseDialog.show(
              context,
              onConfirm: ({
                required String expenseHead,
                required double amount,
                String? description,
                String? userId,
                String? userName,
              }) {
                ref.read(warehouseExpenseProvider.notifier).addExpense(
                  expenseHead: expenseHead,
                  amount:      amount,
                  description: description,
                  userId:      userId,
                  userName:    userName,
                );
              },
            ),
          ),
          Expanded(
            child: state.isLoading && state.expenses.isEmpty
                ? const Center(child: CircularProgressIndicator(
                color: AppColor.primary))
                : state.errorMessage != null && state.expenses.isEmpty
                ? _ErrorView(
              message: state.errorMessage!,
              onRetry: () => ref
                  .read(warehouseExpenseProvider.notifier)
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
class _Header extends StatelessWidget {
  final bool         isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onAddExpense;

  const _Header({
    required this.isLoading,
    required this.onRefresh,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.surface,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expenses',
                    style: TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.textPrimary)),
                SizedBox(height: 2),
                Text('Warehouse ke sab kharche track karo',
                    style: TextStyle(
                        fontSize: 13,
                        color:    AppColor.textSecondary)),
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
            onPressed: onAddExpense,
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
                Text('New Expense',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize:   14,
                        color:      AppColor.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final WarehouseExpenseState state;
  final WidgetRef             ref;
  const _Body({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color:     AppColor.primary,
      onRefresh: () =>
          ref.read(warehouseExpenseProvider.notifier).loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 3 Stat Cards ─────────────────────────────────
            _StatsRow(stats: state.stats),
            const SizedBox(height: 20),

            // ── Search + Filter Row ───────────────────────────
            Row(
              children: [
                // Search
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 500,
                        child: _SearchBar(
                          onChanged: (q) => ref
                              .read(warehouseExpenseProvider.notifier)
                              .onSearchChanged(q),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Filter tabs + Total badge
                _FilterTabs(
                  activeFilter:    state.activeFilter,
                  filteredTotal:   state.filteredTotal,
                  onFilterChanged: (f) => ref
                      .read(warehouseExpenseProvider.notifier)
                      .onFilterChanged(f),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Table ─────────────────────────────────────────
            _ExpenseTable(
              expenses: state.expenses,
              onDelete: (id) => ref
                  .read(warehouseExpenseProvider.notifier)
                  .deleteExpense(id),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATS ROW — 3 cards (image jaisa)
// ─────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final ExpenseStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon:       Icons.receipt_long_outlined,
            iconColor:  AppColor.primary,
            iconBg:     AppColor.primary.withOpacity(0.1),
            label:      'Total Expenses',
            value:      stats.totalCount.toString(),
            isCount:    true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon:       Icons.calendar_today_outlined,
            iconColor:  const Color(0xFFF59E0B),
            iconBg:     const Color(0xFFFFF7E0),
            label:      'Today',
            value:      _fmt(stats.todayTotal),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon:       Icons.calendar_month_outlined,
            iconColor:  AppColor.error,
            iconBg:     AppColor.errorLight,
            label:      'This Month',
            value:      _fmt(stats.thisMonthTotal),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;
  final String   label;
  final String   value;
  final bool     isCount;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.isCount = false,
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
              offset:     const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width:  44,
            height: 44,
            decoration: BoxDecoration(
              color:        iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize:   isCount ? 28 : 20,
                    fontWeight: FontWeight.w700,
                    color:      AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color:    AppColor.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        onChanged:  onChanged,
        style: const TextStyle(
            fontSize: 13, color: AppColor.textPrimary),
        decoration: InputDecoration(
          hintText:  'Search by head, description...',
          hintStyle: const TextStyle(
              fontSize: 13, color: AppColor.textHint),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: AppColor.grey500),
          filled:    true,
          fillColor: AppColor.surface,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.grey200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.grey200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppColor.primary, width: 1.5)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER TABS
// ─────────────────────────────────────────────────────────────
class _FilterTabs extends StatelessWidget {
  final String                activeFilter;
  final double                filteredTotal;
  final void Function(String) onFilterChanged;

  const _FilterTabs({
    required this.activeFilter,
    required this.filteredTotal,
    required this.onFilterChanged,
  });

  static const _tabs = [
    {'key': 'all',        'label': 'All Time'},
    {'key': 'today',      'label': 'Today'},
    {'key': 'this_week',  'label': 'This Week'},
    {'key': 'this_month', 'label': 'This Month'},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ..._tabs.map((tab) {
          final isActive = activeFilter == tab['key'];
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: () => onFilterChanged(tab['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height:   42,
                padding:  const EdgeInsets.symmetric(
                    horizontal: 16),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColor.primary
                      : AppColor.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? AppColor.primary
                        : AppColor.grey300,
                  ),
                ),
                alignment: Alignment.center,
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
        }),

      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EXPENSE TABLE
// ─────────────────────────────────────────────────────────────
class _ExpenseTable extends StatelessWidget {
  final List<WarehouseExpenseModel> expenses;
  final void Function(String)       onDelete;

  const _ExpenseTable({
    required this.expenses,
    required this.onDelete,
  });

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
                Expanded(flex: 3, child: _HCell('Expense Head')),
                Expanded(flex: 2, child: _HCell('Amount')),
                Expanded(flex: 3, child: _HCell('Description')),
                Expanded(flex: 2, child: _HCell('Date')),
                SizedBox(width: 80,  child: _HCell('Actions')),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColor.divider),

          // Rows
          expenses.isEmpty
              ? _EmptyState()
              : ListView.separated(
            shrinkWrap: true,
            physics:    const NeverScrollableScrollPhysics(),
            itemCount:  expenses.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColor.divider),
            itemBuilder: (_, i) => _ExpenseRow(
              expense:  expenses[i],
              onDelete: () => _confirmDelete(
                  context, expenses[i], onDelete),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext               context,
      WarehouseExpenseModel      expense,
      void Function(String)      onDelete,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColor.surface,
        title: const Text('Delete Expense?',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          '"${expense.expenseHead}" — ${_fmt(expense.amount)}\n'
              'Yeh expense delete ho jaayegi.',
          style: const TextStyle(
              fontSize: 13, color: AppColor.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(expense.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: AppColor.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
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
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.w600,
          color:      AppColor.textSecondary));
}

class _ExpenseRow extends StatelessWidget {
  final WarehouseExpenseModel expense;
  final VoidCallback          onDelete;

  const _ExpenseRow({
    required this.expense,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Expense Head
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                      Icons.receipt_outlined,
                      size: 14,
                      color: AppColor.primary),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    expense.expenseHead,
                    style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 130,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        AppColor.errorLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _fmt(expense.amount),
                    style: const TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color:      AppColor.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Description
          Expanded(
            flex: 3,
            child: Text(
              expense.description ?? '—',
              style: const TextStyle(
                  fontSize: 13, color: AppColor.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Date
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd MMM yyyy').format(
                  expense.expenseDate.toLocal()),
              style: const TextStyle(
                  fontSize: 13, color: AppColor.textSecondary),
            ),
          ),

          // Actions
          SizedBox(
            width: 80,
            child: Row(
              children: [
                // Edit — future ke liye
                Container(
                  width:  32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:        AppColor.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 15, color: AppColor.primary),
                ),
                const SizedBox(width: 8),
                // Delete
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width:  32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:        AppColor.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 15, color: AppColor.error),
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
            Text('Koi expense nahi mili',
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
  const _ErrorView({required this.message, required this.onRetry});

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
              style: const TextStyle(color: AppColor.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary, elevation: 0),
            onPressed: onRetry,
            child: const Text('Dobara Try Karo',
                style: TextStyle(color: AppColor.white)),
          ),
        ],
      ),
    );
  }
}