import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/features/branch/sale_invoice/presentation/provider/sale_invoice_list_provider.dart';

class SaleInvoiceListScreen extends ConsumerStatefulWidget {
  const SaleInvoiceListScreen({super.key});

  @override
  ConsumerState<SaleInvoiceListScreen> createState() =>
      _SaleInvoiceListScreenState();
}

class _SaleInvoiceListScreenState
    extends ConsumerState<SaleInvoiceListScreen> {
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
      ref.read(saleInvoiceListProvider.notifier).load();
      _syncDateFields();
    });
  }

  void _syncDateFields() {
    final state = ref.read(saleInvoiceListProvider);
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

  // ── Pick single date ──────────────────────────────────────
  Future<DateTime?> _pickDate(BuildContext context, DateTime initial) async {
    return showDatePicker(
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
  }

  Future<void> _onStartDateTap() async {
    final state  = ref.read(saleInvoiceListProvider);
    final picked = await _pickDate(context, state.fromDate);
    if (picked != null) {
      _startDateCtrl.text = _inputFmt.format(picked);
      ref
          .read(saleInvoiceListProvider.notifier)
          .setDateRange(picked, state.toDate);
    }
  }

  Future<void> _onEndDateTap() async {
    final state  = ref.read(saleInvoiceListProvider);
    final picked = await _pickDate(context, state.toDate);
    if (picked != null) {
      _endDateCtrl.text = _inputFmt.format(picked);
      ref
          .read(saleInvoiceListProvider.notifier)
          .setDateRange(state.fromDate, picked);
    }
  }

  // ── Date TextField ────────────────────────────────────────
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
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
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
                  borderSide: const BorderSide(
                      color: AppColor.primary, width: 1.2),
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(saleInvoiceListProvider);
    final invoices = state.filteredInvoices;

    ref.listen<SaleInvoiceListState>(saleInvoiceListProvider, (_, next) {
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
                ref.read(saleInvoiceListProvider.notifier).clearError(),
          ),
        ));
      }
      // Today button ke baad date fields sync
      _startDateCtrl.text = _inputFmt.format(next.fromDate);
      _endDateCtrl.text   = _inputFmt.format(next.toDate);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Sale Invoices',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight:   60,
        backgroundColor: Colors.white,
        elevation:       0.5,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(saleInvoiceListProvider.notifier).load(),
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

            // ── Stat Cards ─────────────────────────────
            // NOTE: SummaryCard ke andar pehle se Expanded
            // hai — bahar koi Expanded/Flexible wrap NAHI
            Row(
              children: [
                SummaryCard(
                  title: 'Total Invoices',
                  value: '${state.totalCount}',
                  icon:  Icons.receipt_long_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Grand Total',
                  value:
                  'Rs ${state.totalGrand.toStringAsFixed(0)}',
                  icon:  Icons.payments_outlined,
                  color: AppColor.success,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Total Discount',
                  value:
                  'Rs ${state.totalDiscount.toStringAsFixed(0)}',
                  icon:  Icons.discount_outlined,
                  color: AppColor.warning,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Filters ────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [

                  // Search
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged:  ref
                          .read(saleInvoiceListProvider.notifier)
                          .onSearchChanged,
                      style:        const TextStyle(fontSize: 13),
                      cursorHeight: 14,
                      decoration: InputDecoration(
                        hintText: 'Search invoice, customer...',
                        hintStyle: const TextStyle(
                            color:    AppColor.textHint,
                            fontSize: 12),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: AppColor.grey400),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear,
                              size:  16,
                              color: AppColor.grey400),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref
                                .read(saleInvoiceListProvider
                                .notifier)
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

                  // Today
                  IntrinsicWidth(
                    child: OutlinedButton.icon(
                      onPressed: () => ref
                          .read(saleInvoiceListProvider.notifier)
                          .setToday(),
                      icon:  const Icon(Icons.today_rounded, size: 16),
                      label: const Text('Today', style: TextStyle(fontSize: 12)),
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

            // ── Invoice List ───────────────────────────
            Expanded(
              child: invoices.isEmpty
                  ? _EmptyState(
                  isSearching: state.searchQuery.isNotEmpty)
                  : ListView.separated(
                itemCount: invoices.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _InvoiceCard(
                      inv:     invoices[index],
                      dateFmt: _dateFmt,
                      timeFmt: _timeFmt,
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
// Invoice Card
// ══════════════════════════════════════════════════════════════
class _InvoiceCard extends StatelessWidget {
  final dynamic    inv;
  final DateFormat dateFmt;
  final DateFormat timeFmt;

  const _InvoiceCard({
    required this.inv,
    required this.dateFmt,
    required this.timeFmt,
  });

  @override
  Widget build(BuildContext context) {
    final double subtotal =
    inv.items.fold(0.0, (s, i) => s + (i.totalAmount as double? ?? 0.0));

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

          // ── Header ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(
                    color: AppColor.grey300.withValues(alpha: 0.6)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 15, color: AppColor.primary),
                const SizedBox(width: 6),
                Text(
                  inv.invoiceNo as String,
                  style: const TextStyle(
                      fontSize:      13,
                      fontWeight:    FontWeight.w800,
                      color:         AppColor.primary,
                      letterSpacing: 0.3),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dateFmt.format(inv.invoiceDate as DateTime),
                      style: const TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w700,
                          color:      AppColor.textPrimary),
                    ),
                    Text(
                      timeFmt.format(inv.invoiceDate as DateTime),
                      style: const TextStyle(
                          fontSize: 11,
                          color:    AppColor.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Customer + Payment ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 13, color: AppColor.textSecondary),
                const SizedBox(width: 5),
                Text(
                  (inv.customerName as String?) ?? 'Walk In',
                  style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color: inv.customerName != null
                          ? AppColor.textPrimary
                          : AppColor.textSecondary),
                ),
                const Spacer(),
                _PaymentBadge(type: inv.paymentType as String),
              ],
            ),
          ),

          // ── Counter ───────────────────────────────────────
          if (inv.counterName != null)
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.point_of_sale_outlined,
                      size: 13, color: AppColor.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Counter: ',
                      style: TextStyle(
                          fontSize: 12,
                          color:    AppColor.textSecondary)),
                  _CounterChip(name: inv.counterName as String),
                ],
              ),
            ),

          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ── Product Table ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                // Header Row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color:        AppColor.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
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

                // Item Rows
                ...inv.items.asMap().entries.map<Widget>((entry) {
                  final idx  = entry.key as int;
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
                        // Product name
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Container(
                                width:  5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: AppColor.primary
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  item.productName as String,
                                  style: const TextStyle(
                                      fontSize:   12,
                                      fontWeight: FontWeight.w500,
                                      color:      AppColor.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Price
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.priceLabel as String,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 11,
                                color:    AppColor.textPrimary),
                          ),
                        ),
                        // Qty
                        Expanded(
                          flex: 1,
                          child: Text(
                            item.qtyLabel as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize:   11,
                                fontWeight: FontWeight.w600,
                                color:      AppColor.textPrimary),
                          ),
                        ),
                        // Discount
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Rs ${(item.discount as double).toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 11,
                                color:    AppColor.warning),
                          ),
                        ),
                        // Sub Total
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.totalLabel as String,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize:   11,
                                fontWeight: FontWeight.w700,
                                color:      AppColor.primary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // ── Totals ────────────────────────────────────
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 10),

                // Sub Total row
                _TotalRow(
                  label: 'Sub Total',
                  value: 'Rs ${subtotal.toStringAsFixed(0)}',
                  valueColor: AppColor.textPrimary,
                ),

                // Discount row (0 ho to hide)
                if ((inv.totalDiscount as double) > 0) ...[
                  const SizedBox(height: 4),
                  _TotalRow(
                    label:      'Discount',
                    value:      inv.discountLabel as String,
                    valueColor: AppColor.warning,
                  ),
                ],

                const SizedBox(height: 10),

                // Grand Total + Status
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColor.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColor.success.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatusBadge(status: inv.status as String),
                      Row(
                        children: [
                          const Text('Total Amount:',
                              style: TextStyle(
                                  fontSize:   12,
                                  fontWeight: FontWeight.w600,
                                  color:      AppColor.textSecondary)),
                          const SizedBox(width: 10),
                          Text(
                            inv.grandTotalLabel as String,
                            style: const TextStyle(
                                fontSize:   15,
                                fontWeight: FontWeight.w800,
                                color:      AppColor.success),
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
      ),
    );
  }
}

