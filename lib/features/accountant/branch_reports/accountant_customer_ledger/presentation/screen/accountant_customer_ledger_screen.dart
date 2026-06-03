
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../../accountant_customer/data/model/accountant_customer_model.dart';
import '../../data/model/accountant_customer_ledger_model.dart';
import '../provider/accountant_customer_ledger_provider.dart';

class AccountantCustomerLedgerScreen extends ConsumerStatefulWidget {
  const AccountantCustomerLedgerScreen(
      {super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<AccountantCustomerLedgerScreen> createState() =>
      _AccountantCustomerLedgerScreenState();
}

class _AccountantCustomerLedgerScreenState
    extends ConsumerState<AccountantCustomerLedgerScreen> {
  final _searchCtrl = TextEditingController();
  final _amtFmt     = NumberFormat('#,##,###', 'en_IN');
  final _dateFmt    = DateFormat('dd MMM yyyy');

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';
  String get _bid      => widget.branchId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Date Picker ─────────────────────────────────────────
  Future<void> _pickDate(BuildContext ctx, bool isStart) async {
    final notifier = ref.read(customerLedgerProvider(_bid).notifier);
    final state    = ref.read(customerLedgerProvider(_bid));

    final picked = await showDatePicker(
      context:      ctx,
      initialDate:  isStart
          ? (state.startDate ?? DateTime.now())
          : (state.endDate   ?? DateTime.now()),
      firstDate:    DateTime(2020),
      lastDate:     DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    if (isStart) {
      notifier.setStartDate(picked);
    } else {
      notifier.setEndDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(customerLedgerProvider(_bid));
    final notifier = ref.read(customerLedgerProvider(_bid).notifier);

    // Error snackbar
    ref.listen<CustomerLedgerState>(
      customerLedgerProvider(_bid),
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
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Customer Ledger',
          style: TextStyle(
              fontSize:   17,
              fontWeight: FontWeight.w700,
              color:      Color(0xFF1A1D23)),
        ),
        actions: [
          IconButton(
            onPressed: notifier.refresh,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
          Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [

          // ── Top Controls (white card) ───────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [

                // Customer Dropdown
                AppSearchableDropdown<AccountantCustomerReportModel>(
                  hint: 'Customer select karein',
                  items: state.customers.map((c) => DropdownItem(
                    value: c,
                    label: '${c.name}  •  ${c.code}',
                    icon:  Icons.person_outline_rounded,
                  )).toList(),
                  value:     state.selectedCustomer,
                  onChanged: (c) { if (c != null) notifier.selectCustomer(c); },
                ),

                const SizedBox(height: 10),

                // Search Field
                TextField(
                  controller: _searchCtrl,
                  onChanged:  notifier.search,
                  style: const TextStyle(fontSize: 14),
                  cursorHeight: 16,
                  decoration: InputDecoration(
                    hintText: 'Notes ya naam se search karein...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColor.textHint),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: AppColor.primary),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 18, color: AppColor.textHint),
                      onPressed: () {
                        _searchCtrl.clear();
                        notifier.search('');
                      },
                    )
                        : null,
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:   BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColor.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColor.primary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Date Range Row
                Row(
                  children: [
                    // Start Date
                    Expanded(
                      child: _DateButton(
                        label: 'Start Date',
                        date:  state.startDate,
                        fmt:   _dateFmt,
                        onTap: () => _pickDate(context, true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // End Date
                    Expanded(
                      child: _DateButton(
                        label: 'End Date',
                        date:  state.endDate,
                        fmt:   _dateFmt,
                        onTap: () => _pickDate(context, false),
                      ),
                    ),
                    // Clear dates button — sirf tab dikhao jab dates set hon
                    if (state.startDate != null ||
                        state.endDate != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap:        notifier.clearDates,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColor.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColor.error.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: AppColor.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (state.filtered.isNotEmpty)
            Container(
              color:   Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  _SummaryCard(
                    label: 'Total Collected',
                    value: _fmt(state.totalCollected),
                    icon:  Icons.account_balance_wallet_outlined,
                    color: AppColor.primary,
                  ),
                  const SizedBox(width: 8),
                  _SummaryCard(
                    label: 'Filtered Total',
                    value: _fmt(state.totalPaid),
                    icon:  Icons.payments_outlined,
                    color: AppColor.success,
                  ),
                  const SizedBox(width: 8),
                  _SummaryCard(
                    label: 'Entries',
                    value: '${state.filtered.length}',
                    icon:  Icons.receipt_long_outlined,
                    color: AppColor.warning,
                  ),
                ],
              ),
            ),

          Container(height: 1, color: const Color(0xFFE5E7EB)),

          // Result count
          if (!state.isLoadingLedger && state.filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('${state.filtered.length} entry mili',
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textHint)),
                  // Active filter indicator
                  if (state.startDate != null ||
                      state.endDate != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_alt_rounded,
                              size: 12, color: AppColor.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${state.startDate != null ? _dateFmt.format(state.startDate!) : '?'}'
                                ' – '
                                '${state.endDate != null ? _dateFmt.format(state.endDate!) : '?'}',
                            style: const TextStyle(
                                fontSize: 11,
                                color:    AppColor.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            const SizedBox(height: 8),

          // ── Ledger List ─────────────────────────────────
          Expanded(
            child: state.isLoadingLedger
                ? const Center(child: CircularProgressIndicator())
                : state.filtered.isEmpty
                ? _EmptyState(
              message: state.selectedCustomer == null
                  ? 'Customer select karein'
                  : 'Koi entry nahi mili',
            )
                : RefreshIndicator(
              onRefresh: notifier.refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    16, 4, 16, 24),
                itemCount: state.filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (_, i) => _LedgerCard(
                  entry:  state.filtered[i],
                  fmtAmt: _fmt,
                  index:  state.filtered.length - i,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date Button Widget ─────────────────────────────────────
class _DateButton extends StatelessWidget {
  final String      label;
  final DateTime?   date;
  final DateFormat  fmt;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSet = date != null;
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSet
              ? AppColor.primary.withOpacity(0.07)
              : AppColor.grey100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSet ? AppColor.primary : AppColor.grey200,
            width: isSet ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size:  16,
                color: isSet
                    ? AppColor.primary
                    : AppColor.textHint),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:       MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: isSet
                              ? AppColor.primary
                              : AppColor.textHint)),
                  Text(
                    isSet ? fmt.format(date!) : 'Select',
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color: isSet
                            ? AppColor.primary
                            : AppColor.textSecondary),
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

// ── Ledger Card ────────────────────────────────────────────
class _LedgerCard extends StatelessWidget {
  final CustomerLedgerModel     entry;
  final String Function(double) fmtAmt;
  final int                     index;

  const _LedgerCard({
    required this.entry,
    required this.fmtAmt,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy  hh:mm a');

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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('#$index',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.primary)),
                ),
                const SizedBox(width: 8),

                // ✅ SIRF YEH BLOCK NAYA HAI — customer name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.customerName.isNotEmpty ? entry.customerName : '—',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D23)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateFmt.format(entry.createdAt.toLocal()),
                        style: const TextStyle(fontSize: 11, color: AppColor.textHint),
                      ),
                    ],
                  ),
                ),
                // ✅ DATE wali Text ab upar move ho gayi, yahan se hatao

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColor.success.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Paid: ${fmtAmt(entry.payAmount)}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.success),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Amounts
            Row(
              children: [
                _AmountTile(
                  label: 'Previous',
                  value: fmtAmt(entry.previousAmount),
                  color: AppColor.warning,
                ),
                const _Arrow(),
                _AmountTile(
                  label: 'Paid',
                  value: fmtAmt(entry.payAmount),
                  color: AppColor.success,
                ),
                const _Arrow(),
                _AmountTile(
                  label: 'Remaining',
                  value: fmtAmt(entry.newAmount),
                  color: entry.newAmount > 0
                      ? AppColor.error
                      : AppColor.success,
                ),
              ],
            ),

            // Notes
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.notes_rounded,
                    size: 13, color: AppColor.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(entry.notes!,
                      style: const TextStyle(
                          fontSize: 12,
                          color:    AppColor.textSecondary)),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _AmountTile(
      {required this.label,
        required this.value,
        required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value,
          style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w700,
              color:      color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 3),
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: AppColor.textHint)),
    ]),
  );
}

class _Arrow extends StatelessWidget {
  const _Arrow();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: Icon(Icons.arrow_forward_rounded,
        size: 14, color: AppColor.textHint),
  );
}

class _SummaryCard extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final Color    color;
  const _SummaryCard(
      {required this.label,
        required this.value,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(
          vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w800,
                  color:      color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: AppColor.textHint)),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.receipt_long_outlined,
          size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(message,
          style: TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.w600,
              color:      Colors.grey.shade500)),
    ]),
  );
}