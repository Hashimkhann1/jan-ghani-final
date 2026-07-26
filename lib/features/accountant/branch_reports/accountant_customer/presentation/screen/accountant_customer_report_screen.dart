import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/color/app_color.dart';
import '../../data/model/accountant_customer_model.dart';
import '../../data/service/customer_report_pdf_service.dart';
import '../provider/accountant_customer_provider.dart';

class AccountantCustomerReportScreen extends ConsumerStatefulWidget {
  const AccountantCustomerReportScreen(
      {super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<AccountantCustomerReportScreen> createState() =>
      _AccountantCustomerReportScreenState();
}

class _AccountantCustomerReportScreenState
    extends ConsumerState<AccountantCustomerReportScreen> {
  final _searchCtrl = TextEditingController();
  final _amtFmt     = NumberFormat('#,##,###', 'en_IN');

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';
  String get _branchId  => widget.branchId;

  bool _isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 800;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Export PDF — hamesha current filtered list use karta hai ─────────────
  Future<void> _exportPdf(
      BuildContext context, AccountantCustomerReportState state) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Generating PDF...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));

      await AccountantCustomerReportPdfService.exportAndShare(
        items: state.filtered,
        filterType: state.filterType,
        searchQuery: state.searchQuery,
        totalCustomers: state.summary.totalCustomers,
        activeCustomers: state.summary.activeCustomers,
        totalOutstanding: state.summary.totalOutstanding,
        limitExceededCount: state.summary.limitExceededCount,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColor.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(
        accountantCustomerReportProvider(_branchId));
    final notifier = ref.read(
        accountantCustomerReportProvider(_branchId).notifier);
    final desktop  = _isDesktop(context);

    ref.listen<AccountantCustomerReportState>(
      accountantCustomerReportProvider(_branchId),
          (_, next) {
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
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: desktop
          ? _DesktopLayout(
        state:      state,
        notifier:   notifier,
        fmtAmt:     _fmt,
        searchCtrl: _searchCtrl,
        onExportPdf: () => _exportPdf(context, state),
      )
          : _MobileLayout(
        state:      state,
        notifier:   notifier,
        fmtAmt:     _fmt,
        searchCtrl: _searchCtrl,
        onExportPdf: () => _exportPdf(context, state),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DESKTOP LAYOUT
// ══════════════════════════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  final AccountantCustomerReportState state;
  final dynamic                       notifier;
  final String Function(double)       fmtAmt;
  final TextEditingController         searchCtrl;
  final VoidCallback                  onExportPdf;

  const _DesktopLayout({
    required this.state,
    required this.notifier,
    required this.fmtAmt,
    required this.searchCtrl,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Top bar ──────────────────────────────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Row(
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
                  Text('Customer Report',
                      style: TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.w700,
                        color:      Color(0xFF1A1D23),
                      )),
                  SizedBox(height: 2),
                  Text('Tamam customers ki detail',
                      style: TextStyle(
                          fontSize: 13,
                          color:    AppColor.textHint)),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 130,
                child: ElevatedButton.icon(
                  onPressed: onExportPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
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

        // ── Summary + Search row ─────────────────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DeskSummaryCard(
                label: 'Total',
                value: '${state.summary.totalCustomers}',
                icon:  Icons.people_outline_rounded,
                color: AppColor.primary,
              ),
              const SizedBox(width: 10),
              _DeskSummaryCard(
                label: 'Active',
                value: '${state.summary.activeCustomers}',
                icon:  Icons.person_outline_rounded,
                color: AppColor.success,
              ),
              const SizedBox(width: 10),
              _DeskSummaryCard(
                label: 'Outstanding',
                value: fmtAmt(state.summary.totalOutstanding),
                icon:  Icons.account_balance_wallet_outlined,
                color: AppColor.error,
              ),
              const SizedBox(width: 10),
              _DeskSummaryCard(
                label:    'Limit Cross',
                value:    '${state.summary.limitExceededCount}',
                icon:     Icons.warning_amber_rounded,
                color:    const Color(0xFFEF4444),
                selected: state.filterType == 'exceeded',
                onTap:    () => notifier.setFilter(
                    state.filterType == 'exceeded'
                        ? null
                        : 'exceeded'),
              ),
              const SizedBox(width: 16),
              const SizedBox(
                  height: 48,
                  child: VerticalDivider(
                      width: 1, color: Color(0xFFEEEEEE))),
              const SizedBox(width: 16),

              // Filter chips
              _DeskFilterChip(
                label:    'All',
                selected: state.filterType == null,
                color:    AppColor.primary,
                onTap:    () => notifier.setFilter(null),
              ),
              const SizedBox(width: 8),
              _DeskFilterChip(
                label:    'Credit',
                selected: state.filterType == 'credit',
                color:    const Color(0xFFF59E0B),
                onTap:    () => notifier.setFilter('credit'),
              ),
              const SizedBox(width: 8),
              _DeskFilterChip(
                label:    'Petrol',
                selected: state.filterType == 'petrol',
                color:    const Color(0xFF8B5CF6),
                onTap:    () => notifier.setFilter('petrol'),
              ),

              const SizedBox(width: 16),
              const SizedBox(
                  height: 48,
                  child: VerticalDivider(
                      width: 1, color: Color(0xFFEEEEEE))),
              const SizedBox(width: 16),

              // Search
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: searchCtrl,
                    onChanged:  notifier.search,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Name, phone ya code...',
                      hintStyle: const TextStyle(
                          fontSize: 13,
                          color:    AppColor.textHint),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: AppColor.primary),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            size: 16,
                            color: AppColor.textHint),
                        onPressed: () {
                          searchCtrl.clear();
                          notifier.search('');
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColor.grey200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color:  AppColor.primary,
                            width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // ── Table ────────────────────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.filtered.isEmpty
              ? const _EmptyState()
              : _CustomerTable(
            items:  state.filtered,
            fmtAmt: fmtAmt,
          ),
        ),
      ],
    );
  }
}

// ── Desktop Summary Card ───────────────────────────────────────────────────
class _DeskSummaryCard extends StatelessWidget {
  final String        label;
  final String        value;
  final IconData      icon;
  final Color         color;
  final bool          selected;
  final VoidCallback? onTap;

