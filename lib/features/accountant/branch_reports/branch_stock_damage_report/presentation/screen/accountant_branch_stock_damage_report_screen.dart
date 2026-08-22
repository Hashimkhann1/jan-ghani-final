import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../../core/color/app_color.dart';
import '../../../common/pagination/branch_report_pagination_controls.dart';
import '../../data/model/accountant_branch_stock_damage_model.dart';
import '../../data/service/accountant_branch_stock_damage_pdf_service.dart';
import '../provider/accountant_branch_stock_damage_provider.dart';

class AccountantBranchStockDamageReportScreen extends ConsumerStatefulWidget {
  const AccountantBranchStockDamageReportScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<AccountantBranchStockDamageReportScreen> createState() =>
      _AccountantBranchStockDamageReportScreenState();
}

class _AccountantBranchStockDamageReportScreenState
    extends ConsumerState<AccountantBranchStockDamageReportScreen> {
  final _searchCtrl = TextEditingController();
  final _startCtrl  = TextEditingController();
  final _endCtrl    = TextEditingController();

  final _amtFmt   = NumberFormat('#,##,###.##', 'en_IN');
  final _dateFmt  = DateFormat('dd MMM yyyy, hh:mm a');
  final _fieldFmt = DateFormat('dd MMM yyyy');

  String _fmtAmt(double v) => 'Rs ${_amtFmt.format(v)}';
  String _fmtQty(double q) => q.toStringAsFixed(2);
  String _fmtDate(DateTime d) => _dateFmt.format(d);
  bool _isDesktop(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 800;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate(BuildContext context, dynamic notifier,
      AccountantBranchStockDamageState state) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _startCtrl.text = _fieldFmt.format(picked);
      notifier.setStartDate(picked);
    }
  }

  Future<void> _pickEndDate(BuildContext context, dynamic notifier,
      AccountantBranchStockDamageState state) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _endCtrl.text = _fieldFmt.format(picked);
      notifier.setEndDate(picked);
    }
  }

  void _clearDates(dynamic notifier) {
    _startCtrl.clear();
    _endCtrl.clear();
    notifier.clearDateFilter();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountantBranchStockDamageProvider(widget.branchId));
    final notifier = ref.read(accountantBranchStockDamageProvider(widget.branchId).notifier);
    final desktop = _isDesktop(context);

    ref.listen<AccountantBranchStockDamageState>(
      accountantBranchStockDamageProvider(widget.branchId),
          (_, next) {
        if (next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'OK',
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
        state: state,
        notifier: notifier,
        fmtAmt: _fmtAmt,
        fmtQty: _fmtQty,
        fmtDate: _fmtDate,
        searchCtrl: _searchCtrl,
        startCtrl: _startCtrl,
        endCtrl: _endCtrl,
        onPickStart: () => _pickStartDate(context, notifier, state),
        onPickEnd: () => _pickEndDate(context, notifier, state),
        onClearDates: () => _clearDates(notifier),
      )
          : _MobileLayout(
        state: state,
        notifier: notifier,
        fmtAmt: _fmtAmt,
        fmtQty: _fmtQty,
        fmtDate: _fmtDate,
        searchCtrl: _searchCtrl,
        startCtrl: _startCtrl,
        endCtrl: _endCtrl,
        onPickStart: () => _pickStartDate(context, notifier, state),
        onPickEnd: () => _pickEndDate(context, notifier, state),
        onClearDates: () => _clearDates(notifier),
      ),
    );
  }
}

