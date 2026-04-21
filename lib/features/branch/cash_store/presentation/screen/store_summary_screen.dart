import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import '../provider/store_summary_provider.dart';

class StoreSummaryScreen extends ConsumerStatefulWidget {
  const StoreSummaryScreen({super.key});

  @override
  ConsumerState<StoreSummaryScreen> createState() =>
      _StoreSummaryScreenState();
}

class _StoreSummaryScreenState extends ConsumerState<StoreSummaryScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeSummaryProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(storeSummaryProvider);
    final records = state.filteredRecords;
    final dateFmt = DateFormat('dd MMM yyyy');
    final size = MediaQuery.sizeOf(context);

    ref.listen<StoreSummaryState>(storeSummaryProvider, (_, next) {
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
                  ref.read(storeSummaryProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Summary',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(storeSummaryProvider.notifier).load(),
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: state.isLoading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Stat Cards ───────────────────────────
            Row(
              children: [
                SummaryCard(
                  title: 'Total Sale',
                  value: 'Rs ${state.grandTotalSale.toStringAsFixed(0)}',
                  icon:  Icons.point_of_sale_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Cash In',
                  value: 'Rs ${state.grandTotalCashIn.toStringAsFixed(0)}',
                  icon:  Icons.arrow_downward_rounded,
                  color: AppColor.success,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Cash Out',
                  value: 'Rs ${state.grandTotalCashOut.toStringAsFixed(0)}',
                  icon:  Icons.arrow_upward_rounded,
                  color: AppColor.error,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Expense',
                  value: 'Rs ${state.grandTotalExpense.toStringAsFixed(0)}',
                  icon:  Icons.money_off_outlined,
                  color: AppColor.warning,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Net Amount',
                  value: 'Rs ${state.grandTotalAmount.toStringAsFixed(0)}',
                  icon:  Icons.account_balance_outlined,
                  color: AppColor.success,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Search ────────────────────────────────
            SizedBox(
              width: 280,
              child: TextField(
                onChanged: ref.read(storeSummaryProvider.notifier).onSearchChanged,
                style:        const TextStyle(fontSize: 13),
                cursorHeight: 14,
                decoration: InputDecoration(
                  hintText: 'Search by date...',
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

            const SizedBox(height: 16),

            // ── Table ─────────────────────────────────
            Expanded(
              child: records.isEmpty ?
              _EmptyState(isSearching: state.searchQuery.isNotEmpty) :
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  const double minTableWidth = 1100;
                  final tableWidth =
                  availableWidth > minTableWidth ? availableWidth : minTableWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: tableWidth),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColor.grey100),
                          dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                                (s) => s.contains(WidgetState.hovered)
                                ? AppColor.primary.withValues(alpha: 0.05)
                                : null,
                          ),
                          dataRowMinHeight: 56,
                          dataRowMaxHeight: 56,
                          columnSpacing: (tableWidth * 0.025).clamp(14.0, 44.0),
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Cash Sale')),
                            DataColumn(label: Text('Card Sale')),
                            DataColumn(label: Text('Credit Sale')),
                            DataColumn(label: Text('Total Sale')),
                            DataColumn(label: Text('Installment')),
                            DataColumn(label: Text('Cash In')),
                            DataColumn(label: Text('Cash Out')),
                            DataColumn(label: Text('Expense')),
                            DataColumn(label: Text('Net Amount')),
                          ],
                          rows: records.map((r) => DataRow(
                            cells: [
                              // Date
                              DataCell(Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColor.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    dateFmt.format(r.counterDate),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              )),

                              DataCell(_Cell(value: r.totalCashSaleLabel,    color: AppColor.primary)),
                              DataCell(_Cell(value: r.totalCardSaleLabel,    color: AppColor.info)),
                              DataCell(_Cell(value: r.totalCreditSaleLabel,  color: AppColor.warning)),
                              DataCell(_Cell(value: r.totalSaleLabel,        color: AppColor.primary, isBold: true)),
                              DataCell(_Cell(value: r.totalInstallmentLabel, color: AppColor.grey500)),
                              DataCell(_Cell(value: r.totalCashInLabel,      color: AppColor.success)),
                              DataCell(_Cell(value: r.totalCashOutLabel,     color: AppColor.error)),
                              DataCell(_Cell(value: r.totalExpenseLabel,     color: AppColor.error)),

                              // Net Amount
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColor.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColor.success.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  r.totalAmountLabel,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColor.success),
                                ),
                              )),
                            ],
                          )).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String value;
  final Color  color;
  final bool   isBold;
  const _Cell({required this.value, required this.color, this.isBold = false});

  @override
  Widget build(BuildContext context) => Text(value,
      style: TextStyle(
          fontSize:   13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color:      color));
}

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
                : Icons.store_outlined,
            size:  64,
            color: AppColor.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'Koi record nahi mila'
                : 'Koi store record nahi',
            style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      AppColor.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Date change karke search karein'
                : 'Sales hone ke baad yahan data aayega',
            style: const TextStyle(
                fontSize: 13, color: AppColor.textHint),
          ),
        ],
      ),
    );
  }
}