import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../data/model/accountant_discount_wise_sale_report_model.dart';
import '../provider/accountant_discount_wise_sale_report_provider.dart';


class DiscountWiseSaleReportScreen extends ConsumerStatefulWidget {
  const DiscountWiseSaleReportScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<DiscountWiseSaleReportScreen> createState() =>
      _DiscountWiseSaleReportScreenState();
}

class _DiscountWiseSaleReportScreenState
    extends ConsumerState<DiscountWiseSaleReportScreen> {
  final _dateFmt  = DateFormat('dd MMM yyyy');
  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();
  final _amtFmt   = NumberFormat('#,##,###', 'en_IN');

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

  @override
  void initState() {
    super.initState();
    final state = ref.read(discountWiseSaleReportProvider(widget.branchId));
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
    final state = ref.read(discountWiseSaleReportProvider(widget.branchId));
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
          discountWiseSaleReportProvider(widget.branchId).notifier);
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
    required DiscountWiseSaleReportState state,
    required dynamic notifier,
    required List<DropdownItem<String?>> customerItems,
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
    final state    = ref.watch(discountWiseSaleReportProvider(widget.branchId));
    final notifier = ref.read(discountWiseSaleReportProvider(widget.branchId).notifier);
    final summary  = state.summary;
    final desktop  = _isDesktop(context);

    ref.listen<DiscountWiseSaleReportState>(
        discountWiseSaleReportProvider(widget.branchId), (_, next) {
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

    final activeFilterCount = state.selectedCustomerId != null ? 1 : 0;

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
        dateFmt:       _dateFmt,
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
        fmtQty:             _fmtQty,
        fmtAmt:             _fmtAmt,
        onToday:            () => _setToday(notifier),
        activeFilterCount:  activeFilterCount,
        onOpenFilters: () => _showFilterSheet(
          state:         state,
          notifier:      notifier,
          customerItems: customerItems,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Desktop Layout — DataTable
// ══════════════════════════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  final DiscountWiseSaleReportState state;
  final dynamic                     notifier;
  final DiscountReportSummary       summary;
  final TextEditingController       fromCtrl;
  final TextEditingController       toCtrl;
  final List<DropdownItem<String?>> customerItems;
  final DateFormat                  dateFmt;
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
    required this.dateFmt,
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
                    'Discount Wise Sale Report',
                    style: TextStyle(
                      fontSize:   22,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF1A1D23),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Jis product per discount laga uski detail',
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
              const Expanded(child: SizedBox()),
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
                label: 'Discounted Products',
                value: '${summary.totalProducts}',
                icon:  Icons.inventory_2_outlined,
                color: AppColor.primary,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: 'Total Discount',
                value: fmtAmt(summary.totalDiscountAmount),
                icon:  Icons.discount_outlined,
                color: AppColor.error,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: 'Total Qty',
                value: fmtQty(summary.totalQuantity),
                icon:  Icons.numbers_rounded,
                color: AppColor.warning,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: 'Affected Invoices',
                value: '${summary.totalInvoices}',
                icon:  Icons.receipt_outlined,
                color: AppColor.success,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.products.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
            onRefresh: notifier.load,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: DataTable(
                  headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFF5F6FA)),
                  columns: const [
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('SKU')),
                    DataColumn(label: Text('Qty'), numeric: true),
                    DataColumn(label: Text('Invoices'), numeric: true),
                    DataColumn(label: Text('Avg Disc %'), numeric: true),
                    DataColumn(label: Text('Total Discount'), numeric: true),
                    DataColumn(label: Text('Net Sale'), numeric: true),
                  ],
                  rows: state.products.map((p) {
                    return DataRow(cells: [
                      DataCell(Text(p.productName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600))),
                      DataCell(Text(p.sku ?? '—')),
                      DataCell(Text(fmtQty(p.totalQuantity))),
                      DataCell(Text('${p.invoiceCount}')),
                      DataCell(Text('${p.avgDiscountPercent.toStringAsFixed(1)}%')),
                      DataCell(Text(
                        fmtAmt(p.totalDiscount),
                        style: const TextStyle(
                            color: AppColor.error,
                            fontWeight: FontWeight.w700),
                      )),
                      DataCell(Text(fmtAmt(p.totalSaleAmount))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Mobile Layout — expandable product cards
// ══════════════════════════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  final DiscountWiseSaleReportState state;
  final dynamic                     notifier;
  final DiscountReportSummary       summary;
  final DateFormat                  dateFmt;
  final String Function(double)     fmtQty;
  final String Function(double)     fmtAmt;
  final VoidCallback                onToday;
  final VoidCallback                onOpenFilters;
  final int                         activeFilterCount;

  const _MobileLayout({
    required this.state,
    required this.notifier,
    required this.summary,
    required this.dateFmt,
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
          'Discount Wise Sale Report',
          style: TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.w700,
            color:      Color(0xFF1A1D23),
          ),
        ),
        actions: [
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
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            child: Row(
              children: [
                _SummaryCard(
                  label: 'Products',
                  value: '${summary.totalProducts}',
                  icon:  Icons.inventory_2_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 8),
                _SummaryCard(
                  label: 'Discount',
                  value: fmtAmt(summary.totalDiscountAmount),
                  icon:  Icons.discount_outlined,
                  color: AppColor.error,
                ),
                const SizedBox(width: 8),
                _SummaryCard(
                  label: 'Qty',
                  value: fmtQty(summary.totalQuantity),
                  icon:  Icons.numbers_rounded,
                  color: AppColor.warning,
                ),
                const SizedBox(width: 8),
                _SummaryCard(
                  label: 'Invoices',
                  value: '${summary.totalInvoices}',
                  icon:  Icons.receipt_outlined,
                  color: AppColor.success,
                ),
              ],
            ),
          ),
          Container(height: 6, color: const Color(0xFFF5F6FA)),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.products.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount:        state.products.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (_, i) => _ProductCard(
                  product: state.products[i],
                  dateFmt: dateFmt,
                  fmtQty:  fmtQty,
                  fmtAmt:  fmtAmt,
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
// Product Card (mobile) — expandable, invoice-wise breakdown
// ══════════════════════════════════════════════════════════════════════════════
class _ProductCard extends StatefulWidget {
  final DiscountReportProduct   product;
  final DateFormat              dateFmt;
  final String Function(double) fmtQty;
  final String Function(double) fmtAmt;

  const _ProductCard({
    required this.product,
    required this.dateFmt,
    required this.fmtQty,
    required this.fmtAmt,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

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
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap:        () => setState(() => _expanded = !_expanded),
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
                    child: const Icon(Icons.discount_outlined,
                        size: 20, color: AppColor.error),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.productName,
                          style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                            color:      Color(0xFF1A1D23),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.sku != null ? 'SKU: ${p.sku}' : 'Qty: ${widget.fmtQty(p.totalQuantity)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColor.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_outlined,
                                size: 10, color: AppColor.textHint),
                            const SizedBox(width: 3),
                            Text(
                              '${p.invoiceCount} invoices',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColor.textHint),
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
                        widget.fmtAmt(p.totalDiscount),
                        style: const TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w800,
                          color:      AppColor.error,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColor.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColor.warning.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${p.avgDiscountPercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize:   10,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.warning,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedRotation(
                        turns:    _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down,
                            size: 16, color: AppColor.grey400),
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
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: p.details.map((d) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            d.invoiceNo,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColor.primary,
                            ),
                          ),
                          Text(
                            widget.dateFmt.format(d.invoiceDate),
                            style: const TextStyle(
                                fontSize: 11, color: AppColor.textHint),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.customerLabel,
                        style: const TextStyle(
                            fontSize: 11, color: AppColor.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Qty: ${widget.fmtQty(d.quantity)}',
                              style: const TextStyle(fontSize: 11)),
                          Text('Price: ${widget.fmtAmt(d.salePrice)}',
                              style: const TextStyle(fontSize: 11)),
                          Text(
                            'Disc: ${widget.fmtAmt(d.discount)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColor.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )).toList(),
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
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppColor.primary),
          filled:     true,
          fillColor:  AppColor.grey100,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
            borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.discount_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'Koi discount wala item nahi mila',
          style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w600,
            color:      Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Date range ya customer filter change karein',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    ),
  );
}