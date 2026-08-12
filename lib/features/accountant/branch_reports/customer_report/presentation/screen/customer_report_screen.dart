import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/model/customer_invoice_model.dart';
import '../../data/model/customer_return_model.dart';
import '../../data/model/specific_customer_ledger_model.dart';
import '../../data/service/customer_report_pdf_service.dart';
import '../provider/customer_report_provider.dart';
import 'package:jan_ghani_final/core/service/session/accountant_session.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/screen/login_screen.dart';

// ─────────────────────────────────────────────────────────────
// Light theme colors — defined in one place
// ─────────────────────────────────────────────────────────────
class _Clr {
  static const bg          = Color(0xFFF5F5F5);
  static const card        = Color(0xFFFFFFFF);
  static const border      = Color(0xFFE0E0E0);
  static const borderSoft  = Color(0xFFEDEDED);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecond  = Color(0xFF6B6B6B);
  static const textMuted   = Color(0xFF9A9A9A);

  // role colors
  static const blueBg   = Color(0xFFE6F1FB);
  static const blueText = Color(0xFF0C447C);
  static const amberBg   = Color(0xFFFAEEDA);
  static const amberText = Color(0xFF854F0B);
  static const greenBg   = Color(0xFFEAF3DE);
  static const greenText = Color(0xFF3B6D11);
  static const redText   = Color(0xFFA32D2D);
}

// ─────────────────────────────────────────────────────────────
// Feed types
// ─────────────────────────────────────────────────────────────
enum _FeedType { sale, ret, ledger }

class _FeedItem {
  final _FeedType type;
  final DateTime date;
  final CustomerInvoiceModel? sale;
  final CustomerReturnInvoice? ret;
  final SpecificCustomerLedgerModel? ledger;

  _FeedItem.sale(CustomerInvoiceModel s)
      : type = _FeedType.sale,
        date = s.invoiceDate,
        sale = s,
        ret = null,
        ledger = null;

  _FeedItem.ret(CustomerReturnInvoice r)
      : type = _FeedType.ret,
        date = r.returnDate,
        sale = null,
        ret = r,
        ledger = null;

  _FeedItem.ledger(SpecificCustomerLedgerModel l)
      : type = _FeedType.ledger,
        date = l.createdAt,
        sale = null,
        ret = null,
        ledger = l;
}

// ─────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────
class CustomerReportScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;
  final double customerBalance;
  final bool hideAppBarBack;

  const CustomerReportScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerBalance,
    this.hideAppBarBack = false,
  });

  @override
  ConsumerState<CustomerReportScreen> createState() =>
      _CustomerReportScreenState();
}

class _CustomerReportScreenState extends ConsumerState<CustomerReportScreen> {
  final _dateFmt = DateFormat('dd MMM yyyy');
  final _timeFmt = DateFormat('hh:mm a');
  final _amtFmt  = NumberFormat('#,##,###', 'en_IN');

  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();

