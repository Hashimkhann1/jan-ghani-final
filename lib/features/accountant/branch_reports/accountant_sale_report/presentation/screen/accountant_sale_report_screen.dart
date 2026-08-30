import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../../common/pagination/branch_report_pagination_controls.dart';
import '../../data/model/accountant_sale_report_model.dart';
import '../provider/accountant_sale_report_provider.dart';

/// ── Responsive breakpoint ──
const double _kWideBreakpoint = 900;

class AccountantSaleReportScreen extends ConsumerStatefulWidget {
  const AccountantSaleReportScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<AccountantSaleReportScreen> createState() =>
      _AccountantSaleReportScreenState();
}

class _AccountantSaleReportScreenState
    extends ConsumerState<AccountantSaleReportScreen> {
  final _dateFmt      = DateFormat('dd MMM yyyy');
  final _timeFmt      = DateFormat('hh:mm a');
  final _fromCtrl     = TextEditingController();
  final _toCtrl       = TextEditingController();
  final _fromTimeCtrl = TextEditingController();
  final _toTimeCtrl   = TextEditingController();
  final _amtFmt       = NumberFormat('#,##,###', 'en_IN');

  String? _selectedId;

  @override
  void initState() {
    super.initState();
    final state = ref.read(accountantSaleReportProvider(widget.branchId));
    _fromCtrl.text     = _dateFmt.format(state.fromDate);
    _toCtrl.text       = _dateFmt.format(state.toDate);
    _fromTimeCtrl.text = _timeFmt.format(state.fromDate);
    _toTimeCtrl.text   = _timeFmt.format(state.toDate);
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _fromTimeCtrl.dispose();
    _toTimeCtrl.dispose();
    super.dispose();
  }

  String _fmtQty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  String _fmtAmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  SaleReportInvoice? _findById(List<SaleReportInvoice> list, String? id) {
    if (id == null) return null;
    for (final inv in list) {
      if (inv.id == id) return inv;
    }
    return null;
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final state = ref.read(accountantSaleReportProvider(widget.branchId));
    final init  = isFrom ? state.fromDate : state.toDate;
    final picked = await showDatePicker(
      context:     context,
      initialDate: init,
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final notifier = ref.read(
          accountantSaleReportProvider(widget.branchId).notifier);
      final combined = DateTime(
        picked.year, picked.month, picked.day,
        init.hour, init.minute, init.second,
      );
      if (isFrom) {
        _fromCtrl.text = _dateFmt.format(combined);
        notifier.setFromDate(combined);
      } else {
        _toCtrl.text = _dateFmt.format(combined);
        notifier.setToDate(combined);
      }
    }
  }

  Future<void> _pickTime(BuildContext context, bool isFrom) async {
    final state = ref.read(accountantSaleReportProvider(widget.branchId));
    final init  = isFrom ? state.fromDate : state.toDate;
    final picked = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(init),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final notifier = ref.read(
          accountantSaleReportProvider(widget.branchId).notifier);
      final combined = DateTime(
        init.year, init.month, init.day,
        picked.hour, picked.minute,
      );
      if (isFrom) {
        _fromTimeCtrl.text = _timeFmt.format(combined);
        notifier.setFromDate(combined);
      } else {
        _toTimeCtrl.text = _timeFmt.format(combined);
        notifier.setToDate(combined);
      }
    }
  }

  void _setToday(dynamic notifier) {
    notifier.setToday();
    final now        = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay   = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _fromCtrl.text     = _dateFmt.format(startOfDay);
    _toCtrl.text       = _dateFmt.format(endOfDay);
    _fromTimeCtrl.text = _timeFmt.format(startOfDay);
    _toTimeCtrl.text   = _timeFmt.format(endOfDay);
  }

  // ── Filter bottom sheet (narrow screens) ────────────────────────────────
  void _showFilterSheet({
    required AccountantSaleReportState state,
    required dynamic notifier,
    required List<DropdownItem<String?>> customerItems,
    required List<DropdownItem<String?>> paymentItems,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColor.grey200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D23),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _setToday(notifier);
                      notifier.setCustomer(null);
                      notifier.setPaymentType(null);
                      Navigator.pop(ctx);
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColor.primary),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Start Date',
                      controller: _fromCtrl,
                      onTap: () => _pickDate(ctx, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'End Date',
                      controller: _toCtrl,
                      onTap: () => _pickDate(ctx, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Start Time',
                      controller: _fromTimeCtrl,
                      onTap: () => _pickTime(ctx, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'End Time',
                      controller: _toTimeCtrl,
                      onTap: () => _pickTime(ctx, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppSearchableDropdown<String?>(
                items:      customerItems,
                value:      state.selectedCustomerId,
                hint:       'All Customers',
                fullWidth:  true,
                prefixIcon: Icons.person_outline_rounded,
                onChanged:  (v) => notifier.setCustomer(v),
              ),
              const SizedBox(height: 12),
              AppSearchableDropdown<String?>(
                items:      paymentItems,
                value:      state.selectedPaymentType,
                hint:       'All Payment Types',
                fullWidth:  true,
                prefixIcon: Icons.payment_outlined,
                onChanged:  (v) => notifier.setPaymentType(v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── View invoice (bottom sheet) ─────────────────────────────────────────
  void _showInvoiceSheet(SaleReportInvoice invoice) {
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
                  color: AppColor.grey200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Invoice Details',
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
                  child: _InvoiceDetailPanel(
                    invoice: invoice,
                    dateFmt: _dateFmt,
                    timeFmt: _timeFmt,
                    fmtQty:  _fmtQty,
                    fmtAmt:  _fmtAmt,
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
    final state    = ref.watch(accountantSaleReportProvider(widget.branchId));
    final notifier = ref.read(accountantSaleReportProvider(widget.branchId).notifier);
    final summary  = state.summary;

    // Clear the detail-panel selection if it's no longer in the current
    // list (filters, pagination, refresh) — never auto-pick a row; the
    // panel stays empty until the user explicitly clicks "view".
    if (_selectedId != null &&
        !state.invoices.any((inv) => inv.id == _selectedId)) {
      _selectedId = null;
    }
    final selectedInvoice = _findById(state.invoices, _selectedId);

    ref.listen<AccountantSaleReportState>(
        accountantSaleReportProvider(widget.branchId), (_, next) {
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

    final paymentItems = [
      DropdownItem<String?>(
          value: null,
          label: 'All Payments',
          icon:  Icons.payment_outlined),
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

    // Count of active filters — used for the badge
    final activeFilterCount = (state.selectedCustomerId != null ? 1 : 0) +
        (state.selectedPaymentType != null ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Sale Invoice Report',
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
                  onPressed: () => _showFilterSheet(
                    state:         state,
                    notifier:      notifier,
                    customerItems: customerItems,
                    paymentItems:  paymentItems,
                  ),
                  icon: const Icon(Icons.filter_list_rounded,
                      color: AppColor.textSecondary),
                  tooltip: 'Filters',
                ),
                if (activeFilterCount > 0)
                  Positioned(
                    right: 6,
                    top:   6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColor.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$activeFilterCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize:   9,
                          color:      Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          IconButton(
            onPressed: notifier.load,
            icon:    const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
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
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _kWideBreakpoint;

          return Column(
            children: [
              if (isWide)
                Container(
                  color:   Colors.white,
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
                  child: Column(
                    children: [
                      Row(
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
                            child: _TimeField(
                              label:      'Start Time',
                              controller: _fromTimeCtrl,
                              onTap:      () => _pickTime(context, true),
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
                            child: _TimeField(
                              label:      'End Time',
                              controller: _toTimeCtrl,
                              onTap:      () => _pickTime(context, false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
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
                              items:      paymentItems,
                              value:      state.selectedPaymentType,
                              hint:       'All Payment Types',
                              fullWidth:  true,
                              prefixIcon: Icons.payment_outlined,
                              onChanged:  (v) => notifier.setPaymentType(v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Container(
                width:   double.infinity,
                color:   Colors.white,
                padding: EdgeInsets.fromLTRB(
                    isWide ? 28 : 12, isWide ? 0 : 12, isWide ? 28 : 12, isWide ? 16 : 12),
                child: Row(
                  children: [
                    _SummaryCard(
                      label: 'Invoices',
                      value: '${summary.totalInvoices}',
                      icon:  Icons.receipt_outlined,
                      color: AppColor.primary,
                    ),
                    const SizedBox(width: 10),
                    _SummaryCard(
                      label: 'Total Sale',
                      value: _fmtAmt(summary.totalSale),
                      icon:  Icons.payments_outlined,
                      color: AppColor.success,
                    ),
                    const SizedBox(width: 10),
                    _SummaryCard(
                      label: 'Qty',
                      value: _fmtQty(summary.totalQuantity),
                      icon:  Icons.inventory_2_outlined,
                      color: AppColor.warning,
                    ),
                    const SizedBox(width: 10),
                    _SummaryCard(
                      label: 'Discount',
                      value: _fmtAmt(summary.totalDiscount),
                      icon:  Icons.discount_outlined,
                      color: const Color(0xFF6366F1),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
                    : state.invoices.isEmpty
                    ? const _EmptyState()
                    : isWide
                    ? _WideInvoiceContent(
                  invoices:        state.invoices,
                  notifier:        notifier,
                  dateFmt:         _dateFmt,
                  timeFmt:         _timeFmt,
                  fmtQty:          _fmtQty,
                  fmtAmt:          _fmtAmt,
                  selectedId:      _selectedId,
                  selectedInvoice: selectedInvoice,
                  onSelect:        (id) => setState(() => _selectedId = id),
                )
                    : RefreshIndicator(
                  color: AppColor.primary,
                  onRefresh: notifier.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount:        state.invoices.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                    itemBuilder: (_, i) => _InvoiceRow(
                      invoice: state.invoices[i],
                      dateFmt: _dateFmt,
                      timeFmt: _timeFmt,
                      onView:  () => _showInvoiceSheet(state.invoices[i]),
                    ),
                  ),
                ),
              ),
              if (!state.isLoading && state.invoices.isNotEmpty)
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
// Payment → accent color
// ══════════════════════════════════════════════════════════════════════════════
Color _paymentColor(List<String> methods) {
  if (methods.isEmpty) return AppColor.textHint;
  switch (methods.first.toLowerCase()) {
    case 'cash':   return AppColor.success;
    case 'card':   return AppColor.info;
    case 'credit': return AppColor.warning;
    default:       return AppColor.primary;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Wide layout content — invoice table + right-side detail panel
// ══════════════════════════════════════════════════════════════════════════════
class _WideInvoiceContent extends StatelessWidget {
  final List<SaleReportInvoice> invoices;
  final dynamic                     notifier;
  final DateFormat                  dateFmt;
  final DateFormat                  timeFmt;
  final String Function(double)     fmtQty;
  final String Function(double)     fmtAmt;
  final String?                     selectedId;
  final SaleReportInvoice?          selectedInvoice;
  final ValueChanged<String?>       onSelect;

  const _WideInvoiceContent({
    required this.invoices,
    required this.notifier,
    required this.dateFmt,
    required this.timeFmt,
    required this.fmtQty,
    required this.fmtAmt,
    required this.selectedId,
    required this.selectedInvoice,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColor.primary,
            onRefresh: notifier.load,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _InvoiceTable(
                invoices:   invoices,
                dateFmt:    dateFmt,
                timeFmt:    timeFmt,
                selectedId: selectedId,
                onSelect:   onSelect,
              ),
            ),
          ),
        ),
        if (selectedInvoice != null) ...[
          Container(width: 1, color: const Color(0xFFEEEEEE)),
          SizedBox(
            width: 400,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _InvoiceDetailPanel(
                    invoice: selectedInvoice,
                    dateFmt: dateFmt,
                    timeFmt: timeFmt,
                    fmtQty:  fmtQty,
                    fmtAmt:  fmtAmt,
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
// Invoice table (card-style, not a raw DataTable) — used on wide screens
// ══════════════════════════════════════════════════════════════════════════════
class _InvoiceTable extends StatelessWidget {
  final List<SaleReportInvoice> invoices;
  final DateFormat              dateFmt;
  final DateFormat              timeFmt;
  final String?                 selectedId;
  final ValueChanged<String?>   onSelect;

  const _InvoiceTable({
    required this.invoices,
    required this.dateFmt,
    required this.timeFmt,
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
                Expanded(flex: 2, child: _IH(text: 'Invoice No')),
                Expanded(flex: 3, child: _IH(text: 'Customer')),
                Expanded(flex: 3, child: _IH(text: 'Date / Time')),
                Expanded(flex: 2, child: _IH(text: 'Payment')),
                Expanded(flex: 1, child: _IH(text: 'Items', center: true)),
                Expanded(flex: 2, child: _IH(text: 'Grand Total', right: true)),
                SizedBox(width: 44),
              ],
            ),
          ),
          ...invoices.map((inv) {
            final isSelected = inv.id == selectedId;
            final payColor   = _paymentColor(inv.paymentMethods);
            return InkWell(
              onTap: () => onSelect(inv.id),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.primary.withOpacity(0.06)
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
                      child: Text(inv.invoiceNo,
                          style: const TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w700,
                              color:      AppColor.primary)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(inv.customerLabel,
                          style: const TextStyle(
                              fontSize: 13, color: AppColor.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${dateFmt.format(inv.invoiceDate)}, ${timeFmt.format(inv.invoiceDate)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColor.textSecondary),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _PayBadge(label: inv.paymentLabel, color: payColor),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text('${inv.items.length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: AppColor.textSecondary)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Rs ${inv.grandTotal.toStringAsFixed(0)}',
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
                              ? AppColor.primary
                              : AppColor.textSecondary,
                        ),
                        tooltip: 'View invoice',
                        onPressed: () => onSelect(inv.id),
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
// Mobile Invoice Row — compact, tap/"view" opens the detail bottom sheet
// ══════════════════════════════════════════════════════════════════════════════
class _InvoiceRow extends StatelessWidget {
  final SaleReportInvoice invoice;
  final DateFormat        dateFmt;
  final DateFormat        timeFmt;
  final VoidCallback      onView;

  const _InvoiceRow({
    required this.invoice,
    required this.dateFmt,
    required this.timeFmt,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final inv      = invoice;
    final payColor = _paymentColor(inv.paymentMethods);
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
                  color: AppColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.receipt_outlined,
                    size: 20, color: AppColor.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.invoiceNo,
                      style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      inv.customerLabel,
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
                          '${dateFmt.format(inv.invoiceDate)}  ${timeFmt.format(inv.invoiceDate)}',
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
                    'Rs ${inv.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w800,
                      color:      Color(0xFF1A1D23),
                    ),
                  ),
                  const SizedBox(height: 5),
                  _PayBadge(label: inv.paymentLabel, color: payColor),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onView,
                tooltip:   'View invoice',
                icon: const Icon(Icons.visibility_outlined,
                    size: 20, color: AppColor.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Invoice Detail Panel — shared by the desktop side panel and mobile sheet
// ══════════════════════════════════════════════════════════════════════════════
class _InvoiceDetailPanel extends StatelessWidget {
  final SaleReportInvoice?      invoice;
  final DateFormat              dateFmt;
  final DateFormat              timeFmt;
  final String Function(double) fmtQty;
  final String Function(double) fmtAmt;

  const _InvoiceDetailPanel({
    required this.invoice,
    required this.dateFmt,
    required this.timeFmt,
    required this.fmtQty,
    required this.fmtAmt,
  });

  @override
  Widget build(BuildContext context) {
    final inv = invoice;
    if (inv == null) {
      return const _PanelEmptyState(
        message: 'Select an invoice',
        subtitle: 'Click the view icon on a row to see its details here',
      );
    }
    final payColor = _paymentColor(inv.paymentMethods);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                inv.invoiceNo,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: AppColor.primary),
              ),
            ),
            _PayBadge(label: inv.paymentLabel, color: payColor),
          ],
        ),
        const SizedBox(height: 4),
        Text(inv.customerLabel,
            style: const TextStyle(fontSize: 13, color: AppColor.textSecondary)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.access_time_rounded, size: 12, color: AppColor.textHint),
          const SizedBox(width: 4),
          Text(
            '${dateFmt.format(inv.invoiceDate)}, ${timeFmt.format(inv.invoiceDate)}',
            style: const TextStyle(fontSize: 11, color: AppColor.textHint),
          ),
        ]),
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
        ...inv.items.map((item) => Container(
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
                fmtQty(item.quantity),
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
              if (inv.totalDiscount > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount',
                        style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                    Text(
                      '- Rs ${inv.totalDiscount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
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
                    'Rs ${inv.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppColor.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          margin:  const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _AmountBlock(
                  label: 'Previous Amount',
                  value: fmtAmt(inv.previousAmount),
                ),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE5E7EB)),
              Expanded(
                child: _AmountBlock(
                  label: 'New Amount',
                  value: fmtAmt(inv.newAmount),
                ),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE5E7EB)),
              Expanded(
                child: _AmountBlock(
                  label: 'Pay Amount',
                  value: fmtAmt(inv.payAmount),
                ),
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
          child: const Icon(Icons.receipt_long_outlined,
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
// Small amount block used in Previous/New/Pay row
// ══════════════════════════════════════════════════════════════════════════════
class _AmountBlock extends StatelessWidget {
  final String label;
  final String value;

  const _AmountBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.w700,
          color:      Color(0xFF1A1D23),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          color:    AppColor.textHint,
        ),
      ),
    ],
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
          filled:     true,
          fillColor:  AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColor.grey200),
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

class _TimeField extends StatelessWidget {
  final String                label;
  final TextEditingController controller;
  final VoidCallback          onTap;

  const _TimeField({
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
          prefixIcon: const Icon(Icons.access_time_rounded,
              size: 16, color: AppColor.primary),
          filled:     true,
          fillColor:  AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColor.grey200),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

  const _IH({required this.text, this.right = false, this.center = false});

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
        Icon(Icons.receipt_long_outlined,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'No invoices found',
          style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w600,
            color:      Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Try changing filters or the date range',
          style: TextStyle(
              fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    ),
  );
}
