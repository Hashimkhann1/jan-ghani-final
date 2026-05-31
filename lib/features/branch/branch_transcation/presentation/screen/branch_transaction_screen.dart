import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/branch_transaction_provider.dart';
import '../widget/cash_out_dilog.dart';

class BranchTransactionScreen extends ConsumerStatefulWidget {
  const BranchTransactionScreen({super.key});

  @override
  ConsumerState<BranchTransactionScreen> createState() =>
      _BranchTransactionScreenState();
}

class _BranchTransactionScreenState
    extends ConsumerState<BranchTransactionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
          () => ref.read(branchTransactionProvider.notifier).loadData(),
    );
  }

  void _openCashOutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CashOutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchTransactionProvider);
    final fmt   = DateFormat('dd MMM yyyy  hh:mm a');

    ref.listen(branchTransactionProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label:     'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(branchTransactionProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Transaction History',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(branchTransactionProvider.notifier).loadData(),
          ),
          const SizedBox(width: 8),
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: state.isLoading ? null : _openCashOutDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation:       0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon:  const Icon(Icons.arrow_upward_rounded, size: 18),
                label: const Text('Cash Out',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ── Summary Card ────────────────────────
            _SummaryCard(
              totalAmount: state.totalAmount,
              cashInHand:  state.cashInHand,
            ),

            const SizedBox(height: 16),

            // ── Pending sync banner ──────────────────
            if (state.history.any((t) => !t.isSynced))
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(12),
                margin:  const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color:        Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        color: Colors.orange.shade600, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${state.history.where((t) => !t.isSynced).length} transaction(s) pending sync — internet aa ne par Sync karein',
                        style: TextStyle(
                            color:      Colors.orange.shade700,
                            fontSize:   13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Transaction History',
                  style: TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 10),

            // ── DataTable ────────────────────────────
            Expanded(
              child: state.history.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz_rounded,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Koi transaction nahi mili',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: () => ref
                    .read(branchTransactionProvider.notifier)
                    .loadData(),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    const double minWidth = 900;
                    final tableWidth =
                    constraints.maxWidth > minWidth
                        ? constraints.maxWidth
                        : minWidth;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minWidth: tableWidth),
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor:
                            WidgetStateProperty.all(
                                Colors.grey.shade100),
                            dataRowMinHeight: 56,
                            dataRowMaxHeight: 56,
                            columnSpacing:    28,
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Before Amount')),
                              DataColumn(label: Text('Pay Amount')),
                              DataColumn(label: Text('After Amount')),
                              DataColumn(label: Text('By')),
                              DataColumn(label: Text('Date & Time')),
                              DataColumn(label: Text('Status')),
                            ],
                            rows: state.history.map((t) {
                              final isSyncingThis =
                                  state.syncingRowId == t.id;

                              return DataRow(cells: [

                                // Type
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_upward_rounded,
                                          size:  13,
                                          color: Colors.red.shade400),
                                      const SizedBox(width: 5),
                                      Text(
                                        t.type.toUpperCase()
                                            .replaceAll('_', ' '),
                                        style: TextStyle(
                                            fontSize:   11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red.shade600),
                                      ),
                                    ],
                                  ),
                                )),

                                // Before
                                DataCell(Text(
                                  'Rs ${t.beforeAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54),
                                )),

                                // Pay
                                DataCell(Text(
                                  'Rs ${t.payAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize:   13,
                                      fontWeight: FontWeight.w600),
                                )),

                                // After
                                DataCell(Text(
                                  'Rs ${t.afterAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize:   13,
                                      fontWeight: FontWeight.w600,
                                      color: t.afterAmount >= 0
                                          ? Colors.black87
                                          : Colors.red),
                                )),

                                // By
                                DataCell(Text(
                                  t.assignByName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54),
                                )),

                                // Date
                                DataCell(Text(
                                  fmt.format(t.createdAt),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black45),
                                )),

                                // Status / Sync button
                                DataCell(
                                  t.isSynced
                                  // ✅ Synced — green badge
                                      ? Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                        horizontal: 10,
                                        vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.green
                                          .shade50,
                                      borderRadius:
                                      BorderRadius
                                          .circular(8),
                                      border: Border.all(
                                          color: Colors.green
                                              .shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize:
                                      MainAxisSize.min,
                                      children: [
                                        Icon(
                                            Icons.check_circle_outline,
                                            size:  13,
                                            color: Colors
                                                .green.shade600),
                                        const SizedBox(
                                            width: 5),
                                        Text('Synced',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight:
                                                FontWeight
                                                    .w600,
                                                color: Colors
                                                    .green
                                                    .shade600)),
                                      ],
                                    ),
                                  )
                                  // ⏳ Pending — sync button
                                      : SizedBox(
                                    width: 90,
                                    child: ElevatedButton.icon(
                                      onPressed: isSyncingThis
                                          ? null
                                          : () => ref
                                          .read(branchTransactionProvider
                                          .notifier)
                                          .syncRow(
                                          t.id,
                                          t.payAmount),
                                      style: ElevatedButton
                                          .styleFrom(
                                        backgroundColor:
                                        Colors.orange,
                                        foregroundColor:
                                        Colors.white,
                                        padding:
                                        const EdgeInsets
                                            .symmetric(
                                            horizontal: 8,
                                            vertical: 6),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius
                                                .circular(
                                                8)),
                                      ),
                                      icon: isSyncingThis
                                          ? const SizedBox(
                                          width:  12,
                                          height: 12,
                                          child:
                                          CircularProgressIndicator(
                                              strokeWidth:
                                              2,
                                              color: Colors
                                                  .white))
                                          : const Icon(
                                          Icons.sync_rounded,
                                          size: 14),
                                      label: Text(
                                          isSyncingThis
                                              ? '...'
                                              : 'Sync',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                              FontWeight
                                                  .w600)),
                                    ),
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Card ─────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final double totalAmount;
  final double cashInHand;

  const _SummaryCard({required this.totalAmount, required this.cashInHand});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _AmountItem(
                label:  'Total Amount',
                amount: totalAmount,
                color:  Colors.blue,
                icon:   Icons.account_balance_wallet_outlined,
              ),
            ),
            Container(width: 1, height: 50, color: Colors.grey.shade200),
            Expanded(
              child: _AmountItem(
                label:  'Cash In Hand',
                amount: cashInHand,
                color:  Colors.green,
                icon:   Icons.payments_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountItem extends StatelessWidget {
  final String   label;
  final double   amount;
  final Color    color;
  final IconData icon;

  const _AmountItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
              color: color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}