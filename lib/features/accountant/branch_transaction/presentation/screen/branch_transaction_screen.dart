import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/branch_transaction_model.dart';
import '../provider/branch_transaction_provider.dart';

class AccountantBranchTransactionScreen extends ConsumerStatefulWidget {
  final String accountantId;
  const AccountantBranchTransactionScreen({
    super.key,
    required this.accountantId,
  });

  @override
  ConsumerState<AccountantBranchTransactionScreen> createState() =>
      _AccountantBranchTransactionScreenState();
}

class _AccountantBranchTransactionScreenState
    extends ConsumerState<AccountantBranchTransactionScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  static final _displayFmt = DateFormat('dd MMM yyyy  hh:mm a');

  BranchTransactionParams get _params => BranchTransactionParams(
    accountantId: widget.accountantId,
    startDate:    _startDate,
    endDate:      _endDate,
  );

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate:   DateTime(2023),
      lastDate:    DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
          const ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchTransactionProvider(_params));

    return SafeArea(
      child: Column(
        children: [

          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Branch Transactions',
                  style: TextStyle(
                      fontSize:   22,
                      fontWeight: FontWeight.w700,
                      color:      AppColor.textDark),
                ),
                const Text(
                  'Cash In from Branches',
                  style: TextStyle(
                      fontSize: 13, color: AppColor.textMuted),
                ),
                const SizedBox(height: 16),

                // ── Date Filter ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerBtn(
                        label: 'Start Date',
                        date:  _startDate,
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DatePickerBtn(
                        label: 'End Date',
                        date:  _endDate,
                        onTap: () => _pickDate(false),
                      ),
                    ),
                    if (_startDate != null || _endDate != null)
                      IconButton(
                        onPressed: () => setState(() {
                          _startDate = null;
                          _endDate   = null;
                        }),
                        icon: const Icon(Icons.close_rounded,
                            color: AppColor.textMuted, size: 20),
                      ),
                  ],
                ),

                // ── Summary Row ────────────────────────────────────
                if (!state.isLoading && state.error == null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                          Icons.account_balance_wallet_outlined,
                          size:  14,
                          color: AppColor.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Total: Rs ${state.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${state.transactions.length} records',
                        style: const TextStyle(
                            fontSize: 12,
                            color:    AppColor.textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Error Banner ──────────────────────────────────────────
          if (state.error != null)
            Container(
              width:   double.infinity,
              margin:  const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        AppColor.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: AppColor.error.withOpacity(0.3)),
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
                  TextButton(
                    onPressed: () => ref
                        .read(branchTransactionProvider(_params)
                        .notifier)
                        .load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // ── List ──────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.transactions.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: () async => ref
                  .read(branchTransactionProvider(_params)
                  .notifier)
                  .load(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.transactions.length,
                itemBuilder: (ctx, i) {
                  final t = state.transactions[i];
                  return _BranchTxCard(
                    storeName:   t.branchName.isEmpty
                        ? '—'
                        : t.branchName,
                    userName:    t.accountantName,
                    amount: 'Rs ${t.amount.toStringAsFixed(0)}',
                    date: _displayFmt
                        .format(t.createdAt.toLocal()),
                    description: t.description,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WIDGETS
// ─────────────────────────────────────────────────────────────

class _DatePickerBtn extends StatelessWidget {
  final String    label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerBtn({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        AppColor.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColor.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 14, color: AppColor.primary),
            const SizedBox(width: 6),
            Text(
              date == null
                  ? label
                  : '${date!.day}/${date!.month}/${date!.year}',
              style: TextStyle(
                fontSize:   12,
                color:      date == null
                    ? AppColor.textMuted
                    : AppColor.textDark,
                fontWeight: date == null
                    ? FontWeight.w400
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchTxCard extends StatelessWidget {
  final String  storeName;
  final String  userName;
  final String  amount;
  final String  date;
  final String? description;

  const _BranchTxCard({
    required this.storeName,
    required this.userName,
    required this.amount,
    required this.date,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width:  44,
            height: 44,
            decoration: BoxDecoration(
              color:        const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store_rounded,
                color: AppColor.cashIn, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(storeName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize:   14,
                        color:      AppColor.textDark)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 12, color: AppColor.textMuted),
                    const SizedBox(width: 4),
                    Text(userName,
                        style: const TextStyle(
                            fontSize: 12,
                            color:    AppColor.textMuted)),
                  ],
                ),
                if (description != null &&
                    description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColor.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+ $amount',
                style: const TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.w700,
                    color:      AppColor.cashIn),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 11, color: AppColor.textMuted),
                  const SizedBox(width: 3),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 11,
                          color:    AppColor.textMuted)),
                ],
              ),
            ],
          ),
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
        SizedBox(height: 12),
        Text('No transactions found',
            style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      AppColor.textMuted)),
        SizedBox(height: 6),
        Text('Transactions yahan dikhenge',
            style: TextStyle(
                fontSize: 13, color: AppColor.textMuted)),
      ],
    ),
  );
}