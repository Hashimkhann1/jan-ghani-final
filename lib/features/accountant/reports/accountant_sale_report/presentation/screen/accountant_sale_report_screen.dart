import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../data/model/accountant_sale_report_model.dart';
import '../provider/accountant_sale_report_provider.dart';

class AccountantSaleReportScreen extends ConsumerStatefulWidget {
  const AccountantSaleReportScreen({super.key});

  @override
  ConsumerState<AccountantSaleReportScreen> createState() =>
      _AccountantSaleReportScreenState();
}

class _AccountantSaleReportScreenState
    extends ConsumerState<AccountantSaleReportScreen> {
  final _dateFmt    = DateFormat('dd MMM yyyy');
  final _timeFmt    = DateFormat('hh:mm a');
  final _fromCtrl   = TextEditingController();
  final _toCtrl     = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(accountantSaleReportProvider);
    _fromCtrl.text = _dateFmt.format(state.fromDate);
    _toCtrl.text   = _dateFmt.format(state.toDate);
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final state = ref.read(accountantSaleReportProvider);
    final init  = isFrom ? state.fromDate : state.toDate;

    final picked = await showDatePicker(
      context:     context,
      initialDate: init,
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColor.primary,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      if (isFrom) {
        _fromCtrl.text = _dateFmt.format(picked);
        ref.read(accountantSaleReportProvider.notifier)
            .setFromDate(picked);
      } else {
        _toCtrl.text = _dateFmt.format(picked);
        ref.read(accountantSaleReportProvider.notifier)
            .setToDate(picked);
      }
    }
  }

  // ✅ FIX: Smart quantity formatter — decimal preserve karta hai
  String _fmtQty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  final _amtFmt = NumberFormat('#,##,###', 'en_IN');

  String _fmtAmt(double v) {
    return 'Rs ${_amtFmt.format(v.toInt())}';
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(accountantSaleReportProvider);
    final notifier = ref.read(accountantSaleReportProvider.notifier);
    final summary  = state.summary;

    ref.listen<AccountantSaleReportState>(
        accountantSaleReportProvider, (_, next) {
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

    // Customer dropdown items
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

    // Payment type items
    final paymentItems = [
      DropdownItem<String?>(
          value: null, label: 'All Payments',
          icon: Icons.payment_outlined),
      DropdownItem<String?>(
          value: 'cash',   label: 'Cash',
          icon: Icons.payments_outlined),
      DropdownItem<String?>(
          value: 'card',   label: 'Card',
          icon: Icons.credit_card_outlined),
      DropdownItem<String?>(
          value: 'credit', label: 'Credit',
          icon: Icons.receipt_long_outlined),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Sale Report',
            style: TextStyle(
                fontSize:   17,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF1A1D23))),
        actions: [
          IconButton(
            onPressed: notifier.load,
            icon:    const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
            tooltip: 'Refresh',
          ),
          TextButton(
            onPressed: () {
              notifier.setToday();
              final today = DateTime.now();
              final todayClean = DateTime(today.year, today.month, today.day);
              _fromCtrl.text = _dateFmt.format(todayClean);
              _toCtrl.text   = _dateFmt.format(todayClean);
            },
            child: const Text('Today',),
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

          // ── Filters ───────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [

                // Date Row
                Row(children: [
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
                ]),

                const SizedBox(height: 10),

                // Customer Dropdown
                AppSearchableDropdown<String?>(
                  items:     customerItems,
                  value:     state.selectedCustomerId,
                  hint:      'All Customers',
                  fullWidth: true,
                  prefixIcon: Icons.person_outline_rounded,
                  onChanged: (v) => notifier.setCustomer(v),
                ),

                const SizedBox(height: 10),

                // Payment Type Dropdown
                AppSearchableDropdown<String?>(
                  items:     paymentItems,
                  value:     state.selectedPaymentType,
                  hint:      'All Payment Types',
                  fullWidth: true,
                  prefixIcon: Icons.payment_outlined,
                  onChanged: (v) => notifier.setPaymentType(v),
                ),
              ],
            ),
          ),

          // ── Summary Cards ─────────────────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              _SummaryTile(
                label: 'Invoices',
                value: '${summary.totalInvoices}',
                icon:  Icons.receipt_outlined,
                color: AppColor.primary,
              ),
              _divider(),
              _SummaryTile(
                label: 'Total Sale',
                value: _fmtAmt(summary.totalSale),
                icon:  Icons.payments_outlined,
                color: AppColor.success,
              ),
              _divider(),
              _SummaryTile(
                label: 'Qty',
                value: _fmtQty(summary.totalQuantity), // ✅ FIX
                icon:  Icons.inventory_2_outlined,
                color: AppColor.warning,
              ),
              _divider(),
              _SummaryTile(
                label: 'Discount',
                value: _fmtAmt(summary.totalDiscount),
                icon:  Icons.discount_outlined,
                color: AppColor.error,
              ),
            ]),
          ),

          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 8),

          // ── List ──────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.invoices.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount:      state.invoices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _InvoiceCard(
                  invoice: state.invoices[i],
                  dateFmt: _dateFmt,
                  timeFmt: _timeFmt,
                  fmtQty:  _fmtQty, // ✅ FIX: pass karo
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1, height: 36,
    color: const Color(0xFFE5E7EB),
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );
}