// Export PDF — hamesha state.filtered (current applied search + date filter) use karta hai
Future<void> _exportPdf(BuildContext context, AccountantBranchStockDamageState state) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Generating PDF...'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));

    await AccountantBranchStockDamagePdfService.exportAndShare(
      items: state.filtered,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
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

// ══════════════════════════════════════════════════════════════════════════════
// DATE FILTER ROW (shared)
// ══════════════════════════════════════════════════════════════════════════════
class _DateFilterRow extends StatelessWidget {
  final TextEditingController startCtrl;
  final TextEditingController endCtrl;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClearDates;
  final bool hasFilter;

  const _DateFilterRow({
    required this.startCtrl,
    required this.endCtrl,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClearDates,
    required this.hasFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: startCtrl,
            readOnly: true,
            onTap: onPickStart,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Start date',
              hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColor.primary),
              filled: true,
              fillColor: AppColor.grey100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColor.grey200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColor.textHint),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: endCtrl,
            readOnly: true,
            onTap: onPickEnd,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'End date',
              hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColor.primary),
              filled: true,
              fillColor: AppColor.grey100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColor.grey200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
            ),
          ),
        ),
        if (hasFilter) ...[
          const SizedBox(width: 10),
          IconButton(
            onPressed: onClearDates,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18, color: AppColor.error),
            tooltip: 'Clear date filter',
            style: IconButton.styleFrom(
              backgroundColor: AppColor.error.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DESKTOP LAYOUT
// ══════════════════════════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  final AccountantBranchStockDamageState state;
  final dynamic notifier;
  final String Function(double) fmtAmt;
  final String Function(double) fmtQty;
  final String Function(DateTime) fmtDate;
  final TextEditingController searchCtrl;
  final TextEditingController startCtrl;
  final TextEditingController endCtrl;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClearDates;

  const _DesktopLayout({
    required this.state,
    required this.notifier,
    required this.fmtAmt,
    required this.fmtQty,
    required this.fmtDate,
    required this.searchCtrl,
    required this.startCtrl,
    required this.endCtrl,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClearDates,
  });

  @override
  Widget build(BuildContext context) {
    final hasDateFilter = state.startDate != null || state.endDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1D23)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F6FA),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Stock Damage Report',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1D23))),
                  SizedBox(height: 2),
                  Text('Damaged / wasted stock details',
                      style: TextStyle(fontSize: 13, color: AppColor.textHint)),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 130,
                child: ElevatedButton.icon(
                  onPressed: () => _exportPdf(context, state),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: OutlinedButton.icon(
                  onPressed: notifier.load,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: const BorderSide(color: AppColor.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // Summary + Search + Date filter
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _DeskSummaryCard(
                    label: 'Records',
                    value: '${state.summary.totalRecords}',
                    icon: Icons.receipt_long_outlined,
                    color: AppColor.primary,
                  ),
                  const SizedBox(width: 10),
                  _DeskSummaryCard(
                    label: 'Damaged Qty',
                    value: fmtQty(state.summary.totalDamageQty),
                    icon: Icons.broken_image_outlined,
                    color: AppColor.error,
                  ),
                  const SizedBox(width: 10),
                  _DeskSummaryCard(
                    label: 'Purchase Loss',
                    value: fmtAmt(state.summary.totalPurchaseLoss),
                    icon: Icons.shopping_cart_outlined,
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 10),
                  _DeskSummaryCard(
                    label: 'Sale Loss',
                    value: fmtAmt(state.summary.totalSaleLoss),
                    icon: Icons.sell_outlined,
                    color: AppColor.warning,
                  ),
                  const SizedBox(width: 16),
                  const SizedBox(height: 48, width: 1, child: VerticalDivider(width: 1, color: Color(0xFFEEEEEE))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: notifier.search,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search product name...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColor.primary),
                          suffixIcon: state.searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: AppColor.textHint),
                            onPressed: () {
                              searchCtrl.clear();
                              notifier.search('');
                            },
                          )
                              : null,
                          filled: true,
                          fillColor: AppColor.grey100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColor.grey200)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Date filter row (start / end)
              SizedBox(
                width: 520,
                child: _DateFilterRow(
                  startCtrl: startCtrl,
                  endCtrl: endCtrl,
                  onPickStart: onPickStart,
                  onPickEnd: onPickEnd,
                  onClearDates: onClearDates,
                  hasFilter: hasDateFilter,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // Table
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.filtered.isEmpty
              ? const _EmptyState()
              : _DamageTable(items: state.pagedItems, fmtAmt: fmtAmt, fmtQty: fmtQty, fmtDate: fmtDate),
        ),
        if (!state.isLoading && state.filtered.isNotEmpty)
          BranchReportPaginationControls(
            page:        state.pagination.page,
            hasNextPage: state.pagination.hasNextPage,
            onNext:      notifier.nextPage,
            onPrevious:  notifier.previousPage,
          ),
      ],
    );
  }
}

