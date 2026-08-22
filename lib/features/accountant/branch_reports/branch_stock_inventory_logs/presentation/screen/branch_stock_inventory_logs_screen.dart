import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../common/pagination/branch_report_pagination_controls.dart';
import '../../data/model/branch_stock_inventory_logs_model.dart';
import '../provider/branch_stock_inventory_logs_provider.dart';

class BranchStockInventoryLogsScreen extends ConsumerStatefulWidget {
  const BranchStockInventoryLogsScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<BranchStockInventoryLogsScreen> createState() =>
      _BranchStockInventoryLogsScreenState();
}

class _BranchStockInventoryLogsScreenState
    extends ConsumerState<BranchStockInventoryLogsScreen> {
  final _startCtrl = TextEditingController();
  final _endCtrl   = TextEditingController();
  final _dateFmt   = DateFormat('dd MMM yyyy');

  bool _isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 800;

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final state  = ref.read(
        branchStockInventoryLogsProvider(widget.branchId));
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
        .read(branchStockInventoryLogsProvider(widget.branchId).notifier)
        .applyDateFilter(picked, newEnd);
  }

  Future<void> _pickEndDate() async {
    final state  = ref.read(
        branchStockInventoryLogsProvider(widget.branchId));
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
        .read(branchStockInventoryLogsProvider(widget.branchId).notifier)
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
    ref
        .read(branchStockInventoryLogsProvider(widget.branchId).notifier)
        .clearFilter();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
        branchStockInventoryLogsProvider(widget.branchId));
    final notifier = ref.read(
        branchStockInventoryLogsProvider(widget.branchId).notifier);
    final desktop   = _isDesktop(context);
    final hasFilter = state.startDate != null || state.endDate != null;

    ref.listen<BranchStockInventoryLogsState>(
      branchStockInventoryLogsProvider(widget.branchId),
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
          ? _Layout(
        desktop:    true,
        state:      state,
        notifier:   notifier,
        startCtrl:  _startCtrl,
        endCtrl:    _endCtrl,
        hasFilter:  hasFilter,
        onPickStart: _pickStartDate,
        onPickEnd:   _pickEndDate,
        onClear:     _clearFilter,
        onClearStart: () {
          _startCtrl.clear();
          ref
              .read(branchStockInventoryLogsProvider(
              widget.branchId).notifier)
              .applyDateFilter(null, state.endDate);
        },
        onClearEnd: () {
          _endCtrl.clear();
          ref
              .read(branchStockInventoryLogsProvider(
              widget.branchId).notifier)
              .applyDateFilter(state.startDate, null);
        },
      )
          : _Layout(
        desktop:    false,
        state:      state,
        notifier:   notifier,
        startCtrl:  _startCtrl,
        endCtrl:    _endCtrl,
        hasFilter:  hasFilter,
        onPickStart: _pickStartDate,
        onPickEnd:   _pickEndDate,
        onClear:     _clearFilter,
        onClearStart: () {
          _startCtrl.clear();
          ref
              .read(branchStockInventoryLogsProvider(
              widget.branchId).notifier)
              .applyDateFilter(null, state.endDate);
        },
        onClearEnd: () {
          _endCtrl.clear();
          ref
              .read(branchStockInventoryLogsProvider(
              widget.branchId).notifier)
              .applyDateFilter(state.startDate, null);
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared layout — a header bar + date filter + count card + expandable log
// list. The number of changed fields per entry varies, so a fixed table
// doesn't fit this data well; both desktop and mobile use the same
// expandable-card list, just with different chrome/padding.
// ══════════════════════════════════════════════════════════════════════════════
class _Layout extends StatelessWidget {
  final bool                   desktop;
  final BranchStockInventoryLogsState state;
  final dynamic                notifier;
  final TextEditingController  startCtrl;
  final TextEditingController  endCtrl;
  final bool                   hasFilter;
  final VoidCallback           onPickStart;
  final VoidCallback           onPickEnd;
  final VoidCallback           onClear;
  final VoidCallback           onClearStart;
  final VoidCallback           onClearEnd;

  const _Layout({
    required this.desktop,
    required this.state,
    required this.notifier,
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
    final hPad = desktop ? 28.0 : 16.0;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color:   Colors.white,
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 16),
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
              const Text('Stock Inventory Logs',
                  style: TextStyle(
                    fontSize:   20,
                    fontWeight: FontWeight.w700,
                    color:      Color(0xFF1A1D23),
                  )),
              const Spacer(),
              SizedBox(
                width: 44,
                height: 44,
                child: OutlinedButton(
                  onPressed: notifier.load,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: const BorderSide(color: AppColor.primary),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        Container(
          color:   Colors.white,
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 14),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: [
              SizedBox(
                width: desktop ? 180 : 150,
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
              SizedBox(
                width: desktop ? 180 : 150,
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
              if (hasFilter)
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color:        AppColor.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColor.primary.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_rounded,
                        size: 14, color: AppColor.primary),
                    const SizedBox(width: 8),
                    Text('${state.totalCount} changes',
                        style: const TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w700,
                          color:      AppColor.primary,
                        )),
                  ],
                ),
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
              : ListView.separated(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
            itemCount:        state.entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _LogCard(entry: state.entries[i]),
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
    );

    if (desktop) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(child: body),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Expandable Log Card
// ══════════════════════════════════════════════════════════════════════════════
class _LogCard extends StatefulWidget {
  final BranchStockInventoryLogEntry entry;
  const _LogCard({required this.entry});

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry    = widget.entry;
    final dateFmt  = DateFormat('dd MMM yyyy  •  hh:mm a');
    final changes  = entry.changes;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColor.primary.withOpacity(0.25)
              : const Color(0xFFEEEEEE),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: changes.isEmpty
                ? null
                : () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width:  44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        size: 20, color: AppColor.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.productName.isNotEmpty
                              ? entry.productName
                              : '—',
                          style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                            color:      Color(0xFF1A1D23),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(entry.changeTypeLabel,
                                style: const TextStyle(
                                  fontSize:   10,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColor.primary,
                                )),
                          ),
                        ]),
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
                  if (changes.isNotEmpty) ...[
                    Text('${changes.length} field'
                        '${changes.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 10, color: AppColor.textHint)),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns:    _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down,
                          size: 16, color: AppColor.grey400),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_expanded && changes.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              height: 1,
              color:  const Color(0xFFE5E7EB),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                children: changes
                    .map((c) => _ChangeRow(change: c))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final StockLogFieldChange change;
  const _ChangeRow({required this.change});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(change.label,
              style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      AppColor.textSecondary,
              )),
        ),
        Expanded(
          child: Text(change.oldValue,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColor.textHint,
                  decoration: TextDecoration.lineThrough)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded,
              size: 13, color: AppColor.textHint),
        ),
        Expanded(
          child: Text(change.newValue,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF1A1D23),
              )),
        ),
      ],
    ),
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
        Icon(Icons.inventory_2_outlined,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No stock changes found',
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
