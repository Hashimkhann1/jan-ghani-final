import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';
import 'package:jan_ghani_final/features/branch/customer_ledger/data/model/customer_ledger_model.dart';
import 'package:jan_ghani_final/features/branch/customer_ledger/presentation/provider/customer_ledger_provider.dart';
import '../../../customer/presentation/widget/customer_action_button_widget.dart';
import '../widget/amount_badge_widget.dart';
import '../widget/counter_chip_widget.dart';
import '../widget/customer_call_widget.dart';
import '../widget/empty_state_widget.dart';

class AllCustomerLedgerScreen extends ConsumerStatefulWidget {
  const AllCustomerLedgerScreen({super.key});

  @override
  ConsumerState<AllCustomerLedgerScreen> createState() =>
      _AllCustomerLedgerScreenState();
}

class _AllCustomerLedgerScreenState
    extends ConsumerState<AllCustomerLedgerScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerLedgerProvider.notifier).loadLedgers();
      ref.read(counterProvider.notifier).loadCounters();
    });
  }

  void _confirmDelete(BuildContext context, CustomerLedgerModel ledger) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: const Text('Record Delete Karein?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
            '"${ledger.customerName}" ka record delete karna chahte hain?',
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
              ref.read(customerLedgerProvider.notifier)
                  .deleteLedger(ledger.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerLedgerProvider);
    final ledgers = state.filteredLedgers;
    final counters = ref.watch(counterProvider).counters;
    final fmt = DateFormat('dd MMM yyyy  hh:mm a');
    final size = MediaQuery.sizeOf(context);

    ref.listen<CustomerLedgerState>(customerLedgerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
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
                  ref.read(customerLedgerProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Customer Ledger',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(customerLedgerProvider.notifier).loadLedgers(),
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
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
                  title: 'Total Records',
                  value: '${ledgers.length}',
                  icon:  Icons.receipt_long_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Total Paid',
                  value: 'Rs ${state.totalPaid.toStringAsFixed(0)}',
                  icon:  Icons.payments_outlined,
                  color: AppColor.success,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Search ────────────────────────────────
            SizedBox(
              width: 280,
              child: TextField(
                onChanged: ref.read(customerLedgerProvider.notifier).onSearchChanged,
                style:        const TextStyle(fontSize: 13),
                cursorHeight: 14,
                decoration: InputDecoration(
                  hintText: 'Search by customer...',
                  hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColor.grey400),
                  filled:    true,
                  fillColor: AppColor.grey100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              child: ledgers.isEmpty ?
              EmptyState(isSearching: state.searchQuery.isNotEmpty) :
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  const double minTableWidth = 950;
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
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 52,
                          columnSpacing: (tableWidth * 0.03).clamp(16.0, 48.0),
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('Customer')),
                            DataColumn(label: Text('Counter')),
                            DataColumn(label: Text('Previous')),
                            DataColumn(label: Text('Paid')),
                            DataColumn(label: Text('Remaining')),
                            DataColumn(label: Text('Notes')),
                            DataColumn(label: Text('Date & Time')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: ledgers.map((l) {
                            final counterName = l.counterId != null
                                ? counters
                                .where((c) => c.id == l.counterId)
                                .map((c) => c.counterName)
                                .firstOrNull
                                : null;
                            return DataRow(
                              cells: [
                                DataCell(CustomerCell(l: l)),

                                DataCell(CounterChip(counterName: counterName)),

                                DataCell(AmountBadge(
                                    amount: l.previousAmount, color: AppColor.grey500)),

                                DataCell(AmountBadge(
                                    amount: l.payAmount, color: AppColor.success)),

                                DataCell(AmountBadge(
                                  amount: l.newAmount,
                                  color: l.newAmount > 0
                                      ? AppColor.error
                                      : l.newAmount < 0
                                      ? AppColor.info
                                      : AppColor.success,
                                )),

                                DataCell(SizedBox(
                                  width: 140,
                                  child: Text(
                                    l.notes ?? '—',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColor.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                )),

                                DataCell(Text(
                                  fmt.format(l.createdAt),
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColor.textSecondary),
                                )),

                                DataCell(CustomerActionButton(
                                  icon: Icons.delete_outline_rounded,
                                  color: AppColor.error,
                                  tooltip: 'Delete',
                                  onTap: () => _confirmDelete(context, l),
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
          ],
        ),
      ),
    );
  }
}


// ── Counter Chip ──────────────────────────────────────────────

// ── Amount Badge ──────────────────────────────────────────────