  const _DeskSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        selected
            ? color.withOpacity(0.1)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? color.withOpacity(0.4)
              : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:       MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.w800,
                    color:      color,
                  )),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color:    AppColor.textHint)),
            ],
          ),
        ],
      ),
    ),
  );
}

// ── Desktop Filter Chip ────────────────────────────────────────────────────
class _DeskFilterChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const _DeskFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color:        selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? color : AppColor.grey200,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.w600,
          color:
          selected ? Colors.white : AppColor.textSecondary,
        ),
      ),
    ),
  );
}

// ── Customer Table ─────────────────────────────────────────────────────────
class _CustomerTable extends StatelessWidget {
  final List<AccountantCustomerReportModel> items;
  final String Function(double)             fmtAmt;

  const _CustomerTable({
    required this.items,
    required this.fmtAmt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 12),
          child: Row(children: const [
            SizedBox(width: 10),
            _TH(label: '#',          flex: 1),
            _TH(label: 'Name',       flex: 5),
            _TH(label: 'Code',       flex: 2),
            _TH(label: 'Phone',      flex: 3),
            _TH(label: 'Type',       flex: 2, center: true),
            _TH(label: 'Balance',    flex: 3, right: true),
            _TH(label: 'Limit',      flex: 3, right: true),
            _TH(label: 'Usage',      flex: 3, center: true),
            _TH(label: 'Address',    flex: 4),
            _TH(label: 'Status',     flex: 3, center: true),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // Rows
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            itemCount:        items.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (_, i) => _CustomerTableRow(
              index:  i + 1,
              item:   items[i],
              fmtAmt: fmtAmt,
            ),
          ),
        ),
      ],
    );
  }
}

// Table Header Cell
class _TH extends StatelessWidget {
  final String label;
  final int    flex;
  final bool   right;
  final bool   center;

  const _TH({
    required this.label,
    this.flex   = 1,
    this.right  = false,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      label,
      textAlign: right
          ? TextAlign.right
          : center
          ? TextAlign.center
          : TextAlign.left,
      style: const TextStyle(
        fontSize:      11,
        fontWeight:    FontWeight.w700,
        color:         AppColor.textHint,
        letterSpacing: 0.3,
      ),
    ),
  );
}