  CustomerReportArgs get _args => CustomerReportArgs(
    customerId:   widget.customerId,
    customerName: widget.customerName,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sale = ref.read(customerReportInvoiceProvider(_args));
      _fromCtrl.text = _dateFmt.format(sale.fromDate);
      _toCtrl.text   = _dateFmt.format(sale.toDate);
    });
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  Future<DateTime?> _pickDate(DateTime initial) async => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate:   DateTime(2024),
    lastDate:    DateTime.now(),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: _Clr.textPrimary),
      ),
      child: child!,
    ),
  );

  Future<void> _exportPdf() async {
    final saleState   = ref.read(customerReportInvoiceProvider(_args));
    final returnState = ref.read(customerReportReturnProvider(_args));
    final ledgerState = ref.read(customerReportLedgerProvider(_args));

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Generating PDF...'),
        duration: Duration(seconds: 2),
      ));
      await CustomerReportPdfService.exportAndShare(
        customerName:    widget.customerName,
        customerBalance: widget.customerBalance,
        fromDate:        saleState.fromDate,
        toDate:          saleState.toDate,
        sales:           saleState.filtered,
        returns:         returnState.returns,
        ledger:          ledgerState.ledger,
        totalSale:       saleState.totalSale,
        totalReturn:     returnState.summary.totalAmount,
        totalPaid:       ledgerState.totalPaid,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: _Clr.redText,
        ));
      }
    }
  }

  void _applyDateRange(DateTime from, DateTime to) {
    ref.read(customerReportInvoiceProvider(_args).notifier).setDateRange(from, to);
    ref.read(customerReportReturnProvider(_args).notifier)
      ..setFromDate(from)
      ..setToDate(to);
  }

  Future<void> _logout() async {
    await AccountantSession.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AccountantLoginScreen()),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saleState   = ref.watch(customerReportInvoiceProvider(_args));
    final returnState = ref.watch(customerReportReturnProvider(_args));
    final ledgerState = ref.watch(customerReportLedgerProvider(_args));

    final isLoading =
        saleState.isLoading || returnState.isLoading || ledgerState.isLoading;

    final feed = <_FeedItem>[
      ...saleState.filtered.map((s) => _FeedItem.sale(s)),
      ...returnState.returns.map((r) => _FeedItem.ret(r)),
      ...ledgerState.ledger.map((l) => _FeedItem.ledger(l)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final hasBalance = widget.customerBalance > 0;

    return Scaffold(
      backgroundColor: _Clr.bg,
      appBar: AppBar(
        backgroundColor:           _Clr.card,
        elevation:                 0,
        surfaceTintColor:          Colors.transparent,
        automaticallyImplyLeading: !widget.hideAppBarBack,
        leading: widget.hideAppBarBack
            ? null
            : IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _Clr.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.customerName,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _Clr.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined,
                size: 20, color: _Clr.textPrimary),
            tooltip:   'Export PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                size: 20, color: _Clr.textPrimary),
            tooltip:   'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        // ── Balance banner ──────────────────────────────────
        Container(
          width:   double.infinity,
          color:   _Clr.card,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:        _Clr.bg,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: _Clr.border, width: 0.5),
            ),
            child: Row(children: [
              Icon(
                hasBalance
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                size: 16, color: hasBalance ? _Clr.amberText : _Clr.greenText,
              ),
              const SizedBox(width: 8),
              Text(
                hasBalance ? 'Outstanding balance' : 'Balance',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _Clr.textSecond),
              ),
              const Spacer(),
              Text(
                _fmt(widget.customerBalance.abs()),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _Clr.textPrimary),
              ),
            ]),
          ),
        ),

        // ── Date filter ─────────────────────────────────────
        Container(
          color:   _Clr.card,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            Expanded(
              child: _DateField(
                label:      'Start date',
                controller: _fromCtrl,
                onTap: () async {
                  final p = await _pickDate(saleState.fromDate);
                  if (p != null) {
                    _fromCtrl.text = _dateFmt.format(p);
                    _applyDateRange(p, saleState.toDate);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateField(
                label:      'End date',
                controller: _toCtrl,
                onTap: () async {
                  final p = await _pickDate(saleState.toDate);
                  if (p != null) {
                    _toCtrl.text = _dateFmt.format(p);
                    _applyDateRange(saleState.fromDate, p);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 68,
              child: OutlinedButton(
                onPressed: () {
                  final d = DateTime.now();
                  final t = DateTime(d.year, d.month, d.day);
                  _fromCtrl.text = _dateFmt.format(t);
                  _toCtrl.text   = _dateFmt.format(t);
                  _applyDateRange(t, t);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: _Clr.card,
                  foregroundColor: _Clr.textPrimary,
                  side:    const BorderSide(color: _Clr.textPrimary),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                  shape:   RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Today', style: TextStyle(fontSize: 11)),
              ),
            ),
          ]),
        ),

        // ── Summary stats (2-column grid) ───────────────────
        Container(
          color:   _Clr.card,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: _StatCard(label: 'Sales', value: '${saleState.invoiceCount}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(label: 'Total sale', value: _fmt(saleState.totalSale)),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: _StatCard(
                  label: 'Returns',
                  value: _fmt(returnState.summary.totalAmount),
                  valueColor: _Clr.redText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Paid',
                  value: _fmt(ledgerState.totalPaid),
                  valueColor: _Clr.greenText,
                ),
              ),
            ]),
          ]),
        ),

        // ── Feed list ───────────────────────────────────────
        Expanded(
          child: isLoading
              ? const Center(
              child: CircularProgressIndicator(color: _Clr.textPrimary))
              : feed.isEmpty
              ? const _EmptyState(message: 'No records found')
              : RefreshIndicator(
            color: _Clr.textPrimary,
            onRefresh: () async {
              await Future.wait([
                ref
                    .read(customerReportInvoiceProvider(_args)
                    .notifier)
                    .load(),
                ref
                    .read(customerReportReturnProvider(_args)
                    .notifier)
                    .load(),
                ref
                    .read(customerReportLedgerProvider(_args)
                    .notifier)
                    .load(),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text('Activity',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _Clr.textMuted,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                ...feed.map((item) {
                  final card = switch (item.type) {
                    _FeedType.sale => _SaleCard(
                      inv:     item.sale!,
                      dateFmt: _dateFmt,
                      timeFmt: _timeFmt,
                      amtFmt:  _amtFmt,
                    ),
                    _FeedType.ret => _ReturnCard(
                      ret:     item.ret!,
                      dateFmt: _dateFmt,
                      timeFmt: _timeFmt,
                    ),
                    _FeedType.ledger => _LedgerCard(
                      entry:   item.ledger!,
                      dateFmt: _dateFmt,
                      timeFmt: _timeFmt,
                      amtFmt:  _amtFmt,
                    ),
                  };
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  );
                }),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Card shell — shared white raised card
// ══════════════════════════════════════════════════════════════
class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:        _Clr.card,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: _Clr.border, width: 0.5),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

// ── Role badge (Invoice / Return / Ledger) ─────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color  bg;
  final Color  text;
  const _Badge({required this.label, required this.bg, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: text)),
  );
}

// ── Outlined tag (Credit / Cash / Card) ─────────────────────
class _OutlineTag extends StatelessWidget {
  final String label;
  const _OutlineTag({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: const Color(0xFFC9C9C9)),
    ),
    child: Text(label,
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500, color: _Clr.textSecond)),
  );
}

