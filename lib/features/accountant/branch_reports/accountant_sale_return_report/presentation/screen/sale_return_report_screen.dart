import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../../common/pagination/branch_report_pagination_controls.dart';
import '../../data/model/sale_return_report_model.dart';
import '../provider/sale_return_report_provider.dart';

/// ── Responsive breakpoint ──
const double _kWideBreakpoint = 900;

class AccountantSaleReturnReportScreen extends ConsumerStatefulWidget {
  const AccountantSaleReturnReportScreen(
      {super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<AccountantSaleReturnReportScreen> createState() =>
      _AccountantSaleReturnReportScreenState();
}

class _AccountantSaleReturnReportScreenState
    extends ConsumerState<AccountantSaleReturnReportScreen> {
  final _dateFmt  = DateFormat('dd MMM yyyy');
  final _timeFmt  = DateFormat('hh:mm a');
  final _amtFmt   = NumberFormat('#,##,###', 'en_IN');
  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();

  String? _selectedId;

  @override
  void initState() {
    super.initState();
    final state = ref.read(accountantSaleReturnProvider(widget.branchId));
    _fromCtrl.text = _dateFmt.format(state.fromDate);
    _toCtrl.text   = _dateFmt.format(state.toDate);
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  String _fmtAmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';
  String _fmtQty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  SaleReturnInvoice? _findById(List<SaleReturnInvoice> list, String? id) {
    if (id == null) return null;
    for (final ret in list) {
      if (ret.id == id) return ret;
    }
    return null;
  }

  Color _refundColor(String? refundType) {
    switch (refundType) {
      case 'card':   return AppColor.info;
      case 'credit': return AppColor.warning;
      default:       return AppColor.success;
    }
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final state = ref.read(accountantSaleReturnProvider(widget.branchId));
    final init  = isFrom ? state.fromDate : state.toDate;

    final picked = await showDatePicker(
      context:     context,
      initialDate: init,
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
          const ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final notifier =
      ref.read(accountantSaleReturnProvider(widget.branchId).notifier);
      if (isFrom) {
        _fromCtrl.text = _dateFmt.format(picked);
        notifier.setFromDate(picked);
      } else {
        _toCtrl.text = _dateFmt.format(picked);
        notifier.setToDate(picked);
      }
    }
  }

  void _setToday(dynamic notifier) {
    notifier.setToday();
    final today      = DateTime.now();
    final todayClean = DateTime(today.year, today.month, today.day);
    _fromCtrl.text   = _dateFmt.format(todayClean);
    _toCtrl.text     = _dateFmt.format(todayClean);
  }

  // ── Filter Bottom Sheet (narrow screens) ────────────────────────────────
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context:              context,
      isScrollControlled:   true,
      backgroundColor:      Colors.transparent,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(
                      accountantSaleReturnProvider(widget.branchId));
                  final notifier = ref.read(
                      accountantSaleReturnProvider(widget.branchId)
                          .notifier);

                  final customerItems = [
                    DropdownItem<String?>(
                      value: null,
                      label: 'All Customers',
                      icon:  Icons.people_outline_rounded,
                    ),
                    ...state.customers.map((c) => DropdownItem<String?>(
                      value: c.id,
                      label: c.label,
                      icon:  Icons.person_outline_rounded,
                    )),
                  ];

                  final refundItems = [
                    DropdownItem<String?>(
                        value: null,
                        label: 'All Refund Types',
                        icon:  Icons.swap_horiz_rounded),
                    DropdownItem<String?>(
                        value: 'cash',
                        label: 'Cash',
                        icon:  Icons.payments_outlined),
                    DropdownItem<String?>(
                        value: 'card',
                        label: 'Card',
                        icon:  Icons.credit_card_outlined),
                    DropdownItem<String?>(
                        value: 'credit',
                        label: 'Credit',
                        icon:  Icons.receipt_long_outlined),
                  ];

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Handle bar
                        Center(
                          child: Container(
                            width:  40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                        // Header
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Filters',
                              style: TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.w700,
                                color:      Color(0xFF1A1D23),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                notifier.setCustomer(null);
                                notifier.setRefundType(null);
                                _setToday(notifier);
                              },
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Date fields
                        Row(
                          children: [
                            Expanded(
                              child: _DateField(
                                label:      'Start Date',
                                controller: _fromCtrl,
                                onTap:      () => _pickDate(context, true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DateField(
                                label:      'End Date',
                                controller: _toCtrl,
                                onTap:      () => _pickDate(context, false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Customer dropdown
                        const Text(
                          'Customer',
                          style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AppSearchableDropdown<String?>(
                          items:      customerItems,
                          value:      state.selectedCustomerId,
                          hint:       'All Customers',
                          fullWidth:  true,
                          prefixIcon: Icons.person_outline_rounded,
                          onChanged:  (v) => notifier.setCustomer(v),
                        ),
                        const SizedBox(height: 14),

                        // Refund type dropdown
                        const Text(
                          'Refund Type',
                          style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AppSearchableDropdown<String?>(
                          items:      refundItems,
                          value:      state.selectedRefundType,
                          hint:       'All Refund Types',
                          fullWidth:  true,
                          prefixIcon: Icons.swap_horiz_rounded,
                          onChanged:  (v) => notifier.setRefundType(v),
                        ),
                        const SizedBox(height: 20),

                        // Apply button
                        SizedBox(
                          width:  double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(sheetCtx),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontSize:   14,
                                fontWeight: FontWeight.w700,
                                color:      Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ── View return (bottom sheet) ──────────────────────────────────────────
  void _showReturnSheet(SaleReturnInvoice ret) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize:     0.5,
        maxChildSize:     0.95,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F6FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Return Details',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1D23)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _ReturnDetailPanel(
                    ret:     ret,
                    dateFmt: _dateFmt,
                    timeFmt: _timeFmt,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(accountantSaleReturnProvider(widget.branchId));
    final notifier =
    ref.read(accountantSaleReturnProvider(widget.branchId).notifier);
    final summary  = state.summary;

    // Clear the detail-panel selection if it's no longer in the current
    // list (filters, pagination, refresh) — never auto-pick a row; the
    // panel stays empty until the user explicitly clicks "view".
    if (_selectedId != null &&
        !state.returns.any((r) => r.id == _selectedId)) {
      _selectedId = null;
    }
    final selectedReturn = _findById(state.returns, _selectedId);

    final bool hasActiveFilter =
        state.selectedCustomerId != null || state.selectedRefundType != null;

    ref.listen<AccountantSaleReturnState>(
        accountantSaleReturnProvider(widget.branchId), (_, next) {
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
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Sale Return Report',
          style: TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.w700,
            color:      Color(0xFF1A1D23),
          ),
        ),
        actions: [
          Builder(builder: (context) {
            final isWide = MediaQuery.of(context).size.width >= _kWideBreakpoint;
            if (isWide) return const SizedBox.shrink();
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => _showFilterSheet(context),
                  icon: const Icon(Icons.filter_alt_outlined, color: AppColor.textSecondary),
                  tooltip: 'Filters',
                ),
                if (hasActiveFilter)
                  Positioned(
                    right: 8,
                    top:   8,
                    child: Container(
                      width:  8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColor.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          }),
          IconButton(
            onPressed: notifier.load,
            icon:    const Icon(Icons.refresh_rounded, color: AppColor.textSecondary),
            tooltip: 'Refresh',
          ),
          TextButton(
            onPressed: () => _setToday(notifier),
            child: const Text('Today'),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
          Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _kWideBreakpoint;

          final customerItems = [
            DropdownItem<String?>(
              value: null,
              label: 'All Customers',
              icon:  Icons.people_outline_rounded,
            ),
            ...state.customers.map((c) => DropdownItem<String?>(
              value: c.id,
              label: c.label,
              icon:  Icons.person_outline_rounded,
            )),
          ];

          final refundItems = [
            DropdownItem<String?>(
                value: null,
                label: 'All Refund Types',
                icon:  Icons.swap_horiz_rounded),
            DropdownItem<String?>(
                value: 'cash',
                label: 'Cash',
                icon:  Icons.payments_outlined),
            DropdownItem<String?>(
                value: 'card',
                label: 'Card',
                icon:  Icons.credit_card_outlined),
            DropdownItem<String?>(
                value: 'credit',
                label: 'Credit',
                icon:  Icons.receipt_long_outlined),
          ];

          return Column(
            children: [
              if (isWide)
                Container(
                  color:   Colors.white,
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label:      'Start Date',
                          controller: _fromCtrl,
                          onTap:      () => _pickDate(context, true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label:      'End Date',
                          controller: _toCtrl,
                          onTap:      () => _pickDate(context, false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppSearchableDropdown<String?>(
                          items:      customerItems,
                          value:      state.selectedCustomerId,
                          hint:       'All Customers',
                          fullWidth:  true,
                          prefixIcon: Icons.person_outline_rounded,
                          onChanged:  (v) => notifier.setCustomer(v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppSearchableDropdown<String?>(
                          items:      refundItems,
                          value:      state.selectedRefundType,
                          hint:       'All Refund Types',
                          fullWidth:  true,
                          prefixIcon: Icons.swap_horiz_rounded,
                          onChanged:  (v) => notifier.setRefundType(v),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Summary Cards ─────────────────────────────────────────
              Container(
                width:   double.infinity,
                color:   Colors.white,
                padding: EdgeInsets.fromLTRB(
                    isWide ? 28 : 12, isWide ? 0 : 12, isWide ? 28 : 12, isWide ? 16 : 12),
                child: Row(
                  children: [
                    _SummaryCard(
                      label: 'Returns',
                      value: '${summary.totalReturns}',
                      icon:  Icons.assignment_return_outlined,
                      color: AppColor.error,
                    ),
                    const SizedBox(width: 10),
                    _SummaryCard(
                      label: 'Total Return',
                      value: _fmtAmt(summary.totalAmount),
                      icon:  Icons.payments_outlined,
                      color: AppColor.warning,
                    ),
                    const SizedBox(width: 10),
                    _SummaryCard(
                      label: 'Qty',
                      value: _fmtQty(summary.totalQuantity),
                      icon:  Icons.inventory_2_outlined,
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 10),
                    _SummaryCard(
                      label: 'Discount',
                      value: _fmtAmt(summary.totalDiscount),
                      icon:  Icons.discount_outlined,
                      color: AppColor.success,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // ── List / Table ───────────────────────────────────────────
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColor.error))
                    : state.returns.isEmpty
                    ? const _EmptyState()
                    : isWide
                    ? _WideReturnContent(
                  returns:        state.returns,
                  notifier:       notifier,
                  dateFmt:        _dateFmt,
                  timeFmt:        _timeFmt,
                  refundColor:    _refundColor,
                  selectedId:     _selectedId,
                  selectedReturn: selectedReturn,
                  onSelect:       (id) => setState(() => _selectedId = id),
                )
                    : RefreshIndicator(
                  color: AppColor.error,
                  onRefresh: notifier.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        16, 12, 16, 24),
                    itemCount:        state.returns.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ReturnRow(
                      ret:     state.returns[i],
                      dateFmt: _dateFmt,
                      timeFmt: _timeFmt,
                      refundColor: _refundColor(state.returns[i].refundType),
                      onView:  () => _showReturnSheet(state.returns[i]),
                    ),
                  ),
                ),
              ),
              if (!state.isLoading && state.returns.isNotEmpty)
                BranchReportPaginationControls(
                  page:        state.pagination.page,
                  hasNextPage: state.pagination.hasNextPage,
                  isLoading:   state.pagination.isLoadingPage,
                  onNext:      notifier.nextPage,
                  onPrevious:  notifier.previousPage,
                ),
            ],
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Wide layout content — return table + right-side detail panel
// ══════════════════════════════════════════════════════════════════════════════
class _WideReturnContent extends StatelessWidget {
  final List<SaleReturnInvoice> returns;
  final dynamic                 notifier;
  final DateFormat              dateFmt;
  final DateFormat              timeFmt;
  final Color Function(String?) refundColor;
  final String?                 selectedId;
  final SaleReturnInvoice?      selectedReturn;
  final ValueChanged<String?>   onSelect;

  const _WideReturnContent({
    required this.returns,
    required this.notifier,
    required this.dateFmt,
    required this.timeFmt,
    required this.refundColor,
    required this.selectedId,
    required this.selectedReturn,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColor.error,
            onRefresh: notifier.load,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _ReturnTable(
                returns:     returns,
                dateFmt:     dateFmt,
                timeFmt:     timeFmt,
                refundColor: refundColor,
                selectedId:  selectedId,
                onSelect:    onSelect,
              ),
            ),
          ),
        ),
        if (selectedReturn != null) ...[
          Container(width: 1, color: const Color(0xFFEEEEEE)),
          SizedBox(
            width: 400,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _ReturnDetailPanel(
                    ret:     selectedReturn,
                    dateFmt: dateFmt,
                    timeFmt: timeFmt,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => onSelect(null),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColor.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Return table (card-style, not a raw DataTable) — used on wide screens
// ══════════════════════════════════════════════════════════════════════════════
class _ReturnTable extends StatelessWidget {
  final List<SaleReturnInvoice> returns;
  final DateFormat              dateFmt;
  final DateFormat              timeFmt;
  final Color Function(String?) refundColor;
  final String?                 selectedId;
  final ValueChanged<String?>   onSelect;

  const _ReturnTable({
    required this.returns,
    required this.dateFmt,
    required this.timeFmt,
    required this.refundColor,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color:   const Color(0xFFF5F6FA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Expanded(flex: 2, child: _IH(text: 'Return No')),
                Expanded(flex: 3, child: _IH(text: 'Customer')),
                Expanded(flex: 3, child: _IH(text: 'Date / Time')),
                Expanded(flex: 2, child: _IH(text: 'Refund')),
                Expanded(flex: 1, child: _IH(text: 'Items', center: true)),
                Expanded(flex: 2, child: _IH(text: 'Grand Total', right: true)),
                SizedBox(width: 44),
              ],
            ),
          ),
          ...returns.map((ret) {
            final isSelected = ret.id == selectedId;
            final rColor     = refundColor(ret.refundType);
            return InkWell(
              onTap: () => onSelect(ret.id),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.error.withOpacity(0.06)
                      : Colors.white,
                  border: const Border(
                      top: BorderSide(color: Color(0xFFF1F2F5))),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(ret.returnNo,
                          style: const TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w700,
                              color:      AppColor.error)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(ret.customerLabel,
                          style: const TextStyle(
                              fontSize: 13, color: AppColor.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${dateFmt.format(ret.returnDate)}, ${timeFmt.format(ret.returnDate)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColor.textSecondary),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _PayBadge(label: ret.paymentLabel, color: rColor),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text('${ret.items.length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: AppColor.textSecondary)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Rs ${ret.grandTotal.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1D23)),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: IconButton(
                        icon: Icon(
                          Icons.visibility_outlined,
                          size:  18,
                          color: isSelected
                              ? AppColor.error
                              : AppColor.textSecondary,
                        ),
                        tooltip: 'View return',
                        onPressed: () => onSelect(ret.id),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Summary Card
// ══════════════════════════════════════════════════════════════════════════════
class _SummaryCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w800,
                color:      color,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color:    AppColor.textHint,
            ),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Mobile Return Row — compact, tap/"view" opens the detail bottom sheet
// ══════════════════════════════════════════════════════════════════════════════
class _ReturnRow extends StatelessWidget {
  final SaleReturnInvoice ret;
  final DateFormat        dateFmt;
  final DateFormat        timeFmt;
  final Color              refundColor;
  final VoidCallback      onView;

  const _ReturnRow({
    required this.ret,
    required this.dateFmt,
    required this.timeFmt,
    required this.refundColor,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap:        onView,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width:  44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColor.error.withOpacity(0.15),
                      AppColor.error.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.assignment_return_outlined,
                    size: 20, color: AppColor.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ret.returnNo,
                      style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.error,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ret.customerLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color:    AppColor.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 10, color: AppColor.textHint),
                        const SizedBox(width: 3),
                        Text(
                          '${dateFmt.format(ret.returnDate)}  ${timeFmt.format(ret.returnDate)}',
                          style: const TextStyle(
                              fontSize: 10,
                              color:    AppColor.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs ${ret.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w800,
                      color:      Color(0xFF1A1D23),
                    ),
                  ),
                  const SizedBox(height: 5),
                  _PayBadge(label: ret.paymentLabel, color: refundColor),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onView,
                tooltip:   'View return',
                icon: const Icon(Icons.visibility_outlined,
                    size: 20, color: AppColor.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Return Detail Panel — shared by the desktop side panel and mobile sheet
// ══════════════════════════════════════════════════════════════════════════════
class _ReturnDetailPanel extends StatelessWidget {
  final SaleReturnInvoice? ret;
  final DateFormat         dateFmt;
  final DateFormat         timeFmt;

  const _ReturnDetailPanel({
    required this.ret,
    required this.dateFmt,
    required this.timeFmt,
  });

  Color _refundColor(String? refundType) {
    switch (refundType) {
      case 'card':   return AppColor.info;
      case 'credit': return AppColor.warning;
      default:       return AppColor.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ret;
    if (r == null) {
      return const _PanelEmptyState(
        message: 'Select a return',
        subtitle: 'Click the view icon on a row to see its details here',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                r.returnNo,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: AppColor.error),
              ),
            ),
            _PayBadge(label: r.paymentLabel, color: _refundColor(r.refundType)),
          ],
        ),
        const SizedBox(height: 4),
        Text(r.customerLabel,
            style: const TextStyle(fontSize: 13, color: AppColor.textSecondary)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.access_time_rounded, size: 12, color: AppColor.textHint),
          const SizedBox(width: 4),
          Text(
            '${dateFmt.format(r.returnDate)}, ${timeFmt.format(r.returnDate)}',
            style: const TextStyle(fontSize: 11, color: AppColor.textHint),
          ),
        ]),
        if (r.returnReason != null && r.returnReason!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.info_outline, size: 12, color: AppColor.textHint),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                r.returnReason!,
                style: const TextStyle(fontSize: 11, color: AppColor.textHint),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color:        const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: const [
            Expanded(flex: 4, child: _IH(text: 'Product')),
            Expanded(flex: 2, child: _IH(text: 'Qty', center: true)),
            Expanded(flex: 2, child: _IH(text: 'Price', center: true)),
            Expanded(flex: 2, child: _IH(text: 'Total', right: true)),
          ]),
        ),
        const SizedBox(height: 6),
        ...r.items.map((item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(children: [
            Expanded(
              flex: 4,
              child: Text(
                item.productName,
                style: const TextStyle(fontSize: 12, color: AppColor.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.quantity.toStringAsFixed(0),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Rs ${item.salePrice.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Rs ${item.totalAmount.toStringAsFixed(0)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
              ),
            ),
          ]),
        )),
        Container(
          margin:  const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            children: [
              if (r.totalDiscount > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount',
                        style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                    Text(
                      '- Rs ${r.totalDiscount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.success, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 6),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D23)),
                  ),
                  Text(
                    'Rs ${r.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppColor.error),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelEmptyState extends StatelessWidget {
  final String message;
  final String subtitle;
  const _PanelEmptyState({required this.message, required this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color:        const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: const Icon(Icons.assignment_return_outlined,
              size: 26, color: AppColor.textHint),
        ),
        const SizedBox(height: 14),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.textSecondary)),
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColor.textHint)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared Widgets
// ══════════════════════════════════════════════════════════════════════════════
class _DateField extends StatelessWidget {
  final String                label;
  final TextEditingController controller;
  final VoidCallback          onTap;

  const _DateField({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      AppColor.textSecondary,
        ),
      ),
      const SizedBox(height: 4),
      TextField(
        controller:   controller,
        readOnly:     true,
        onTap:        onTap,
        cursorHeight: 14,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1D23)),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppColor.primary),
          filled:    true,
          fillColor: AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 12),
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
    ],
  );
}

class _PayBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _PayBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize:   10,
        fontWeight: FontWeight.w600,
        color:      color,
      ),
    ),
  );
}

class _IH extends StatelessWidget {
  final String text;
  final bool   right;
  final bool   center;

  const _IH({
    required this.text,
    this.right  = false,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: right
        ? TextAlign.right
        : center
        ? TextAlign.center
        : TextAlign.left,
    style: const TextStyle(
      fontSize:      10,
      fontWeight:    FontWeight.w600,
      color:         AppColor.textHint,
      letterSpacing: 0.3,
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.assignment_return_outlined,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'Koi return nahi mila',
          style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w600,
            color:      Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Filters change karein ya date range update karein',
          style: TextStyle(
              fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    ),
  );
}