class _DeskSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DeskSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFEEEEEE)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColor.textHint)),
          ],
        ),
      ],
    ),
  );
}

class _DamageTable extends StatelessWidget {
  final List<AccountantBranchStockDamageModel> items;
  final String Function(double) fmtAmt;
  final String Function(double) fmtQty;
  final String Function(DateTime) fmtDate;

  const _DamageTable({
    required this.items,
    required this.fmtAmt,
    required this.fmtQty,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Row(children: [
            const SizedBox(width: 10),
            _TH(label: '#', flex: 1),
            _TH(label: 'Product', flex: 5),
            _TH(label: 'Damage Qty', flex: 3, center: true),
            _TH(label: 'Purchase Price', flex: 3, right: true),
            _TH(label: 'Sale Price', flex: 3, right: true),
            _TH(label: 'Purchase Loss', flex: 3, right: true),
            _TH(label: 'Sale Loss', flex: 3, right: true),
            _TH(label: 'Date', flex: 4, center: true),
          ]),
        ),
        Container(height: 1, color: const Color(0xFFEEEEEE)),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (_, i) => _TableRow(
                index: i + 1, item: items[i], fmtAmt: fmtAmt, fmtQty: fmtQty, fmtDate: fmtDate),
          ),
        ),
      ],
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final int flex;
  final bool right;
  final bool center;

  const _TH({required this.label, this.flex = 1, this.right = false, this.center = false});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      label,
      textAlign: right ? TextAlign.right : center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.textHint, letterSpacing: 0.3),
    ),
  );
}

class _TableRow extends StatelessWidget {
  final int index;
  final AccountantBranchStockDamageModel item;
  final String Function(double) fmtAmt;
  final String Function(double) fmtQty;
  final String Function(DateTime) fmtDate;