// ── Invoice Card ──────────────────────────────────────────────
class _InvoiceCard extends StatefulWidget {
  final SaleReportInvoice      invoice;
  final DateFormat             dateFmt;
  final DateFormat             timeFmt;
  final String Function(double) fmtQty; // ✅ FIX

  const _InvoiceCard({
    required this.invoice,
    required this.dateFmt,
    required this.timeFmt,
    required this.fmtQty, // ✅ FIX
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

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;

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
      child: Column(children: [

        // ── Header ──────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Invoice icon
              Container(
                width:  42,
                height: 42,
                decoration: BoxDecoration(
                  color:        AppColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_outlined,
                    size: 20, color: AppColor.primary),
              ),
              const SizedBox(width: 12),

              // Invoice info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(inv.invoiceNo,
                            style: const TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w700,
                                color:      AppColor.primary)),
                        Text(
                          'Rs ${inv.grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize:   14,
                              fontWeight: FontWeight.w800,
                              color:      Color(0xFF1A1D23)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            inv.customerLabel,
                            style: const TextStyle(
                                fontSize: 12,
                                color:    AppColor.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PayBadge(
                          label: inv.paymentLabel,
                          color: _paymentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.dateFmt.format(inv.invoiceDate)}  ${widget.timeFmt.format(inv.invoiceDate)}',
                          style: const TextStyle(
                              fontSize: 10,
                              color:    AppColor.textHint),
                        ),
                        Text(
                          // ✅ FIX: toStringAsFixed(0) → _fmtQty
                          '${inv.items.length} items  •  Qty: ${widget.fmtQty(inv.totalQuantity)}',
                          style: const TextStyle(
                              fontSize: 10,
                              color:    AppColor.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns:    _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down,
                    size: 20, color: AppColor.grey400),
              ),
            ]),
          ),
        ),

        // ── Expanded Items ───────────────────────────────
        if (_expanded) ...[
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [

              // Items header
              Row(children: const [
                Expanded(flex: 3, child: _IH(text: 'Product')),
                Expanded(flex: 1, child: _IH(text: 'Qty',   right: false)),
                Expanded(flex: 1, child: _IH(text: 'Price', right: false)),
                Expanded(flex: 1, child: _IH(text: 'Total', right: true)),
              ]),
              const SizedBox(height: 6),

              ...inv.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: Text(item.productName,
                        style: const TextStyle(
                            fontSize: 12,
                            color:    AppColor.textPrimary),
                        maxLines:  1,
                        overflow:  TextOverflow.ellipsis),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      widget.fmtQty(item.quantity), // ✅ FIX
                      style: const TextStyle(
                          fontSize: 12,
                          color:    AppColor.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Rs ${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12,
                          color:    AppColor.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Rs ${item.totalAmount.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color:      AppColor.textPrimary),
                    ),
                  ),
                ]),
              )),

              // Discount row
              if (inv.totalDiscount > 0) ...[
                const Divider(height: 12, color: Color(0xFFE5E7EB)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],

              // Grand total
              const Divider(height: 12, color: Color(0xFFE5E7EB)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total',
                      style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w700)),
                  Text(
                    'Rs ${inv.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w800,
                        color:      AppColor.primary),
                  ),
                ],
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ── Date Field ────────────────────────────────────────────────
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
      Text(label,
          style: const TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      AppColor.textSecondary)),
      const SizedBox(height: 4),
      TextField(
        controller:  controller,
        readOnly:    true,
        onTap:       onTap,
        cursorHeight: 14,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppColor.primary),
          filled:     true,
          fillColor:  AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
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

// ── Summary Tile ──────────────────────────────────────────────
class _SummaryTile extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w800,
                color:      color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color:    AppColor.textHint)),
      ],
    ),
  );
}

// ── Payment Badge ─────────────────────────────────────────────
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
    child: Text(label,
        style: TextStyle(
            fontSize:   10,
            fontWeight: FontWeight.w600,
            color:      color)),
  );
}

// ── Item Header ───────────────────────────────────────────────
class _IH extends StatelessWidget {
  final String text;
  final bool   right;
  const _IH({required this.text, this.right = false});

  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
          fontSize:      10,
          fontWeight:    FontWeight.w600,
          color:         AppColor.textHint,
          letterSpacing: 0.3));
}

// ── Empty State ───────────────────────────────────────────────
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
        Text('Koi invoice nahi mila',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 6),
        Text('Filters change karein ya date range update karein',
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );
}