// ── Item table header ────────────────────────────────────────
class _ItemTableHeader extends StatelessWidget {
  const _ItemTableHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: const [
      Expanded(
        flex: 3,
        child: Text('Product',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: _Clr.textMuted)),
      ),
      Expanded(
        flex: 1,
        child: Text('Qty',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: _Clr.textMuted)),
      ),
      Expanded(
        flex: 2,
        child: Text('Price',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: _Clr.textMuted)),
      ),
      Expanded(
        flex: 2,
        child: Text('Disc',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: _Clr.textMuted)),
      ),
      Expanded(
        flex: 2,
        child: Text('Sub total',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: _Clr.textMuted)),
      ),
    ]),
  );
}

// ── Item row inside an expanded invoice/return (table style) ─
class _ItemRow extends StatelessWidget {
  final String name;
  final String qty;
  final String price;
  final String discount;
  final String total;
  const _ItemRow({
    required this.name,
    required this.qty,
    required this.price,
    required this.discount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Text(name,
              style: const TextStyle(fontSize: 12, color: _Clr.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: 1,
          child: Text(qty,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _Clr.textSecond)),
        ),
        Expanded(
          flex: 2,
          child: Text(price,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _Clr.textSecond)),
        ),
        Expanded(
          flex: 2,
          child: Text(discount,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _Clr.textSecond)),
        ),
        Expanded(
          flex: 2,
          child: Text(total,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _Clr.textPrimary)),
        ),
      ],
    ),
  );
}

