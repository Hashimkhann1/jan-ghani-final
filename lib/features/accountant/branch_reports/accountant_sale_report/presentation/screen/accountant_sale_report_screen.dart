import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../data/model/accountant_sale_report_model.dart';
import '../provider/accountant_sale_report_provider.dart';

class AccountantSaleReportScreen extends ConsumerStatefulWidget {
  const AccountantSaleReportScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<AccountantSaleReportScreen> createState() =>
      _AccountantSaleReportScreenState();
}

class _AccountantSaleReportScreenState
    extends ConsumerState<AccountantSaleReportScreen> {
  final _dateFmt  = DateFormat('dd MMM yyyy');
  final _timeFmt  = DateFormat('hh:mm a');
  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();
  final _amtFmt   = NumberFormat('#,##,###', 'en_IN');

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

  @override
  void initState() {
    super.initState();
    final state = ref.read(accountantSaleReportProvider(widget.branchId));
    _fromCtrl.text = _dateFmt.format(state.fromDate);
    _toCtrl.text   = _dateFmt.format(state.toDate);
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  String _fmtQty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  String _fmtAmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

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

  // ── Filter bottom sheet (mobile) ────────────────────────────────────────
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
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Apply Filters'),
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
    final desktop  = _isDesktop(context);

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

    // Kitne filters active hain — badge dikhane ke liye
    final activeFilterCount = (state.selectedCustomerId != null ? 1 : 0) +
        (state.selectedPaymentType != null ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: desktop
          ? _DesktopLayout(
        state:         state,
        notifier:      notifier,
        summary:       summary,
        fromCtrl:      _fromCtrl,
        toCtrl:        _toCtrl,
        customerItems: customerItems,
        paymentItems:  paymentItems,
        dateFmt:       _dateFmt,
        timeFmt:       _timeFmt,
        fmtQty:        _fmtQty,
        fmtAmt:        _fmtAmt,
        onPickFrom:    () => _pickDate(context, true),
        onPickTo:      () => _pickDate(context, false),
        onToday:       () => _setToday(notifier),
      )
          : _MobileLayout(
        state:              state,
        notifier:           notifier,
        summary:            summary,
        dateFmt:            _dateFmt,
        timeFmt:            _timeFmt,
        fmtQty:             _fmtQty,
        fmtAmt:             _fmtAmt,
        onToday:            () => _setToday(notifier),
        activeFilterCount:  activeFilterCount,
        onOpenFilters: () => _showFilterSheet(
          state:         state,
          notifier:      notifier,
          customerItems: customerItems,
          paymentItems:  paymentItems,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Desktop Layout (unchanged)
// ══════════════════════════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  final AccountantSaleReportState   state;
  final dynamic                     notifier;
  final dynamic                     summary;
  final TextEditingController       fromCtrl;
  final TextEditingController       toCtrl;
  final List<DropdownItem<String?>> customerItems;
  final List<DropdownItem<String?>> paymentItems;
  final DateFormat                  dateFmt;
  final DateFormat                  timeFmt;
  final String Function(double)     fmtQty;
  final String Function(double)     fmtAmt;
  final VoidCallback                onPickFrom;
  final VoidCallback                onPickTo;
  final VoidCallback                onToday;

  const _DesktopLayout({
    required this.state,
    required this.notifier,
    required this.summary,
    required this.fromCtrl,
    required this.toCtrl,
    required this.customerItems,
    required this.paymentItems,
    required this.dateFmt,
    required this.timeFmt,
    required this.fmtQty,
    required this.fmtAmt,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF1A1D23)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F6FA),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:       MainAxisSize.min,
                children: [
                  Text(
                    'Sale Invoice Report',
                    style: TextStyle(
                      fontSize:   22,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF1A1D23),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sale invoices ki detail aur filters',
                    style: TextStyle(fontSize: 13, color: AppColor.textHint),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 90,
                child: OutlinedButton(
                  onPressed: onToday,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: const BorderSide(color: AppColor.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Today'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: OutlinedButton.icon(
                  onPressed: notifier.load,
                  icon:  const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: const BorderSide(color: AppColor.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
          child: Row(
            children: [
              Expanded(
                child: _DateField(
                  label:      'Start Date',
                  controller: fromCtrl,
                  onTap:      onPickFrom,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label:      'End Date',
                  controller: toCtrl,
                  onTap:      onPickTo,
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
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
          child: Row(
            children: [
              _SummaryCard(
                label: 'Total Invoices',
                value: '${summary.totalInvoices}',
                icon:  Icons.receipt_outlined,
                color: AppColor.primary,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: 'Total Sale',
                value: 'Rs ${NumberFormat('#,##,###', 'en_IN').format(summary.totalSale.toInt())}',
                icon:  Icons.payments_outlined,
                color: AppColor.success,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: 'Total Qty',
                value: summary.totalQuantity % 1 == 0
                    ? summary.totalQuantity.toInt().toString()
                    : summary.totalQuantity.toStringAsFixed(2),
                icon:  Icons.inventory_2_outlined,
                color: AppColor.warning,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: 'Total Discount',
                value: 'Rs ${NumberFormat('#,##,###', 'en_IN').format(summary.totalDiscount.toInt())}',
                icon:  Icons.discount_outlined,
                color: AppColor.error,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.invoices.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding:          const EdgeInsets.all(24),
              itemCount:        state.invoices.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
              itemBuilder: (_, i) => _InvoiceCard(
                invoice: state.invoices[i],
                dateFmt: dateFmt,
                timeFmt: timeFmt,
                fmtQty:  fmtQty,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Mobile Layout — filters ab AppBar ke filter icon se bottom sheet mein khultay hain
// ══════════════════════════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  final AccountantSaleReportState state;
  final dynamic                   notifier;
  final dynamic                   summary;
  final DateFormat                dateFmt;
  final DateFormat                timeFmt;
  final String Function(double)   fmtQty;
  final String Function(double)   fmtAmt;
  final VoidCallback              onToday;
  final VoidCallback              onOpenFilters;
  final int                       activeFilterCount;

  const _MobileLayout({
    required this.state,
    required this.notifier,
    required this.summary,
    required this.dateFmt,
    required this.timeFmt,
    required this.fmtQty,
    required this.fmtAmt,
    required this.onToday,
    required this.onOpenFilters,
    required this.activeFilterCount,
  });

  @override
  Widget build(BuildContext context) {
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
          // ── Filter icon with active-count badge ──────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onOpenFilters,
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
          ),
          IconButton(
            onPressed: notifier.load,
            icon:    const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
            tooltip: 'Refresh',
          ),
          TextButton(
            onPressed: onToday,
            child: const Text('Today'),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [
          // ── Summary Cards ───────────────────────────────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 5,vertical: 10),
            child: Row(
              children: [
                _SummaryCard(
                  label: 'Invoices',
                  value: '${summary.totalInvoices}',
                  icon:  Icons.receipt_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 8),
                _SummaryCard(
                  label: 'Total Sale',
                  value: fmtAmt(summary.totalSale),
                  icon:  Icons.payments_outlined,
                  color: AppColor.success,
                ),
                const SizedBox(width: 8),
                _SummaryCard(
                  label: 'Qty',
                  value: fmtQty(summary.totalQuantity),
                  icon:  Icons.inventory_2_outlined,
                  color: AppColor.warning,
                ),
                const SizedBox(width: 8),
                _SummaryCard(
                  label: 'Discount',
                  value: fmtAmt(summary.totalDiscount),
                  icon:  Icons.discount_outlined,
                  color: AppColor.error,
                ),
              ],
            ),
          ),
          Container(height: 6, color: const Color(0xFFF5F6FA)),

          // ── Invoice List ────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.invoices.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount:        state.invoices.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (_, i) => _InvoiceCard(
                  invoice: state.invoices[i],
                  dateFmt: dateFmt,
                  timeFmt: timeFmt,
                  fmtQty:  fmtQty,
                ),
              ),
            ),
          ),
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
// Invoice Card
// ══════════════════════════════════════════════════════════════════════════════
class _InvoiceCard extends StatefulWidget {
  final SaleReportInvoice       invoice;
  final DateFormat              dateFmt;
  final DateFormat              timeFmt;
  final String Function(double) fmtQty;

  const _InvoiceCard({
    required this.invoice,
    required this.dateFmt,
    required this.timeFmt,
    required this.fmtQty,
  });

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  bool _expanded = false;

  Color get _paymentColor {
    final methods = widget.invoice.paymentMethods;
    if (methods.contains('credit')) return AppColor.warning;
    if (methods.contains('card'))   return AppColor.info;
    return AppColor.success;
  }

  Color get _paymentBg => _paymentColor.withOpacity(0.1);

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColor.primary.withOpacity(0.25)
              : const Color(0xFFEEEEEE),
        ),
        boxShadow: _expanded
            ? [
          BoxShadow(
            color:       AppColor.primary.withOpacity(0.06),
            blurRadius:  12,
            offset:      const Offset(0, 4),
          )
        ]
            : [
          BoxShadow(
            color:       Colors.black.withOpacity(0.03),
            blurRadius:  6,
            offset:      const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap:        () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width:  44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColor.primary.withOpacity(0.15),
                          AppColor.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end:   Alignment.bottomRight,
                      ),
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
                              '${widget.dateFmt.format(inv.invoiceDate)}  ${widget.timeFmt.format(inv.invoiceDate)}',
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
                      _PayBadge(
                        label: inv.paymentLabel,
                        color: _paymentColor,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${inv.items.length} items',
                            style: const TextStyle(
                                fontSize: 10,
                                color:    AppColor.textHint),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns:    _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                                Icons.keyboard_arrow_down,
                                size:  16,
                                color: AppColor.grey400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              height: 1,
              color:  const Color(0xFFE5E7EB),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color:        const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: const [
                      Expanded(
                          flex: 4,
                          child: _IH(text: 'Product')),
                      Expanded(
                          flex: 2,
                          child: _IH(text: 'Qty', center: true)),
                      Expanded(
                          flex: 2,
                          child: _IH(text: 'Price', center: true)),
                      Expanded(
                          flex: 2,
                          child: _IH(text: 'Total', right: true)),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  ...inv.items.map((item) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    child: Row(children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColor.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          widget.fmtQty(item.quantity),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColor.textSecondary),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Rs ${item.salePrice.toStringAsFixed(0)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColor.textSecondary),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Rs ${item.totalAmount.toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.textPrimary,
                          ),
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
                      border: Border.all(
                          color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      children: [
                        if (inv.totalDiscount > 0) ...[
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:    AppColor.textSecondary)),
                              Text(
                                '- Rs ${inv.totalDiscount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize:   12,
                                  color:      AppColor.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Divider(
                              height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 6),
                        ],
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total',
                              style: TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w700,
                                color:      Color(0xFF1A1D23),
                              ),
                            ),
                            Text(
                              'Rs ${inv.grandTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize:   14,
                                fontWeight: FontWeight.w800,
                                color:      AppColor.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
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
            fontSize: 13, fontWeight: FontWeight.w600),
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
          'Koi invoice nahi mila',
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