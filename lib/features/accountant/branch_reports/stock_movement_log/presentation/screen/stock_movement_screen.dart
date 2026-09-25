import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/app_icon.dart';
import '../../../common/export/report_excel_export.dart';
import '../../../common/export/report_export_button.dart';
import '../../../common/filter/report_filter_dialog.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../../common/pagination/branch_report_pagination_controls.dart';
import '../../data/model/stock_movement_model.dart';
import '../../data/service/stock_movement_excel_service.dart';
import '../provider/stock_movement_provider.dart';

/// Below this width the log is shown as cards instead of a table.
const double _kWideBreakpoint = 900;

class StockMovementScreen extends ConsumerStatefulWidget {
  const StockMovementScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<StockMovementScreen> createState() =>
      _StockMovementScreenState();
}

class _StockMovementScreenState extends ConsumerState<StockMovementScreen> {
  final _dateFmt = DateFormat('dd MMM yyyy');

  Future<void> _pickDate({required bool isFrom}) async {
    final provider = stockMovementProvider(widget.branchId);
    final state    = ref.read(provider);
    final notifier = ref.read(provider.notifier);
    final picked = await showDatePicker(
      context:     context,
      initialDate: isFrom ? state.fromDate : state.toDate,
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   AppColor.primary,
            onPrimary: Colors.white,
            onSurface: Color(0xFF1A1D23),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    isFrom ? notifier.setFromDate(picked) : notifier.setToDate(picked);
  }

  // ── Export (Excel / PDF / CSV) — the full filtered log, not one page ────
  Future<List<ExcelSheetData>> _exportSheets() async {
    final state = ref.read(stockMovementProvider(widget.branchId));
    final rows  = state.filteredRows;
    if (rows.isEmpty) return const [];

    return StockMovementExcelService.exportSheets(
      data: StockMovementReportData(
          rows: rows, branchName: state.data.branchName),
      fromDate: state.fromDate,
      toDate:   state.toDate,
      type:     state.selectedType,
    );
  }

  void _openFilters() {
    final provider = stockMovementProvider(widget.branchId);
    showReportFilterDialog(
      context: context,
      onReset: () {
        final n = ref.read(provider.notifier);
        n.setToday();
        n.setType(null);
      },
      content: Consumer(builder: (ctx, ref, _) {
        final state    = ref.watch(provider);
        final notifier = ref.read(provider.notifier);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing:    8,
              runSpacing: 8,
              children: [
                _DateButton(
                  label: 'From',
                  value: _dateFmt.format(state.fromDate),
                  onTap: () => _pickDate(isFrom: true),
                ),
                _DateButton(
                  label: 'To',
                  value: _dateFmt.format(state.toDate),
                  onTap: () => _pickDate(isFrom: false),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing:    8,
              runSpacing: 6,
              children: [
                _TypeChip(
                  label:    'All',
                  selected: state.selectedType == null,
                  onTap:    () => notifier.setType(null),
                ),
                for (final t in StockMovementType.values)
                  _TypeChip(
                    label:    t.label,
                    selected: state.selectedType == t,
                    color:    _typeColor(t),
                    onTap:    () => notifier.setType(t),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = stockMovementProvider(widget.branchId);
    final state    = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    ref.listen<StockMovementState>(provider, (_, next) {
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
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Stock Movement Log',
          style: TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.w700,
            color:      Color(0xFF1A1D23),
          ),
        ),
        actions: [
          ReportFilterButton(
            onPressed:   _openFilters,
            activeCount: state.selectedType != null ? 1 : 0,
          ),
          ReportExportButton(
            fileNamePrefix: 'stock_movement_log',
            loadSheets: _exportSheets,
          ),
          IconButton(
            onPressed: notifier.load,
            icon:    const AppIcon('ic_refresh', size: 22, color: AppColor.textSecondary),
            tooltip: 'Refresh',
          ),
          TextButton(onPressed: notifier.setToday, child: const Text('Today')),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= _kWideBreakpoint;
        final hPad = wide ? 28.0 : 16.0;
        final rows = state.pageRows;

        return Column(
          children: [
            Container(
              color:   Colors.white,
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing:    8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatPill(
                        label: 'Events',
                        value: '${state.filteredRows.length}',
                        color: AppColor.primary,
                      ),
                      _StatPill(
                        label: 'Stock in',
                        value: '+${_fmtQty(_sum(state.filteredRows, positive: true))}',
                        color: AppColor.success,
                      ),
                      _StatPill(
                        label: 'Stock out',
                        value: '-${_fmtQty(_sum(state.filteredRows, positive: false))}',
                        color: AppColor.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : rows.isEmpty
                      ? const _EmptyState()
                      : wide
                          ? _Table(rows: rows, hPad: hPad)
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _MovementCard(row: rows[i]),
                            ),
            ),
            if (!state.isLoading && rows.isNotEmpty)
              BranchReportPaginationControls(
                page:        state.page,
                hasNextPage: state.hasNextPage,
                onNext:      notifier.nextPage,
                onPrevious:  notifier.previousPage,
                totalCount:  state.filteredRows.length,
                totalPages:  (state.filteredRows.length /
                        BranchReportPagination.pageSize).ceil(),
              ),
          ],
        );
      }),
    );
  }

  static double _sum(List<StockMovementRow> rows, {required bool positive}) {
    var s = 0.0;
    for (final r in rows) {
      final q = r.entry.qtyChange;
      if (positive && q > 0) s += q;
      if (!positive && q < 0) s -= q;
    }
    return s;
  }
}

// ── Formatting / colors ────────────────────────────────────────────────────

final _qtyFmt      = NumberFormat('#,##0.##');
final _rowDateFmt  = DateFormat('dd MMM yyyy, hh:mm a');

String _fmtQty(double q) => _qtyFmt.format(q);
String _fmtSigned(double q) => q > 0 ? '+${_fmtQty(q)}' : _fmtQty(q);

Color _typeColor(StockMovementType t) {
  switch (t) {
    case StockMovementType.sale:            return const Color(0xFF2563EB);
    case StockMovementType.saleReturn:      return const Color(0xFF16A34A);
    case StockMovementType.purchase:        return const Color(0xFF0891B2);
    case StockMovementType.damage:          return AppColor.error;
    case StockMovementType.adjustment:      return const Color(0xFF7C3AED);
    case StockMovementType.countCorrection: return const Color(0xFFD97706);
  }
}

Color _qtyColor(double q) =>
    q > 0 ? AppColor.success : (q < 0 ? AppColor.error : AppColor.textSecondary);

// ── Wide layout: table ─────────────────────────────────────────────────────

class _Table extends StatelessWidget {
  final List<StockMovementRow> rows;
  final double hPad;
  const _Table({required this.rows, required this.hPad});

  static const _headers = [
    ('Date & Time', 3), ('Product', 4), ('Category', 2), ('Event', 2),
    ('Qty Change', 2), ('Reference', 3), ('Reason', 4), ('Resulting Stock', 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color:   const Color(0xFF1E3A8A),
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 10),
          child: Row(
            children: [
              for (final h in _headers)
                Expanded(
                  flex: h.$2,
                  child: Text(h.$1,
                      style: const TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w700,
                        color:      Colors.white,
                      )),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (_, i) {
              final r = rows[i];
              final e = r.entry;
              return Container(
                color:   i.isEven ? Colors.white : const Color(0xFFFAFAFB),
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 10),
                child: Row(
                  children: [
                    _cell(3, _rowDateFmt.format(e.dateTime)),
                    _cell(4, e.productName, bold: true),
                    _cell(2, r.categoryName),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _TypeBadge(type: e.type),
                      ),
                    ),
                    _cell(2, _fmtSigned(e.qtyChange),
                        bold: true, color: _qtyColor(e.qtyChange)),
                    _cell(3, e.referenceNo.isEmpty ? '—' : e.referenceNo),
                    _cell(4, e.reason.isEmpty ? '—' : e.reason),
                    _cell(2, r.resultingStock == null
                        ? '—'
                        : _fmtQty(r.resultingStock!), bold: true),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _cell(int flex, String text, {bool bold = false, Color? color}) =>
      Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize:   12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color:      color ?? const Color(0xFF1A1D23),
            ),
          ),
        ),
      );
}

// ── Narrow layout: card ────────────────────────────────────────────────────

class _MovementCard extends StatelessWidget {
  final StockMovementRow row;
  const _MovementCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final e = row.entry;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e.productName.isEmpty ? '—' : e.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      Color(0xFF1A1D23),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _fmtSigned(e.qtyChange),
                style: TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.w800,
                  color:      _qtyColor(e.qtyChange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _TypeBadge(type: e.type),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColor.textSecondary),
                ),
              ),
              Text(
                'Stock: ${row.resultingStock == null ? '—' : _fmtQty(row.resultingStock!)}',
                style: const TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w700,
                  color:      Color(0xFF1A1D23),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              _rowDateFmt.format(e.dateTime),
              if (e.referenceNo.isNotEmpty) e.referenceNo,
            ].join('  •  '),
            style: const TextStyle(fontSize: 11, color: AppColor.textHint),
          ),
          if (e.reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(e.reason,
                style: const TextStyle(
                    fontSize: 11, color: AppColor.textSecondary)),
          ],
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final StockMovementType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(type.label,
          style: TextStyle(
            fontSize:   10,
            fontWeight: FontWeight.w700,
            color:      color,
          )),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColor.primary,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color:      selected ? Colors.white : color,
          )),
    ),
  );
}

class _DateButton extends StatelessWidget {
  final String       label;
  final String       value;
  final VoidCallback onTap;
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color:        AppColor.grey100,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon('ic_calendar', size: 16, color: AppColor.primary),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12, color: AppColor.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: color.withOpacity(0.18)),
    ),
    child: Text('$label: $value',
        style: TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.w700,
          color:      color,
        )),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon('ic_total_products', size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No stock movements found',
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      Colors.grey.shade500,
            )),
        const SizedBox(height: 6),
        Text('Try changing the date range or event type',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );
}
