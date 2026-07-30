import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:ui' as ui;
import '../../data/model/customer_invoice_model.dart';
import '../../data/model/customer_return_model.dart';
import '../../data/model/specific_customer_ledger_model.dart';
import '../../data/service/customer_report_pdf_service.dart';
import '../provider/customer_report_provider.dart';
import 'package:jan_ghani_final/core/service/session/accountant_session.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/screen/login_screen.dart';

// ─────────────────────────────────────────────────────────────
// Urdu notebook colors — ek jagah define
// ─────────────────────────────────────────────────────────────
class _NbColor {
  static const bg         = Color(0xFFFDFAF4);
  static const bgHeader   = Color(0xFFF0E8D0);
  static const bgAlt      = Color(0xFFFFFDF5);
  static const bgPayment  = Color(0xFFF5F0E0);
  static const bgBanner   = Color(0xFFFFF8E8);
  static const border     = Color(0xFFD4C9A8);
  static const borderGold = Color(0xFFB8A060);
  static const textDark   = Color(0xFF2D1A00);
  static const textMid    = Color(0xFF6B4C1A);
  static const textMuted  = Color(0xFF9A7A50);
  static const textGreen  = Color(0xFF1A4A1A);
  static const textRed    = Color(0xFF8B1A1A);
  static const colHead    = Color(0xFFE8DFC8);
}