  const _TableRow({
    required this.index,
    required this.item,
    required this.fmtAmt,
    required this.fmtQty,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text('$index', style: const TextStyle(fontSize: 12, color: AppColor.textHint)),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(item.productName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1D23)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 3,
            child: Text(fmtQty(item.stockDamage),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.error)),
          ),
          Expanded(
            flex: 3,
            child: Text(fmtAmt(item.purchasePrice),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8B5CF6))),
          ),
          Expanded(
            flex: 3,
            child: Text(fmtAmt(item.salePrice),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.primary)),
          ),
          Expanded(
            flex: 3,
            child: Text(fmtAmt(item.purchaseLoss),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.error)),
          ),
          Expanded(
            flex: 3,
            child: Text(fmtAmt(item.saleLoss),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.error)),
          ),
          Expanded(
            flex: 4,
            child: Text(fmtDate(item.createdAt),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColor.textHint)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE LAYOUT
// ══════════════════════════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  final AccountantBranchStockDamageState state;
  final dynamic notifier;
  final String Function(double) fmtAmt;
  final String Function(double) fmtQty;
  final String Function(DateTime) fmtDate;
  final TextEditingController searchCtrl;
  final TextEditingController startCtrl;
  final TextEditingController endCtrl;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClearDates;

  const _MobileLayout({
    required this.state,
    required this.notifier,
    required this.fmtAmt,
    required this.fmtQty,
    required this.fmtDate,
    required this.searchCtrl,
    required this.startCtrl,
    required this.endCtrl,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClearDates,
  });

  @override
  Widget build(BuildContext context) {
    final hasDateFilter = state.startDate != null || state.endDate != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Stock Damage Report',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1D23))),
        actions: [
          IconButton(
            onPressed: () => _exportPdf(context, state),
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColor.primary),
            tooltip: 'Export PDF',
          ),
          IconButton(
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh_rounded, color: AppColor.textSecondary),
            tooltip: 'Refresh',
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
          // Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: searchCtrl,
              onChanged: notifier.search,
              style: const TextStyle(fontSize: 14),
              cursorHeight: 16,
              decoration: InputDecoration(
                hintText: 'Search product name...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColor.primary),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColor.textHint),
                  onPressed: () {
                    searchCtrl.clear();
                    notifier.search('');
                  },
                )
                    : null,
                filled: true,
                fillColor: AppColor.grey100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColor.grey200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
              ),
            ),
          ),

          // Date filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _DateFilterRow(
              startCtrl: startCtrl,
              endCtrl: endCtrl,
              onPickStart: onPickStart,
              onPickEnd: onPickEnd,
              onClearDates: onClearDates,
              hasFilter: hasDateFilter,
            ),
          ),

          // Summary Cards
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              _MobileSummaryCard(label: 'Records', value: '${state.summary.totalRecords}', icon: Icons.receipt_long_outlined, color: AppColor.primary),
              const SizedBox(width: 8),
              _MobileSummaryCard(label: 'Damaged', value: fmtQty(state.summary.totalDamageQty), icon: Icons.broken_image_outlined, color: AppColor.error),
            ]),
          ),

          // Values Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(children: [
              Expanded(
                child: _ValueCard(
                  label: 'Purchase Loss',
                  value: fmtAmt(state.summary.totalPurchaseLoss),
                  icon: Icons.shopping_cart_outlined,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ValueCard(
                  label: 'Sale Loss',
                  value: fmtAmt(state.summary.totalSaleLoss),
                  icon: Icons.sell_outlined,
                  color: AppColor.error,
                ),
              ),
            ]),
          ),
          Container(height: 6, color: const Color(0xFFF5F6FA)),

          if (!state.isLoading && state.filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(children: [
                Text('${state.filtered.length} records',
                    style: const TextStyle(fontSize: 12, color: AppColor.textHint)),
              ]),
            ),

          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filtered.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: state.pagedItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _DamageCard(
                    item: state.pagedItems[i], fmtAmt: fmtAmt, fmtQty: fmtQty, fmtDate: fmtDate),
              ),
            ),
          ),
          if (!state.isLoading && state.filtered.isNotEmpty)
            BranchReportPaginationControls(
              page:        state.pagination.page,
              hasNextPage: state.pagination.hasNextPage,
              onNext:      notifier.nextPage,
              onPrevious:  notifier.previousPage,
            ),
        ],
      ),
    );
  }
}

class _MobileSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MobileSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(height: 7),
          Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
        ],
      ),
    ),
  );
}

class _ValueCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _ValueCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 5),
        Text(value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColor.textHint)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Damage Card (Mobile)
// ══════════════════════════════════════════════════════════════════════════════
class _DamageCard extends StatelessWidget {
  final AccountantBranchStockDamageModel item;
  final String Function(double) fmtAmt;
  final String Function(double) fmtQty;
  final String Function(DateTime) fmtDate;

  const _DamageCard({
    required this.item,
    required this.fmtAmt,
    required this.fmtQty,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColor.error.withOpacity(0.15), AppColor.error.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.broken_image_outlined, color: AppColor.error, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1D23)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 11, color: AppColor.textHint),
                        const SizedBox(width: 4),
                        Text(fmtDate(item.createdAt), style: const TextStyle(fontSize: 11, color: AppColor.textHint)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColor.error.withOpacity(0.35)),
                  ),
                  child: Text('Qty ${fmtQty(item.stockDamage)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.error)),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(10)),
            child: IntrinsicHeight(
              child: Row(children: [
                Expanded(child: _PriceTile(icon: Icons.shopping_cart_outlined, label: 'Purchase Loss', value: fmtAmt(item.purchaseLoss), color: const Color(0xFF8B5CF6))),
                VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade200),
                Expanded(child: _PriceTile(icon: Icons.sell_outlined, label: 'Sale Loss', value: fmtAmt(item.saleLoss), color: AppColor.error)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _PriceTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(height: 5),
      Text(value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 9, color: AppColor.textHint)),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No damage record found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text('Try a different esearch or date range',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );
}