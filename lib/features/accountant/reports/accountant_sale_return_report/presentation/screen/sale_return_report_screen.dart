import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../data/model/sale_return_report_model.dart';
import '../provider/sale_return_report_provider.dart';

class AccountantSaleReturnReportScreen extends ConsumerStatefulWidget {
  const AccountantSaleReturnReportScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    final state = ref.read(accountantSaleReturnProvider);
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
    final state = ref.read(accountantSaleReturnProvider);
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
      if (isFrom) {
        _fromCtrl.text = _dateFmt.format(picked);
        ref.read(accountantSaleReturnProvider.notifier).setFromDate(picked);
      } else {
        _toCtrl.text = _dateFmt.format(picked);
        ref.read(accountantSaleReturnProvider.notifier).setToDate(picked);
      }
    }
  }

  String _fmtAmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(accountantSaleReturnProvider);
    final notifier = ref.read(accountantSaleReturnProvider.notifier);
    final summary  = state.summary;

    ref.listen<AccountantSaleReturnState>(
        accountantSaleReturnProvider, (_, next) {
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

    // Customer dropdown
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

    // Refund type dropdown (matches DB refund_type values)
    final refundItems = [
      DropdownItem<String?>(
          value: null,     label: 'All Refund Types',
          icon: Icons.swap_horiz_rounded),
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
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Return Report',
          style: TextStyle(
              fontSize:   17,
              fontWeight: FontWeight.w700,
              color:      Color(0xFF1A1D23)),
        ),
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
              final clean = DateTime(today.year, today.month, today.day);
              _fromCtrl.text = _dateFmt.format(clean);
              _toCtrl.text   = _dateFmt.format(clean);
            },
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

          // ── Filters ───────────────────────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(children: [

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
                items:      customerItems,
                value:      state.selectedCustomerId,
                hint:       'All Customers',
                fullWidth:  true,
                prefixIcon: Icons.person_outline_rounded,
                onChanged:  (v) => notifier.setCustomer(v),
              ),

              const SizedBox(height: 10),

              // Refund Type Dropdown
              AppSearchableDropdown<String?>(
                items:      refundItems,
                value:      state.selectedRefundType,
                hint:       'All Refund Types',
                fullWidth:  true,
                prefixIcon: Icons.swap_horiz_rounded,
                onChanged:  (v) => notifier.setRefundType(v),
              ),
            ]),
          ),

          // ── Summary Cards ─────────────────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              _SummaryTile(
                label: 'Returns',
                value: '${summary.totalReturns}',
                icon:  Icons.assignment_return_outlined,
                color: AppColor.primary,
              ),
              _divider(),
              _SummaryTile(
                label: 'Total Return',
                value: _fmtAmt(summary.totalAmount),
                icon:  Icons.payments_outlined,
                color: AppColor.error,
              ),
              _divider(),
              _SummaryTile(
                label: 'Qty',
                value: summary.totalQuantity.toStringAsFixed(0),
                icon:  Icons.inventory_2_outlined,
                color: AppColor.warning,
              ),
              _divider(),
              _SummaryTile(
                label: 'Discount',
                value: _fmtAmt(summary.totalDiscount),
                icon:  Icons.discount_outlined,
                color: AppColor.success,
              ),
            ]),
          ),

          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 8),

          // ── List ──────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.returns.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount:        state.returns.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (_, i) => _ReturnCard(
                  ret:     state.returns[i],
                  dateFmt: _dateFmt,
                  timeFmt: _timeFmt,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width:  1,
    height: 36,
    color:  const Color(0xFFE5E7EB),
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );
}

// ═══════════════════════════════════════════════════════════
//  Return Card
// ═══════════════════════════════════════════════════════════

class _ReturnCard extends StatefulWidget {
  final SaleReturnInvoice ret;
  final DateFormat        dateFmt;
  final DateFormat        timeFmt;

