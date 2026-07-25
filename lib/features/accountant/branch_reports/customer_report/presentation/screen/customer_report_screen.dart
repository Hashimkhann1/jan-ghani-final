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
// Unified feed item — Sale / Return / Ledger ek hi type mein
// ─────────────────────────────────────────────────────────────
enum _FeedType { sale, ret, ledger }


class _FeedItem {
  final _FeedType type;
  final DateTime  date;
  final CustomerInvoiceModel?          sale;
  final CustomerReturnInvoice?         ret;
  final SpecificCustomerLedgerModel?   ledger;

  _FeedItem.sale(CustomerInvoiceModel s)
      : type   = _FeedType.sale,
        date   = s.invoiceDate,
        sale   = s,
        ret    = null,
        ledger = null;

  _FeedItem.ret(CustomerReturnInvoice r)
      : type   = _FeedType.ret,
        date   = r.returnDate,
        sale   = null,
        ret    = r,
        ledger = null;

  _FeedItem.ledger(SpecificCustomerLedgerModel l)
      : type   = _FeedType.ledger,
        date   = l.createdAt,
        sale   = null,
        ret    = null,
        ledger = l;
}

// ─────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────
class CustomerReportScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;
  final double customerBalance;
  final bool   hideAppBarBack;

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

    final isLoading = saleState.isLoading || returnState.isLoading || ledgerState.isLoading;

    // ── Merge teeno lists ek jagah, date descending sort ──────
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
          icon:      const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.customerName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black)),
        actions: [
          IconButton(
            icon:      const Icon(Icons.picture_as_pdf_outlined, size: 20, color: Colors.black),
            tooltip:   'Export PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon:    const Icon(Icons.logout_rounded, size: 20, color: Colors.black),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [

        // ── Balance banner ────────────────────────────────────
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
                hasBalance ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                size: 18, color: Colors.black,
              ),
              const SizedBox(width: 8),
              Text(hasBalance ? 'Outstanding: ' : 'Balance: ',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
              Text(_fmt(widget.customerBalance.abs()),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black)),
            ]),
          ),
        ),

        // ── Date filter (sale + return dono par apply hota hai) ──
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            Expanded(child: _DateField(label: 'Start', controller: _fromCtrl, onTap: () async {
              final p = await _pickDate(saleState.fromDate);
              if (p != null) { _fromCtrl.text = _dateFmt.format(p); _applyDateRange(p, saleState.toDate); }
            })),
            const SizedBox(width: 10),
            Expanded(child: _DateField(label: 'End', controller: _toCtrl, onTap: () async {
              final p = await _pickDate(saleState.toDate);
              if (p != null) { _toCtrl.text = _dateFmt.format(p); _applyDateRange(saleState.fromDate, p); }
            })),
            const SizedBox(width: 10),
            SizedBox(
              width: 68,
              child: OutlinedButton(
                onPressed: () {
                  final d = DateTime.now(); final t = DateTime(d.year, d.month, d.day);
                  _fromCtrl.text = _dateFmt.format(t); _toCtrl.text = _dateFmt.format(t);
                  _applyDateRange(t, t);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black, side: const BorderSide(color: Colors.black),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                  shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Today', style: TextStyle(fontSize: 11)),
              ),
            ),
          ]),
        ),

        // ── Combined summary ───────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          child: Row(children: [
            Expanded(child: _StatTile(label: 'Sales',        value: '${saleState.invoiceCount}',        icon: Icons.receipt_long_outlined)),
            Container(width: 1, height: 36, color: const Color(0xFFE5E7EB), margin: const EdgeInsets.symmetric(horizontal: 4)),
            Expanded(child: _StatTile(label: 'Total Sale',   value: _fmt(saleState.totalSale),           icon: Icons.payments_outlined)),
            Container(width: 1, height: 36, color: const Color(0xFFE5E7EB), margin: const EdgeInsets.symmetric(horizontal: 4)),
            Expanded(child: _StatTile(label: 'Total Return', value: _fmt(returnState.summary.totalAmount), icon: Icons.assignment_return_outlined)),
            Container(width: 1, height: 36, color: const Color(0xFFE5E7EB), margin: const EdgeInsets.symmetric(horizontal: 4)),
            Expanded(child: _StatTile(label: 'Paid',         value: _fmt(ledgerState.totalPaid),          icon: Icons.account_balance_wallet_outlined)),
          ]),
        ),

        // ── Merged list ─────────────────────────────────────────
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : feed.isEmpty
              ? const _EmptyState(message: 'No records found')
              : RefreshIndicator(
            color: Colors.black,
            onRefresh: () async {
              await Future.wait([
                ref.read(customerReportInvoiceProvider(_args).notifier).load(),
                ref.read(customerReportReturnProvider(_args).notifier).load(),
                ref.read(customerReportLedgerProvider(_args).notifier).load(),
              ]);
            },
            child: ListView.separated(
              padding:          const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount:        feed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = feed[i];
                return switch (item.type) {
                  _FeedType.sale   => _SaleCard(inv: item.sale!, dateFmt: _dateFmt, timeFmt: _timeFmt),
                  _FeedType.ret    => _ReturnCard(ret: item.ret!, dateFmt: _dateFmt, timeFmt: _timeFmt),
                  _FeedType.ledger => _LedgerRow(entry: item.ledger!, dateFmt: _dateFmt, timeFmt: _timeFmt, amtFmt: _amtFmt),
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
// Sale Card
// ══════════════════════════════════════════════════════════════
class _SaleCard extends StatefulWidget {
  final CustomerInvoiceModel inv; final DateFormat dateFmt; final DateFormat timeFmt;
  const _SaleCard({required this.inv, required this.dateFmt, required this.timeFmt});
  @override State<_SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<_SaleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final inv        = widget.inv;
    final isCash      = inv.paymentType.contains('cash');
    final isCredit    = inv.paymentType.contains('credit');
    final badgeLabel  = isCredit ? 'Credit' : isCash ? 'Cash' : 'Card';

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(children: [
        InkWell(
          onTap:        () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_long_rounded, size: 20, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    _TypeTag(label: 'SALE'),
                    const SizedBox(width: 6),
                    Text(inv.invoiceNo,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black)),
                  ]),
                  Text(inv.grandTotalLabel,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)),
                ]),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    _Badge(label: badgeLabel),
                    const SizedBox(width: 6),
                    Text('${inv.items.length} items', style: const TextStyle(fontSize: 10, color: Colors.black45)),
                  ]),
                  Text('${widget.dateFmt.format(inv.invoiceDate)}  ${widget.timeFmt.format(inv.invoiceDate)}',
                      style: const TextStyle(fontSize: 10, color: Colors.black45)),
                ]),
              ])),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0, duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black45),
              ),
            ]),
          ),
        ),

        if (_expanded) ...[
          Container(height: 1, color: const Color(0xFFEDEDED)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              const _ItemTableHeader(),
              const SizedBox(height: 6),
              ...inv.items.map((item) => _ItemRow(
                productName: item.productName,
                qty:         item.qtyLabel,
                salePrice:   item.salePriceLabel,
                total:       item.totalLabel,
              )),
              if (inv.totalDiscount > 0) ...[
                const Divider(height: 12, color: Color(0xFFE5E7EB)),
                _TotalRow(label: 'Discount', value: '- ${inv.discountLabel}'),
              ],
              const Divider(height: 12, color: Color(0xFFE5E7EB)),
              _TotalRow(label: 'Grand Total', value: inv.grandTotalLabel, bold: true),

              const SizedBox(height: 10),
              Container(height: 1, color: const Color(0xFFEDEDED)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _BalanceStat(label: 'Previous', value: inv.previousAmountLabel)),
                Container(width: 1, height: 28, color: const Color(0xFFEDEDED)),
                Expanded(child: _BalanceStat(label: 'Paid', value: inv.payAmountLabel)),
                Container(width: 1, height: 28, color: const Color(0xFFEDEDED)),
                Expanded(child: _BalanceStat(label: 'New Balance', value: inv.newAmountLabel)),
              ]),
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
  final CustomerReturnInvoice ret; final DateFormat dateFmt; final DateFormat timeFmt;
  const _ReturnCard({required this.ret, required this.dateFmt, required this.timeFmt});
  @override State<_ReturnCard> createState() => _ReturnCardState();
}

