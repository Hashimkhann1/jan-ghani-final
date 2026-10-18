import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/model/customer_invoice_model.dart';
import '../../data/model/customer_return_model.dart';
import '../../data/model/specific_customer_ledger_model.dart';
import '../../data/service/customer_report_pdf_service.dart';
import '../provider/customer_report_provider.dart';
import '../widget/customer_avatar.dart';
import 'package:jan_ghani_final/core/service/session/accountant_session.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:jan_ghani_final/core/routes/accountant_paths.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/providers/accountant_auth_providers.dart';

// ─────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────
class _Clr {
  static const bg          = Color(0xFFF7F8FA);
  static const card        = Color(0xFFFFFFFF);
  static const border      = Color(0xFFE4E7EC);
  static const borderSoft  = Color(0xFFF0F1F3);
  static const textPrimary = Color(0xFF101828);
  static const textSecond  = Color(0xFF475467);
  static const textMuted   = Color(0xFF98A2B3);
  static const accent      = Color(0xFF0F5C3F);
  static const accentBg    = Color(0xFFE3F0E8);

  static const blueBg   = Color(0xFFEFF8FF);
  static const blueText = Color(0xFF1570EF);
  static const amberBg  = Color(0xFFFFFAEB);
  static const amberText = Color(0xFFB54708);
  static const greenBg   = Color(0xFFECFDF3);
  static const greenText = Color(0xFF027A48);
  static const redBg     = Color(0xFFFFF1F3);
  static const redText   = Color(0xFFC01048);
}

// Responsive breakpoint
const double _kWebBreakpoint = 720;

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
      : type = _FeedType.sale, date = s.invoiceDate,
        sale = s, ret = null, ledger = null;

  _FeedItem.ret(CustomerReturnInvoice r)
      : type = _FeedType.ret, date = r.returnDate,
        sale = null, ret = r, ledger = null;

  _FeedItem.ledger(SpecificCustomerLedgerModel l)
      : type = _FeedType.ledger, date = l.createdAt,
        sale = null, ret = null, ledger = l;
}

