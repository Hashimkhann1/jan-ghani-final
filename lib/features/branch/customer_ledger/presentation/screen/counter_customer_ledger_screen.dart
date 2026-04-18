import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';
import 'package:jan_ghani_final/features/branch/customer_ledger/data/model/customer_ledger_model.dart';
import 'package:jan_ghani_final/features/branch/customer_ledger/presentation/provider/customer_ledger_provider.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../customer/presentation/widget/customer_action_button_widget.dart';
import '../widget/add_ledger_dialog.dart';
import '../widget/amount_badge_widget.dart';
import '../widget/customer_call_widget.dart';

class CounterCustomerLedgerScreen extends ConsumerStatefulWidget {
  const CounterCustomerLedgerScreen({super.key});

  @override
  ConsumerState<CounterCustomerLedgerScreen> createState() =>
      _CounterCustomerLedgerScreenState();
}

class _CounterCustomerLedgerScreenState
    extends ConsumerState<CounterCustomerLedgerScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerLedgerProvider.notifier).loadLedgers();
      ref.read(counterProvider.notifier).loadCounters();
    });
  }

  // ── Edit Dialog ───────────────────────────────────────────
  void _openEditDialog(BuildContext context, CustomerLedgerModel ledger) {
    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (_) => AddLedgerDialog(ledger: ledger), // ← ledger pass karo
    );
  }

  // ── Delete Dialog ─────────────────────────────────────────
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
    final auth = ref.watch(authProvider);
    final counters = ref.watch(counterProvider).counters;
    final fmt  = DateFormat('dd MMM yyyy  hh:mm a');
    final size = MediaQuery.sizeOf(context);
    final ledgers = state.allLedgers.where((l) =>
    l.deletedAt == null && l.counterId == auth.counterId && (state.searchQuery.isEmpty || l.customerName.toLowerCase().contains(state.searchQuery.toLowerCase()))).toList();

    final counterName = auth.counterId != null ? counters.where((c) => c.id == auth.counterId).map((c) => c.counterName).firstOrNull ?? 'Counter' : 'Counter';

    final totalPaid = ledgers.fold(0.0, (sum, l) => sum + l.payAmount);

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
        title: Text('$counterName — Ledger',
            style: const TextStyle(fontWeight: FontWeight.w700)),
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
          const SizedBox(width: 4),
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                onPressed: auth.counterId == null
                    ? null
                    : () => showDialog(
                  context:            context,
                  barrierDismissible: false,
                  builder: (_) => const AddLedgerDialog(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  elevation:       0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon:  const Icon(Icons.add, size: 18),
                label: const Text('New Payment',
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

            // ── Counter Banner ───────────────────────
            if (auth.counterId == null)
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(14),
                margin:  const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:        AppColor.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColor.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColor.warning, size: 18),
                    SizedBox(width: 10),
                    Text('Aapko koi counter assign nahi',
                        style: TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.warning)),
                  ],
                ),
              ),

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
                  value: 'Rs ${totalPaid.toStringAsFixed(0)}',
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
                style: const TextStyle(fontSize: 13),
                cursorHeight: 14,
                decoration: InputDecoration(
                  hintText: 'Search by customer...',
                  hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColor.grey400),
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
              child: ledgers.isEmpty ?
              _EmptyState(
                isSearching: state.searchQuery.isNotEmpty,
                noCounterAssigned: auth.counterId == null,
              ) : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColor.grey100),
                    dataRowColor:
                    WidgetStateProperty.resolveWith<Color?>((s) => s.contains(WidgetState.hovered) ? AppColor.primary.withValues(alpha: 0.05) : null),
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 52,
                    columnSpacing: size.width * 0.045,
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Customer')),
                      DataColumn(label: Text('Previous')),
                      DataColumn(label: Text('Paid')),
                      DataColumn(label: Text('Remaining')),
                      DataColumn(label: Text('Notes')),
                      DataColumn(label: Text('Date & Time')),
                      DataColumn(label: Text('Actions')), // ← 2 buttons
                    ],
                    rows: ledgers.map((l) => DataRow(
                      cells: [
                        DataCell(CustomerCell(l: l)),
                        DataCell(AmountBadge(amount: l.previousAmount, color:  AppColor.grey500)),
                        DataCell(AmountBadge(amount: l.payAmount, color:  AppColor.success)),
                        DataCell(AmountBadge(amount: l.newAmount, color:  l.newAmount > 0 ? AppColor.error : l.newAmount < 0 ? AppColor.info : AppColor.success,),),
                        DataCell(SizedBox(width: 140, child: Text(l.notes ?? '—',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.textSecondary,
                            ),
                            overflow:  TextOverflow.ellipsis,
                            maxLines:  1,
                          ),),),
                        DataCell(Text(fmt.format(l.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColor.textSecondary,
                          ),
                        )),

                        // ── Actions ── ← edit + delete
                        DataCell(Row(
                          children: [
                            CustomerActionButton(
                              icon:    Icons.edit_outlined,
                              color:   AppColor.primary,
                              tooltip: 'Edit',
                              onTap: () => _openEditDialog(context, l),
                            ),
                            const SizedBox(width: 6),
                            CustomerActionButton(
                              icon:    Icons.delete_outline_rounded,
                              color:   AppColor.error,
                              tooltip: 'Delete',
                              onTap: () =>
                                  _confirmDelete(context, l),
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

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final bool noCounterAssigned;
  const _EmptyState({
    this.isSearching       = false,
    this.noCounterAssigned = false,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          noCounterAssigned
              ? Icons.block_outlined
              : isSearching
              ? Icons.search_off_rounded
              : Icons.account_balance_wallet_outlined,
          size:  64,
          color: AppColor.grey300,
        ),
        const SizedBox(height: 16),
        Text(
          noCounterAssigned
              ? 'Counter assign nahi'
              : isSearching
              ? 'Koi record nahi mila'
              : 'Koi payment record nahi',
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
              ? 'Search query change karein'
              : 'New Payment button se record add karein',
          style: const TextStyle(
              fontSize: 13, color: AppColor.textHint),
        ),
      ],
    ),
  );
}