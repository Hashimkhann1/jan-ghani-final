import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/features/branch/expense/data/model/expense_model.dart';
import 'package:jan_ghani_final/features/branch/expense/presentation/provider/expense_provider.dart';
import '../../../customer/presentation/widget/customer_action_button_widget.dart';
import '../../../customer/presentation/widget/customer_filter_chip_widget.dart';
import '../widget/add_expense_dialog.dart';

class AllExpenseScreen extends ConsumerWidget {
  const AllExpenseScreen({super.key});

  void _openDialog(BuildContext context, {ExpenseModel? expense}) {
    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (_) => AddExpenseDialog(expense: expense),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: const Text('Expense Delete Karein?',
            style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
            '"${expense.expenseHead}" ko delete karna chahte hain?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error,
                foregroundColor: Colors.white,
                elevation:       0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              ref
                  .read(expenseProvider.notifier)
                  .deleteExpense(expense.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(expenseProvider);
    final expenses = state.filteredExpenses;
    final fmt      = DateFormat('dd MMM yyyy');
    final size = MediaQuery.sizeOf(context);
    ref.listen<ExpenseState>(expenseProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label:     'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(expenseProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(expenseProvider.notifier).loadExpenses(),
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 4),
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                onPressed: () => _openDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  elevation:       0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon:  const Icon(Icons.add, size: 18),
                label: const Text('New Expense',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Stat Cards ───────────────────────────
            Row(
              children: [
                SummaryCard(
                  title: 'Total Expenses',
                  value: '${state.totalCount}',
                  icon:  Icons.receipt_long_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Today',
                  value: 'Rs ${state.todayAmount.toStringAsFixed(0)}',
                  icon:  Icons.today_outlined,
                  color: AppColor.warning,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'This Month',
                  value: 'Rs ${state.monthAmount.toStringAsFixed(0)}',
                  icon:  Icons.calendar_month_outlined,
                  color: AppColor.error,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Search + Period Filters ───────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      onChanged: ref
                          .read(expenseProvider.notifier)
                          .onSearchChanged,
                      style:        const TextStyle(fontSize: 13),
                      cursorHeight: 14,
                      decoration: InputDecoration(
                        hintText: 'Search by head, description...',
                        hintStyle: const TextStyle(
                            color: AppColor.textHint, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: AppColor.grey400),
                        filled:    true,
                        fillColor: AppColor.grey100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:   BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  ...[
                    ('all',   'All Time'),
                    ('today', 'Today'),
                    ('week',  'This Week'),
                    ('month', 'This Month'),
                  ].map((p) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: CustomerFilterChip(
                      label:         p.$2,
                      value:         p.$1,
                      selectedValue: state.filterPeriod,
                      onTap: ref
                          .read(expenseProvider.notifier)
                          .onFilterPeriodChanged,
                    ),
                  )),

                  // Total amount chip
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color:        AppColor.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColor.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size:  14,
                          color: AppColor.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Total: Rs ${state.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Table ────────────────────────────────
            Expanded(
              child: expenses.isEmpty
                  ? _EmptyState(
                  isSearching: state.searchQuery.isNotEmpty)
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        AppColor.grey100),
                    dataRowColor:
                    WidgetStateProperty.resolveWith<Color?>((s) => s.contains(WidgetState.hovered) ? AppColor.primary.withValues(alpha: 0.05) : null),
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 52,
                    columnSpacing: size.width * 0.12,
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Expense Head')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: expenses.map((e) => DataRow(
                      cells: [
                        // Expense Head
                        DataCell(Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColor.primary
                                    .withValues(alpha: 0.08),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.receipt_outlined,
                                size:  14,
                                color: AppColor.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              e.expenseHead,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize:   13),
                            ),
                          ],
                        )),

                        // Amount
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColor.error
                                .withValues(alpha: 0.08),
                            borderRadius:
                            BorderRadius.circular(6),
                          ),
                          child: Text(
                            e.amountLabel,
                            style: const TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w700,
                              color:      AppColor.error,
                            ),
                          ),
                        )),

                        // Description
                        DataCell(SizedBox(
                          width: 220,
                          child: Text(
                            e.description ?? '—',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColor.textSecondary),
                            overflow:  TextOverflow.ellipsis,
                            maxLines:  1,
                          ),
                        )),

                        // Date
                        DataCell(Text(
                          fmt.format(e.createdAt),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.textSecondary),
                        )),

                        // Actions
                        DataCell(Row(
                          children: [
                            CustomerActionButton(
                              icon:    Icons.edit_outlined,
                              color:   AppColor.primary,
                              tooltip: 'Edit',
                              onTap: () =>
                                  _openDialog(context,
                                      expense: e),
                            ),
                            const SizedBox(width: 6),
                            CustomerActionButton(
                              icon:    Icons.delete_outline_rounded,
                              color:   AppColor.error,
                              tooltip: 'Delete',
                              onTap: () =>
                                  _confirmDelete(
                                      context, ref, e),
                            ),
                          ],
                        )),
                      ],
                    )).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isSearching;
  const _EmptyState({this.isSearching = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching
                ? Icons.search_off_rounded
                : Icons.receipt_long_outlined,
            size:  64,
            color: AppColor.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'Koi expense nahi mila'
                : 'Koi expense nahi hai',
            style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      AppColor.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Search query change karein'
                : 'New Expense button se expense add karein',
            style: const TextStyle(
                fontSize: 13, color: AppColor.textHint),
          ),
        ],
      ),
    );
  }
}