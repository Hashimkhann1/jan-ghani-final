// lib/features/accountant/branch_reports/accountant_branch_transaction/presentation/screen/accountant_branch_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../data/model/accountant_branch_transaction_model.dart';
import '../provider/accountant_branch_transaction_provider.dart';

class AccountantBranchTransactionScreen extends ConsumerStatefulWidget {
  const AccountantBranchTransactionScreen({
    super.key,
    required this.branchId,

  });

  final String branchId;


  @override
  ConsumerState<AccountantBranchTransactionScreen> createState() =>
      _AccountantBranchTransactionScreenState();
}

class _AccountantBranchTransactionScreenState
    extends ConsumerState<AccountantBranchTransactionScreen> {
  final _startCtrl = TextEditingController();
  final _endCtrl   = TextEditingController();
  final _dateFmt   = DateFormat('dd MMM yyyy');

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  // ── Start Date Picker ──────────────────────────────────
  Future<void> _pickStartDate() async {
    final state = ref.read(branchTransactionProvider(widget.branchId));
    final picked = await showDatePicker(
      context:      context,
      initialDate:  state.startDate ?? DateTime.now(),
      firstDate:    DateTime(2020),
      lastDate:     DateTime.now().add(const Duration(days: 1)),
      builder:      _dateTheme,
    );
    if (picked == null) return;
    _startCtrl.text = _dateFmt.format(picked);

    // Agar end date pehle se set hai aur start us se baad hai tu clear karo
    final endDate = state.endDate;
    final newEnd  = (endDate != null && endDate.isBefore(picked))
        ? null
        : endDate;
    if (newEnd == null) _endCtrl.clear();

    await ref
        .read(branchTransactionProvider(widget.branchId).notifier)
        .applyDateFilter(picked, newEnd);
  }

  // ── End Date Picker ────────────────────────────────────
  Future<void> _pickEndDate() async {
    final state = ref.read(branchTransactionProvider(widget.branchId));
    final picked = await showDatePicker(
      context:      context,
      initialDate:  state.endDate   ??
          state.startDate ?? DateTime.now(),
      firstDate:    state.startDate ?? DateTime(2020),
      lastDate:     DateTime.now().add(const Duration(days: 1)),
      builder:      _dateTheme,
    );
    if (picked == null) return;
    _endCtrl.text = _dateFmt.format(picked);
    await ref
        .read(branchTransactionProvider(widget.branchId).notifier)
        .applyDateFilter(state.startDate, picked);
  }

  Widget _dateTheme(BuildContext ctx, Widget? child) => Theme(
    data: Theme.of(ctx).copyWith(
      colorScheme: const ColorScheme.light(
        primary:   AppColor.primary,
        onPrimary: Colors.white,
        onSurface: Color(0xFF1A1D23),
      ),
    ),
    child: child!,
  );

  // ── Clear Filter ───────────────────────────────────────
  void _clearFilter() {
    _startCtrl.clear();
    _endCtrl.clear();
    ref
        .read(branchTransactionProvider(widget.branchId).notifier)
        .clearFilter();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(branchTransactionProvider(widget.branchId));
    final notifier = ref.read(branchTransactionProvider(widget.branchId).notifier);
    final fmt      = NumberFormat('#,##0.00', 'en_US');
    final hasFilter = state.startDate != null || state.endDate != null;

    // ── Error Snackbar ─────────────────────────────────
    ref.listen<BranchTransactionState>(
      branchTransactionProvider(widget.branchId),
          (_, next) {
        if (next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label:     'OK',
              textColor: Colors.white,
              onPressed: notifier.clearError,
            ),
          ));
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [

          // ── AppBar ──────────────────────────────────────
          SliverAppBar(
            pinned:           true,
            backgroundColor:  Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation:        0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Branch Transactions',
                  style: TextStyle(
                    fontSize:   17,
                    fontWeight: FontWeight.w800,
                    color:      Color(0xFF1A1D23),
                  ),
                ),
                Text(
                  state.branchName,
                  style: const TextStyle(
                    fontSize:  12,
                    color:     AppColor.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: notifier.load,
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColor.textSecondary),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 4),
            ],
            // ── Date Filter Fields ─────────────────────
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(68),
              child: Container(
                color:   Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    // Start Date
                    Expanded(
                      child: _DateField(
                        controller:  _startCtrl,
                        hint:        'Start Date',
                        icon:        Icons.calendar_today_rounded,
                        onTap:       _pickStartDate,
                        onClear:     _startCtrl.text.isNotEmpty
                            ? () {
                          _startCtrl.clear();
                          ref
                              .read(branchTransactionProvider(
                              widget.branchId)
                              .notifier)
                              .applyDateFilter(
                              null, state.endDate);
                        }
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('—',
                          style: TextStyle(
                              color:      Colors.grey.shade400,
                              fontWeight: FontWeight.w600)),
                    ),
                    // End Date
                    Expanded(
                      child: _DateField(
                        controller:  _endCtrl,
                        hint:        'End Date',
                        icon:        Icons.event_rounded,
                        onTap:       _pickEndDate,
                        onClear:     _endCtrl.text.isNotEmpty
                            ? () {
                          _endCtrl.clear();
                          ref
                              .read(branchTransactionProvider(
                              widget.branchId)
                              .notifier)
                              .applyDateFilter(
                              state.startDate, null);
                        }
                            : null,
                      ),
                    ),
                    // Clear All
                    if (hasFilter) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _clearFilter,
                        child: Container(
                          width:  34,
                          height: 34,
                          decoration: BoxDecoration(
                            color:        AppColor.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.filter_alt_off_rounded,
                            size:  16,
                            color: AppColor.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Summary: Total Transactions + Total Amount ──
          if (!state.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    // Total Transactions
                    Expanded(
                      child: _StatBox(
                        label: 'Total Transactions',
                        value: '${state.transactions.length}',
                        icon:  Icons.receipt_long_rounded,
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Total Amount
                    Expanded(
                      child: _StatBox(
                        label: 'Total Amount',
                        value: 'Rs. ${fmt.format(state.totalCashOut)}',
                        icon:  Icons.account_balance_wallet_rounded,
                        color: const Color(0xFFF97316),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Count Label ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                state.transactions.isEmpty && !state.isLoading
                    ? 'Koi transaction nahi mili'
                    : '${state.transactions.length} transactions',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
          ),

          // ── Loading ──────────────────────────────────────
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )

          // ── Empty ────────────────────────────────────────
          else if (state.transactions.isEmpty)
            const SliverFillRemaining(child: _EmptyState())

          // ── List ─────────────────────────────────────────
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.separated(
                itemCount:        state.transactions.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (_, i) => _TransactionCard(
                  transaction: state.transactions[i],
                  branchName:  state.branchName,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Date TextField
// ═══════════════════════════════════════════════════════════
class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String     hint;
  final IconData   icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextField(
          controller:   controller,
          readOnly:     true,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          cursorHeight: 14,
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: const TextStyle(
                fontSize: 12, color: AppColor.textHint),
            prefixIcon: Icon(icon,
                size: 16, color: AppColor.primary),
            suffixIcon: onClear != null
                ? GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  size: 14, color: AppColor.textHint),
            )
                : null,
            filled:      true,
            fillColor:   AppColor.grey100,
            isDense:     true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:   BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: AppColor.grey200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppColor.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Stat Box (summary)
// ═══════════════════════════════════════════════════════════
class _StatBox extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color   color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color:    AppColor.textHint)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w800,
                      color:      color,
                    ),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Transaction Card — Simplified
// ═══════════════════════════════════════════════════════════
class _TransactionCard extends StatelessWidget {
  final BranchTransactionModel transaction;
  final String                 branchName;

  const _TransactionCard({
    required this.transaction,
    required this.branchName,
  });

  @override
  Widget build(BuildContext context) {
    final fmt     = NumberFormat('#,##0.00', 'en_US');
    final dateFmt = DateFormat('dd MMM yyyy  •  hh:mm a');
    final isCashIn = transaction.isCashIn;
    final color    = isCashIn
        ? const Color(0xFF10B981)
        : const Color(0xFFF97316);

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        child: Row(
          children: [

            // ── Left: Icon ─────────────────────────────
            Container(
              width:  44,
              height: 44,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCashIn
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: color,
                size:  20,
              ),
            ),
            const SizedBox(width: 12),

            // ── Middle: Branch + Assign By + Date ──────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branch Name
                  Text(
                    branchName,
                    style: const TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF1A1D23),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Assign By
                  Text(
                    transaction.assignByName.isNotEmpty
                        ? transaction.assignByName
                        : '—',
                    style: const TextStyle(
                      fontSize: 12,
                      color:    AppColor.textHint,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Date
                  Text(
                    dateFmt.format(
                        transaction.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: 11,
                      color:    Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),

            // ── Right: Amount ──────────────────────────
            Text(
              'Rs.\n${fmt.format(transaction.payAmount)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w800,
                color:      color,
                height:     1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Empty State
// ═══════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.swap_horiz_rounded,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'Koi transaction nahi mili',
          style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w600,
            color:      Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Date filter change karein',
          style: TextStyle(
              fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    ),
  );
}