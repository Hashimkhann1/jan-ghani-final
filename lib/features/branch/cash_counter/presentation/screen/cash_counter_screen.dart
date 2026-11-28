import 'package:jan_ghani_final/core/widget/branch_ui.dart';
import 'package:jan_ghani_final/core/color/branch_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';
import 'package:jan_ghani_final/core/widget/pagination_bar.dart';
import 'package:jan_ghani_final/features/branch/cash_counter/presentation/provider/cash_counter_provider.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../customer_ledger/presentation/widget/counter_chip_widget.dart';
import '../widget/add_cash_transaction_dialog.dart';

class CashCounterScreen extends ConsumerStatefulWidget {
  const CashCounterScreen({super.key});

  @override
  ConsumerState<CashCounterScreen> createState() => _CashCounterScreenState();
}

class _CashCounterScreenState extends ConsumerState<CashCounterScreen> {

  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cashCounterProvider.notifier).loadRecords();
      ref.read(counterProvider.notifier).loadCounters();
    });
  }

  void _openTransactionDialog(BuildContext context) async {
    await showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (_) => const AddCashTransactionDialog(),
    );
    if (mounted) {
      ref.read(cashCounterProvider.notifier).loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(cashCounterProvider);
    final records  = state.filteredRecords;
    final auth     = ref.watch(authProvider);
    final counters = ref.watch(counterProvider).counters;
    final dateFmt  = DateFormat('dd MMM yyyy');
    final size = MediaQuery.sizeOf(context);

    final isOwnerOrManager =
        auth.role == 'store_owner' || auth.role == 'store_manager';

    final assignedCounter = auth.counterId != null
        ? counters
        .where((c) => c.id == auth.counterId)
        .map((c) => c.counterName)
        .firstOrNull
        : null;

    ref.listen<CashCounterState>(cashCounterProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    return Scaffold(
      appBar: BranchAppBar(
        title:    'Cash Counter',
        subtitle: assignedCounter ?? 'Rozana counter ka hisaab',
        actions: [
          BranchRefreshButton(
              onPressed: () =>
                  ref.read(cashCounterProvider.notifier).loadRecords()),
          BranchActionButton(
            label:     'Count Cash',
            iconAsset: 'ic_count_cash',
            onPressed: () => _openTransactionDialog(context),
          ),
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
                BranchStatCard(
                  title: 'Total Sale',
                  value: branchMoney(state.grandTotalSale),
                  iconAsset: 'ic_cash_registration',
                  color: BranchColor.navy,
                ),
                const SizedBox(width: 12),
                BranchStatCard(
                  title: 'Cash In',
                  value: branchMoney(state.grandCashIn),
                  iconAsset: 'ic_cash_in',
                  color: AppColor.success,
                ),
                const SizedBox(width: 12),
                BranchStatCard(
                  title: 'Cash Out',
                  value: branchMoney(state.grandCashOut),
                  iconAsset: 'ic_cash_out',
                  color: AppColor.error,
                ),
                const SizedBox(width: 12),
                BranchStatCard(
                  title: 'Overall Amount',
                  value: branchMoney(state.grandTotalAmount),
                  iconAsset: 'ic_bank_net',
                  color: BranchColor.accent,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Search ────────────────────────────────
            SizedBox(
              width: 300,
              child: TextField(
                onChanged: ref.read(cashCounterProvider.notifier).onSearchChanged,
                style:        const TextStyle(fontSize: 13),
                cursorHeight: 14,
                decoration: InputDecoration(
                  hintText: 'Search by date...',
                  hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
                  prefixIcon: const AppIcon('ic_search', size: 18, color: AppColor.grey400),
                  prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Table ─────────────────────────────────
            Expanded(
              child: records.isEmpty ?
              _EmptyState(
                isSearching: state.searchQuery.isNotEmpty,
                noCounterAssigned: !isOwnerOrManager && auth.counterId == null,
              ) :
              BranchTableCard(
                child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
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
                          dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                                (s) => s.contains(WidgetState.hovered)
                                ? BranchColor.navy.withValues(alpha: 0.05)
                                : null,
                          ),
                          headingRowHeight: 46,
                          dataRowMinHeight: 50,
                          dataRowMaxHeight: 50,
                          dividerThickness: 0.6,
                          horizontalMargin: 16,
                          columnSpacing: (tableWidth * 0.025).clamp(14.0, 44.0),
                          showCheckboxColumn: false,
                          // Raqam wale columns right par, taake muqabla aasan ho.
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Counter')),
                            DataColumn(label: Text('Cash Sale'), numeric: true),
                            DataColumn(label: Text('Card Sale'), numeric: true),
                            DataColumn(label: Text('Udhar Sale'), numeric: true),
                            DataColumn(label: Text('Total Sale'), numeric: true),
                            DataColumn(label: Text('Customer Recovery'), numeric: true),
                            DataColumn(label: Text('Cash In'), numeric: true),
                            DataColumn(label: Text('Cash Out'), numeric: true),
                            DataColumn(label: Text('Overall Amount'), numeric: true),
                          ],
                          rows: pageSlice(records, _page).map((r) {
                            final counterName = r.counterId != null
                                ? counters
                                .where((c) => c.id == r.counterId)
                                .map((c) => c.counterName)
                                .firstOrNull
                                : null;

                            return DataRow(
                              cells: [
                                // Date
                                DataCell(Text(
                                  dateFmt.format(r.counterDate),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13),
                                )),

                                DataCell(CounterChip(counterName: counterName)),
                                DataCell(BranchAmount(r.cashSale)),
                                DataCell(BranchAmount(r.cardSale)),
                                DataCell(BranchAmount(r.creditSale, color: AppColor.warningDark)),
                                DataCell(BranchAmount(r.totalSale, isBold: true)),
                                DataCell(BranchAmount(r.installment)),
                                DataCell(BranchAmount(r.cashIn,  color: AppColor.success)),
                                DataCell(BranchAmount(r.cashOut, color: AppColor.error)),

                                // Overall Amount
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: BranchColor.navy.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    branchMoney(r.totalAmount),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: BranchColor.navy,
                                        fontFeatures: [FontFeature.tabularFigures()]),
                                  ),
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: PaginationBar(
                      total: records.length,
                      page:  _page,
                      onPageChanged: (p) => setState(() => _page = p),
                    ),
                  ),
                ],
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
  final bool noCounterAssigned;
  const _EmptyState({
    this.isSearching       = false,
    this.noCounterAssigned = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            noCounterAssigned ? Icons.block_outlined : isSearching ? Icons.search_off_rounded : Icons.point_of_sale_outlined,
            size:  64,
            color: AppColor.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            noCounterAssigned
                ? 'Counter assign nahi'
                : isSearching
                ? 'Koi record nahi mila'
                : 'Koi counter record nahi',
            style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      AppColor.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            noCounterAssigned
                ? 'Admin se counter assign karwayein'
                : isSearching
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