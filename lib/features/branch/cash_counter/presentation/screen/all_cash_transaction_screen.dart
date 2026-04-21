import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import '../../data/model/cash_transaction_model.dart';
import '../provider/cash_transaction_provider.dart';

class AllCashTransactionScreen extends ConsumerStatefulWidget {
  const AllCashTransactionScreen({super.key});

  @override
  ConsumerState<AllCashTransactionScreen> createState() =>
      _AllCashTransactionScreenState();
}

class _AllCashTransactionScreenState
    extends ConsumerState<AllCashTransactionScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cashTransactionProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashTransactionProvider);
    final transactions = state.allTransactions;
    final fmt = DateFormat('dd MMM yyyy  hh:mm a');
    final size = MediaQuery.sizeOf(context);

    ref.listen<CashTransactionState>(cashTransactionProvider, (prev, next) {
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
                  ref.read(cashTransactionProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Cash Transactions',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(cashTransactionProvider.notifier).loadAll(),
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
          children: [

            // ── Stat Cards ───────────────────────────
            Row(
              children: [
                SummaryCard(
                  title: 'Total Records',
                  value: '${transactions.length}',
                  icon:  Icons.receipt_long_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Total Cash In',
                  value: 'Rs ${state.totalCashIn.toStringAsFixed(0)}',
                  icon:  Icons.arrow_downward_rounded,
                  color: AppColor.success,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Total Cash Out',
                  value: 'Rs ${state.totalCashOut.toStringAsFixed(0)}',
                  icon:  Icons.arrow_upward_rounded,
                  color: AppColor.error,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Table ─────────────────────────────────
            Expanded(
              child: transactions.isEmpty ?
              const _EmptyState() :
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  const double minTableWidth = 850;
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
                          dataRowMinHeight: 54,
                          dataRowMaxHeight: 54,
                          columnSpacing: (tableWidth * 0.04).clamp(16.0, 56.0),
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Previous')),
                            DataColumn(label: Text('Amount')),
                            DataColumn(label: Text('Remaining')),
                            DataColumn(label: Text('Description')),
                            DataColumn(label: Text('Date & Time')),
                          ],
                          rows: transactions.map((t) => DataRow(
                            cells: [
                              DataCell(_TypeBadge(t: t)),

                              DataCell(Text(t.previousAmountLabel,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColor.textSecondary))),

                              DataCell(Text(t.cashOutAmount.toString(),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColor.textSecondary))),

                              DataCell(Text(t.remainingAmountLabel,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: t.remainingAmount >= 0
                                          ? AppColor.textPrimary
                                          : AppColor.error))),

                              DataCell(SizedBox(
                                width: 180,
                                child: Text(t.description ?? '—',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColor.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1),
                              )),

                              DataCell(Text(fmt.format(t.createdAt),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColor.textSecondary))),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.swap_horiz_rounded, size: 64, color: AppColor.grey300),
        SizedBox(height: 16),
        Text('Koi transaction nahi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppColor.textSecondary)),
        SizedBox(height: 6),
        Text('Transactions yahan dikhenge',
            style: TextStyle(fontSize: 13, color: AppColor.textHint)),
      ],
    ),
  );
}

// ── Type Badge ────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final CashTransactionModel t;
  const _TypeBadge({required this.t});

  @override
  Widget build(BuildContext context) {
    final color = t.isCashIn ? AppColor.success : AppColor.error;
    final icon  = t.isCashIn
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(t.typeLabel,
              style: TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w700,
                  color:      color)),
        ],
      ),
    );
  }
}