// ── Total Row helper ──────────────────────────────────────────
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
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      valueColor),
        ),
      ),
    ],
  );
}

// ── Counter Chip ──────────────────────────────────────────────
class _CounterChip extends StatelessWidget {
  final String name;
  const _CounterChip({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColor.primary.withValues(alpha: 0.08),
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

// ── Payment Badge ─────────────────────────────────────────────
class _PaymentBadge extends StatelessWidget {
  final String type;
  const _PaymentBadge({required this.type});

  Color    get _color  => const {'cash': AppColor.success, 'card': AppColor.info, 'credit': AppColor.warning}[type] ?? AppColor.grey400;
  IconData get _icon   => const {'cash': Icons.payments_outlined, 'card': Icons.credit_card_outlined, 'credit': Icons.person_outline_rounded}[type] ?? Icons.help_outline;
  String   get _label  => const {'cash': 'Cash', 'card': 'Card', 'credit': 'Credit'}[type] ?? type;

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

// ── Status Badge ──────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color    get _color => const {'completed': AppColor.success, 'cancelled': AppColor.error, 'returned': AppColor.warning}[status] ?? AppColor.grey400;
  IconData get _icon  => const {'completed': Icons.check_circle_outline_rounded, 'cancelled': Icons.cancel_outlined, 'returned': Icons.assignment_return_outlined}[status] ?? Icons.help_outline;
  String   get _label => const {'completed': 'Completed', 'cancelled': 'Cancelled', 'returned': 'Returned'}[status] ?? status;

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

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isSearching;
  const _EmptyState({this.isSearching = false});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSearching
              ? Icons.search_off_rounded
              : Icons.receipt_long_outlined,
          size:  64,
          color: AppColor.grey300,
        ),
        const SizedBox(height: 16),
        Text(
          isSearching
              ? 'Koi invoice nahi mila'
              : 'Koi invoice nahi',
          style: const TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      AppColor.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          isSearching
              ? 'Search query change karein'
              : 'Sales karne ke baad yahan dikhega',
          style: const TextStyle(
              fontSize: 13, color: AppColor.textHint),
        ),
      ],
    ),
  );
}