class _ReturnCardState extends State<_ReturnCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ret = widget.ret;
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(children: [
        InkWell(
          onTap:        () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.assignment_return_rounded, size: 20, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    _TypeTag(label: 'RETURN'),
                    const SizedBox(width: 6),
                    Text(ret.returnNo,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black)),
                  ]),
                  Text('Rs ${ret.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)),
                ]),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    _Badge(label: ret.paymentLabel),
                    const SizedBox(width: 6),
                    Text('${ret.items.length} items', style: const TextStyle(fontSize: 10, color: Colors.black45)),
                  ]),
                  Text('${widget.dateFmt.format(ret.returnDate)}  ${widget.timeFmt.format(ret.returnDate)}',
                      style: const TextStyle(fontSize: 10, color: Colors.black45)),
                ]),
              ])),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0, duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black45),
              ),
            ]),
          ),
        ),

        if (_expanded) ...[
          Container(height: 1, color: const Color(0xFFEDEDED)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              const _ItemTableHeader(),
              const SizedBox(height: 6),
              ...ret.items.map((item) => _ItemRow(
                productName: item.productName,
                qty:         item.qtyLabel,
                salePrice:   item.salePriceLabel,
                total:       'Rs ${item.totalAmount.toStringAsFixed(0)}',
              )),
              if (ret.totalDiscount > 0) ...[
                const Divider(height: 12, color: Color(0xFFE5E7EB)),
                _TotalRow(label: 'Discount', value: '- Rs ${ret.totalDiscount.toStringAsFixed(0)}'),
              ],
              const Divider(height: 12, color: Color(0xFFE5E7EB)),
              _TotalRow(label: 'Grand Total', value: 'Rs ${ret.grandTotal.toStringAsFixed(0)}', bold: true),
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
  final DateFormat dateFmt; final DateFormat timeFmt; final NumberFormat amtFmt;
  const _LedgerRow({required this.entry, required this.dateFmt, required this.timeFmt, required this.amtFmt});

  String _fmt(double v) => 'Rs ${amtFmt.format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final icon      = isPayment ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final label     = isPayment ? 'Payment' : 'Credit';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: Colors.black),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _TypeTag(label: 'LEDGER'),
                const SizedBox(width: 6),
                _Badge(label: label),
              ]),
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(entry.notes!, style: const TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ]),
            Text(isPayment ? '- ${_fmt(entry.payAmount)}' : '+ ${_fmt(entry.payAmount)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black)),
          ]),
          const SizedBox(height: 10),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${dateFmt.format(entry.createdAt)}  ${timeFmt.format(entry.createdAt)}',
                style: const TextStyle(fontSize: 10, color: Colors.black45)),
            Row(children: [
              Text(_fmt(entry.previousAmount), style: const TextStyle(fontSize: 11, color: Colors.black54)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child:   Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.black45),
              ),
              Text(_fmt(entry.newAmount), style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black,
              )),
            ]),
          ]),
        ])),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Shared Widgets