// ─────────────────────────────────────────────────────────────
// Urdu font helper
// ─────────────────────────────────────────────────────────────
TextStyle _urdu({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _NbColor.textDark,
}) =>
    GoogleFonts.notoNastaliqUrdu(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );

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
        colorScheme: const ColorScheme.light(primary: Colors.black),
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
          backgroundColor: Colors.red,
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor:           Colors.white,
        elevation:                 0,
        surfaceTintColor:          Colors.transparent,
        automaticallyImplyLeading: !widget.hideAppBarBack,
        leading: widget.hideAppBarBack
            ? null
            : IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.customerName,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined,
                size: 20, color: Colors.black),
            tooltip:   'Export PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                size: 20, color: Colors.black),
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
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:        Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border:       Border.all(color: Colors.black.withOpacity(0.15)),
            ),
            child: Row(children: [
              Icon(
                hasBalance
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18, color: Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                hasBalance ? 'Outstanding: ' : 'Balance: ',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
              Text(
                _fmt(widget.customerBalance.abs()),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black),
              ),
            ]),
          ),
        ),

        // ── Date filter ─────────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            Expanded(
              child: _DateField(
                label:      'Start',
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
                label:      'End',
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
                  foregroundColor: Colors.black,
                  side:    const BorderSide(color: Colors.black),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                  shape:   RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Today', style: TextStyle(fontSize: 11)),
              ),
            ),
          ]),
        ),

        // ── Summary stats ───────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          child: Row(children: [
            Expanded(
              child: _StatTile(
                  label: 'Sales',
                  value: '${saleState.invoiceCount}',
                  icon: Icons.receipt_long_outlined),
            ),
            Container(
                width: 1,
                height: 36,
                color: const Color(0xFFE5E7EB),
                margin: const EdgeInsets.symmetric(horizontal: 4)),
            Expanded(
              child: _StatTile(
                  label: 'Total Sale',
                  value: _fmt(saleState.totalSale),
                  icon: Icons.payments_outlined),
            ),
            Container(
                width: 1,
                height: 36,
                color: const Color(0xFFE5E7EB),
                margin: const EdgeInsets.symmetric(horizontal: 4)),
            Expanded(
              child: _StatTile(
                  label: 'Total Return',
                  value: _fmt(returnState.summary.totalAmount),
                  icon: Icons.assignment_return_outlined),
            ),
            Container(
                width: 1,
                height: 36,
                color: const Color(0xFFE5E7EB),
                margin: const EdgeInsets.symmetric(horizontal: 4)),
            Expanded(
              child: _StatTile(
                  label: 'Paid',
                  value: _fmt(ledgerState.totalPaid),
                  icon: Icons.account_balance_wallet_outlined),
            ),
          ]),
        ),

        // ── Feed list ───────────────────────────────────────
        Expanded(
          child: isLoading
              ? const Center(
              child: CircularProgressIndicator(color: Colors.black))
              : feed.isEmpty
              ? const _EmptyState(message: 'No records found')
              : RefreshIndicator(
            color: Colors.black,
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
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount:        feed.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = feed[i];
                return switch (item.type) {
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
              },
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Notebook wrapper — shared outer shell
// ══════════════════════════════════════════════════════════════
class _NbShell extends StatelessWidget {
  final Widget child;
  const _NbShell({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:        _NbColor.bg,
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: _NbColor.border),
    ),
    child: Directionality(
      textDirection: ui.TextDirection.rtl,
      child: child,
    ),
  );
}

// ── Notebook column header row ─────────────────────────────
class _NbColHead extends StatelessWidget {
  final List<String> labels;
  final List<int>    flexes;
  const _NbColHead({required this.labels, required this.flexes});

  @override
  Widget build(BuildContext context) => Container(
    color:   _NbColor.colHead,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    child: Row(
      children: List.generate(labels.length, (i) {
        final isFirst = i == 0;
        return Expanded(
          flex: flexes[i],
          child: Text(
            labels[i],
            textAlign: isFirst ? TextAlign.right : TextAlign.center,
            style: _urdu(
                size: 10,
                weight: FontWeight.w700,
                color: const Color(0xFF5A3E10)),
          ),
        );
      }),
    ),
  );
}

// ── Notebook item row ──────────────────────────────────────
class _NbItemRow extends StatelessWidget {
  final String name;
  final String qty;
  final String price;
  final String total;
  final bool   isEven;
  const _NbItemRow({
    required this.name,
    required this.qty,
    required this.price,
    required this.total,
    this.isEven = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    color:   isEven ? _NbColor.bgAlt : _NbColor.bg,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      Expanded(
        flex: 3,
        child: Text(name,
            textAlign: TextAlign.right,
            style: _urdu(size: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ),
      Expanded(
        flex: 1,
        child: Text(qty,
            textAlign: TextAlign.center,
            style: _urdu(size: 12, color: _NbColor.textMid)),
      ),
      Expanded(
        flex: 2,
        child: Text(price,
            textAlign: TextAlign.center,
            style: _urdu(size: 12, color: _NbColor.textMid)),
      ),
      Expanded(
        flex: 2,
        child: Text(total,
            textAlign: TextAlign.center,
            style: _urdu(
                size: 12,
                weight: FontWeight.w700,
                color: _NbColor.textGreen)),
      ),
    ]),
  );
}

// ── Total / summary row ────────────────────────────────────
class _NbTotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;
  final bool   bold;
  final bool   topBorder;
  const _NbTotalRow({
    required this.label,
    required this.value,
    this.valueColor = _NbColor.textDark,
    this.bold       = false,
    this.topBorder  = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: topBorder
        ? const BoxDecoration(
        border: Border(
            top: BorderSide(color: _NbColor.borderGold, width: 1.5)))
        : null,
    padding: EdgeInsets.only(
        top: topBorder ? 6 : 0, bottom: 4, left: 12, right: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: _urdu(
                size: bold ? 13 : 12,
                weight: bold ? FontWeight.w700 : FontWeight.w400,
                color: bold ? _NbColor.textDark : _NbColor.textMid)),
        Text(value,
            style: _urdu(
                size: bold ? 14 : 12,
                weight: bold ? FontWeight.w700 : FontWeight.w700,
                color: valueColor)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// Sale Card — Urdu notebook invoice
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

  String _fmt(double v) => '₨ ${widget.amtFmt.format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    final inv      = widget.inv;
    final isCredit = inv.paymentType.contains('credit');
    final payLabel = isCredit ? 'اُدھار' : inv.paymentType.contains('cash') ? 'نقد' : 'کارڈ';

    return _NbShell(
      child: Column(children: [
        // ── Header — tap to expand ──────────────────────────
        InkWell(
          onTap:        () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: const BoxDecoration(
              color: _NbColor.bgHeader,
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // right side — bill info
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(children: [
                    _NbTag(label: 'بِل'),
                    const SizedBox(width: 6),
                    Text(inv.invoiceNo,
                        style: _urdu(size: 13, weight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    _NbBadge(label: payLabel),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.dateFmt.format(inv.invoiceDate)}  ${widget.timeFmt.format(inv.invoiceDate)}',
                      style: _urdu(size: 10, color: _NbColor.textMuted),
                    ),
                  ]),
                ]),
                // left side — amount + chevron
                Row(children: [
                  AnimatedRotation(
                    turns:    _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: _NbColor.textMid),
                  ),
                  const SizedBox(width: 8),
                  Text(inv.grandTotalLabel,
                      style: _urdu(
                          size: 15,
                          weight: FontWeight.w700,
                          color: _NbColor.textGreen)),
                ]),
              ],
            ),
          ),
        ),

        // ── Expanded body — notebook invoice ───────────────
        if (_expanded) ...[
          Container(height: 1, color: _NbColor.borderGold),

          // items table
          _NbColHead(
            labels: ['سامان', 'تعداد', 'قیمت', 'کُل'],
            flexes: [3, 1, 2, 2],
          ),
          Container(height: 1, color: _NbColor.border),
          ...inv.items.asMap().entries.map((e) => _NbItemRow(
            name:   e.value.productName,
            qty:    e.value.qtyLabel,
            price:  e.value.salePriceLabel,
            total:  e.value.totalLabel,
            isEven: e.key.isEven,
          )),

          // totals
          Container(height: 1, color: _NbColor.border),
          const SizedBox(height: 6),
          if (inv.totalDiscount > 0)
            _NbTotalRow(
              label:      'کل مال',
              value:      _fmt(inv.grandTotal + inv.totalDiscount),
              valueColor: _NbColor.textDark,
            ),
          if (inv.totalDiscount > 0)
            _NbTotalRow(
              label:      'چھوٹ (رعایت)',
              value:      '- ${_fmt(inv.totalDiscount)}',
              valueColor: _NbColor.textGreen,
            ),
          _NbTotalRow(
            label:      'کُل بِل',
            value:      inv.grandTotalLabel,
            valueColor: _NbColor.textRed,
            bold:       true,
            topBorder:  true,
          ),
          const SizedBox(height: 6),

          // payment section
          Container(
            color:   _NbColor.bgPayment,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(children: [
              _NbTotalRow(
                  label: 'پہلے سے باقی',
                  value: inv.previousAmountLabel,
                  valueColor: _NbColor.textRed),
              _NbTotalRow(
                  label: 'ابھی دیا',
                  value: inv.payAmountLabel,
                  valueColor: _NbColor.textGreen),
              _NbTotalRow(
                label:      'اب باقی ہے',
                value:      inv.newAmountLabel,
                valueColor: _NbColor.textRed,
                bold:       true,
                topBorder:  true,
              ),
            ]),
          ),

          // footer
          Container(
            width:   double.infinity,
            color:   _NbColor.bgHeader,
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(
              'شکریہ — اللہ برکت دے',
              textAlign: TextAlign.center,
              style: _urdu(size: 11, color: _NbColor.textMuted),
            ),
          ),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Return Card — Urdu notebook
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

    return _NbShell(
      child: Column(children: [
        // ── Header ─────────────────────────────────────────
        InkWell(
          onTap:        () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(children: [
                    _NbTag(label: 'واپسی', color: const Color(0xFFC0621A)),
                    const SizedBox(width: 6),
                    Text(ret.returnNo,
                        style: _urdu(size: 13, weight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    _NbBadge(
                        label: ret.paymentLabel,
                        color: const Color(0xFFC0621A)),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.dateFmt.format(ret.returnDate)}  ${widget.timeFmt.format(ret.returnDate)}',
                      style: _urdu(size: 10, color: _NbColor.textMuted),
                    ),
                  ]),
                ]),
                Row(children: [
                  AnimatedRotation(
                    turns:    _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: _NbColor.textMid),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₨ ${ret.grandTotal.toStringAsFixed(0)}',
                    style: _urdu(
                        size: 15,
                        weight: FontWeight.w700,
                        color: const Color(0xFFC0621A)),
                  ),
                ]),
              ],
            ),
          ),
        ),

        // ── Expanded body ───────────────────────────────────
        if (_expanded) ...[
          Container(height: 1, color: const Color(0xFFD4A060)),

          _NbColHead(
            labels: ['سامان', 'تعداد', 'قیمت', 'کُل'],
            flexes: [3, 1, 2, 2],
          ),
          Container(height: 1, color: _NbColor.border),
          ...ret.items.asMap().entries.map((e) => _NbItemRow(
            name:   e.value.productName,
            qty:    e.value.qtyLabel,
            price:  e.value.salePriceLabel,
            total:  '₨ ${e.value.totalAmount.toStringAsFixed(0)}',
            isEven: e.key.isEven,
          )),

          Container(height: 1, color: _NbColor.border),
          const SizedBox(height: 6),
          if (ret.totalDiscount > 0)
            _NbTotalRow(
                label:      'چھوٹ',
                value:      '- ₨ ${ret.totalDiscount.toStringAsFixed(0)}',
                valueColor: _NbColor.textGreen),
          _NbTotalRow(
            label:      'کُل واپسی',
            value:      '₨ ${ret.grandTotal.toStringAsFixed(0)}',
            valueColor: const Color(0xFFC0621A),
            bold:       true,
            topBorder:  true,
          ),
          const SizedBox(height: 8),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Ledger Card — Urdu notebook
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

  String _fmt(double v) => '₨ ${amtFmt.format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final typeLabel = isPayment ? 'ادائیگی' : 'کریڈٹ';
    final amtColor  = isPayment ? _NbColor.textGreen : _NbColor.textRed;
    final amtSign   = isPayment ? '- ' : '+ ';
    final bgTop     = isPayment
        ? const Color(0xFFE8F5E8)
        : const Color(0xFFFFF0E0);

    return _NbShell(
      child: Column(children: [
        // ── Header ─────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color:        bgTop,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // right — label + date
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(children: [
                  _NbTag(
                      label: 'کھاتہ',
                      color: isPayment
                          ? _NbColor.textGreen
                          : const Color(0xFFC0621A)),
                  const SizedBox(width: 6),
                  _NbBadge(
                      label: typeLabel,
                      color: isPayment
                          ? _NbColor.textGreen
                          : const Color(0xFFC0621A)),
                ]),
                const SizedBox(height: 3),
                Text(
                  '${dateFmt.format(entry.createdAt)}  ${timeFmt.format(entry.createdAt)}',
                  style: _urdu(size: 10, color: _NbColor.textMuted),
                ),
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(entry.notes!,
                      style: _urdu(size: 11, color: _NbColor.textMuted)),
                ],
              ]),
              // left — amount
              Text(
                '$amtSign${_fmt(entry.payAmount)}',
                style: _urdu(
                    size: 16, weight: FontWeight.w700, color: amtColor),
              ),
            ],
          ),
        ),

        // ── Balance trail ───────────────────────────────────
        Container(height: 1, color: _NbColor.border),
        Container(
          color:   _NbColor.bgPayment,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // previous → new  (RTL so new is on right)
              Row(children: [
                Text(_fmt(entry.newAmount),
                    style: _urdu(
                        size: 13,
                        weight: FontWeight.w700,
                        color: _NbColor.textRed)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child:   Icon(Icons.arrow_forward_rounded,
                      size: 14, color: _NbColor.textMid),
                ),
                Text(_fmt(entry.previousAmount),
                    style: _urdu(size: 12, color: _NbColor.textMid)),
              ]),
              Text('باقی',
                  style: _urdu(size: 11, color: _NbColor.textMuted)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Small shared widgets
// ══════════════════════════════════════════════════════════════

// Black filled tag — SALE / RETURN / LEDGER
class _NbTag extends StatelessWidget {
  final String label;
  final Color  color;
  const _NbTag({required this.label, this.color = _NbColor.textDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color:        color,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label,
        style: _urdu(
            size: 9, weight: FontWeight.w700, color: Colors.white)),
  );
}

// Outlined badge
class _NbBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _NbBadge({required this.label, this.color = _NbColor.textDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(4),
      border:       Border.all(color: color.withOpacity(0.35)),
    ),
    child: Text(label,
        style: _urdu(size: 9, weight: FontWeight.w700, color: color)),
  );
}

// ── Stat tile (top summary bar) ────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
          color:        Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 15, color: Colors.black),
    ),
    const SizedBox(height: 5),
    Text(value,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.black),
        maxLines: 1,
        overflow: TextOverflow.ellipsis),
    const SizedBox(height: 2),
    Text(label,
        style: const TextStyle(fontSize: 9, color: Colors.black45)),
  ]);
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
        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
    decoration: InputDecoration(
      labelText:  label,
      labelStyle: const TextStyle(fontSize: 11, color: Colors.black54),
      prefixIcon: const Icon(Icons.calendar_today_outlined,
          size: 14, color: Colors.black),
      filled:         true,
      fillColor:      const Color(0xFFF2F2F2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black)),
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
              color:        const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.inbox_outlined,
              size: 36, color: Colors.black38),
        ),
        const SizedBox(height: 16),
        Text(message,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black45)),
      ]),
    ),
  );
}