import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../common/pagination/branch_report_pagination_controls.dart';
import '../../data/model/customer_logs_model.dart';
import '../provider/customer_logs_provider.dart';

class CustomerLogsScreen extends ConsumerStatefulWidget {
  const CustomerLogsScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<CustomerLogsScreen> createState() =>
      _CustomerLogsScreenState();
}

class _CustomerLogsScreenState extends ConsumerState<CustomerLogsScreen> {
  final _startCtrl = TextEditingController();
  final _endCtrl   = TextEditingController();
  final _dateFmt   = DateFormat('dd MMM yyyy');
  final _amtFmt    = NumberFormat('#,##,###', 'en_IN');

  bool _isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 800;

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final state  = ref.read(customerLogsProvider(widget.branchId));
    final picked = await showDatePicker(
      context:     context,
      initialDate: state.startDate ?? DateTime.now(),
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now().add(const Duration(days: 1)),
      builder:     _dateTheme,
    );
    if (picked == null) return;
    _startCtrl.text = _dateFmt.format(picked);
    final endDate   = state.endDate;
    final newEnd    = (endDate != null && endDate.isBefore(picked))
        ? null
        : endDate;
    if (newEnd == null) _endCtrl.clear();
    await ref
        .read(customerLogsProvider(widget.branchId).notifier)
        .applyDateFilter(picked, newEnd);
  }

  Future<void> _pickEndDate() async {
    final state  = ref.read(customerLogsProvider(widget.branchId));
    final picked = await showDatePicker(
      context:     context,
      initialDate: state.endDate ?? state.startDate ?? DateTime.now(),
      firstDate:   state.startDate ?? DateTime(2020),
      lastDate:    DateTime.now().add(const Duration(days: 1)),
      builder:     _dateTheme,
    );
    if (picked == null) return;
    _endCtrl.text = _dateFmt.format(picked);
    await ref
        .read(customerLogsProvider(widget.branchId).notifier)
        .applyDateFilter(state.startDate, picked);
  }

  Widget _dateTheme(BuildContext ctx, Widget? child) => Theme(
    data: Theme.of(ctx).copyWith(
      colorScheme: const ColorScheme.light(
        primary:   AppColor.primary,
        onPrimary: Colors.white,
        onSurface: Color(0xFF1A1D23),
      ),
    ),
    child: child!,
  );

  void _clearFilter() {
    _startCtrl.clear();
    _endCtrl.clear();
    ref.read(customerLogsProvider(widget.branchId).notifier).clearFilter();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(customerLogsProvider(widget.branchId));
    final notifier = ref.read(customerLogsProvider(widget.branchId).notifier);
    final desktop   = _isDesktop(context);
    final hasFilter = state.startDate != null || state.endDate != null;

    ref.listen<CustomerLogsState>(
      customerLogsProvider(widget.branchId),
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
        amtFmt:     _amtFmt,
        startCtrl:  _startCtrl,
        endCtrl:    _endCtrl,
        hasFilter:  hasFilter,
        onPickStart: _pickStartDate,
        onPickEnd:   _pickEndDate,
        onClear:     _clearFilter,
        onClearStart: () {
          _startCtrl.clear();
          ref
              .read(customerLogsProvider(widget.branchId).notifier)
              .applyDateFilter(null, state.endDate);
        },
        onClearEnd: () {
          _endCtrl.clear();
          ref
              .read(customerLogsProvider(widget.branchId).notifier)
              .applyDateFilter(state.startDate, null);
        },
      )
          : _MobileLayout(
        state:      state,
        notifier:   notifier,
        amtFmt:     _amtFmt,
        startCtrl:  _startCtrl,
        endCtrl:    _endCtrl,
        hasFilter:  hasFilter,
        onPickStart: _pickStartDate,
        onPickEnd:   _pickEndDate,
        onClear:     _clearFilter,
        onClearStart: () {
          _startCtrl.clear();
          ref
              .read(customerLogsProvider(widget.branchId).notifier)
              .applyDateFilter(null, state.endDate);
        },
        onClearEnd: () {
          _endCtrl.clear();
          ref
              .read(customerLogsProvider(widget.branchId).notifier)
              .applyDateFilter(state.startDate, null);
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DESKTOP LAYOUT
// ══════════════════════════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  final CustomerLogsState     state;
  final dynamic               notifier;
  final NumberFormat          amtFmt;
  final TextEditingController startCtrl;
  final TextEditingController endCtrl;
  final bool                  hasFilter;
  final VoidCallback          onPickStart;
  final VoidCallback          onPickEnd;
  final VoidCallback          onClear;
  final VoidCallback          onClearStart;
  final VoidCallback          onClearEnd;

  const _DesktopLayout({
    required this.state,
    required this.notifier,
    required this.amtFmt,
    required this.startCtrl,
    required this.endCtrl,
    required this.hasFilter,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClear,
    required this.onClearStart,
    required this.onClearEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              const Text('Customer Logs',
                  style: TextStyle(
                    fontSize:   22,
                    fontWeight: FontWeight.w700,
                    color:      Color(0xFF1A1D23),
                  )),
              const Spacer(),
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

        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: _DateField(
                  controller: startCtrl,
                  hint:       'Start Date',
                  icon:       Icons.calendar_today_rounded,
                  onTap:      onPickStart,
                  onClear:    startCtrl.text.isNotEmpty
                      ? onClearStart
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('—',
                    style: TextStyle(
                        color:      Colors.grey.shade400,
                        fontWeight: FontWeight.w600)),
              ),
              SizedBox(
                width: 180,
                child: _DateField(
                  controller: endCtrl,
                  hint:       'End Date',
                  icon:       Icons.event_rounded,
                  onTap:      onPickEnd,
                  onClear:    endCtrl.text.isNotEmpty
                      ? onClearEnd
                      : null,
                ),
              ),
              if (hasFilter) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClear,
                  child: Container(
                    width:  36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:        AppColor.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                        Icons.filter_alt_off_rounded,
                        size:  16,
                        color: AppColor.error),
                  ),
                ),
              ],
              const SizedBox(width: 24),
              const SizedBox(
                  height: 48,
                  child: VerticalDivider(
                      width: 1, color: Color(0xFFEEEEEE))),
              const SizedBox(width: 24),

              _DeskStatCard(
                label: 'Total Entries',
                value: '${state.totalCount}',
                icon:  Icons.receipt_long_rounded,
                color: AppColor.primary,
              ),
              const SizedBox(width: 10),
              _DeskStatCard(
                label: 'Total Increase',
                value: 'Rs ${amtFmt.format(state.totalIncrease.toInt())}',
                icon:  Icons.arrow_upward_rounded,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 10),
              _DeskStatCard(
                label: 'Total Decrease',
                value: 'Rs ${amtFmt.format(state.totalDecrease.toInt())}',
                icon:  Icons.arrow_downward_rounded,
                color: const Color(0xFFF97316),
              ),
              const SizedBox(width: 10),
              _DeskStatCard(
                label: 'Net Change',
                value: 'Rs ${amtFmt.format(state.netChange.toInt())}',
                icon:  Icons.difference_rounded,
                color: state.netChange >= 0
                    ? const Color(0xFF10B981)
                    : AppColor.error,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.entries.isEmpty
              ? const _EmptyState()
              : _LogTable(items: state.entries, amtFmt: amtFmt),
        ),
        if (!state.isLoading && state.entries.isNotEmpty)
          BranchReportPaginationControls(
            page:        state.pagination.page,
            hasNextPage: state.pagination.hasNextPage,
            isLoading:   state.pagination.isLoadingPage,
            onNext:      notifier.nextPage,
            onPrevious:  notifier.previousPage,
          ),
      ],
    );
  }
}

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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    fontSize: 11, color: AppColor.textHint)),
          ],
        ),
      ],
    ),
  );
}

