import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/core/widget/pagination_bar.dart';
import 'package:jan_ghani_final/features/branch/cash_counter/presentation/provider/cash_counter_provider.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../customer_ledger/presentation/widget/counter_chip_widget.dart';
import '../widget/add_cash_registration_dialog.dart';
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
      appBar: AppBar(
        title: const Text('Cash Counter', style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: () => ref.read(cashCounterProvider.notifier).loadRecords(),
            icon: const AppIcon('ic_refresh', size: 20, color: AppColor.textSecondary),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 4),
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: OutlinedButton.icon(
                onPressed: () => _openTransactionDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.success,
                  side: const BorderSide(color: AppColor.success),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon:  const AppIcon('ic_count_cash', size: 18, color: AppColor.success),
                label: const Text('Count Cash',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AddCashRegistrationDialog(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  elevation:       0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon:  const AppIcon('ic_cash_registration', size: 18, color: Colors.white),
                label: const Text('Cash Registration',
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
                  title: 'Total Sale',
                  value: 'Rs ${state.grandTotalSale.toStringAsFixed(0)}',
                  iconAsset: 'ic_cash_registration',
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Cash In',
                  value: 'Rs ${state.grandCashIn.toStringAsFixed(0)}',
                  iconAsset: 'ic_cash_in',
                  color: AppColor.success,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Cash Out',
                  value: 'Rs ${state.grandCashOut.toStringAsFixed(0)}',
                  iconAsset: 'ic_cash_out',
                  color: AppColor.error,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Net Amount',
                  value: 'Rs ${state.grandTotalAmount.toStringAsFixed(0)}',
                  iconAsset: 'ic_bank_net',
                  color: AppColor.info,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Search ────────────────────────────────
            SizedBox(
              width: 280,
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
                  fillColor: AppColor.grey100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
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
              Column(
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
                            DataColumn(label: Text('Counter')),
                            DataColumn(label: Text('Cash Sale')),
                            DataColumn(label: Text('Card Sale')),
                            DataColumn(label: Text('Credit Sale')),
                            DataColumn(label: Text('Total Sale')),
                            DataColumn(label: Text('Installment')),
                            DataColumn(label: Text('Cash In')),
                            DataColumn(label: Text('Cash Out')),
                            DataColumn(label: Text('Net Amount')),
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
                                DataCell(Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColor.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const AppIcon(
                                        'ic_calendar',
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

                                DataCell(CounterChip(counterName: counterName)),
                                DataCell(_Cell(value: r.cashSaleLabel,   color: AppColor.primary)),
                                DataCell(_Cell(value: r.cardSaleLabel,   color: AppColor.info)),
                                DataCell(_Cell(value: r.creditSaleLabel, color: AppColor.warning)),
                                DataCell(_Cell(value: r.totalSaleLabel,  color: AppColor.primary, isBold: true)),
                                DataCell(_Cell(value: r.installmentLabel, color: AppColor.grey500)),
                                DataCell(_Cell(value: r.cashInLabel,     color: AppColor.success)),
                                DataCell(_Cell(value: r.cashOutLabel,    color: AppColor.error)),

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
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
                  ),
                  PaginationBar(
                    total: records.length,
                    page:  _page,
                    onPageChanged: (p) => setState(() => _page = p),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Table Cell ────────────────────────────────────────────────
class _Cell extends StatelessWidget {
  final String value;
  final Color  color;
  final bool   isBold;
  const _Cell({
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) => Text(value,
      style: TextStyle(
          fontSize:   13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color:      color));
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