// ─────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────
class CustomerReportScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;
  final double customerBalance;
  final String? customerPhone;
  final bool hideAppBarBack;

  const CustomerReportScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerBalance,
    this.customerPhone,
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
  final _searchCtrl = TextEditingController();
  final _fromCtrl   = TextEditingController();
  final _toCtrl     = TextEditingController();

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
    _searchCtrl.dispose();
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
        colorScheme: const ColorScheme.light(primary: _Clr.accent),
      ),
      child: child!,
    ),
  );

  void _applyDateRange(DateTime from, DateTime to) {
    ref.read(customerReportInvoiceProvider(_args).notifier).setDateRange(from, to);
    ref.read(customerReportReturnProvider(_args).notifier)
      ..setFromDate(from)
      ..setToDate(to);
    ref.read(customerReportLedgerProvider(_args).notifier).setDateRange(from, to);
  }

  Future<void> _exportPdf() async {
    final saleState   = ref.read(customerReportInvoiceProvider(_args));
    final returnState = ref.read(customerReportReturnProvider(_args));
    final ledgerState = ref.read(customerReportLedgerProvider(_args));

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Generating PDF…'),
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

  Future<void> _logout() async {
    await AccountantSession.clear();
    // sessionProvider bhi clear — warna router wapas customer portal par bhej deta.
    await ref.read(accountantAuthNotifierProvider.notifier).logout();
    if (mounted) context.go(AccPaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final saleState   = ref.watch(customerReportInvoiceProvider(_args));
    final returnState = ref.watch(customerReportReturnProvider(_args));
    final ledgerState = ref.watch(customerReportLedgerProvider(_args));

    final isLoading =
        saleState.isLoading || returnState.isLoading || ledgerState.isLoading;

    final feed = <_FeedItem>[
      ...saleState.filtered.map(_FeedItem.sale),
      ...returnState.returns.map(_FeedItem.ret),
      ...ledgerState.ledger.map(_FeedItem.ledger),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kWebBreakpoint;
        return isWide
            ? _buildWideLayout(context, saleState, isLoading, feed)
            : _buildNarrowLayout(context, saleState, isLoading, feed);
      },
    );
  }

  // ── NARROW (Android/mobile) ────────────────────────────────
  Widget _buildNarrowLayout(
      BuildContext context,
      CustomerReportInvoiceState saleState,
      bool isLoading,
      List<_FeedItem> feed,
      ) {
    return Scaffold(
      backgroundColor: _Clr.bg,
      appBar: _buildAppBar(context),
      body: _FeedList(
        isLoading: isLoading,
        feed:      feed,
        dateFmt:   _dateFmt,
        timeFmt:   _timeFmt,
        amtFmt:    _amtFmt,
        header: Column(children: [
          _CustomerHeader(
            balance: widget.customerBalance,
            fmt:     _fmt,
          ),
          _FilterBar(
            fromCtrl:  _fromCtrl,
            toCtrl:    _toCtrl,
            onPickFrom: () async {
              final p = await _pickDate(saleState.fromDate);
              if (p != null) {
                _fromCtrl.text = _dateFmt.format(p);
                _applyDateRange(p, saleState.toDate);
              }
            },
            onPickTo: () async {
              final p = await _pickDate(saleState.toDate);
              if (p != null) {
                _toCtrl.text = _dateFmt.format(p);
                _applyDateRange(saleState.fromDate, p);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _SearchBar(
              controller: _searchCtrl,
              onChanged: (q) => ref
                  .read(customerReportInvoiceProvider(_args).notifier)
                  .onSearchChanged(q),
            ),
          ),
        ]),
        onRefresh: () async {
          await Future.wait([
            ref.read(customerReportInvoiceProvider(_args).notifier).load(),
            ref.read(customerReportReturnProvider(_args).notifier).load(),
            ref.read(customerReportLedgerProvider(_args).notifier).load(),
          ]);
        },
      ),
    );
  }

  // ── WIDE (Web/tablet) ──────────────────────────────────────
  Widget _buildWideLayout(
      BuildContext context,
      CustomerReportInvoiceState saleState,
      bool isLoading,
      List<_FeedItem> feed,
      ) {
    return Scaffold(
      backgroundColor: _Clr.bg,
      appBar: _buildAppBar(context),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left sidebar ──────────────────────────────────
          SizedBox(
            width: 300,
            child: Container(
              color: _Clr.card,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CustomerHeaderVertical(
                      customerId: widget.customerId,
                      name:    widget.customerName,
                      phone:   widget.customerPhone,
                      balance: widget.customerBalance,
                      fmt:     _fmt,
                    ),
                    const SizedBox(height: 20),
                    _FilterBarVertical(
                      fromCtrl:  _fromCtrl,
                      toCtrl:    _toCtrl,
                      onPickFrom: () async {
                        final p = await _pickDate(saleState.fromDate);
                        if (p != null) {
                          _fromCtrl.text = _dateFmt.format(p);
                          _applyDateRange(p, saleState.toDate);
                        }
                      },
                      onPickTo: () async {
                        final p = await _pickDate(saleState.toDate);
                        if (p != null) {
                          _toCtrl.text = _dateFmt.format(p);
                          _applyDateRange(saleState.fromDate, p);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Main feed ────────────────────────────────────
          Expanded(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (q) => ref
                      .read(customerReportInvoiceProvider(_args).notifier)
                      .onSearchChanged(q),
                ),
              ),
              Expanded(
                child: _FeedList(
                  isLoading: isLoading,
                  feed:      feed,
                  dateFmt:   _dateFmt,
                  timeFmt:   _timeFmt,
                  amtFmt:    _amtFmt,
                  isWide:    true,
                  onRefresh: () async {
                    await Future.wait([
                      ref.read(customerReportInvoiceProvider(_args).notifier).load(),
                      ref.read(customerReportReturnProvider(_args).notifier).load(),
                      ref.read(customerReportLedgerProvider(_args).notifier).load(),
                    ]);
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(
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
      widget.hideAppBarBack ? 'My Invoices' : 'Customer Statement',
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: _Clr.textPrimary),
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: _Clr.border),
    ),
    actions: [
      IconButton(
        icon: const AppIcon('ic_print', size: 20, color: _Clr.textSecond),
        tooltip:   'Export PDF',
        onPressed: _exportPdf,
      ),
      IconButton(
        icon: const Icon(Icons.logout_rounded,
            size: 20, color: _Clr.textSecond),
        tooltip:   'Logout',
        onPressed: _logout,
      ),
      const SizedBox(width: 4),
    ],
  );
}

// ══════════════════════════════════════════════════════════════
// Customer Header — Mobile (horizontal)
// ══════════════════════════════════════════════════════════════
class _CustomerHeader extends StatelessWidget {
  final double  balance;
  final String Function(double) fmt;
  const _CustomerHeader({required this.balance, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final hasBalance = balance > 0;
    final fg = hasBalance ? _Clr.amberText : _Clr.greenText;
    return Container(
      color: _Clr.card,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(children: [
        // Balance card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color:        hasBalance ? _Clr.amberBg : _Clr.greenBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasBalance
                  ? const Color(0xFFFEC84B)
                  : const Color(0xFF6CE9A6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hasBalance ? 'Outstanding balance' : 'Balance cleared',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
                const SizedBox(height: 2),
                Text(fmt(balance.abs()),
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800, color: fg)),
              ]),
              Icon(
                hasBalance
                    ? Icons.account_balance_wallet_outlined
                    : Icons.check_circle_outline_rounded,
                size: 30, color: fg.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Customer Header — Web sidebar (vertical)
// ══════════════════════════════════════════════════════════════
class _CustomerHeaderVertical extends StatelessWidget {
  final String  customerId;
  final String  name;
  final String? phone;
  final double  balance;
  final String Function(double) fmt;
  const _CustomerHeaderVertical({
    required this.customerId, required this.name, this.phone,
    required this.balance, required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final hasBalance = balance > 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CustomerAvatar(customerId: customerId, name: name, size: 42),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: _Clr.textPrimary),
                overflow: TextOverflow.ellipsis),
            if (phone != null && phone!.isNotEmpty)
              Text(phone!,
                  style: const TextStyle(fontSize: 11, color: _Clr.textMuted)),
          ]),
        ),
      ]),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        hasBalance ? _Clr.amberBg : _Clr.greenBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasBalance
                ? const Color(0xFFFEC84B)
                : const Color(0xFF6CE9A6),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            hasBalance ? 'Outstanding Balance' : 'Balance Cleared',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: hasBalance ? _Clr.amberText : _Clr.greenText),
          ),
          const SizedBox(height: 4),
          Text(
            fmt(balance.abs()),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: hasBalance ? _Clr.amberText : _Clr.greenText),
          ),
        ]),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// Filter Bar — Mobile (horizontal)
// ══════════════════════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  final TextEditingController fromCtrl;
  final TextEditingController toCtrl;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  const _FilterBar({
    required this.fromCtrl, required this.toCtrl,
    required this.onPickFrom, required this.onPickTo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _Clr.card,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: [
        Expanded(
          child: _DateField(label: 'From', controller: fromCtrl, onTap: onPickFrom),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DateField(label: 'To', controller: toCtrl, onTap: onPickTo),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Filter Bar — Web sidebar (vertical)
// ══════════════════════════════════════════════════════════════
class _FilterBarVertical extends StatelessWidget {
  final TextEditingController fromCtrl;
  final TextEditingController toCtrl;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  const _FilterBarVertical({
    required this.fromCtrl, required this.toCtrl,
    required this.onPickFrom, required this.onPickTo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Date Range',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: _Clr.textMuted, letterSpacing: 0.4)),
      const SizedBox(height: 8),
      _DateField(label: 'From', controller: fromCtrl, onTap: onPickFrom),
      const SizedBox(height: 8),
      _DateField(label: 'To', controller: toCtrl, onTap: onPickTo),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// Feed List
// ══════════════════════════════════════════════════════════════
class _FeedList extends StatelessWidget {
  final bool isLoading;
  final List<_FeedItem> feed;
  final DateFormat   dateFmt;
  final DateFormat   timeFmt;
  final NumberFormat amtFmt;
  final bool isWide;
  final Future<void> Function() onRefresh;

  /// Diya jaye to list ke saath scroll hota hai (header, filter, search upar
  /// scroll ho kar chhup jate hain).
  final Widget? header;
  const _FeedList({
    required this.isLoading, required this.feed,
    required this.dateFmt,   required this.timeFmt,
    required this.amtFmt,    required this.onRefresh,
    this.isWide = false,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    // Rows: header, phir loading / empty / (count + date groups + cards).
    // Hamesha ek hi ListView — taake search field loading par dobara na bane.
    final rows = <Object>[];
    if (header != null) rows.add(header!);
    if (isLoading) {
      rows.add(const _LoadingRow());
    } else if (feed.isEmpty) {
      rows.add(const _EmptyState(message: 'No records found for this period'));
    } else {
      rows.add('${feed.length} records');
      // Date ke hisaab se groups: Today / Yesterday / dd MMM yyyy.
      final now = DateTime.now();
      String? lastKey;
      for (final it in feed) {
        final d = it.date.toLocal();
        final days = DateTime(now.year, now.month, now.day)
            .difference(DateTime(d.year, d.month, d.day)).inDays;
        final key = days == 0 ? 'Today' : days == 1 ? 'Yesterday' : dateFmt.format(d);
        if (key != lastKey) {
          rows.add(key);
          lastKey = key;
        }
        rows.add(it);
      }
    }

    final pad = isWide ? 20.0 : 16.0;
    return RefreshIndicator(
      color: _Clr.accent,
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: header != null ? 0 : 12, bottom: 24),
        itemCount: rows.length,
        itemBuilder: (ctx, i) {
          final row = rows[i];
          if (row is Widget) {
            // header / loading / empty — full width
            return row is _LoadingRow || row is _EmptyState
                ? row
                : Padding(
                    padding: EdgeInsets.only(bottom: header != null ? 12 : 0),
                    child: row);
          }
          if (row is String) {
            return Padding(
              padding: EdgeInsets.fromLTRB(pad, i <= 1 ? 0 : 6, pad, 8),
              child: Text(
                row,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _Clr.textSecond,
                    letterSpacing: 0.3),
              ),
            );
          }
          final item = row as _FeedItem;
          return Padding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, 10),
            child: switch (item.type) {
              _FeedType.sale => _SaleCard(
                inv: item.sale!, dateFmt: dateFmt,
                timeFmt: timeFmt, amtFmt: amtFmt,
              ),
              _FeedType.ret => _ReturnCard(
                ret: item.ret!, dateFmt: dateFmt, timeFmt: timeFmt,
              ),
              _FeedType.ledger => _LedgerCard(
                entry: item.ledger!, dateFmt: dateFmt,
                timeFmt: timeFmt, amtFmt: amtFmt,
              ),
            },
          );
        },
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 64),
    child: Center(child: CircularProgressIndicator(color: _Clr.accent)),
  );
}

// ══════════════════════════════════════════════════════════════
// Search bar
// ══════════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: TextField(
        controller: controller,
        onChanged:  onChanged,
        style: const TextStyle(fontSize: 13, color: _Clr.textPrimary),
        decoration: InputDecoration(
          hintText:  'Search invoice, product…',
          hintStyle: const TextStyle(fontSize: 13, color: _Clr.textMuted),
          prefixIcon: const AppIcon('ic_search',
              size: 18, color: _Clr.textMuted),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (_, __) => controller.text.isNotEmpty
                ? IconButton(
              icon: const AppIcon('ic_clear',
                  size: 16, color: _Clr.textMuted),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            )
                : const SizedBox.shrink(),
          ),
          filled:         true,
          fillColor:      _Clr.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _Clr.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _Clr.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _Clr.accent, width: 1.5)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Card shell
// ══════════════════════════════════════════════════════════════
class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:        _Clr.card,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: _Clr.border, width: 0.8),
      boxShadow: [
        BoxShadow(
          color:  Colors.black.withOpacity(0.03),
          offset: const Offset(0, 1),
          blurRadius: 4,
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
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
    required this.inv, required this.dateFmt,
    required this.timeFmt, required this.amtFmt,
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
    final payLabel = isCredit ? 'Credit'
        : inv.paymentType.contains('cash') ? 'Cash' : 'Card';

    return _CardShell(
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left icon
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _Clr.blueBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const AppIcon('sidebar_icons/sale_invoice',
                      size: 16, color: _Clr.blueText),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const _Badge(label: 'Invoice', bg: _Clr.blueBg, text: _Clr.blueText),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(inv.invoiceNo,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: _Clr.textPrimary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        _Badge(
                          label: payLabel,
                          bg:    isCredit ? _Clr.amberBg : _Clr.greenBg,
                          text:  isCredit ? _Clr.amberText : _Clr.greenText,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${inv.items.length} item${inv.items.length == 1 ? '' : 's'}  •  ${widget.timeFmt.format(inv.invoiceDate)}',
                            style: const TextStyle(fontSize: 11, color: _Clr.textMuted),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(inv.grandTotalLabel,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800,
                          color: _Clr.textPrimary)),
                  AnimatedRotation(
                    turns:    _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: _Clr.textMuted),
                  ),
                ]),
              ],
            ),
          ),
        ),

        if (_expanded) ...[
          Container(height: 0.5, color: _Clr.borderSoft),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Column(children: [
              ...inv.items.map((it) => _ItemRow(
                name:     it.productName,
                qty:      it.qtyLabel,
                price:    it.salePriceLabel,
                discount: it.discount > 0
                    ? 'Rs ${it.discount.toStringAsFixed(0)}' : '—',
                total:    it.totalLabel,
              )),
              _TotalRow(label: 'Grand Total', value: inv.grandTotalLabel),
            ]),
          ),
          Container(
            color: _Clr.bg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(children: [
              _PaymentLine(label: 'Previous balance', value: inv.previousAmountLabel),
              const SizedBox(height: 4),
              _PaymentLine(label: 'Paid now', value: inv.payAmountLabel,
                  valueColor: _Clr.greenText),
              const SizedBox(height: 4),
              _PaymentLine(label: 'Balance now', value: inv.newAmountLabel,
                  valueColor: inv.newAmount > 0 ? _Clr.redText : _Clr.greenText,
                  bold: true),
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
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  const _ReturnCard({required this.ret, required this.dateFmt, required this.timeFmt});
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
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _Clr.amberBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const AppIcon('sidebar_icons/sale_return_report',
                      size: 16, color: _Clr.amberText),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const _Badge(label: 'Return', bg: _Clr.amberBg, text: _Clr.amberText),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(ret.returnNo,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: _Clr.textPrimary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        _OutlineTag(label: ret.paymentLabel),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${widget.dateFmt.format(ret.returnDate)}, ${widget.timeFmt.format(ret.returnDate)}',
                            style: const TextStyle(fontSize: 11, color: _Clr.textMuted),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Rs ${ret.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: _Clr.amberText)),
                  AnimatedRotation(
                    turns:    _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: _Clr.textMuted),
                  ),
                ]),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          Container(height: 0.5, color: _Clr.borderSoft),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(children: [
              ...ret.items.map((it) => _ItemRow(
                name:     it.productName,
                qty:      it.qtyLabel,
                price:    it.salePriceLabel,
                discount: it.discount > 0
                    ? 'Rs ${it.discount.toStringAsFixed(0)}' : '—',
                total:    'Rs ${it.totalAmount.toStringAsFixed(0)}',
              )),
              _TotalRow(label: 'Total return', value: 'Rs ${ret.grandTotal.toStringAsFixed(0)}',
                  valueColor: _Clr.amberText),
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
    required this.entry, required this.dateFmt,
    required this.timeFmt, required this.amtFmt,
  });

  String _fmt(double v) => 'Rs ${amtFmt.format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final typeLabel = isPayment ? 'Payment' : 'Credit';
    final amtColor  = isPayment ? _Clr.greenText : _Clr.redText;
    final iconBg    = isPayment ? _Clr.greenBg    : _Clr.redBg;
    final amtSign   = isPayment ? '- '            : '+ ';

    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(
                isPayment ? 'ic_pay_now' : 'ic_credit_sale',
                size: 16, color: amtColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _Badge(
                      label: 'Ledger',
                      bg:    _Clr.greenBg,
                      text:  _Clr.greenText,
                    ),
                    const SizedBox(width: 6),
                    Text(typeLabel,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: _Clr.textSecond)),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFmt.format(entry.createdAt)}, ${timeFmt.format(entry.createdAt)}',
                    style: const TextStyle(fontSize: 11, color: _Clr.textMuted),
                  ),
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(entry.notes!,
                        style: const TextStyle(fontSize: 11, color: _Clr.textMuted)),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _Clr.bg, borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Text(_fmt(entry.previousAmount),
                              style: const TextStyle(
                                  fontSize: 11, color: _Clr.textMuted)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(Icons.arrow_forward_rounded,
                                size: 12, color: _Clr.textMuted),
                          ),
                          Text(_fmt(entry.newAmount),
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: entry.newAmount > 0
                                      ? _Clr.redText : _Clr.greenText)),
                        ]),
                        const Text('Balance',
                            style: TextStyle(fontSize: 10, color: _Clr.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$amtSign${_fmt(entry.payAmount)}',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: amtColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Small shared widgets
// ══════════════════════════════════════════════════════════════

class _DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    readOnly:   true,
    onTap:      onTap,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _Clr.textPrimary),
    decoration: InputDecoration(
      labelText:  label,
      labelStyle: const TextStyle(fontSize: 11, color: _Clr.textSecond),
      prefixIcon: const AppIcon('ic_calendar',
          size: 14, color: _Clr.textMuted),
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
          borderSide: const BorderSide(color: _Clr.accent)),
    ),
  );
}

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