  const _ReturnCard({
    required this.ret,
    required this.dateFmt,
    required this.timeFmt,
  });

  @override
  State<_ReturnCard> createState() => _ReturnCardState();
}

class _ReturnCardState extends State<_ReturnCard> {
  bool _expanded = false;

  Color get _refundColor {
    switch (widget.ret.refundType) {
      case 'card':   return AppColor.info;
      case 'credit': return AppColor.warning;
      default:       return AppColor.success; // cash
    }
  }

  @override
  Widget build(BuildContext context) {
    final ret = widget.ret;

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

        // ── Header ─────────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [

              // Icon
              Container(
                width:  42,
                height: 42,
                decoration: BoxDecoration(
                  color:        AppColor.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_return_outlined,
                  size:  20,
                  color: AppColor.error,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Return No  |  Grand Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ret.returnNo,
                            style: const TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w700,
                                color:      AppColor.error)),
                        Text(
                          'Rs ${ret.grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize:   14,
                              fontWeight: FontWeight.w800,
                              color:      Color(0xFF1A1D23)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Customer  |  Refund Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ret.customerLabel,
                            style: const TextStyle(
                                fontSize: 12,
                                color:    AppColor.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PayBadge(
                          label: ret.paymentLabel,
                          color: _refundColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Date  |  Items count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.dateFmt.format(ret.returnDate)}  ${widget.timeFmt.format(ret.returnDate)}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColor.textHint),
                        ),
                        Text(
                          '${ret.items.length} items  •  Qty: ${ret.totalQuantity.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColor.textHint),
                        ),
                      ],
                    ),

                    // Return reason (if available)
                    if (ret.returnReason != null &&
                        ret.returnReason!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.info_outline,
                            size: 11, color: AppColor.textHint),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ret.returnReason!,
                            style: const TextStyle(
                                fontSize: 10, color: AppColor.textHint),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
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

        // ── Expanded Items ──────────────────────────────────
        if (_expanded) ...[
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [

              // Items header
              const Row(children: [
                Expanded(flex: 3, child: _IH(text: 'Product')),
                Expanded(flex: 1, child: _IH(text: 'Qty',   right: false)),
                Expanded(flex: 1, child: _IH(text: 'Price', right: false)),
                Expanded(flex: 1, child: _IH(text: 'Total', right: true)),
              ]),
              const SizedBox(height: 6),

              ...ret.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: Text(item.productName,
                        style: const TextStyle(
                            fontSize: 12,
                            color:    AppColor.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      item.quantity.toStringAsFixed(0),
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
              if (ret.totalDiscount > 0) ...[
                const Divider(height: 12, color: Color(0xFFE5E7EB)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount',
                        style: TextStyle(
                            fontSize: 12,
                            color:    AppColor.textSecondary)),
                    Text(
                      '- Rs ${ret.totalDiscount.toStringAsFixed(0)}',
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
                    'Rs ${ret.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w800,
                        color:      AppColor.error),
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

// ═══════════════════════════════════════════════════════════
//  Shared Widgets (same pattern as sale report)
// ═══════════════════════════════════════════════════════════

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
        controller:   controller,
        readOnly:     true,
        onTap:        onTap,
        cursorHeight: 14,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
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
            borderSide:   const BorderSide(
                color: AppColor.primary, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

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
    child: Column(children: [
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
              color:      color),
          maxLines:  1,
          overflow:  TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: AppColor.textHint)),
    ]),
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
    child: Text(label,
        style: TextStyle(
            fontSize:   10,
            fontWeight: FontWeight.w600,
            color:      color)),
  );
}

class _IH extends StatelessWidget {
  final String text;
  final bool   right;
  const _IH({required this.text, this.right = false});

  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
          fontSize:     10,
          fontWeight:   FontWeight.w600,
          color:        AppColor.textHint,
          letterSpacing: 0.3));
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
        Text('Koi return nahi mila',
            style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text('Filters change karein ya date range update karein',
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );
}