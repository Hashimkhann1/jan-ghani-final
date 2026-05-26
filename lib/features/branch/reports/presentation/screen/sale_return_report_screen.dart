import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/provider/customer_provider.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/provider/auth_provider.dart';
import '../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../data/model/sale_return_report_model.dart';
import '../provider/sale_return_report_provider.dart';

class SaleReturnReportScreen extends ConsumerStatefulWidget {
  const SaleReturnReportScreen({super.key});

  @override
  ConsumerState<SaleReturnReportScreen> createState() => _SaleReturnScreenState();
}

class _SaleReturnScreenState extends ConsumerState<SaleReturnReportScreen> {
  final _searchCtrl    = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl   = TextEditingController();
  final _dateFmt       = DateFormat('dd MMM yyyy');
  final _timeFmt       = DateFormat('hh:mm a');
  final _inputFmt      = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(saleReturnProvider.notifier).load();
      _syncDateFields();
    });
  }

  void _syncDateFields() {
    final state = ref.read(saleReturnProvider);
    _startDateCtrl.text = _inputFmt.format(state.fromDate);
    _endDateCtrl.text   = _inputFmt.format(state.toDate);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime initial) =>
      showDatePicker(
        context:     context,
        initialDate: initial,
        firstDate:   DateTime(2024),
        lastDate:    DateTime.now().add(const Duration(days: 1)),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary:   AppColor.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        ),
      );

  Future<void> _onStartDateTap() async {
    final state  = ref.read(saleReturnProvider);
    final picked = await _pickDate(context, state.fromDate);
    if (picked != null) {
      _startDateCtrl.text = _inputFmt.format(picked);
      ref.read(saleReturnProvider.notifier).setDateRange(picked, state.toDate);
    }
  }

  Future<void> _onEndDateTap() async {
    final state  = ref.read(saleReturnProvider);
    final picked = await _pickDate(context, state.toDate);
    if (picked != null) {
      _endDateCtrl.text = _inputFmt.format(picked);
      ref.read(saleReturnProvider.notifier).setDateRange(state.fromDate, picked);
    }
  }

  Widget _dateField({
    required String                label,
    required TextEditingController ctrl,
    required VoidCallback          onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: SizedBox(
            width: 155,
            child: TextField(
              controller: ctrl,
              readOnly:   true,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText:  label,
                labelStyle: const TextStyle(
                    fontSize: 11, color: AppColor.textSecondary),
                prefixIcon: const Icon(Icons.calendar_today_rounded,
                    size: 15, color: AppColor.primary),
                filled:    true,
                fillColor: AppColor.grey100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:   BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                  const BorderSide(color: AppColor.primary, width: 1.2),
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(saleReturnProvider);
    final auth      = ref.watch(authProvider);
    final returns   = state.filteredReturns;
    final customers = ref.watch(customerProvider).allCustomers
        .where((c) => c.deletedAt == null && c.isActive)
        .toList();

    final customerItems = <DropdownItem<String?>>[
      const DropdownItem<String?>(
          value: null, label: 'All Customers',
          icon: Icons.people_outline_rounded),
      ...customers.map((c) => DropdownItem<String?>(
          value: c.id, label: c.name,
          icon: Icons.person_outline_rounded)),
    ];

    final cashierItems = <DropdownItem<String?>>[
      const DropdownItem<String?>(
          value: null, label: 'All Cashiers',
          icon: Icons.people_outline_rounded),
      ...state.cashiers.map((c) => DropdownItem<String?>(
          value: c.id, label: c.fullName,
          icon: Icons.person_outline_rounded)),
    ];

    ref.listen<SaleReturnState>(saleReturnProvider, (_, next) {
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
            onPressed: () =>
                ref.read(saleReturnProvider.notifier).clearError(),
          ),
        ));
      }
      _startDateCtrl.text = _inputFmt.format(next.fromDate);
      _endDateCtrl.text   = _inputFmt.format(next.toDate);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Sale Returns',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight:   60,
        backgroundColor: Colors.white,
        elevation:       0.5,
        actions: [
          IconButton(
            onPressed: () => ref.read(saleReturnProvider.notifier).load(),
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Stat Cards ──────────────────────────
            if (state.isCustomerSelected) ...[
              _CustomerReturnBanner(state: state),
            ] else ...[
              Row(
                children: [
                  SummaryCard(
                    title: 'Total Returns',
                    value: '${state.totalCount}',
                    icon:  Icons.assignment_return_outlined,
                    color: AppColor.error,
                  ),
                  const SizedBox(width: 12),
                  SummaryCard(
                    title: 'Total Refund',
                    value: 'Rs ${state.totalGrand.toStringAsFixed(0)}',
                    icon:  Icons.currency_exchange_outlined,
                    color: AppColor.warning,
                  ),
                  const SizedBox(width: 12),
                  SummaryCard(
                    title: 'Total Discount',
                    value: 'Rs ${state.totalDiscount.toStringAsFixed(0)}',
                    icon:  Icons.discount_outlined,
                    color: AppColor.success,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // ── Filters ──────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [

                  // Search
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged:  ref
                          .read(saleReturnProvider.notifier)
                          .onSearchChanged,
                      style:        const TextStyle(fontSize: 13),
                      cursorHeight: 14,
                      decoration: InputDecoration(
                        hintText: 'Search return, customer...',
                        hintStyle: const TextStyle(
                            color: AppColor.textHint, fontSize: 12),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: AppColor.grey400),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: 16, color: AppColor.grey400),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref
                                .read(saleReturnProvider.notifier)
                                .onSearchChanged('');
                          },
                        )
                            : null,
                        filled:    true,
                        fillColor: AppColor.grey100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:   BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Customer Dropdown
                  AppSearchableDropdown<String?>(
                    hint:         'All Customers',
                    prefixIcon:   Icons.person_search_outlined,
                    desktopWidth: 200,
                    value:        state.selectedCustomerId,
                    items:        customerItems,
                    onChanged: (id) {
                      final customer = id != null
                          ? customers
                          .where((c) => c.id == id)
                          .firstOrNull
                          : null;
                      ref
                          .read(saleReturnProvider.notifier)
                          .selectCustomer(id, customer?.name);
                    },
                  ),
                  const SizedBox(width: 12),

                  // Manager: Cashier Dropdown
                  if (auth.isManager) ...[
                    state.isCashiersLoading
                        ? const SizedBox(
                      width: 42, height: 42,
                      child: Center(
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                      ),
                    )
                        : AppSearchableDropdown<String?>(
                      hint:         'All Cashiers',
                      prefixIcon:   Icons.badge_outlined,
                      desktopWidth: 200,
                      value:        state.selectedCashierId,
                      items:        cashierItems,
                      onChanged: (id) => ref
                          .read(saleReturnProvider.notifier)
                          .selectCashier(id),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Today Button
                  IntrinsicWidth(
                    child: OutlinedButton.icon(
                      onPressed: () => ref
                          .read(saleReturnProvider.notifier)
                          .setToday(),
                      icon:  const Icon(Icons.today_rounded, size: 16),
                      label: const Text('Today',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.primary,
                        side: const BorderSide(color: AppColor.primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Start Date
                  _dateField(
                    label: 'Start Date',
                    ctrl:  _startDateCtrl,
                    onTap: _onStartDateTap,
                  ),
                  const SizedBox(width: 8),
                  const Text('—',
                      style: TextStyle(
                          color:      AppColor.textSecondary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),

                  // End Date
                  _dateField(
                    label: 'End Date',
                    ctrl:  _endDateCtrl,
                    onTap: _onEndDateTap,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Return List ──────────────────────────
            Expanded(
              child: returns.isEmpty
                  ? _EmptyReturnState(
                  isSearching: state.searchQuery.isNotEmpty ||
                      state.isCustomerSelected)
                  : ListView.separated(
                itemCount:        returns.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
                itemBuilder: (_, i) => _ReturnCard(
                  ret:       returns[i],
                  dateFmt:   _dateFmt,
                  timeFmt:   _timeFmt,
                  isManager: auth.isManager,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Customer Return Banner
// ══════════════════════════════════════════════════════════════
class _CustomerReturnBanner extends StatelessWidget {
  final SaleReturnState state;
  const _CustomerReturnBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:  AppColor.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColor.error.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_pin_outlined,
                  size: 16, color: AppColor.error),
              const SizedBox(width: 8),
              Text(
                state.selectedCustomerName ?? 'Selected Customer',
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      AppColor.error),
              ),
              const Spacer(),
              Text('${state.customerReturnCount} returns',
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SummaryCard(
              title: 'Total Refund',
              value: 'Rs ${state.customerTotalRefund.toStringAsFixed(0)}',
              icon:  Icons.currency_exchange_outlined,
              color: AppColor.error,
            ),
            const SizedBox(width: 12),
            SummaryCard(
              title: 'Cash Refund',
              value: 'Rs ${state.customerCashRefund.toStringAsFixed(0)}',
              icon:  Icons.money_outlined,
              color: AppColor.success,
            ),
            const SizedBox(width: 12),
            SummaryCard(
              title: 'Credit Refund',
              value: 'Rs ${state.customerCreditRefund.toStringAsFixed(0)}',
              icon:  Icons.credit_card_outlined,
              color: AppColor.warning,
            ),
            const SizedBox(width: 12),
            SummaryCard(
              title: 'Discount',
              value: 'Rs ${state.customerTotalDiscount.toStringAsFixed(0)}',
              icon:  Icons.discount_outlined,
              color: AppColor.info,
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Return Card
// ══════════════════════════════════════════════════════════════
class _ReturnCard extends StatelessWidget {
  final SaleReturnModel ret;
  final DateFormat      dateFmt;
  final DateFormat      timeFmt;
  final bool            isManager;

  const _ReturnCard({
    required this.ret,
    required this.dateFmt,
    required this.timeFmt,
    required this.isManager,
  });

  @override
  Widget build(BuildContext context) {
    final double subtotal =
    ret.items.fold(0.0, (s, i) => s + i.totalAmount);

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [

          // ── Header ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColor.error.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(
                    color: AppColor.grey300.withValues(alpha: 0.6)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_return_outlined,
                    size: 15, color: AppColor.error),
                const SizedBox(width: 6),
                Text(ret.returnNo,
                    style: const TextStyle(
                        fontSize:      13,
                        fontWeight:    FontWeight.w800,
                        color:         AppColor.error,
                        letterSpacing: 0.3)),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(dateFmt.format(ret.returnDate),
                        style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textPrimary)),
                    Text(timeFmt.format(ret.returnDate),
                        style: const TextStyle(
                            fontSize: 11,
                            color:    AppColor.textSecondary)),
                  ],
                ),
              ],
            ),
          ),

          // ── Customer + Refund type ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 13, color: AppColor.textSecondary),
                const SizedBox(width: 5),
                Text(
                  ret.customerName ?? 'Walk In',
                  style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color:      ret.customerName != null
                          ? AppColor.textPrimary
                          : AppColor.textSecondary),
                ),
                const Spacer(),
                _RefundBadge(type: ret.refundType),
              ],
            ),
          ),

          // ── Return Reason ────────────────────────────────
          if (ret.returnReason != null &&
              ret.returnReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 13, color: AppColor.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Reason: ',
                      style: TextStyle(
                          fontSize: 12,
                          color:    AppColor.textSecondary)),
                  Expanded(
                    child: Text(ret.returnReason!,
                        style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w500,
                            color:      AppColor.textPrimary),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),

          if (ret.counterName != null)
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.point_of_sale_outlined,
                      size: 13, color: AppColor.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Counter: ',
                      style: TextStyle(
                          fontSize: 12,
                          color:    AppColor.textSecondary)),
                  _CounterChip(name: ret.counterName!),
                ],
              ),
            ),

          if (isManager && ret.cashierName != null)
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined,
                      size: 13, color: AppColor.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Cashier: ',
                      style: TextStyle(
                          fontSize: 12,
                          color:    AppColor.textSecondary)),
                  _CashierChip(name: ret.cashierName!),
                ],
              ),
            ),

          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ── Items Table ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                      color:        AppColor.grey100,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Expanded(
                          flex: 4,
                          child: Text('Product',
                              style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColor.textSecondary))),
                      Expanded(
                          flex: 2,
                          child: Text('Price',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColor.textSecondary))),
                      Expanded(
                          flex: 1,
                          child: Text('Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColor.textSecondary))),
                      Expanded(
                          flex: 2,
                          child: Text('Discount',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColor.textSecondary))),
                      Expanded(
                          flex: 2,
                          child: Text('Sub Total',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColor.textSecondary))),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Table rows
                ...ret.items.asMap().entries.map((entry) {
                  final idx  = entry.key;
                  final item = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: idx % 2 != 0
                          ? AppColor.grey100.withValues(alpha: 0.5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Container(
                                width: 5, height: 5,
                                decoration: BoxDecoration(
                                  color: AppColor.error
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(item.productName,
                                    style: const TextStyle(
                                        fontSize:   12,
                                        fontWeight: FontWeight.w500,
                                        color:      AppColor.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                            flex: 2,
                            child: Text(item.priceLabel,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color:    AppColor.textPrimary))),
                        Expanded(
                            flex: 1,
                            child: Text(item.qtyLabel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize:   11,
                                    fontWeight: FontWeight.w600,
                                    color:      AppColor.textPrimary))),
                        Expanded(
                            flex: 2,
                            child: Text(
                                'Rs ${item.discount.toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color:    AppColor.warning))),
                        Expanded(
                            flex: 2,
                            child: Text(item.totalLabel,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize:   11,
                                    fontWeight: FontWeight.w700,
                                    color:      AppColor.error))),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 10),

                _TotalRow(
                  label:      'Sub Total',
                  value:      'Rs ${subtotal.toStringAsFixed(0)}',
                  valueColor: AppColor.textPrimary,
                ),

                if (ret.totalDiscount > 0) ...[
                  const SizedBox(height: 4),
                  _TotalRow(
                    label:      'Discount',
                    value:      ret.discountLabel,
                    valueColor: AppColor.warning,
                  ),
                ],

                const SizedBox(height: 10),

                // Grand total row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColor.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColor.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatusBadge(status: ret.status),
                      Row(
                        children: [
                          const Text('Refund Amount:',
                              style: TextStyle(
                                  fontSize:   12,
                                  fontWeight: FontWeight.w600,
                                  color:      AppColor.textSecondary)),
                          const SizedBox(width: 10),
                          Text(ret.grandTotalLabel,
                              style: const TextStyle(
                                  fontSize:   15,
                                  fontWeight: FontWeight.w800,
                                  color:      AppColor.error)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Helper Widgets
// ══════════════════════════════════════════════════════════════

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;
  const _TotalRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text('$label:',
          style: const TextStyle(
              fontSize: 12, color: AppColor.textSecondary)),
      const SizedBox(width: 12),
      SizedBox(
        width: 110,
        child: Text(value,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      valueColor)),
      ),
    ],
  );
}

class _RefundBadge extends StatelessWidget {
  final String type;
  const _RefundBadge({required this.type});

  Color    get _color => const {'cash': AppColor.success, 'card': AppColor.info,    'credit': AppColor.warning}[type] ?? AppColor.grey400;
  IconData get _icon  => const {'cash': Icons.payments_outlined, 'card': Icons.credit_card_outlined, 'credit': Icons.person_outline_rounded}[type] ?? Icons.help_outline;
  String   get _label => const {'cash': 'Cash Refund', 'card': 'Card Refund', 'credit': 'Credit Refund'}[type] ?? type;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color:        _color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: _color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 11, color: _color),
        const SizedBox(width: 4),
        Text(_label,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      _color)),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color    get _color => const {'completed': AppColor.success, 'cancelled': AppColor.error}[status] ?? AppColor.grey400;
  IconData get _icon  => const {'completed': Icons.check_circle_outline_rounded, 'cancelled': Icons.cancel_outlined}[status] ?? Icons.help_outline;
  String   get _label => const {'completed': 'Completed', 'cancelled': 'Cancelled'}[status] ?? status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color:        _color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 12, color: _color),
        const SizedBox(width: 4),
        Text(_label,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      _color)),
      ],
    ),
  );
}

class _CounterChip extends StatelessWidget {
  final String name;
  const _CounterChip({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        AppColor.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.point_of_sale_outlined,
            size: 11, color: AppColor.primary),
        const SizedBox(width: 4),
        Text(name,
            style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      AppColor.primary)),
      ],
    ),
  );
}

class _CashierChip extends StatelessWidget {
  final String name;
  const _CashierChip({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        AppColor.info.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.badge_outlined, size: 11, color: AppColor.info),
        const SizedBox(width: 4),
        Text(name,
            style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      AppColor.info)),
      ],
    ),
  );
}

class _EmptyReturnState extends StatelessWidget {
  final bool isSearching;
  const _EmptyReturnState({this.isSearching = false});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSearching
              ? Icons.search_off_rounded
              : Icons.assignment_return_outlined,
          size:  64,
          color: AppColor.grey300,
        ),
        const SizedBox(height: 16),
        Text(
          isSearching ? 'Koi return nahi mila' : 'Koi return nahi',
          style: const TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      AppColor.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          isSearching
              ? 'Filter change karein'
              : 'Returns ke baad yahan dikhega',
          style: const TextStyle(
              fontSize: 13, color: AppColor.textHint),
        ),
      ],
    ),
  );
}