import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/core/widget/pagination_bar.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';
import 'package:jan_ghani_final/features/branch/customer_ledger/data/model/customer_ledger_model.dart';
import 'package:jan_ghani_final/features/branch/customer_ledger/presentation/provider/customer_ledger_provider.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../customer/presentation/widget/customer_action_button_widget.dart';
import '../../../permissions/presentation/provider/permissions_provider.dart';
import '../widget/add_ledger_dialog.dart';
import '../widget/amount_badge_widget.dart';
import '../widget/counter_chip_widget.dart';
import '../widget/customer_call_widget.dart';

class CounterCustomerLedgerScreen extends ConsumerStatefulWidget {
  const CounterCustomerLedgerScreen({super.key});

  @override
  ConsumerState<CounterCustomerLedgerScreen> createState() => _CounterCustomerLedgerScreenState();
}

class _CounterCustomerLedgerScreenState
    extends ConsumerState<CounterCustomerLedgerScreen> {

  static final _dateFmt = DateFormat('dd MMM yyyy');

  // Persistent controller — search field ab poore build() ke tabdeel hote
  // hue bhi apni text/focus save rakhta hai (pehle controller na hone ki
  // wajah se, jab isLoading spinner body ko replace karta tha, field
  // dobara ban'ta tha aur typed text + focus dono gayab ho jate thay).
  final _searchCtrl = TextEditingController();

  // Full-page spinner sirf pehli dafa load hone tak — uske baad (jese
  // search/filter change par) chhota inline loading bar dikhta hai taake
  // search field mount hi rahe.
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerLedgerProvider.notifier).loadLedgers();
      ref.read(counterProvider.notifier).loadCounters();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Edit Dialog ───────────────────────────────────────────
  void _openEditDialog(BuildContext context, CustomerLedgerModel ledger) {
    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (_) => AddLedgerDialog(ledger: ledger),
    );
  }

  void _showFullNote(BuildContext context, String note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(note, style: const TextStyle(fontSize: 13, color: AppColor.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Delete Dialog ─────────────────────────────────────────
  void _confirmDelete(BuildContext context, CustomerLedgerModel ledger) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Record Delete Karein?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('"${ledger.customerName}" ka record delete karna chahte hain?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error,
                foregroundColor: Colors.white,
                elevation:       0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              ref.read(customerLedgerProvider.notifier).deleteLedger(ledger.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromDate(BuildContext context, DateTime? current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(customerLedgerProvider.notifier).setFromDate(picked);
    }
  }

  Future<void> _pickToDate(BuildContext context, DateTime? current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(customerLedgerProvider.notifier).setToDate(picked);
    }
  }

  Widget _dateFilterField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Expanded(
      child: TextField(
        readOnly: true,
        onTap: onTap,
        controller: TextEditingController(
          text: value != null ? _dateFmt.format(value) : '',
        ),
        style: const TextStyle(fontSize: 13, color: AppColor.textSecondary),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
          prefixIcon: const AppIcon('ic_calendar', size: 16, color: AppColor.grey400),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          suffixIcon: value != null
              ? InkWell(
            onTap: onClear,
            child: const Icon(Icons.close, size: 16, color: AppColor.grey400),
          )
              : null,
          filled: true,
          fillColor: AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerLedgerProvider);
    final auth = ref.watch(authProvider);
    final perms = ref.watch(permissionsProvider);
    final canEdit   = perms.isGranted(auth.userId, auth.role, 'customer_ledger.edit');
    final canDelete = perms.isGranted(auth.userId, auth.role, 'customer_ledger.delete');
    final counters = ref.watch(counterProvider).counters;
    final fmt = DateFormat('dd MMM yyyy  hh:mm a');
    final notifier = ref.read(customerLedgerProvider.notifier);

    // Counter + date + search filter ab DB query karti hai — yeh sirf
    // current page hai.
    final ledgers = state.filteredLedgers;

    final counterName = auth.counterId != null ? counters.where((c) => c.id == auth.counterId).map((c) => c.counterName).firstOrNull ?? 'Counter' : 'Counter';

    final totalPaid = state.totalPaid;

    ref.listen<CustomerLedgerState>(customerLedgerProvider, (prev, next) {
      if (!next.isLoading) _hasLoadedOnce = true;

      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        title: Text('$counterName — Ledger', style: const TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(customerLedgerProvider.notifier).loadLedgers(),
            icon:    const AppIcon('ic_refresh', size: 20, color: AppColor.textSecondary),
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
                icon:  const AppIcon('ic_plus_new', size: 18, color: Colors.white),
                label: const Text('New Payment',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: (state.isLoading && !_hasLoadedOnce)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Inline loading bar (search/filter refetch) — search field ko
            // mounted/focused rehne deta hai, full spinner ki tarah destroy
            // nahi karta.
            SizedBox(
              height: 2,
              child: state.isLoading
                  ? const LinearProgressIndicator(minHeight: 2)
                  : null,
            ),
            const SizedBox(height: 6),

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
                    Text('No counter assigned to you',
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
                  value: '${state.totalCount}',
                  iconAsset: 'ic_credit_sale',
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Total Paid',
                  value: 'Rs ${totalPaid.toStringAsFixed(0)}',
                  iconAsset: 'ic_cash_in',
                  color: AppColor.success,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Search + Date Filter ──────────────────
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: notifier.onSearchChanged,
                    style: const TextStyle(fontSize: 13),
                    cursorHeight: 14,
                    decoration: InputDecoration(
                      hintText: 'Search by customer...',
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
                _dateFilterField(
                  label: 'From Date',
                  value: state.fromDate,
                  onTap: () => _pickFromDate(context, state.fromDate),
                  onClear: () => notifier.setFromDate(null),
                ),
                _dateFilterField(
                  label: 'To Date',
                  value: state.toDate,
                  onTap: () => _pickToDate(context, state.toDate),
                  onClear: () => notifier.setToDate(null),
                ),
                if (!state.isDefaultDateRange)
                  TextButton.icon(
                    onPressed: notifier.clearDateFilter,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: const Text('Clear Filter'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColor.error,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Table ─────────────────────────────────
            Expanded(
              child: ledgers.isEmpty ?
              _EmptyState(
                isSearching: state.searchQuery.isNotEmpty,
                noCounterAssigned: auth.counterId == null,
              ) :
              Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  const double minTableWidth = 1050;
                  final tableWidth =
                  availableWidth > minTableWidth ? availableWidth : minTableWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: tableWidth),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColor.grey100),
                          dataRowColor: WidgetStateProperty.resolveWith<Color?>((s) => s.contains(WidgetState.hovered) ? AppColor.primary.withValues(alpha: 0.05) : null,
                          ),
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 52,
                          columnSpacing: (tableWidth * 0.03).clamp(16.0, 50.0),
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('Customer')),
                            DataColumn(label: Text('User')),
                            DataColumn(label: Text('Previous')),
                            DataColumn(label: Text('Paid')),
                            DataColumn(label: Text('Remaining')),
                            DataColumn(label: Text('Notes')),
                            DataColumn(label: Text('Date & Time')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: ledgers.map((l) {
                            final userName = l.userFullName;

                            return DataRow(
                              cells: [
                                DataCell(CustomerCell(l: l)),

                                DataCell(CounterChip(counterName: userName)),

                                DataCell(AmountBadge(amount: l.previousAmount, color: AppColor.grey500)),

                                DataCell(AmountBadge(amount: l.payAmount, color: AppColor.success)),

                                DataCell(AmountBadge(
                                  amount: l.newAmount,
                                  color: l.newAmount > 0 ? AppColor.error : l.newAmount < 0 ? AppColor.info : AppColor.success,
                                )),

                                // ── Notes: tap to view full text in a dialog (reliable across web/touch) ──
                                DataCell(SizedBox(
                                  width: 220,
                                  child: InkWell(
                                    onTap: (l.notes == null || l.notes!.isEmpty)
                                        ? null
                                        : () => _showFullNote(context, l.notes!),
                                    child: Tooltip(
                                      message: l.notes ?? '',
                                      waitDuration: const Duration(milliseconds: 400),
                                      child: Text(
                                        l.notes ?? '—',
                                        style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                )),

                                DataCell(Text(
                                  fmt.format(l.createdAt),
                                  style: const TextStyle(fontSize: 11, color: AppColor.textSecondary),
                                )),

                                // Actions
                                DataCell(Row(
                                  children: [
                                    // Edit — sirf 'customer_ledger.edit' grant hone par
                                    if (canEdit) ...[
                                      CustomerActionButton(
                                        icon: Icons.edit_outlined,
                                        color: AppColor.primary,
                                        tooltip: 'Edit',
                                        onTap: () => _openEditDialog(context, l),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    // Delete — sirf 'customer_ledger.delete' grant hone par
                                    if (canDelete)
                                      CustomerActionButton(
                                        icon: Icons.delete_outline_rounded,
                                        color: AppColor.error,
                                        tooltip: 'Delete',
                                        onTap: () => _confirmDelete(context, l),
                                      ),
                                  ],
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
                    total: state.totalCount,
                    page:  state.page,
                    onPageChanged: notifier.setPage,
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
              ? 'No counter assigned'
              : isSearching
              ? 'No record found'
              : 'No payment record yet',
          style: const TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      AppColor.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          noCounterAssigned
              ? 'Ask admin to assign a counter'
              : isSearching
              ? 'Try changing your search query'
              : 'Add a record using the New Payment button',
          style: const TextStyle(
              fontSize: 13, color: AppColor.textHint),
        ),
      ],
    ),
  );
}