class _LogTable extends StatelessWidget {
  final List<CustomerLogEntry> items;
  final NumberFormat           amtFmt;

  const _LogTable({required this.items, required this.amtFmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Row(children: const [
            SizedBox(width: 10),
            _TH(label: '#',             flex: 1),
            _TH(label: 'Customer',      flex: 5),
            _TH(label: 'Old Balance',   flex: 3, right: true),
            _TH(label: 'New Balance',   flex: 3, right: true),
            _TH(label: 'Change',        flex: 3, right: true),
            _TH(label: 'Date & Time',   flex: 4),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            itemCount:        items.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (_, i) => _LogTableRow(
              index:  i + 1,
              item:   items[i],
              amtFmt: amtFmt,
            ),
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

class _LogTableRow extends StatelessWidget {
  final int             index;
  final CustomerLogEntry item;
  final NumberFormat    amtFmt;

  const _LogTableRow({
    required this.index,
    required this.item,
    required this.amtFmt,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy  •  hh:mm a');
    final color   = item.isIncrease
        ? const Color(0xFF10B981)
        : const Color(0xFFF97316);

    return Container(
      color:   Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text('$index',
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textHint)),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width:  32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.isIncrease
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: color,
                    size:  15,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.customerName.isNotEmpty
                        ? item.customerName
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
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Rs ${amtFmt.format(item.oldBalance.toInt())}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12, color: AppColor.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Rs ${amtFmt.format(item.newBalance.toInt())}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF1A1D23),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${item.isIncrease ? '+' : '-'}Rs '
                  '${amtFmt.format(item.changeAmount.abs().toInt())}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w800,
                color:      color,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                dateFmt.format(item.createdAt.toLocal()),
                style: const TextStyle(
                    fontSize: 11, color: AppColor.textHint),
              ),
            ),
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
  final CustomerLogsState     state;
  final dynamic               notifier;
  final NumberFormat          amtFmt;
  final TextEditingController startCtrl;
  final TextEditingController endCtrl;
  final bool                  hasFilter;
  final VoidCallback          onPickStart;
  final VoidCallback          onPickEnd;
  final VoidCallback          onClear;
  final VoidCallback          onClearStart;
  final VoidCallback          onClearEnd;

  const _MobileLayout({
    required this.state,
    required this.notifier,
    required this.amtFmt,
    required this.startCtrl,
    required this.endCtrl,
    required this.hasFilter,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClear,
    required this.onClearStart,
    required this.onClearEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Customer Logs',
            style: TextStyle(
              fontSize:   17,
              fontWeight: FontWeight.w800,
              color:      Color(0xFF1A1D23),
            )),
        actions: [
          IconButton(
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _DateField(
                    controller: startCtrl,
                    hint:       'Start Date',
                    icon:       Icons.calendar_today_rounded,
                    onTap:      onPickStart,
                    onClear:    startCtrl.text.isNotEmpty
                        ? onClearStart
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—',
                      style: TextStyle(
                          color:      Colors.grey.shade400,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: _DateField(
                    controller: endCtrl,
                    hint:       'End Date',
                    icon:       Icons.event_rounded,
                    onTap:      onPickEnd,
                    onClear:    endCtrl.text.isNotEmpty
                        ? onClearEnd
                        : null,
                  ),
                ),
                if (hasFilter) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      width:  34,
                      height: 34,
                      decoration: BoxDecoration(
                        color:        AppColor.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                          Icons.filter_alt_off_rounded,
                          size:  16,
                          color: AppColor.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(height: 1, color: const Color(0xFFE5E7EB)),

          if (!state.isLoading)
            Container(
              color:   Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _MobileSummaryCard(
                        label: 'Entries',
                        value: '${state.totalCount}',
                        icon:  Icons.receipt_long_rounded,
                        color: AppColor.primary,
                      ),
                      const SizedBox(width: 10),
                      _MobileSummaryCard(
                        label: 'Increase',
                        value:
                        'Rs ${amtFmt.format(state.totalIncrease.toInt())}',
                        icon:  Icons.arrow_upward_rounded,
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MobileSummaryCard(
                        label: 'Decrease',
                        value:
                        'Rs ${amtFmt.format(state.totalDecrease.toInt())}',
                        icon:  Icons.arrow_downward_rounded,
                        color: const Color(0xFFF97316),
                      ),
                      const SizedBox(width: 10),
                      _MobileSummaryCard(
                        label: 'Net Change',
                        value:
                        'Rs ${amtFmt.format(state.netChange.toInt())}',
                        icon:  Icons.difference_rounded,
                        color: state.netChange >= 0
                            ? const Color(0xFF10B981)
                            : AppColor.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          Container(height: 6, color: const Color(0xFFF5F6FA)),

          if (!state.isLoading && state.entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(children: [
                Text('${state.totalCount} entries',
                    style: const TextStyle(
                        fontSize: 12, color: AppColor.textHint)),
              ]),
            ),

          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.entries.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: state.entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _LogCard(
                  entry:  state.entries[i],
                  amtFmt: amtFmt,
                ),
              ),
            ),
          ),
          if (!state.isLoading && state.entries.isNotEmpty)
            BranchReportPaginationControls(
              page:        state.pagination.page,
              hasNextPage: state.pagination.hasNextPage,
              isLoading:   state.pagination.isLoadingPage,
              onNext:      notifier.nextPage,
              onPrevious:  notifier.previousPage,
            ),
        ],
      ),
    );
  }
}

class _MobileSummaryCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _MobileSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        fontSize: 11, color: AppColor.textHint)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _LogCard extends StatelessWidget {
  final CustomerLogEntry entry;
  final NumberFormat     amtFmt;

  const _LogCard({required this.entry, required this.amtFmt});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy  •  hh:mm a');
    final color   = entry.isIncrease
        ? const Color(0xFF10B981)
        : const Color(0xFFF97316);

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width:  46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    entry.isIncrease
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: color,
                    size:  20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.customerName.isNotEmpty
                            ? entry.customerName
                            : '—',
                        style: const TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w700,
                          color:      Color(0xFF1A1D23),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.access_time_rounded,
                            size: 10, color: AppColor.textHint),
                        const SizedBox(width: 3),
                        Text(
                          dateFmt.format(entry.createdAt.toLocal()),
                          style: const TextStyle(
                              fontSize: 10, color: AppColor.textHint),
                        ),
                      ]),
                    ],
                  ),
                ),
                Text(
                  '${entry.isIncrease ? '+' : '-'}Rs '
                      '${amtFmt.format(entry.changeAmount.abs().toInt())}',
                  style: TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.w800,
                    color:      color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _AmountBlock(
                      label: 'Old Balance',
                      value:
                      'Rs ${amtFmt.format(entry.oldBalance.toInt())}',
                    ),
                  ),
                  Container(width: 1, height: 28, color: const Color(0xFFE5E7EB)),
                  Expanded(
                    child: _AmountBlock(
                      label: 'New Balance',
                      value:
                      'Rs ${amtFmt.format(entry.newBalance.toInt())}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  final String label;
  final String value;

  const _AmountBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.w700,
          color:      Color(0xFF1A1D23),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          color:    AppColor.textHint,
        ),
      ),
    ],
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared Widgets
// ══════════════════════════════════════════════════════════════════════════════
class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String                hint;
  final IconData              icon;
  final VoidCallback          onTap;
  final VoidCallback?         onClear;

  const _DateField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AbsorbPointer(
      child: TextField(
        controller:   controller,
        readOnly:     true,
        cursorHeight: 14,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppColor.textHint),
          prefixIcon: Icon(icon, size: 16, color: AppColor.primary),
          suffixIcon: onClear != null
              ? GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColor.textHint),
          )
              : null,
          filled:    true,
          fillColor: AppColor.grey100,
          isDense:   true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:   BorderSide.none,
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
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No customer logs found',
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      Colors.grey.shade500,
            )),
        const SizedBox(height: 6),
        Text('Try changing the date filter',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );
}
