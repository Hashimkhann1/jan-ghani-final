import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/color/app_color.dart';
import '../provider/customer_invoice_provider.dart';
import '../../data/model/customer_invoice_model.dart';

class CustomerInvoiceScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerInvoiceScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  ConsumerState<CustomerInvoiceScreen> createState() =>
      _CustomerInvoiceScreenState();
}

class _CustomerInvoiceScreenState
    extends ConsumerState<CustomerInvoiceScreen> {
  final _searchCtrl    = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl   = TextEditingController();
  final _dateFmt       = DateFormat('dd MMM yyyy');
  final _timeFmt       = DateFormat('hh:mm a');
  final _inputFmt      = DateFormat('dd/MM/yyyy');

  ({String customerId, String customerName}) get _args => (
  customerId:   widget.customerId,
  customerName: widget.customerName,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(customerInvoiceProvider(_args));
      _startDateCtrl.text = _inputFmt.format(state.fromDate);
      _endDateCtrl.text   = _inputFmt.format(state.toDate);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime initial) async =>
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

  Widget _dateField({
    required String                label,
    required TextEditingController ctrl,
    required VoidCallback          onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: SizedBox(
            width: 150,
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
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(customerInvoiceProvider(_args));
    final invoices = state.filteredInvoices;
    final notifier = ref.read(customerInvoiceProvider(_args).notifier);

    ref.listen(customerInvoiceProvider(_args), (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.errorMessage!),
          backgroundColor: AppColor.error,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
        notifier.clearError();
      }
      _startDateCtrl.text = _inputFmt.format(next.fromDate);
      _endDateCtrl.text   = _inputFmt.format(next.toDate);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Invoices',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(widget.customerName,
                style: const TextStyle(
                    fontSize: 12, color: AppColor.textSecondary)),
          ],
        ),
        toolbarHeight:   65,
        backgroundColor: Colors.white,
        elevation:       0.5,
        actions: [
          IconButton(
            onPressed: notifier.load,
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ── Stats Banner ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        AppColor.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(
                    color: AppColor.primary.withOpacity(0.15)),
              ),
              child: Row(children: [
                _StatChip(
                  label: 'Invoices',
                  value: '${state.invoiceCount}',
                  color: AppColor.primary,
                  icon:  Icons.receipt_long_outlined,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Total',
                  value: 'Rs ${state.totalSale.toStringAsFixed(0)}',
                  color: AppColor.success,
                  icon:  Icons.payments_outlined,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Cash',
                  value: 'Rs ${state.cashSale.toStringAsFixed(0)}',
                  color: AppColor.info,
                  icon:  Icons.money_outlined,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Credit',
                  value: 'Rs ${state.creditSale.toStringAsFixed(0)}',
                  color: AppColor.warning,
                  icon:  Icons.credit_card_outlined,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Discount',
                  value: 'Rs ${state.totalDiscount.toStringAsFixed(0)}',
                  color: AppColor.error,
                  icon:  Icons.discount_outlined,
                ),
              ]),
            ),

            const SizedBox(height: 14),

            // ── Filters ────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged:  notifier.onSearchChanged,
                    style:        const TextStyle(fontSize: 13),
                    cursorHeight: 14,
                    decoration: InputDecoration(
                      hintText:  'Search invoice, product...',
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
                          notifier.onSearchChanged('');
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
                OutlinedButton.icon(
                  onPressed: notifier.setToday,
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
                const SizedBox(width: 12),
                _dateField(
                  label: 'Start Date',
                  ctrl:  _startDateCtrl,
                  onTap: () async {
                    final picked = await _pickDate(state.fromDate);
                    if (picked != null) {
                      notifier.setDateRange(picked, state.toDate);
                    }
                  },
                ),
                const SizedBox(width: 8),
                const Text('—',
                    style: TextStyle(color: AppColor.textSecondary)),
                const SizedBox(width: 8),
                _dateField(
                  label: 'End Date',
                  ctrl:  _endDateCtrl,
                  onTap: () async {
                    final picked = await _pickDate(state.toDate);
                    if (picked != null) {
                      notifier.setDateRange(state.fromDate, picked);
                    }
                  },
                ),
              ]),
            ),

            const SizedBox(height: 14),

            // ── Invoice List ───────────────────────────────
            Expanded(
              child: invoices.isEmpty
                  ? _EmptyState(isSearching: state.searchQuery.isNotEmpty)
                  : ListView.separated(
                itemCount:        invoices.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
                itemBuilder: (_, i) => _CustomerInvoiceCard(
                  inv:     invoices[i],
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

// ── Stat Chip ─────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String   label;
  final String   value;
  final Color    color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w800,
                  color:      color)),
        ],
      ),
    ),
  );
}

// ── Invoice Card ──────────────────────────────────────────────
class _CustomerInvoiceCard extends StatelessWidget {
  final CustomerInvoiceModel inv;
  final DateFormat           dateFmt;
  final DateFormat           timeFmt;