class _OutlineTag extends StatelessWidget {
  final String label;
  const _OutlineTag({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: _Clr.border),
    ),
    child: Text(label,
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500, color: _Clr.textSecond)),
  );
}

class _ItemRow extends StatelessWidget {
  final String name, qty, price, discount, total;
  const _ItemRow({
    required this.name, required this.qty, required this.price,
    required this.discount, required this.total,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: _Clr.textPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text('$qty × $price',
                style: const TextStyle(fontSize: 11, color: _Clr.textMuted)),
            if (discount != '—')
              _Badge(label: '- $discount', bg: _Clr.greenBg, text: _Clr.greenText),
          ]),
        ]),
      ),
      const SizedBox(width: 10),
      Text(total,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: _Clr.textPrimary)),
    ]),
  );
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final Color  valueColor;
  const _TotalRow({required this.label, required this.value, this.valueColor = _Clr.textPrimary});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 8),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: _Clr.borderSoft, width: 0.5)),
    ),
    margin: const EdgeInsets.only(top: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _Clr.textPrimary)),
      Text(value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
    ]),
  );
}

class _PaymentLine extends StatelessWidget {
  final String label, value;
  final Color  valueColor;
  final bool   bold;
  const _PaymentLine({
    required this.label, required this.value,
    this.valueColor = _Clr.textSecond, this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: TextStyle(
              fontSize: 12, color: bold ? _Clr.textPrimary : _Clr.textSecond,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
      Text(value,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: valueColor)),
    ],
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
          width: 72, height: 72,
          decoration: BoxDecoration(
            color:        _Clr.card,
            border:       Border.all(color: _Clr.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const AppIcon('ic_cart_empty', size: 32, color: _Clr.textMuted),
        ),
        const SizedBox(height: 16),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: _Clr.textSecond)),
        const SizedBox(height: 6),
        const Text('Try changing the date range',
            style: TextStyle(fontSize: 12, color: _Clr.textMuted)),
      ]),
    ),
  );
}