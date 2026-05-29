import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../data/model/customer_invoice_model.dart';
import '../../data/model/customer_return_model.dart';
import '../../data/model/specific_customer_ledger_model.dart';
import '../provider/customer_invoice_provider.dart';
import '../provider/customer_return_provider.dart';
import '../provider/specific_customer_ledger_provider.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState
    extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabCtrl;
  final _dateFmt  = DateFormat('dd MMM yyyy');
  final _timeFmt  = DateFormat('hh:mm a');
  final _amtFmt   = NumberFormat('#,##,###', 'en_IN');

  // ── Sale filters ──────────────────────────────────────────
  final _saleFromCtrl = TextEditingController();
  final _saleToCtrl   = TextEditingController();

  // ── Return filters ────────────────────────────────────────
  final _retFromCtrl = TextEditingController();
  final _retToCtrl   = TextEditingController();

  ({String customerId, String customerName}) get _args => (
  customerId:   widget.customerId,
  customerName: widget.customerName,
  );

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sale = ref.read(customerInvoiceProvider(_args));
      _saleFromCtrl.text = _dateFmt.format(sale.fromDate);
      _saleToCtrl.text   = _dateFmt.format(sale.toDate);

      final ret = ref.read(customerReturnProvider(_args));
      _retFromCtrl.text = _dateFmt.format(ret.fromDate);
      _retToCtrl.text   = _dateFmt.format(ret.toDate);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _saleFromCtrl.dispose();
    _saleToCtrl.dispose();
    _retFromCtrl.dispose();
    _retToCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  Future<DateTime?> _pickDate(DateTime initial) async =>
      showDatePicker(
        context:     context,
        initialDate: initial,
        firstDate:   DateTime(2024),
        lastDate:    DateTime.now(),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
                primary: AppColor.primary),
          ),
          child: child!,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Detail',
                style: TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.w700,
                    color:      Color(0xFF1A1D23))),
            Text(widget.customerName,
                style: const TextStyle(
                    fontSize: 12, color: AppColor.textSecondary)),
          ],
        ),
        toolbarHeight: 65,
        bottom: TabBar(
          controller:         _tabCtrl,
          labelColor:         AppColor.primary,
          unselectedLabelColor: AppColor.textSecondary,
          indicatorColor:     AppColor.primary,
          indicatorWeight:    2.5,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Sales',   icon: Icon(Icons.receipt_long_outlined,   size: 18)),
            Tab(text: 'Returns', icon: Icon(Icons.assignment_return_outlined, size: 18)),
            Tab(text: 'Ledger',  icon: Icon(Icons.account_balance_wallet_outlined, size: 18)),
          ],
        ),
        flexibleSpace: Container(color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _SaleTab(
            args:       _args,
            dateFmt:    _dateFmt,
            timeFmt:    _timeFmt,
            fromCtrl:   _saleFromCtrl,
            toCtrl:     _saleToCtrl,
            fmt:        _fmt,
            pickDate:   _pickDate,
          ),
          _ReturnTab(
            args:       _args,
            dateFmt:    _dateFmt,
            timeFmt:    _timeFmt,
            fromCtrl:   _retFromCtrl,
            toCtrl:     _retToCtrl,
            fmt:        _fmt,
            pickDate:   _pickDate,
          ),
          _LedgerTab(
            args:     _args,
            dateFmt:  _dateFmt,
            timeFmt:  _timeFmt,
            amtFmt:   _amtFmt,
            fmt:      _fmt,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1 — Sales
// ══════════════════════════════════════════════════════════════
class _SaleTab extends ConsumerWidget {
  final ({String customerId, String customerName}) args;
  final DateFormat                                 dateFmt;
  final DateFormat                                 timeFmt;
  final TextEditingController                      fromCtrl;
  final TextEditingController                      toCtrl;
  final String Function(double)                    fmt;
  final Future<DateTime?> Function(DateTime)       pickDate;

  const _SaleTab({
    required this.args,
    required this.dateFmt,
    required this.timeFmt,
    required this.fromCtrl,
    required this.toCtrl,
    required this.fmt,
    required this.pickDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(customerInvoiceProvider(args));
    final notifier = ref.read(customerInvoiceProvider(args).notifier);
    final invoices = state.filteredInvoices;

    final refundItems = [
      DropdownItem<String?>(value: null,     label: 'All Types',   icon: Icons.swap_horiz_rounded),
      DropdownItem<String?>(value: 'cash',   label: 'Cash',        icon: Icons.payments_outlined),
      DropdownItem<String?>(value: 'card',   label: 'Card',        icon: Icons.credit_card_outlined),
      DropdownItem<String?>(value: 'credit', label: 'Credit',      icon: Icons.receipt_long_outlined),
    ];

    return Column(children: [

      // ── Filters ──────────────────────────────────────────
      Container(
        color:   Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Row(children: [
          Expanded(
            child: _DateField(
              label:      'Start',
              controller: fromCtrl,
              onTap: () async {
                final p = await pickDate(state.fromDate);
                if (p != null) {
                  fromCtrl.text = dateFmt.format(p);
                  notifier.setDateRange(p, state.toDate);
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DateField(
              label:      'End',
              controller: toCtrl,
              onTap: () async {
                final p = await pickDate(state.toDate);
                if (p != null) {
                  toCtrl.text = dateFmt.format(p);
                  notifier.setDateRange(state.fromDate, p);
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {
              notifier.setToday();
              final today = DateTime.now();
              final d     = DateTime(today.year, today.month, today.day);
              fromCtrl.text = dateFmt.format(d);
              toCtrl.text   = dateFmt.format(d);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.primary,
              side:    const BorderSide(color: AppColor.primary),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Today',
                style: TextStyle(fontSize: 12)),
          ),
        ]),
      ),

      // ── Summary ───────────────────────────────────────────
      Container(
        color:   Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(children: [
          _StatTile(
            label: 'Invoices',
            value: '${state.invoiceCount}',
            color: AppColor.primary,
            icon:  Icons.receipt_long_outlined,
          ),
          _vDivider(),
          _StatTile(
            label: 'Total',
            value: fmt(state.totalSale),
            color: AppColor.success,
            icon:  Icons.payments_outlined,
          ),
          _vDivider(),
          _StatTile(
            label: 'Cash',
            value: fmt(state.cashSale),
            color: AppColor.info,
            icon:  Icons.money_outlined,
          ),
          _vDivider(),
          _StatTile(
            label: 'Credit',
            value: fmt(state.creditSale),
            color: AppColor.warning,
            icon:  Icons.credit_card_outlined,
          ),
        ]),
      ),

      Container(height: 1, color: const Color(0xFFE5E7EB)),
      const SizedBox(height: 6),

      // ── List ──────────────────────────────────────────────
      Expanded(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : invoices.isEmpty
            ? const _EmptyState(
            icon:    Icons.receipt_long_outlined,
            message: 'Koi sale nahi mili')
            : RefreshIndicator(
          onRefresh: notifier.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount:        invoices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _SaleCard(
              inv:     invoices[i],
              dateFmt: dateFmt,
              timeFmt: timeFmt,
            ),
          ),
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 2 — Returns
// ══════════════════════════════════════════════════════════════
class _ReturnTab extends ConsumerWidget {
  final ({String customerId, String customerName}) args;
  final DateFormat                                 dateFmt;
  final DateFormat                                 timeFmt;
  final TextEditingController                      fromCtrl;
  final TextEditingController                      toCtrl;
  final String Function(double)                    fmt;
  final Future<DateTime?> Function(DateTime)       pickDate;

  const _ReturnTab({
    required this.args,
    required this.dateFmt,
    required this.timeFmt,
    required this.fromCtrl,
    required this.toCtrl,
    required this.fmt,
    required this.pickDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(customerReturnProvider(args));
    final notifier = ref.read(customerReturnProvider(args).notifier);
    final returns  = state.returns;
    final summary  = state.summary;

    return Column(children: [

      // ── Filters ──────────────────────────────────────────
      Container(
        color:   Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Row(children: [
          Expanded(
            child: _DateField(
              label:      'Start',
              controller: fromCtrl,
              onTap: () async {
                final p = await pickDate(state.fromDate);
                if (p != null) {
                  fromCtrl.text = dateFmt.format(p);
                  notifier.setFromDate(p);
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DateField(
              label:      'End',
              controller: toCtrl,
              onTap: () async {
                final p = await pickDate(state.toDate);
                if (p != null) {
                  toCtrl.text = dateFmt.format(p);
                  notifier.setToDate(p);
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {
              notifier.setToday();
              final today = DateTime.now();
              final d     = DateTime(today.year, today.month, today.day);
              fromCtrl.text = dateFmt.format(d);
              toCtrl.text   = dateFmt.format(d);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.error,
              side:    const BorderSide(color: AppColor.error),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Today',
                style: TextStyle(fontSize: 12)),
          ),
        ]),
      ),

      // ── Summary ───────────────────────────────────────────
      Container(
        color:   Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(children: [
          _StatTile(
            label: 'Returns',
            value: '${summary.totalReturns}',
            color: AppColor.primary,
            icon:  Icons.assignment_return_outlined,
          ),
          _vDivider(),
          _StatTile(
            label: 'Total',
            value: fmt(summary.totalAmount),
            color: AppColor.error,
            icon:  Icons.payments_outlined,
          ),
          _vDivider(),
          _StatTile(
            label: 'Qty',
            value: summary.totalQuantity.toStringAsFixed(0),
            color: AppColor.warning,
            icon:  Icons.inventory_2_outlined,
          ),
          _vDivider(),
          _StatTile(
            label: 'Discount',
            value: fmt(summary.totalDiscount),
            color: AppColor.success,
            icon:  Icons.discount_outlined,
          ),
        ]),
      ),

      Container(height: 1, color: const Color(0xFFE5E7EB)),
      const SizedBox(height: 6),

      // ── List ──────────────────────────────────────────────
      Expanded(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : returns.isEmpty
            ? const _EmptyState(
            icon:    Icons.assignment_return_outlined,
            message: 'Koi return nahi mila')
            : RefreshIndicator(
          onRefresh: notifier.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount:        returns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ReturnCard(
              ret:     returns[i],
              dateFmt: dateFmt,
              timeFmt: timeFmt,
            ),
          ),
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 3 — Ledger
// ══════════════════════════════════════════════════════════════
class _LedgerTab extends ConsumerWidget {
  final ({String customerId, String customerName}) args;
  final DateFormat                                 dateFmt;
  final DateFormat                                 timeFmt;
  final NumberFormat                               amtFmt;
  final String Function(double)                    fmt;

  const _LedgerTab({
    required this.args,
    required this.dateFmt,
    required this.timeFmt,
    required this.amtFmt,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(customerLedgerProvider(args));
    final notifier = ref.read(customerLedgerProvider(args).notifier);

    return Column(children: [

      // ── Summary ───────────────────────────────────────────
      Container(
        color:   Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Row(children: [
          _StatTile(
            label: 'Transactions',
            value: '${state.ledger.length}',
            color: AppColor.primary,
            icon:  Icons.receipt_long_outlined,
          ),
          _vDivider(),
          _StatTile(
            label: 'Total Paid',
            value: fmt(state.totalPaid),
            color: AppColor.success,
            icon:  Icons.payments_outlined,
          ),
          _vDivider(),
          _StatTile(
            label: 'Balance',
            value: fmt(state.currentBalance),
            color: state.currentBalance > 0
                ? AppColor.error
                : AppColor.success,
            icon:  Icons.account_balance_wallet_outlined,
          ),
        ]),
      ),

      Container(height: 1, color: const Color(0xFFE5E7EB)),
      const SizedBox(height: 6),

      // ── List ──────────────────────────────────────────────
      Expanded(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.ledger.isEmpty
            ? const _EmptyState(
            icon:    Icons.account_balance_wallet_outlined,
            message: 'Koi ledger record nahi')
            : RefreshIndicator(
          onRefresh: notifier.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount:        state.ledger.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _LedgerRow(
              entry:   state.ledger[i],
              dateFmt: dateFmt,
              timeFmt: timeFmt,
              amtFmt:  amtFmt,
            ),
          ),
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// Sale Card
// ══════════════════════════════════════════════════════════════
class _SaleCard extends StatefulWidget {
  final CustomerInvoiceModel inv;
  final DateFormat           dateFmt;
  final DateFormat           timeFmt;

  const _SaleCard({
    required this.inv,
    required this.dateFmt,
    required this.timeFmt,
  });

  @override
  State<_SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<_SaleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final inv      = widget.inv;
    final subtotal = inv.items.fold(0.0, (s, i) => s + i.totalAmount);

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [

        // ── Header ────────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width:  40, height: 40,
                decoration: BoxDecoration(
                  color:        AppColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    size: 18, color: AppColor.primary),
              ),
              const SizedBox(width: 12),
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
                        Text(inv.grandTotalLabel,
                            style: const TextStyle(
                                fontSize:   14,
                                fontWeight: FontWeight.w800,
                                color:      Color(0xFF1A1D23))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PayBadge(type: inv.paymentType),
                        Text(
                          '${inv.items.length} items',
                          style: const TextStyle(
                              fontSize: 10,
                              color:    AppColor.textHint),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.dateFmt.format(inv.invoiceDate)}  ${widget.timeFmt.format(inv.invoiceDate)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColor.textHint),
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

        // ── Expanded ──────────────────────────────────────
        if (_expanded) ...[
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              const Row(children: [
                Expanded(flex: 3, child: _IH(text: 'Product')),
                Expanded(flex: 1, child: _IH(text: 'Qty')),
                Expanded(flex: 2, child: _IH(text: 'Price')),
                Expanded(flex: 2, child: _IH(text: 'Total', right: true)),
              ]),
              const SizedBox(height: 6),
              ...inv.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(flex: 3,
                      child: Text(item.productName,
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColor.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 1,
                      child: Text(item.qtyLabel,
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColor.textSecondary))),
                  Expanded(flex: 2,
                      child: Text(item.priceLabel,
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColor.textSecondary))),
                  Expanded(flex: 2,
                      child: Text(item.totalLabel,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w600,
                              color:      AppColor.textPrimary))),
                ]),
              )),
              if (inv.totalDiscount > 0) ...[
                const Divider(height: 12, color: Color(0xFFE5E7EB)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount',
                        style: TextStyle(
                            fontSize: 12,
                            color:    AppColor.textSecondary)),
                    Text('- ${inv.discountLabel}',
                        style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.warning)),
                  ],
                ),
              ],
              const Divider(height: 12, color: Color(0xFFE5E7EB)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total',
                      style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w700)),
                  Text(inv.grandTotalLabel,
                      style: const TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w800,
                          color:      AppColor.success)),
                ],
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Return Card
// ══════════════════════════════════════════════════════════════
class _ReturnCard extends StatefulWidget {
  final CustomerReturnInvoice ret;
  final DateFormat            dateFmt;
  final DateFormat            timeFmt;

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
      default:       return AppColor.success;
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
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [

        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width:  40, height: 40,
                decoration: BoxDecoration(
                  color:        AppColor.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_return_outlined,
                    size: 18, color: AppColor.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PayBadge2(
                            label: ret.paymentLabel,
                            color: _refundColor),
                        Text(
                          '${ret.items.length} items',
                          style: const TextStyle(
                              fontSize: 10,
                              color:    AppColor.textHint),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.dateFmt.format(ret.returnDate)}  ${widget.timeFmt.format(ret.returnDate)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColor.textHint),
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

        if (_expanded) ...[
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              const Row(children: [
                Expanded(flex: 3, child: _IH(text: 'Product')),
                Expanded(flex: 1, child: _IH(text: 'Qty')),
                Expanded(flex: 2, child: _IH(text: 'Price')),
                Expanded(flex: 2, child: _IH(text: 'Total', right: true)),
              ]),
              const SizedBox(height: 6),
              ...ret.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(flex: 3,
                      child: Text(item.productName,
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColor.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 1,
                      child: Text(item.quantity.toStringAsFixed(0),
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColor.textSecondary))),
                  Expanded(flex: 2,
                      child: Text(
                          'Rs ${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColor.textSecondary))),
                  Expanded(flex: 2,
                      child: Text(
                          'Rs ${item.totalAmount.toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w600,
                              color:      AppColor.textPrimary))),
                ]),
              )),
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
                          fontWeight: FontWeight.w600,
                          color:      AppColor.success),
                    ),
                  ],
                ),
              ],
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

// ══════════════════════════════════════════════════════════════
// Ledger Row
// ══════════════════════════════════════════════════════════════
class _LedgerRow extends StatelessWidget {
  final SpecificCustomerLedgerModel entry;
  final DateFormat          dateFmt;
  final DateFormat          timeFmt;
  final NumberFormat        amtFmt;

  const _LedgerRow({
    required this.entry,
    required this.dateFmt,
    required this.timeFmt,
    required this.amtFmt,
  });

  String _fmt(double v) => 'Rs ${amtFmt.format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final color     = isPayment ? AppColor.success : AppColor.error;
    final icon      = isPayment
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final label     = isPayment ? 'Payment' : 'Credit';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width:  40, height: 40,
          decoration: BoxDecoration(
            color:        color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:        color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                fontSize:   10,
                                fontWeight: FontWeight.w700,
                                color:      color)),
                      ),
                      if (entry.notes != null &&
                          entry.notes!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(entry.notes!,
                            style: const TextStyle(
                                fontSize: 11,
                                color:    AppColor.textHint)),
                      ],
                    ],
                  ),
                  Text(
                    isPayment
                        ? '- ${_fmt(entry.payAmount)}'
                        : '+ ${_fmt(entry.payAmount)}',
                    style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w800,
                        color:      color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${dateFmt.format(entry.createdAt)}  ${timeFmt.format(entry.createdAt)}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColor.textHint),
                  ),
                  Row(children: [
                    Text(_fmt(entry.previousAmount),
                        style: const TextStyle(
                            fontSize: 11,
                            color:    AppColor.textSecondary)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 12, color: AppColor.textHint),
                    ),
                    Text(_fmt(entry.newAmount),
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color: entry.newAmount > 0
                                ? AppColor.error
                                : AppColor.success)),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Shared Helper Widgets
// ══════════════════════════════════════════════════════════════

class _StatTile extends StatelessWidget {
  final String   label;
  final String   value;
  final Color    color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
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
        child: Icon(icon, size: 15, color: color),
      ),
      const SizedBox(height: 5),
      Text(value,
          style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w800,
              color:      color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              fontSize: 9, color: AppColor.textHint)),
    ]),
  );
}

Widget _vDivider() => Container(
  width:  1,
  height: 36,
  color:  const Color(0xFFE5E7EB),
  margin: const EdgeInsets.symmetric(horizontal: 6),
);

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
  Widget build(BuildContext context) => TextField(
    controller:   controller,
    readOnly:     true,
    onTap:        onTap,
    cursorHeight: 14,
    style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      labelText:  label,
      labelStyle: const TextStyle(
          fontSize: 11, color: AppColor.textSecondary),
      prefixIcon: const Icon(Icons.calendar_today_outlined,
          size: 14, color: AppColor.primary),
      filled:    true,
      fillColor: AppColor.grey100,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:   BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
        const BorderSide(color: AppColor.grey200),
      ),
    ),
  );
}

class _PayBadge extends StatelessWidget {
  final String type;
  const _PayBadge({required this.type});

  Color get _color => type.contains('credit')
      ? AppColor.warning
      : type.contains('card')
      ? AppColor.info
      : AppColor.success;
  String get _label => type.contains('credit')
      ? 'Credit'
      : type.contains('card')
      ? 'Card'
      : 'Cash';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color:        _color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(5),
      border:       Border.all(color: _color.withOpacity(0.3)),
    ),
    child: Text(_label,
        style: TextStyle(
            fontSize:   10,
            fontWeight: FontWeight.w600,
            color:      _color)),
  );
}

class _PayBadge2 extends StatelessWidget {
  final String label;
  final Color  color;
  const _PayBadge2({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(5),
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
  final IconData icon;
  final String   message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(message,
          style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      Colors.grey.shade500)),
    ]),
  );
}