// Table Row
class _CustomerTableRow extends StatelessWidget {
  final int                          index;
  final AccountantCustomerReportModel item;
  final String Function(double)      fmtAmt;

  const _CustomerTableRow({
    required this.index,
    required this.item,
    required this.fmtAmt,
  });

  Color get _typeColor {
    switch (item.customerType) {
      case 'credit': return const Color(0xFFF59E0B);
      case 'petrol': return const Color(0xFF8B5CF6);
      default:       return AppColor.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exceeded    = item.isCreditLimitExceeded;
    final hasBalance  = item.balance > 0;
    final balColor    = exceeded
        ? const Color(0xFFEF4444)
        : hasBalance
        ? AppColor.error
        : AppColor.success;
    final usageRatio  = item.creditUsageRatio;

    return Container(
      color:   Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // #
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text('$index',
                  style: const TextStyle(
                      fontSize: 12,
                      color:    AppColor.textHint)),
            ),
          ),

          // Name + avatar letter
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width:  30,
                  height: 30,
                  decoration: BoxDecoration(
                    color:        _typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      item.name.isNotEmpty
                          ? item.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w800,
                        color:      _typeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:       MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      Color(0xFF1A1D23),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (exceeded)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color:        const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('LIMIT CROSS',
                              style: TextStyle(
                                fontSize:   8,
                                fontWeight: FontWeight.w800,
                                color:      Colors.white,
                              )),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Code
          Expanded(
            flex: 2,
            child: Text(item.code,
                style: const TextStyle(
                    fontSize: 12,
                    color:    AppColor.textHint)),
          ),

          // Phone
          Expanded(
            flex: 3,
            child: Text(
              item.phone.isEmpty ? '-' : item.phone,
              style: const TextStyle(
                  fontSize: 12,
                  color:    AppColor.textSecondary),
            ),
          ),

          // Type badge
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      color: _typeColor.withOpacity(0.3)),
                ),
                child: Text(
                  item.customerType.toUpperCase(),
                  style: TextStyle(
                    fontSize:   9,
                    fontWeight: FontWeight.w700,
                    color:      _typeColor,
                  ),
                ),
              ),
            ),
          ),

          // Balance
          Expanded(
            flex: 3,
            child: Text(
              fmtAmt(item.balance),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w700,
                color:      balColor,
              ),
            ),
          ),

          // Credit Limit
          Expanded(
            flex: 3,
            child: Text(
              item.creditLimit > 0
                  ? fmtAmt(item.creditLimit)
                  : '-',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12,
                  color:    AppColor.textSecondary),
            ),
          ),

          // Usage progress bar
          Expanded(
            flex: 3,
            child: item.creditLimit > 0
                ? Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:       usageRatio.clamp(0.0, 1.0),
                      minHeight:   6,
                      backgroundColor: exceeded
                          ? const Color(0xFFEF4444)
                          .withOpacity(0.15)
                          : const Color(0xFFE5E7EB),
                      valueColor:
                      AlwaysStoppedAnimation<Color>(
                        exceeded
                            ? const Color(0xFFEF4444)
                            : usageRatio > 0.75
                            ? const Color(0xFFF59E0B)
                            : AppColor.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(usageRatio * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 9,
                      color:    exceeded
                          ? const Color(0xFFEF4444)
                          : AppColor.textHint,
                    ),
                  ),
                ],
              ),
            )
                : const Center(
              child: Text('-',
                  style: TextStyle(
                      fontSize: 12,
                      color:    AppColor.textHint)),
            ),
          ),

          // Address
          Expanded(
            flex: 4,
            child: Text(
              item.address.isEmpty ? '-' : item.address,
              style: const TextStyle(
                  fontSize: 11,
                  color:    AppColor.textHint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status + WhatsApp
          Expanded(
            flex: 3,
            child: Center(
              child: item.phone.isNotEmpty && item.balance > 0
                  ? GestureDetector(
                onTap: () => _sendWhatsApp(
                    context, item, fmtAmt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366)
                        .withOpacity(0.08),
                    borderRadius:
                    BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0xFF25D366)
                            .withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat,
                          size:  13,
                          color: Color(0xFF25D366)),
                      SizedBox(width: 4),
                      Text('Remind',
                          style: TextStyle(
                            fontSize:   10,
                            fontWeight: FontWeight.w600,
                            color:      Color(0xFF25D366),
                          )),
                    ],
                  ),
                ),
              )
                  : Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        AppColor.success
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Clear',
                    style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.success,
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendWhatsApp(
      BuildContext context,
      AccountantCustomerReportModel c,
      String Function(double) fmtAmt) async {
    final balance = fmtAmt(c.balance);
    final message =
        'السلام علیکم ${c.name} صاحب،\n\n'
        'امید ہے آپ بالکل ٹھیک ہوں گے۔\n\n'
        '*جان غنی اسٹور* کی طرف سے گزارش ہے کہ '
        'آپ کے اکاؤنٹ میں ابھی *Rs $balance* کا بقایا جات موجود ہے۔\n\n'
        'مہربانی فرما کر جلد از جلد کچھ رقم جمع کروائیں۔\n\n'
        'شکریہ 🙏\n*جان غنی اسٹور*';
    final phone    = c.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final intlPhone =
    phone.startsWith('0') ? '92${phone.substring(1)}' : phone;
    final url      = Uri.parse(
        'https://wa.me/$intlPhone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('WhatsApp nahi khul raha'),
        backgroundColor: Colors.red,
        behavior:        SnackBarBehavior.floating,
      ));
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE LAYOUT
// ══════════════════════════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  final AccountantCustomerReportState state;
  final dynamic                       notifier;
  final String Function(double)       fmtAmt;
  final TextEditingController         searchCtrl;
  final VoidCallback                  onExportPdf;

  const _MobileLayout({
    required this.state,
    required this.notifier,
    required this.fmtAmt,
    required this.searchCtrl,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Customer Report',
            style: TextStyle(
                fontSize:   17,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF1A1D23))),
        actions: [
          IconButton(
            onPressed: onExportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined,
                color: AppColor.primary),
            tooltip: 'Export PDF',
          ),
          IconButton(
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [

          // ── Search ───────────────────────────────────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: searchCtrl,
              onChanged:  notifier.search,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Name, phone ya code se search karein...',
                hintStyle: const TextStyle(
                    fontSize: 13, color: AppColor.textHint),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: AppColor.primary),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 18, color: AppColor.textHint),
                  onPressed: () {
                    searchCtrl.clear();
                    notifier.search('');
                  },
                )
                    : null,
                filled:    true,
                fillColor: AppColor.grey100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:   BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                  const BorderSide(color: AppColor.grey200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppColor.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Filter Chips ─────────────────────────────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                      label:    'All',
                      selected: state.filterType == null,
                      color:    AppColor.primary,
                      onTap:    () => notifier.setFilter(null)),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label:    'Credit',
                      selected: state.filterType == 'credit',
                      color:    const Color(0xFFF59E0B),
                      onTap:    () => notifier.setFilter('credit')),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label:    'Petrol',
                      selected: state.filterType == 'petrol',
                      color:    const Color(0xFF8B5CF6),
                      onTap:    () => notifier.setFilter('petrol')),
                  const SizedBox(width: 8),
                  _ExceededChip(
                    selected: state.filterType == 'exceeded',
                    count:    state.summary.limitExceededCount,
                    onTap:    () => notifier.setFilter('exceeded'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // ── Summary Cards ────────────────────────────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
                children: [
                  _SummaryCard(
                    label: 'Total',
                    value: '${state.summary.totalCustomers}',
                    icon:  Icons.people_outline_rounded,
                    color: AppColor.primary,
                  ),
                  const SizedBox(width: 8),
                  _SummaryCard(
                    label: 'Active',
                    value: '${state.summary.activeCustomers}',
                    icon:  Icons.person_outline_rounded,
                    color: AppColor.success,
                  ),
                  const SizedBox(width: 8),
                  _SummaryCard(
                    label: 'Outstanding',
                    value: fmtAmt(state.summary.totalOutstanding),
                    icon:  Icons.account_balance_wallet_outlined,
                    color: AppColor.error,
                  ),
                  const SizedBox(width: 8),
                  _SummaryCard(
                    label: 'Limit Cross',
                    value: '${state.summary.limitExceededCount}',
                    icon:  Icons.warning_amber_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ]),
          ),
          Container(height: 6, color: const Color(0xFFF5F6FA)),

          // Result count
          if (!state.isLoading && state.filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(children: [
                Text('${state.filtered.length} customer',
                    style: const TextStyle(
                        fontSize: 12,
                        color:    AppColor.textHint)),
              ]),
            ),

          // ── Customer Cards ───────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filtered.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 24),
                itemCount:        state.filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (_, i) => _CustomerCard(
                  customer: state.filtered[i],
                  fmtAmt:   fmtAmt,
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
// Mobile Summary Card
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
// Customer Card (Mobile)
// ══════════════════════════════════════════════════════════════════════════════
class _CustomerCard extends StatelessWidget {
  final AccountantCustomerReportModel customer;
  final String Function(double)       fmtAmt;

  const _CustomerCard({
    required this.customer,
    required this.fmtAmt,
  });

  Color get _typeColor {
    switch (customer.customerType) {
      case 'credit': return const Color(0xFFF59E0B);
      case 'petrol': return const Color(0xFF8B5CF6);
      default:       return AppColor.success;
    }
  }

  Future<void> _sendWhatsAppReminder(BuildContext context) async {
    final balance   = fmtAmt(customer.balance);
    final name      = customer.name;
    final message   =
        'السلام علیکم $name صاحب،\n\n'
        'امید ہے آپ بالکل ٹھیک ہوں گے۔\n\n'
        '*جان غنی اسٹور* کی طرف سے گزارش ہے کہ '
        'آپ کے اکاؤنٹ میں ابھی *Rs $balance* کا بقایا جات موجود ہے۔\n\n'
        'مہربانی فرما کر جلد از جلد کچھ رقم جمع کروائیں تاکہ '
        'آپ کا اکاؤنٹ درست رہے اور آپ کو مزید سہولت مل سکے۔\n\n'
        'شکریہ 🙏\n*جان غنی اسٹور*';
    final phone     =
    customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final intlPhone =
    phone.startsWith('0') ? '92${phone.substring(1)}' : phone;
    final url       = Uri.parse(
        'https://wa.me/$intlPhone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('WhatsApp nahi khul raha'),
        backgroundColor: Colors.red,
        behavior:        SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final exceeded   = customer.isCreditLimitExceeded;
    final hasBalance = customer.balance > 0;
    final balColor   = exceeded
        ? const Color(0xFFEF4444)
        : hasBalance
        ? AppColor.error
        : AppColor.success;
    final usageRatio = customer.creditUsageRatio;

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: exceeded
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : const Color(0xFFEFEFF2),
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header strip: avatar + name + limit badge ────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width:  48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:        _typeColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:      _typeColor.withOpacity(0.35),
                        blurRadius: 8,
                        offset:     const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize:   19,
                        fontWeight: FontWeight.w800,
                        color:      Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w700,
                          color:      Color(0xFF1A1D23),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing:   10,
                        runSpacing: 4,
                        children: [
                          _MetaChip(
                            icon: Icons.phone_outlined,
                            text: customer.phone.isEmpty
                                ? '-' : customer.phone,
                          ),
                          _MetaChip(
                            icon: Icons.tag_rounded,
                            text: customer.code,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (exceeded)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color:        const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 11, color: Colors.white),
                        SizedBox(width: 3),
                        Text('LIMIT',
                            style: TextStyle(
                              fontSize:   9,
                              fontWeight: FontWeight.w800,
                              color:      Colors.white,
                              letterSpacing: 0.3,
                            )),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Balance + Type strip ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color:        balColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Balance',
                            style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: balColor.withOpacity(0.75))),
                        const SizedBox(height: 2),
                        Text(
                          fmtAmt(customer.balance),
                          style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w800,
                            color:      balColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:        _typeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _typeColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    customer.customerType.toUpperCase(),
                    style: TextStyle(
                      fontSize:   10.5,
                      fontWeight: FontWeight.w800,
                      color:      _typeColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Credit Limit Section ───────────────────────────────────────
          if (customer.creditLimit > 0) ...[
            const SizedBox(height: 10),
            Container(
              margin:  const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        exceeded
                    ? const Color(0xFFEF4444).withOpacity(0.05)
                    : const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: exceeded
                      ? const Color(0xFFEF4444).withOpacity(0.2)
                      : const Color(0xFFEEEEEE),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(
                          exceeded
                              ? Icons.warning_amber_rounded
                              : Icons.credit_score_outlined,
                          size:  12,
                          color: exceeded
                              ? const Color(0xFFEF4444)
                              : AppColor.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Credit Limit',
                          style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            color:      exceeded
                                ? const Color(0xFFEF4444)
                                : AppColor.textHint,
                          ),
                        ),
                      ]),
                      Flexible(
                        child: RichText(
                          textAlign: TextAlign.right,
                          text: TextSpan(children: [
                            TextSpan(
                              text: fmtAmt(customer.balance),
                              style: TextStyle(
                                fontSize:   11,
                                fontWeight: FontWeight.w700,
                                color:      exceeded
                                    ? const Color(0xFFEF4444)
                                    : AppColor.textSecondary,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${fmtAmt(customer.creditLimit)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color:    AppColor.textHint),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:      usageRatio.clamp(0.0, 1.0),
                      minHeight:  6,
                      backgroundColor: exceeded
                          ? const Color(0xFFEF4444).withOpacity(0.15)
                          : const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        exceeded
                            ? const Color(0xFFEF4444)
                            : usageRatio > 0.75
                            ? const Color(0xFFF59E0B)
                            : AppColor.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  exceeded
                      ? Text(
                    'Limit se ${fmtAmt(customer.balance - customer.creditLimit)} zyada',
                    style: const TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                      color:      Color(0xFFEF4444),
                    ),
                  )
                      : Text(
                    '${(usageRatio * 100).toStringAsFixed(0)}% used',
                    style: TextStyle(
                      fontSize: 10,
                      color:    usageRatio > 0.75
                          ? const Color(0xFFF59E0B)
                          : AppColor.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Address ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 12, color: AppColor.textHint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  customer.address.isEmpty
                      ? 'No address'
                      : customer.address,
                  style: const TextStyle(
                      fontSize: 11.5,
                      color:    AppColor.textHint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),

          // ── WhatsApp Button ────────────────────────────────────────────
          if (customer.phone.isNotEmpty && customer.balance > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: GestureDetector(
                onTap: () => _sendWhatsAppReminder(context),
                child: Container(
                  width:   double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF25D366).withOpacity(0.35)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, size: 15, color: Color(0xFF25D366)),
                      SizedBox(width: 6),
                      Text(
                        'Send Payment Reminder',
                        style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color:      Color(0xFF25D366),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}
// ══════════════════════════════════════════════════════════════════════════════
// Shared Widgets
// ══════════════════════════════════════════════════════════════════════════════
class _FilterChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color:        selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? color : AppColor.grey200,
          width: 1.5,
        ),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color:
            selected ? Colors.white : AppColor.textSecondary,
          )),
    ),
  );
}

class _ExceededChip extends StatelessWidget {
  final bool         selected;
  final int          count;
  final VoidCallback onTap;

  const _ExceededChip({
    required this.selected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFEF4444);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:        selected ? red : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? red : AppColor.grey200, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 13,
                color: selected ? Colors.white : red),
            const SizedBox(width: 4),
            Text('Limit Cross',
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      selected ? Colors.white : red,
                )),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color:        selected
                      ? Colors.white.withOpacity(0.3)
                      : red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w800,
                      color:      selected ? Colors.white : red,
                    )),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.people_outline_rounded,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Koi customer nahi mila',
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      Colors.grey.shade500,
            )),
        const SizedBox(height: 6),
        Text('Search change karein ya filter hatayein',
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: AppColor.textHint),
      const SizedBox(width: 3),
      Text(text,
          style: const TextStyle(
              fontSize: 11.5, color: AppColor.textSecondary)),
    ],
  );
}