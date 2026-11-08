import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../branch/customer_ledger/data/model/customer_ledger_model.dart';
import '../../../accountant_dashboard/presentation/widget/dashboard_stat_card.dart';
import '../../../common/action/report_refresh_button.dart';
import '../../../common/pagination/branch_report_infinite_scroll.dart';
import '../provider/customer_ledger_report_provider.dart';

class CustomerLedgerReportScreen extends ConsumerStatefulWidget {
  const CustomerLedgerReportScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<CustomerLedgerReportScreen> createState() =>
      _CustomerLedgerReportScreenState();
}

class _CustomerLedgerReportScreenState
    extends ConsumerState<CustomerLedgerReportScreen> {
  final _searchCtrl = TextEditingController();
  final _amt = NumberFormat('#,##,###', 'en_IN');
  final _dateFmt = DateFormat('dd MMM yyyy');
  final _dateTimeFmt = DateFormat('dd MMM yyyy  •  hh:mm a');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final p = customerLedgerReportProvider(widget.branchId);
    final s = ref.read(p);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: s.startDate != null && s.endDate != null
          ? DateTimeRange(start: s.startDate!, end: s.endDate!)
          : null,
    );
    if (picked == null) return;
    ref.read(p.notifier).applyDateFilter(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    final p = customerLedgerReportProvider(widget.branchId);
    final state = ref.watch(p);
    final n = ref.read(p.notifier);
    final wide = MediaQuery.of(context).size.width >= 800;
    final hasFilter = state.startDate != null || state.endDate != null;

    ref.listen<CustomerLedgerReportState>(p, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: AppColor.error,
          behavior: SnackBarBehavior.floating,
        ));
        n.clearError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 16, wide ? 28 : 16, 14),
            child: Column(
              children: [
                Row(children: [
                  const Expanded(
                    child: Text('Customer Ledger',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D23))),
                  ),
                  ReportRefreshButton(onPressed: n.load),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onSubmitted: n.setSearch,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search customer…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: state.search.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  n.setSearch('');
                                },
                              ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(hasFilter && state.startDate != null
                        ? '${_dateFmt.format(state.startDate!)} - '
                            '${state.endDate != null ? _dateFmt.format(state.endDate!) : '…'}'
                        : 'Date range'),
                  ),
                  if (hasFilter)
                    IconButton(
                      tooltip: 'Clear date filter',
                      onPressed: () => n.applyDateFilter(null, null),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                ]),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 12, wide ? 28 : 16, 12),
            child: Wrap(spacing: 10, runSpacing: 10, children: [
              SizedBox(
                width: 190,
                child: DashboardStatCard(
                  title: 'Total Entries',
                  value: '${state.totalCount}',
                  iconAsset: 'ic_total_sale',
                  color: AppColor.primary,
                ),
              ),
              SizedBox(
                width: 190,
                child: DashboardStatCard(
                  title: 'Total Paid',
                  value: 'Rs ${_amt.format(state.totalPaid.toInt())}',
                  iconAsset: 'ic_cash_in',
                  color: const Color(0xFF10B981),
                ),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: BranchReportInfiniteScroll(
              hasMore: state.pagination.hasNextPage,
              isLoading: state.pagination.isLoadingPage,
              onLoadMore: n.nextPage,
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.entries.isEmpty
                      ? const Center(
                          child: Text('No ledger entries found',
                              style: TextStyle(color: AppColor.textHint)))
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                              wide ? 28 : 16, 12, wide ? 28 : 16, 24),
                          itemCount: state.entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _LedgerRow(
                            e: state.entries[i],
                            amt: _amt,
                            dateFmt: _dateTimeFmt,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final CustomerLedgerModel e;
  final NumberFormat amt;
  final DateFormat dateFmt;
  const _LedgerRow({required this.e, required this.amt, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    String rs(double v) => 'Rs ${amt.format(v.toInt())}';
    Widget cell(String label, String value, {Color? color, bool bold = false}) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColor.textHint)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                      color: color ?? const Color(0xFF1A1D23))),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(e.customerName.isEmpty ? '—' : e.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D23))),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(e.paymentMethod.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B5CF6))),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            cell('Previous', rs(e.previousAmount)),
            cell('Paid', rs(e.payAmount),
                color: const Color(0xFF10B981), bold: true),
            cell('New Balance', rs(e.newAmount), bold: true),
          ]),
          const SizedBox(height: 8),
          Text(
            '${dateFmt.format(e.createdAt.toLocal())}'
            '${(e.userFullName ?? '').isNotEmpty ? '  •  ${e.userFullName}' : ''}'
            '${(e.notes ?? '').isNotEmpty ? '  •  ${e.notes}' : ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColor.textHint),
          ),
        ],
      ),
    );
  }
}
