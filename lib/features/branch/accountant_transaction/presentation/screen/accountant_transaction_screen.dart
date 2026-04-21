import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/provider/auth_provider.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/account_transaction_model.dart';
import '../provider/accountant_transaction_provider.dart';
import '../widget/cashout_dialog.dart';

class AccountantTransactionScreen extends ConsumerWidget {
  /// Pass the current branch's UUID

  const AccountantTransactionScreen({super.key,});
  static final _fmt = DateFormat('dd MMM yyyy  hh:mm a');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(authProvider).storeId;
    final state = ref.watch(accountantTransactionProvider(branchId));
    final size  = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Accountant Transactions',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize:   18,
              color:      AppColor.textPrimary),
        ),
        actions: [
          // ── Cash Out Button ──
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => CashOutDialog(branchId: branchId),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColor.error.withOpacity(0.1),
                foregroundColor: AppColor.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
              ),
              icon:  const Icon(Icons.arrow_upward_rounded, size: 18),
              label: const Text('Cash Out',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          // ── Refresh ──
          IconButton(
            onPressed: () async {
              await ref
                  .read(accountantTransactionProvider(branchId).notifier)
                  .syncIfOnline();
            },
            icon:    const Icon(Icons.refresh_rounded),
            color:   AppColor.textSecondary,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: state.isLoading && state.transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ── Error Banner ──────────────────────────────────────
            if (state.error != null)
              Container(
                width:   double.infinity,
                margin:  const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        AppColor.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(
                      color: AppColor.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColor.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(state.error!,
                          style: const TextStyle(
                              color: AppColor.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            // ── 3 Summary Cards ───────────────────────────────────
            Row(
              children: [
                _SummaryCard(
                  title: 'Total Records',
                  value: '${state.transactions.length}',
                  icon:  Icons.receipt_long_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  title: 'Total Cash In',
                  value: 'Rs ${state.totalCashIn.toStringAsFixed(0)}',
                  icon:  Icons.arrow_downward_rounded,
                  color: AppColor.success,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  title: 'Total Cash Out',
                  value: 'Rs ${state.totalCashOut.toStringAsFixed(0)}',
                  icon:  Icons.arrow_upward_rounded,
                  color: AppColor.error,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Table ─────────────────────────────────────────────
            Expanded(
              child: state.transactions.isEmpty ?
              const _EmptyState() :
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.grey300.withOpacity(0.5)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      const double minTableWidth = 900;
                      final tableWidth =
                      availableWidth > minTableWidth ? availableWidth : minTableWidth;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: tableWidth),
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor:
                              WidgetStateProperty.all(AppColor.grey100),
                              headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColor.textPrimary),
                              dataRowColor: WidgetStateProperty.resolveWith(
                                    (s) => s.contains(WidgetState.hovered)
                                    ? AppColor.primary.withOpacity(0.04)
                                    : null,
                              ),
                              dataRowMinHeight: 54,
                              dataRowMaxHeight: 54,
                              columnSpacing: (tableWidth * 0.03).clamp(16.0, 52.0),
                              showCheckboxColumn: false,
                              dividerThickness: 0.5,
                              columns: const [
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Accountant')),
                                DataColumn(label: Text('Previous')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text('Remaining')),
                                DataColumn(label: Text('Description')),
                                DataColumn(label: Text('Date & Time')),
                              ],
                              rows: state.transactions
                                  .map((t) => _buildRow(t))
                                  .toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(AccountantTransactionModel t) {
    return DataRow(cells: [
      // Type Badge
      DataCell(_TypeBadge(isCashIn: t.isCashIn, label: t.typeLabel)),

      // Accountant Name
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius:          14,
            backgroundColor: AppColor.primary.withOpacity(0.1),
            child: Text(
              t.accountantName[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColor.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(t.accountantName,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColor.textPrimary)),
        ],
      )),

      // Previous
      DataCell(Text(
        'Rs ${t.previousAmount.toStringAsFixed(0)}',
        style: const TextStyle(
            fontSize: 13, color: AppColor.textSecondary),
      )),

      // Amount
      DataCell(Text(
        'Rs ${t.amount.toStringAsFixed(0)}',
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColor.textPrimary),
      )),

      // Remaining
      DataCell(Text(
        'Rs ${t.remainingAmount.toStringAsFixed(0)}',
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: t.remainingAmount >= 0
                ? AppColor.textPrimary
                : AppColor.error),
      )),

      // Description
      DataCell(SizedBox(
        width: 160,
        child: Text(
          t.description ?? '—',
          style: const TextStyle(
              fontSize: 12, color: AppColor.textSecondary),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      )),

      // Date
      DataCell(Text(
        _fmt.format(t.createdAt.toLocal()),
        style: const TextStyle(
            fontSize: 11, color: AppColor.textSecondary),
      )),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String   title;
  final String   value;
  final IconData icon;
  final Color    color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColor.grey300.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width:  36,
              height: 36,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(
                    fontSize: 11, color: AppColor.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool   isCashIn;
  final String label;
  const _TypeBadge({required this.isCashIn, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = isCashIn ? AppColor.success : AppColor.error;
    final icon  = isCashIn
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w700,
                  color:      color)),
        ],
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
        Icon(Icons.swap_horiz_rounded,
            size: 64, color: AppColor.grey300),
        SizedBox(height: 16),
        Text('Koi transaction nahi',
            style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      AppColor.textSecondary)),
        SizedBox(height: 6),
        Text('Transactions yahan dikhenge',
            style: TextStyle(
                fontSize: 13, color: AppColor.textHint)),
      ],
    ),
  );
}