// ── Total row (bold "Total bill" line) ──────────────────────
class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;
  const _TotalRow({
    required this.label,
    required this.value,
    this.valueColor = _Clr.textPrimary,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 8),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: _Clr.borderSoft, width: 0.5)),
    ),
    margin: const EdgeInsets.only(top: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _Clr.textPrimary)),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// Sale Card
// ══════════════════════════════════════════════════════════════
class _SaleCard extends StatefulWidget {
  final CustomerInvoiceModel inv;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final NumberFormat amtFmt;
  const _SaleCard({
    required this.inv,
    required this.dateFmt,
    required this.timeFmt,
    required this.amtFmt,
  });
  @override
  State<_SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<_SaleCard> {
  bool _expanded = false;

  String _fmt(double v) => 'Rs ${widget.amtFmt.format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    final inv      = widget.inv;
    final isCredit = inv.paymentType.contains('credit');
    final payLabel = isCredit
        ? 'Credit'
        : inv.paymentType.contains('cash')
        ? 'Cash'
        : 'Card';

    return _CardShell(
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const _Badge(
                            label: 'Invoice', bg: _Clr.blueBg, text: _Clr.blueText),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(inv.invoiceNo,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _Clr.textPrimary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Row(children: [
                        _OutlineTag(label: payLabel),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.dateFmt.format(inv.invoiceDate)}, ${widget.timeFmt.format(inv.invoiceDate)}',
                          style: const TextStyle(fontSize: 11, color: _Clr.textMuted),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(inv.grandTotalLabel,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _Clr.textPrimary)),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns:    _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: _Clr.textSecond),
                ),
              ],
            ),
          ),
        ),

        if (_expanded) ...[
          Container(height: 0.5, color: _Clr.borderSoft),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(children: [
              const _ItemTableHeader(),
              Container(height: 0.5, color: _Clr.borderSoft),
              ...inv.items.map((it) => _ItemRow(
                name:     it.productName,
                qty:      it.qtyLabel,
                price:    it.salePriceLabel,
                discount: it.discount > 0
                    ? 'Rs ${it.discount.toStringAsFixed(0)}'
                    : '—',
                total:    it.totalLabel,
              )),
              _TotalRow(label: 'Total bill', value: inv.grandTotalLabel),
            ]),
          ),

          // payment breakdown
          Container(
            color:   _Clr.bg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(children: [
              _PaymentLine(label: 'Previous balance', value: inv.previousAmountLabel),
              const SizedBox(height: 4),
              _PaymentLine(
                  label: 'Paid now',
                  value: inv.payAmountLabel,
                  valueColor: _Clr.greenText),
              const SizedBox(height: 4),
              _PaymentLine(
                  label: 'Balance now',
                  value: inv.newAmountLabel,
                  valueColor: _Clr.redText,
                  bold: true),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ── Small key/value row used in the payment breakdown ──────
class _PaymentLine extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;
  final bool   bold;
  const _PaymentLine({
    required this.label,
    required this.value,
    this.valueColor = _Clr.textSecond,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: TextStyle(
              fontSize: 12,
              color: bold ? _Clr.textPrimary : _Clr.textSecond,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
      Text(value,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor)),
    ],
  );
}

// ══════════════════════════════════════════════════════════════
// Return Card
// ══════════════════════════════════════════════════════════════
class _ReturnCard extends StatefulWidget {
  final CustomerReturnInvoice ret;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
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

  @override
  Widget build(BuildContext context) {
    final ret = widget.ret;

    return _CardShell(
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const _Badge(
                            label: 'Return', bg: _Clr.amberBg, text: _Clr.amberText),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(ret.returnNo,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _Clr.textPrimary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Row(children: [
                        _OutlineTag(label: ret.paymentLabel),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.dateFmt.format(ret.returnDate)}, ${widget.timeFmt.format(ret.returnDate)}',
                          style: const TextStyle(fontSize: 11, color: _Clr.textMuted),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rs ${ret.grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _Clr.amberText),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns:    _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: _Clr.textSecond),
                ),
              ],
            ),
          ),
        ),

        if (_expanded) ...[
          Container(height: 0.5, color: _Clr.borderSoft),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(children: [
              const _ItemTableHeader(),
              Container(height: 0.5, color: _Clr.borderSoft),
              ...ret.items.map((it) => _ItemRow(
                name:     it.productName,
                qty:      it.qtyLabel,
                price:    it.salePriceLabel,
                discount: it.discount > 0
                    ? 'Rs ${it.discount.toStringAsFixed(0)}'
                    : '—',
                total:    'Rs ${it.totalAmount.toStringAsFixed(0)}',
              )),
              _TotalRow(
                label:      'Total return',
                value:      'Rs ${ret.grandTotal.toStringAsFixed(0)}',
                valueColor: _Clr.amberText,
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Ledger Card
// ══════════════════════════════════════════════════════════════
class _LedgerCard extends StatelessWidget {
  final SpecificCustomerLedgerModel entry;
  final DateFormat   dateFmt;
  final DateFormat   timeFmt;
  final NumberFormat amtFmt;
  const _LedgerCard({
    required this.entry,
    required this.dateFmt,
    required this.timeFmt,
    required this.amtFmt,
  });

  String _fmt(double v) => 'Rs ${amtFmt.format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final typeLabel = isPayment ? 'Payment' : 'Credit';
    final amtColor  = isPayment ? _Clr.greenText : _Clr.redText;
    final amtSign   = isPayment ? '- ' : '+ ';

    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _Badge(
                          label: 'Ledger', bg: _Clr.greenBg, text: _Clr.greenText),
                      const SizedBox(width: 6),
                      Text(typeLabel,
                          style: const TextStyle(
                              fontSize: 12, color: _Clr.textSecond)),
                    ]),
                    const SizedBox(height: 5),
                    Text(
                      '${dateFmt.format(entry.createdAt)}, ${timeFmt.format(entry.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: _Clr.textMuted),
                    ),
                    if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(entry.notes!,
                          style: const TextStyle(fontSize: 11, color: _Clr.textMuted)),
                    ],
                  ],
                ),
              ),
              Text(
                '$amtSign${_fmt(entry.payAmount)}',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: amtColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color:        _Clr.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Text(_fmt(entry.previousAmount),
                      style: const TextStyle(fontSize: 12, color: _Clr.textSecond)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child:   Icon(Icons.arrow_forward_rounded,
                        size: 13, color: _Clr.textMuted),
                  ),
                  Text(_fmt(entry.newAmount),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _Clr.redText)),
                ]),
                const Text('Balance',
                    style: TextStyle(fontSize: 10, color: _Clr.textMuted)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Small shared widgets
// ══════════════════════════════════════════════════════════════

// ── Stat card (2-column summary grid) ──────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;
  const _StatCard({
    required this.label,
    required this.value,
    this.valueColor = _Clr.textPrimary,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:        _Clr.bg,
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: _Clr.border, width: 0.5),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: _Clr.textMuted)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

// ── Date field ─────────────────────────────────────────────
class _DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;
  const _DateField(
      {required this.label,
        required this.controller,
        required this.onTap});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    readOnly:   true,
    onTap:      onTap,
    cursorHeight: 14,
    style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, color: _Clr.textPrimary),
    decoration: InputDecoration(
      labelText:  label,
      labelStyle: const TextStyle(fontSize: 11, color: _Clr.textSecond),
      prefixIcon: const Icon(Icons.calendar_today_outlined,
          size: 14, color: _Clr.textPrimary),
      filled:         true,
      fillColor:      _Clr.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _Clr.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _Clr.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _Clr.textPrimary)),
    ),
  );
}

// ── Empty state ────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width:  80,
          height: 80,
          decoration: BoxDecoration(
              color:        _Clr.card,
              border: Border.all(color: _Clr.border),
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.inbox_outlined,
              size: 36, color: _Clr.textMuted),
        ),
        const SizedBox(height: 16),
        Text(message,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _Clr.textSecond)),
      ]),
    ),
  );
}