import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/model/cash_transaction_model.dart';
import '../provider/cash_transaction_provider.dart';
import '../widget/add_cash_transaction_dialog.dart';

class CounterCashTransactionScreen extends ConsumerStatefulWidget {
  const CounterCashTransactionScreen({super.key});

  @override
  ConsumerState<CounterCashTransactionScreen> createState() =>
      _CounterCashTransactionScreenState();
}

class _CounterCashTransactionScreenState
    extends ConsumerState<CounterCashTransactionScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cashTransactionProvider.notifier).load();
      ref.read(counterProvider.notifier).loadCounters();
    });
  }

  void _openDialog(BuildContext context) async {
    await showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (_) => const AddCashTransactionDialog(),
    );
    if (mounted) {
      ref.read(cashTransactionProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashTransactionProvider);
    final auth = ref.watch(authProvider);
    final counters = ref.watch(counterProvider).counters;
    final fmt = DateFormat('dd MMM yyyy  hh:mm a');
    final size = MediaQuery.sizeOf(context);

    // Sirf is counter ki transactions
    final transactions = state.allTransactions
        .where((t) => t.counterId == auth.counterId)
        .toList();

    final counterName = auth.counterId != null
        ? counters
        .where((c) => c.id == auth.counterId)
        .map((c) => c.counterName)
        .firstOrNull ?? 'Counter'
        : 'Counter';

    ref.listen<CashTransactionState>(cashTransactionProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label:     'OK',
              textColor: Colors.white,
              onPressed: () => ref.read(cashTransactionProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('$counterName — Transactions',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: () => ref.read(cashTransactionProvider.notifier).load(),
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 4),
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                onPressed: auth.counterId == null ? null : () => _openDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  elevation:       0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon:  const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('New Transaction',
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
                    Icon(Icons.warning_amber_rounded, color: AppColor.warning, size: 18),
                    SizedBox(width: 10),
                    Text('Aapko koi counter assign nahi',
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.warning,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Stat Cards ───────────────────────────
            Row(
              children: [
                SummaryCard(
                  title: 'Today Total',
                  value: 'Rs ${state.todayTotal.toStringAsFixed(0)}',
                  icon:  Icons.account_balance_wallet_outlined,
                  color: state.todayTotal >= 0 ? AppColor.success : AppColor.error,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Cash In',
                  value: 'Rs ${transactions.where((t) => t.isCashIn).fold(0.0, (s, t) => s + t.cashOutAmount).toStringAsFixed(0)}',
                  icon:  Icons.arrow_downward_rounded,
                  color: AppColor.success,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Cash Out',
                  value: 'Rs ${transactions.where((t) => t.isCashOut).fold(0.0, (s, t) => s + t.cashOutAmount).toStringAsFixed(0)}',
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColor.grey100),
                    dataRowColor:
                    WidgetStateProperty.resolveWith<Color?>((s) => s.contains(WidgetState.hovered) ? AppColor.primary.withValues(alpha: 0.05) : null),
                    dataRowMinHeight:   54,
                    dataRowMaxHeight:   54,
                    columnSpacing: size.width * 0.07,
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
                                fontSize:   13,
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
                              overflow:  TextOverflow.ellipsis,
                              maxLines:  1),
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
        Text('New Transaction button se add karein',
            style: TextStyle(fontSize: 13, color: AppColor.textHint)),
      ],
    ),
  );
}

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