  const _CustomerInvoiceCard({
    required this.inv,
    required this.dateFmt,
    required this.timeFmt,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = inv.items
        .fold(0.0, (s, i) => s + i.totalAmount);

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [

        // ── Header ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColor.primary.withOpacity(0.04),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14)),
            border: Border(
              bottom: BorderSide(
                  color: AppColor.grey300.withOpacity(0.6)),
            ),
          ),
          child: Row(children: [
            const Icon(Icons.receipt_long_outlined,
                size: 15, color: AppColor.primary),
            const SizedBox(width: 6),
            Text(inv.invoiceNo,
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w800,
                    color:      AppColor.primary,
                    letterSpacing: 0.3)),
            const Spacer(),
            _PaymentBadge(type: inv.paymentType),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(dateFmt.format(inv.invoiceDate),
                  style: const TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      color:      AppColor.textPrimary)),
              Text(timeFmt.format(inv.invoiceDate),
                  style: const TextStyle(
                      fontSize: 11, color: AppColor.textSecondary)),
            ]),
          ]),
        ),

        // ── Items Table ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                  color:        AppColor.grey100,
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Expanded(flex: 4,
                    child: Text('Product',
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textSecondary))),
                Expanded(flex: 2,
                    child: Text('Price',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textSecondary))),
                Expanded(flex: 1,
                    child: Text('Qty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textSecondary))),
                Expanded(flex: 2,
                    child: Text('Discount',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textSecondary))),
                Expanded(flex: 2,
                    child: Text('Sub Total',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textSecondary))),
              ]),
            ),
            const SizedBox(height: 4),

            ...inv.items.asMap().entries.map((e) {
              final idx  = e.key;
              final item = e.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: idx % 2 != 0
                      ? AppColor.grey100.withOpacity(0.5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(children: [
                  Expanded(flex: 4,
                      child: Text(item.productName,
                          style: const TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w500,
                              color:      AppColor.textPrimary),
                          overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 2,
                      child: Text(item.priceLabel,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 11,
                              color:    AppColor.textPrimary))),
                  Expanded(flex: 1,
                      child: Text(item.qtyLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize:   11,
                              fontWeight: FontWeight.w600,
                              color:      AppColor.textPrimary))),
                  Expanded(flex: 2,
                      child: Text(
                          'Rs ${item.discount.toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 11,
                              color:    AppColor.warning))),
                  Expanded(flex: 2,
                      child: Text(item.totalLabel,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize:   11,
                              fontWeight: FontWeight.w700,
                              color:      AppColor.primary))),
                ]),
              );
            }),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 10),

            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Text('Sub Total:',
                  style: TextStyle(
                      fontSize: 12, color: AppColor.textSecondary)),
              const SizedBox(width: 12),
              Text('Rs ${subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.textPrimary)),
            ]),

            if (inv.totalDiscount > 0) ...[
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                const Text('Discount:',
                    style: TextStyle(
                        fontSize: 12, color: AppColor.textSecondary)),
                const SizedBox(width: 12),
                Text('- ${inv.discountLabel}',
                    style: const TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.warning)),
              ]),
            ],

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:        AppColor.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColor.success.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusBadge(status: inv.status),
                  Row(children: [
                    const Text('Grand Total:',
                        style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.textSecondary)),
                    const SizedBox(width: 10),
                    Text(inv.grandTotalLabel,
                        style: const TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.w800,
                            color:      AppColor.success)),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────
class _PaymentBadge extends StatelessWidget {
  final String type;
  const _PaymentBadge({required this.type});

  Color    get _color => type.contains('credit') ? AppColor.warning : type.contains('card') ? AppColor.info : AppColor.success;
  IconData get _icon  => type.contains('credit') ? Icons.credit_card_outlined : type.contains('card') ? Icons.credit_card_outlined : Icons.payments_outlined;
  String   get _label => type.contains('credit') ? 'Credit' : type.contains('card') ? 'Card' : 'Cash';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color:        _color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: _color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(_icon, size: 11, color: _color),
      const SizedBox(width: 4),
      Text(_label,
          style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      _color)),
    ]),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color    get _color => status == 'completed' ? AppColor.success : status == 'cancelled' ? AppColor.error : AppColor.warning;
  IconData get _icon  => status == 'completed' ? Icons.check_circle_outline_rounded : status == 'cancelled' ? Icons.cancel_outlined : Icons.assignment_return_outlined;
  String   get _label => status == 'completed' ? 'Completed' : status == 'cancelled' ? 'Cancelled' : 'Returned';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color:        _color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(_icon, size: 12, color: _color),
      const SizedBox(width: 4),
      Text(_label,
          style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      _color)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  const _EmptyState({this.isSearching = false});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(
        isSearching
            ? Icons.search_off_rounded
            : Icons.receipt_long_outlined,
        size:  64,
        color: AppColor.grey300,
      ),
      const SizedBox(height: 16),
      Text(
        isSearching ? 'Koi invoice nahi mila' : 'Koi invoice nahi',
        style: const TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w600,
            color:      AppColor.textSecondary),
      ),
      const SizedBox(height: 6),
      Text(
        isSearching ? 'Search change karein' : 'Is customer ki koi sale nahi',
        style: const TextStyle(
            fontSize: 13, color: AppColor.textHint),
      ),
    ]),
  );
}