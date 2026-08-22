import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../../accountant_customer/data/model/accountant_customer_model.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../../common/pagination/branch_report_pagination_controls.dart';
import '../../data/model/accountant_customer_ledger_model.dart';
import '../../data/service/customer_ledger_pdf_service.dart';
import '../provider/accountant_customer_ledger_provider.dart';

// Filter-chip range label — date + time, dono
final _rangeFmt = DateFormat('dd MMM, hh:mm a');

class AccountantCustomerLedgerScreen extends ConsumerStatefulWidget {
  const AccountantCustomerLedgerScreen(
      {super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<AccountantCustomerLedgerScreen> createState() =>
      _AccountantCustomerLedgerScreenState();
}

class _AccountantCustomerLedgerScreenState
    extends ConsumerState<AccountantCustomerLedgerScreen> {
  final _searchCtrl = TextEditingController();
  final _amtFmt     = NumberFormat('#,##,###', 'en_IN');
  final _dateFmt    = DateFormat('dd MMM yyyy');
  final _timeFmt    = DateFormat('hh:mm a');

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';
  String get _bid      => widget.branchId;

  bool _isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 800;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext ctx, bool isStart) async {
    final notifier = ref.read(customerLedgerProvider(_bid).notifier);
    final state    = ref.read(customerLedgerProvider(_bid));
    final current  = isStart ? state.startDate : state.endDate;
    final picked   = await showDatePicker(
      context:     ctx,
      initialDate: current ?? DateTime.now(),
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
          ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    // Existing time-of-day preserve karein; pehli dafa set ho raha ho to
    // start ke liye din ki shuruaat aur end ke liye din ka aakhri lamha.
    final combined = current != null
        ? DateTime(picked.year, picked.month, picked.day,
        current.hour, current.minute, current.second)
        : (isStart
        ? DateTime(picked.year, picked.month, picked.day)
        : DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
    if (isStart) {
      notifier.setStartDate(combined);
    } else {
      notifier.setEndDate(combined);
    }
  }

  Future<void> _pickTime(BuildContext ctx, bool isStart) async {
    final notifier = ref.read(customerLedgerProvider(_bid).notifier);
    final state    = ref.read(customerLedgerProvider(_bid));
    final current  = isStart ? state.startDate : state.endDate;
    final basis    = current ?? DateTime.now();
    final picked   = await showTimePicker(
      context:     ctx,
      initialTime: TimeOfDay.fromDateTime(basis),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
          ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final combined = DateTime(
      basis.year, basis.month, basis.day,
      picked.hour, picked.minute,
    );
    if (isStart) {
      notifier.setStartDate(combined);
    } else {
      notifier.setEndDate(combined);
    }
  }

  // ── Export PDF — hamesha current filtered list use karta hai ─────────────
  Future<void> _exportPdf(BuildContext context, CustomerLedgerState state) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Generating PDF...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));

      await CustomerLedgerPdfService.exportAndShare(
        items: state.filtered,
        customerName: state.selectedCustomer?.name,
        startDate: state.startDate,
        endDate: state.endDate,
        searchQuery: state.searchQuery,
        totalCollected: state.totalCollected,
        totalPaid: state.totalPaid,
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

  // ── Filter bottom sheet (mobile) ────────────────────────────────────────
  void _showFilterSheet({
    required CustomerLedgerState state,
    required dynamic notifier,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColor.grey200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        notifier.clearDates();
                        _searchCtrl.clear();
                        notifier.search('');
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Customer dropdown
                AppSearchableDropdown<AccountantCustomerReportModel>(
                  hint:  'Customer select karein',
                  items: state.customers
                      .map((c) => DropdownItem(
                    value: c,
                    label: '${c.name}  •  ${c.code}',
                    icon:  Icons.person_outline_rounded,
                  ))
                      .toList(),
                  value:     state.selectedCustomer,
                  onChanged: (c) {
                    if (c != null) notifier.selectCustomer(c);
                  },
                ),
                const SizedBox(height: 12),

                // Search
                TextField(
                  controller:   _searchCtrl,
                  onChanged:    notifier.search,
                  style: const TextStyle(fontSize: 14),
                  cursorHeight: 16,
                  decoration: InputDecoration(
                    hintText: 'Notes ya naam se search karein...',
                    hintStyle: const TextStyle(
                        fontSize: 13,
                        color:    AppColor.textHint),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: AppColor.primary),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 18, color: AppColor.textHint),
                      onPressed: () {
                        _searchCtrl.clear();
                        notifier.search('');
                        setSheetState(() {});
                      },
                    )
                        : null,
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:   BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColor.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColor.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Date range
                Row(children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Start Date',
                      date:  state.startDate,
                      fmt:   _dateFmt,
                      onTap: () async {
                        await _pickDate(ctx, true);
                        setSheetState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateButton(
                      label: 'End Date',
                      date:  state.endDate,
                      fmt:   _dateFmt,
                      onTap: () async {
                        await _pickDate(ctx, false);
                        setSheetState(() {});
                      },
                    ),
                  ),
                  if (state.startDate != null ||
                      state.endDate != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        notifier.clearDates();
                        setSheetState(() {});
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColor.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColor.error
                                  .withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColor.error),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 8),

                // Time range
                Row(children: [
                  Expanded(
                    child: _TimeButton(
                      label: 'Start Time',
                      date:  state.startDate,
                      fmt:   _timeFmt,
                      onTap: () async {
                        await _pickTime(ctx, true);
                        setSheetState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeButton(
                      label: 'End Time',
                      date:  state.endDate,
                      fmt:   _timeFmt,
                      onTap: () async {
                        await _pickTime(ctx, false);
                        setSheetState(() {});
                      },
                    ),
                  ),
                ]),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(customerLedgerProvider(_bid));
    final notifier = ref.read(customerLedgerProvider(_bid).notifier);
    final desktop  = _isDesktop(context);

    ref.listen<CustomerLedgerState>(
      customerLedgerProvider(_bid),
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

    final activeFilterCount =
        (state.selectedCustomer != null ? 1 : 0) +
            (state.startDate != null || state.endDate != null ? 1 : 0) +
            (state.searchQuery.isNotEmpty ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: desktop
          ? _DesktopLayout(
        state:      state,
        notifier:   notifier,
        fmt:        _fmt,
        dateFmt:    _dateFmt,
        timeFmt:    _timeFmt,
        searchCtrl: _searchCtrl,
        onPickStart:     () => _pickDate(context, true),
        onPickEnd:       () => _pickDate(context, false),
        onPickStartTime: () => _pickTime(context, true),
        onPickEndTime:   () => _pickTime(context, false),
        onExportPdf: () => _exportPdf(context, state),
      )
          : _MobileLayout(
        state:             state,
        notifier:          notifier,
        fmt:               _fmt,
        dateFmt:           _dateFmt,
        activeFilterCount: activeFilterCount,
        onOpenFilters: () => _showFilterSheet(
          state:    state,
          notifier: notifier,
        ),
        onExportPdf: () => _exportPdf(context, state),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DESKTOP LAYOUT
// ══════════════════════════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  final CustomerLedgerState     state;
  final dynamic                 notifier;
  final String Function(double) fmt;
  final DateFormat              dateFmt;
  final DateFormat              timeFmt;
  final TextEditingController   searchCtrl;
  final VoidCallback            onPickStart;
  final VoidCallback            onPickEnd;
  final VoidCallback            onPickStartTime;
  final VoidCallback            onPickEndTime;
  final VoidCallback            onExportPdf;

  const _DesktopLayout({
    required this.state,
    required this.notifier,
    required this.fmt,
    required this.dateFmt,
    required this.timeFmt,
    required this.searchCtrl,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onPickStartTime,
    required this.onPickEndTime,
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
                  Text('Customer Ledger',
                      style: TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.w700,
                        color:      Color(0xFF1A1D23),
                      )),
                  SizedBox(height: 2),
                  Text('Customer ki tamam payments ki detail',
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
                  onPressed: notifier.refresh,
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

        // ── Filters row ──────────────────────────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Wrap(
            spacing:    12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [

              // Customer dropdown
              SizedBox(
                width: 280,
                child: AppSearchableDropdown
                <AccountantCustomerReportModel>(
                  hint:  'Customer select karein',
                  items: state.customers
                      .map((c) => DropdownItem(
                    value: c,
                    label: '${c.name}  •  ${c.code}',
                    icon:  Icons.person_outline_rounded,
                  ))
                      .toList(),
                  value:     state.selectedCustomer,
                  onChanged: (c) {
                    if (c != null) notifier.selectCustomer(c);
                  },
                ),
              ),

              // Start Date
              SizedBox(
                width: 170,
                child: _DateButton(
                  label: 'Start Date',
                  date:  state.startDate,
                  fmt:   dateFmt,
                  onTap: onPickStart,
                ),
              ),

              // End Date
              SizedBox(
                width: 170,
                child: _DateButton(
                  label: 'End Date',
                  date:  state.endDate,
                  fmt:   dateFmt,
                  onTap: onPickEnd,
                ),
              ),

              // Start Time
              SizedBox(
                width: 130,
                child: _TimeButton(
                  label: 'Start Time',
                  date:  state.startDate,
                  fmt:   timeFmt,
                  onTap: onPickStartTime,
                ),
              ),

              // End Time
              SizedBox(
                width: 130,
                child: _TimeButton(
                  label: 'End Time',
                  date:  state.endDate,
                  fmt:   timeFmt,
                  onTap: onPickEndTime,
                ),
              ),

              // Clear dates
              if (state.startDate != null ||
                  state.endDate != null)
                InkWell(
                  onTap:        notifier.clearDates,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColor.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                          AppColor.error.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColor.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Search
          SizedBox(
            height: 42,
            child: TextField(
              controller: searchCtrl,
              onChanged:  notifier.search,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Notes ya naam se search karein...',
                hintStyle: const TextStyle(
                    fontSize: 13,
                    color:    AppColor.textHint),
                prefixIcon: const Icon(
                    Icons.search_rounded,
                    size:  18,
                    color: AppColor.primary),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(
                      Icons.clear_rounded,
                      size:  16,
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
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // ── Summary cards row ────────────────────────────────────────────────
        if (state.filtered.isNotEmpty)
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(28, 10, 28, 14),
            child: Row(
              children: [
                _DeskStatCard(
                  label: 'Total Collected',
                  value: fmt(state.totalCollected),
                  icon:  Icons.account_balance_wallet_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 10),
                _DeskStatCard(
                  label: 'Filtered Total',
                  value: fmt(state.totalPaid),
                  icon:  Icons.payments_outlined,
                  color: AppColor.success,
                ),
                const SizedBox(width: 10),
                _DeskStatCard(
                  label: 'Entries',
                  value: '${state.filtered.length}',
                  icon:  Icons.receipt_long_outlined,
                  color: AppColor.warning,
                ),
                if (state.startDate != null ||
                    state.endDate != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color:        AppColor.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColor.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt_rounded,
                            size: 14, color: AppColor.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${state.startDate != null ? _rangeFmt.format(state.startDate!) : '?'}'
                              '  –  '
                              '${state.endDate != null ? _rangeFmt.format(state.endDate!) : '?'}',
                          style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

        if (state.filtered.isNotEmpty)
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // ── Table ────────────────────────────────────────────────────────────
        Expanded(
          child: state.isLoadingLedger
              ? const Center(child: CircularProgressIndicator())
              : state.filtered.isEmpty
              ? _EmptyState(
            message: state.selectedCustomer == null
                ? 'Customer select karein'
                : 'Koi entry nahi mili',
          )
              : _LedgerTable(
            items:      state.pagedEntries,
            totalCount: state.filtered.length,
            pageOffset: state.pagination.page * BranchReportPagination.pageSize,
            fmt:    fmt,
            dateFmt: DateFormat('dd MMM yyyy  hh:mm a'),
          ),
        ),
        if (!state.isLoadingLedger && state.filtered.isNotEmpty)
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

// ── Desktop Stat Card ──────────────────────────────────────────────────────
class _DeskStatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _DeskStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: color.withOpacity(0.15)),
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
  );
}

// ── Ledger Table ───────────────────────────────────────────────────────────
class _LedgerTable extends StatelessWidget {
  final List<CustomerLedgerModel> items;
  final int                       totalCount;
  final int                       pageOffset;
  final String Function(double)   fmt;
  final DateFormat                dateFmt;

  const _LedgerTable({
    required this.items,
    required this.totalCount,
    required this.pageOffset,
    required this.fmt,
    required this.dateFmt,
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
            _TH(label: 'Customer',   flex: 4),
            _TH(label: 'Previous',   flex: 3, right: true),
            _TH(label: 'Paid',       flex: 3, right: true),
            _TH(label: 'Remaining',  flex: 3, right: true),
            _TH(label: 'Notes',      flex: 4),
            _TH(label: 'Date & Time',flex: 4),
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
            itemBuilder: (ctx, i) {
              final e         = items[i];
              final rowNumber = totalCount - (pageOffset + i);
              final remaining = e.newAmount;
              final remColor  = remaining > 0
                  ? AppColor.error
                  : AppColor.success;

              return Container(
                color:   Colors.white,
                padding: const EdgeInsets.symmetric(
                    vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // #
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColor.primary
                                .withOpacity(0.08),
                            borderRadius:
                            BorderRadius.circular(5),
                          ),
                          child: Text(
                            '$rowNumber',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize:   11,
                              fontWeight: FontWeight.w700,
                              color:      AppColor.primary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Customer
                    Expanded(
                      flex: 4,
                      child: Text(
                        e.customerName.isNotEmpty
                            ? e.customerName
                            : '—',
                        style: const TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      Color(0xFF1A1D23),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Previous
                    Expanded(
                      flex: 3,
                      child: Text(
                        fmt(e.previousAmount),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color:      AppColor.warning,
                        ),
                      ),
                    ),

                    // Paid
                    Expanded(
                      flex: 3,
                      child: Text(
                        fmt(e.payAmount),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w700,
                          color:      AppColor.success,
                        ),
                      ),
                    ),

                    // Remaining
                    Expanded(
                      flex: 3,
                      child: Text(
                        fmt(remaining),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w700,
                          color:      remColor,
                        ),
                      ),
                    ),

                    // Notes
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding:
                        const EdgeInsets.only(left: 12),
                        child: Text(
                          (e.notes != null &&
                              e.notes!.isNotEmpty)
                              ? e.notes!
                              : '—',
                          style: const TextStyle(
                              fontSize: 11,
                              color:    AppColor.textHint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Date & Time
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding:
                        const EdgeInsets.only(left: 12),
                        child: Row(children: [
                          const Icon(
                              Icons.access_time_rounded,
                              size:  11,
                              color: AppColor.textHint),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dateFmt.format(
                                  e.createdAt.toLocal()),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color:    AppColor.textHint),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

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

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE LAYOUT — filters ab AppBar ke filter icon se bottom sheet mein khultay hain
// ══════════════════════════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  final CustomerLedgerState     state;
  final dynamic                 notifier;
  final String Function(double) fmt;
  final DateFormat              dateFmt;
  final VoidCallback            onOpenFilters;
  final int                     activeFilterCount;
  final VoidCallback            onExportPdf;

  const _MobileLayout({
    required this.state,
    required this.notifier,
    required this.fmt,
    required this.dateFmt,
    required this.onOpenFilters,
    required this.activeFilterCount,
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
        title: const Text(
          'Customer Ledger',
          style: TextStyle(
              fontSize:   17,
              fontWeight: FontWeight.w700,
              color:      Color(0xFF1A1D23)),
        ),
        actions: [
          IconButton(
            onPressed: onExportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined,
                color: AppColor.primary),
            tooltip: 'Export PDF',
          ),
          // ── Filter icon with active-count badge ──────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onOpenFilters,
                icon: const Icon(Icons.filter_list_rounded,
                    color: AppColor.textSecondary),
                tooltip: 'Filters',
              ),
              if (activeFilterCount > 0)
                Positioned(
                  right: 6,
                  top:   6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColor.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$activeFilterCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize:   9,
                        color:      Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: notifier.refresh,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
            tooltip: 'Refresh',
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

          // ── Summary Cards ────────────────────────────────────────────
          if (state.filtered.isNotEmpty)
            Container(
              color:   Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(children: [
                _SummaryCard(
                  label: 'Total Collected',
                  value: fmt(state.totalCollected),
                  icon:  Icons.account_balance_wallet_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 8),
                _SummaryCard(
                  label: 'Filtered Total',
                  value: fmt(state.totalPaid),
                  icon:  Icons.payments_outlined,
                  color: AppColor.success,
                ),
                const SizedBox(width: 8),
                _SummaryCard(
                  label: 'Entries',
                  value: '${state.filtered.length}',
                  icon:  Icons.receipt_long_outlined,
                  color: AppColor.warning,
                ),
              ]),
            ),

          Container(height: 1, color: const Color(0xFFE5E7EB)),

          // Result count + active filter chip
          if (!state.isLoadingLedger &&
              state.filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(children: [
                Text('${state.filtered.length} entry mili',
                    style: const TextStyle(
                        fontSize: 12,
                        color:    AppColor.textHint)),
                if (state.startDate != null ||
                    state.endDate != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:        AppColor.primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt_rounded,
                            size:  12,
                            color: AppColor.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${state.startDate != null ? _rangeFmt.format(state.startDate!) : '?'}'
                              ' – '
                              '${state.endDate != null ? _rangeFmt.format(state.endDate!) : '?'}',
                          style: const TextStyle(
                            fontSize:   11,
                            color:      AppColor.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
            )
          else
            const SizedBox(height: 8),

          // ── Ledger List ──────────────────────────────────────────────
          Expanded(
            child: state.isLoadingLedger
                ? const Center(child: CircularProgressIndicator())
                : state.filtered.isEmpty
                ? _EmptyState(
              message: state.selectedCustomer == null
                  ? 'Customer select karein'
                  : 'Koi entry nahi mili',
            )
                : RefreshIndicator(
              onRefresh: notifier.refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    16, 4, 16, 24),
                itemCount:        state.pagedEntries.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (_, i) => _LedgerCard(
                  entry:  state.pagedEntries[i],
                  fmtAmt: fmt,
                  index:  state.filtered.length -
                      (state.pagination.page * BranchReportPagination.pageSize + i),
                ),
              ),
            ),
          ),
          if (!state.isLoadingLedger && state.filtered.isNotEmpty)
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

// ══════════════════════════════════════════════════════════════════════════════
// Ledger Card (Mobile)
// ══════════════════════════════════════════════════════════════════════════════
class _LedgerCard extends StatelessWidget {
  final CustomerLedgerModel     entry;
  final String Function(double) fmtAmt;
  final int                     index;

  const _LedgerCard({
    required this.entry,
    required this.fmtAmt,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt   = DateFormat('dd MMM yyyy  hh:mm a');
    final remaining = entry.newAmount;
    final remColor  = remaining > 0
        ? AppColor.error
        : AppColor.success;

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:        AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('#$index',
                      style: const TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.primary,
                      )),
                ),
                const SizedBox(width: 10),

                // Customer name + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.customerName.isNotEmpty
                            ? entry.customerName
                            : '—',
                        style: const TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w700,
                          color:      Color(0xFF1A1D23),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.access_time_rounded,
                            size:  10,
                            color: AppColor.textHint),
                        const SizedBox(width: 3),
                        Text(
                          dateFmt.format(
                              entry.createdAt.toLocal()),
                          style: const TextStyle(
                              fontSize: 10,
                              color:    AppColor.textHint),
                        ),
                      ]),
                    ],
                  ),
                ),

                // Paid badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color:        AppColor.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        color: AppColor.success.withOpacity(0.3)),
                  ),
                  child: Text(
                    fmtAmt(entry.payAmount),
                    style: const TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w800,
                      color:      AppColor.success,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Amounts grid ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color:        const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IntrinsicHeight(
                child: Row(children: [
                  Expanded(
                    child: _AmountTile(
                      label: 'Previous',
                      value: fmtAmt(entry.previousAmount),
                      color: AppColor.warning,
                    ),
                  ),
                  VerticalDivider(
                      width: 1, thickness: 1,
                      color: Colors.grey.shade200),
                  Expanded(
                    child: _AmountTile(
                      label: 'Paid',
                      value: fmtAmt(entry.payAmount),
                      color: AppColor.success,
                    ),
                  ),
                  VerticalDivider(
                      width: 1, thickness: 1,
                      color: Colors.grey.shade200),
                  Expanded(
                    child: _AmountTile(
                      label: 'Remaining',
                      value: fmtAmt(remaining),
                      color: remColor,
                    ),
                  ),
                ]),
              ),
            ),

            // ── Notes ─────────────────────────────────────────────────
            if (entry.notes != null &&
                entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.notes_rounded,
                    size: 13, color: AppColor.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    entry.notes!,
                    style: const TextStyle(
                        fontSize: 12,
                        color:    AppColor.textSecondary),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared Widgets
// ══════════════════════════════════════════════════════════════════════════════
class _DateButton extends StatelessWidget {
  final String       label;
  final DateTime?    date;
  final DateFormat   fmt;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSet = date != null;
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        isSet
              ? AppColor.primary.withOpacity(0.07)
              : AppColor.grey100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSet ? AppColor.primary : AppColor.grey200,
            width: isSet ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded,
              size:  16,
              color: isSet
                  ? AppColor.primary
                  : AppColor.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:       MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: isSet
                            ? AppColor.primary
                            : AppColor.textHint)),
                Text(
                  isSet ? fmt.format(date!) : 'Select',
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color: isSet
                        ? AppColor.primary
                        : AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String       label;
  final DateTime?    date;
  final DateFormat   fmt;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.date,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSet = date != null;
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        isSet
              ? AppColor.primary.withOpacity(0.07)
              : AppColor.grey100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSet ? AppColor.primary : AppColor.grey200,
            width: isSet ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(Icons.access_time_rounded,
              size:  16,
              color: isSet
                  ? AppColor.primary
                  : AppColor.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:       MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: isSet
                            ? AppColor.primary
                            : AppColor.textHint)),
                Text(
                  isSet ? fmt.format(date!) : 'Select',
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color: isSet
                        ? AppColor.primary
                        : AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label, value;
  final Color  color;

  const _AmountTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value,
        style: TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.w700,
          color:      color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis),
    const SizedBox(height: 3),
    Text(label,
        style: const TextStyle(
            fontSize: 10,
            color:    AppColor.textHint)),
  ]);
}

class _SummaryCard extends StatelessWidget {
  final String   label, value;
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
          Text(value,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w800,
                color:      color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color:    AppColor.textHint)),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.receipt_long_outlined,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(message,
            style: TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            )),
      ],
    ),
  );
}