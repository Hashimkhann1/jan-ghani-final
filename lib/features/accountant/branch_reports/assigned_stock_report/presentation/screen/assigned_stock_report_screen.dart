import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/app_icon.dart';
import '../../../accountant_dashboard/presentation/widget/dashboard_stat_card.dart';
import '../../../common/action/report_refresh_button.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../../common/pagination/branch_report_pagination_controls.dart';
import '../../data/model/assigned_stock_model.dart';
import '../provider/assigned_stock_provider.dart';

final _numFmt  = NumberFormat('#,##0.##');
final _dateFmt = DateFormat('dd MMM yyyy');
final _dtFmt   = DateFormat('dd MMM yyyy, hh:mm a');

Color _statusColor(String s) {
  switch (s) {
    case 'accepted': return AppColor.success;
    case 'rejected': return AppColor.error;
    default:         return const Color(0xFFD97706);
  }
}

String _statusLabel(String s) =>
    s.isEmpty ? '—' : s[0].toUpperCase() + s.substring(1);

/// Stock the warehouse assigned to this branch (stock transfers), with the
/// products inside each transfer.
class AssignedStockReportScreen extends ConsumerStatefulWidget {
  const AssignedStockReportScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<AssignedStockReportScreen> createState() =>
      _AssignedStockReportScreenState();
}

class _AssignedStockReportScreenState
    extends ConsumerState<AssignedStockReportScreen> {
  Future<void> _pickDate({required bool isFrom}) async {
    final provider = assignedStockProvider(widget.branchId);
    final state    = ref.read(provider);
    final notifier = ref.read(provider.notifier);
    final picked = await showDatePicker(
      context:     context,
      initialDate: isFrom ? state.fromDate : state.toDate,
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    isFrom ? notifier.setFromDate(picked) : notifier.setToDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final provider = assignedStockProvider(widget.branchId);
    final state    = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    ref.listen<AssignedStockState>(provider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.errorMessage!),
          backgroundColor: AppColor.error,
          behavior:        SnackBarBehavior.floating,
        ));
        notifier.clearError();
      }
    });

    final rows = state.pageRows;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Assigned Stock',
          style: TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.w700,
            color:      Color(0xFF1A1D23),
          ),
        ),
        actions: [
          ReportRefreshButton(onPressed: notifier.load),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
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
                    for (final s in const [null, 'pending', 'accepted', 'rejected'])
                      _StatusChip(
                        label:    s == null ? 'All' : _statusLabel(s),
                        color:    s == null ? AppColor.primary : _statusColor(s),
                        selected: state.status == s,
                        onTap:    () => notifier.setStatus(s),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatPill(
                      label: 'Transfers',
                      value: '${state.filtered.length}',
                      color: AppColor.primary,
                    ),
                    _StatPill(
                      label: 'Total units',
                      value: _numFmt.format(state.totalUnits),
                      color: const Color(0xFF0891B2),
                    ),
                    _StatPill(
                      label: 'Cost value',
                      value: _numFmt.format(state.totalCost),
                      color: const Color(0xFFD97706),
                    ),
                    _StatPill(
                      label: 'Sale value',
                      value: _numFmt.format(state.totalSale),
                      color: AppColor.success,
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
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _TransferCard(transfer: rows[i]),
                      ),
          ),
          if (!state.isLoading && rows.isNotEmpty)
            BranchReportPaginationControls(
              page:        state.page,
              hasNextPage: state.hasNextPage,
              onNext:      notifier.nextPage,
              onPrevious:  notifier.previousPage,
              totalCount:  state.filtered.length,
              totalPages:  (state.filtered.length /
                      BranchReportPagination.pageSize).ceil(),
            ),
        ],
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final AssignedStockTransfer transfer;
  const _TransferCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final t     = transfer;
    final color = _statusColor(t.status);
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  t.transferNumber,
                  style: const TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w800,
                    color:      Color(0xFF1A1D23),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_statusLabel(t.status),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              [
                _dtFmt.format(t.assignedAt),
                if ((t.assignedByName ?? '').isNotEmpty) 'by ${t.assignedByName}',
              ].join('  •  '),
              style: const TextStyle(fontSize: 11, color: AppColor.textHint),
            ),
          ),
          children: [
            Row(
              children: [
                _Metric('Products', '${t.items.length}'),
                _Metric('Units', _numFmt.format(t.totalUnits)),
                _Metric('Cost', _numFmt.format(t.totalCost)),
                _Metric('Sale', _numFmt.format(t.totalSale)),
              ],
            ),
            if (t.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(t.notes,
                    style: const TextStyle(
                        fontSize: 11, color: AppColor.textSecondary)),
              ),
            ],
            const Divider(height: 20, color: Color(0xFFEEEEEE)),
            for (final i in t.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        i.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_numFmt.format(i.quantitySent)} ${i.unit}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800),
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

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric(this.label, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
  final String label;
  final String value;
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
  final Color color;
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 170,
    child: DashboardStatCard(
      title:   label,
      value:   value,
      color:   color,
      compact: true,
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
        AppIcon('ic_total_products', size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No assigned stock found',
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      Colors.grey.shade500,
            )),
        const SizedBox(height: 6),
        Text('Try changing the date range or status',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );
}