// ══════════════════════════════════════════════════════════════
class _StatTile extends StatelessWidget {
  final String label; final String value; final IconData icon;
  const _StatTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 15, color: Colors.black),
    ),
    const SizedBox(height: 5),
    Text(value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 9, color: Colors.black45)),
  ]);
}

class _BalanceStat extends StatelessWidget {
  final String label; final String value;
  const _BalanceStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 9, color: Colors.black45)),
  ]);
}

class _ItemTableHeader extends StatelessWidget {
  const _ItemTableHeader();
  @override
  Widget build(BuildContext context) => const Row(children: [
    Expanded(flex: 3, child: _IH(text: 'Product')),
    Expanded(flex: 1, child: _IH(text: 'Qty')),
    Expanded(flex: 2, child: _IH(text: 'Price')),
    Expanded(flex: 2, child: _IH(text: 'Total', right: true)),
  ]);
}

class _ItemRow extends StatelessWidget {
  final String productName; final String qty; final String salePrice; final String total;
  const _ItemRow({required this.productName, required this.qty, required this.salePrice, required this.total});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(flex: 3, child: Text(productName,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      Expanded(flex: 1, child: Text(qty,       style: const TextStyle(fontSize: 12, color: Colors.black54))),
      Expanded(flex: 2, child: Text(salePrice, style: const TextStyle(fontSize: 12, color: Colors.black54))),
      Expanded(flex: 2, child: Text(total,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87))),
    ]),
  );
}

class _TotalRow extends StatelessWidget {
  final String label; final String value; final bool bold;
  const _TotalRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
          fontSize: bold ? 13 : 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: Colors.black87)),
      Text(value, style: TextStyle(
          fontSize: bold ? 14 : 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: Colors.black)),
    ],
  );
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color:        Colors.black.withOpacity(0.06),
      borderRadius: BorderRadius.circular(5),
      border:       Border.all(color: Colors.black.withOpacity(0.2)),
    ),
    child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black)),
  );
}

// ── Type tag — list mein sale/return/ledger pehchan-ne ke liye ──
class _TypeTag extends StatelessWidget {
  final String label;
  const _TypeTag({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color:        Colors.black,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: const TextStyle(
      fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4,
    )),
  );
}

class _DateField extends StatelessWidget {
  final String label; final TextEditingController controller;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, readOnly: true, onTap: onTap, cursorHeight: 14,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
    decoration: InputDecoration(
      labelText:  label,
      labelStyle: const TextStyle(fontSize: 11, color: Colors.black54),
      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black),
      filled:     true, fillColor: const Color(0xFFF2F2F2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black)),
    ),
  );
}

class _IH extends StatelessWidget {
  final String text; final bool right;
  const _IH({required this.text, this.right = false});

  @override
  Widget build(BuildContext context) => Text(text,
    textAlign: right ? TextAlign.right : TextAlign.left,
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black45, letterSpacing: 0.3),
  );
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.inbox_outlined, size: 36, color: Colors.black38),
        ),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black45)),
      ]),
    ),
  );
}