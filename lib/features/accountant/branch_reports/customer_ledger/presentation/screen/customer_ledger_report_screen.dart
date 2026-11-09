import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../branch/customer_ledger/data/model/customer_ledger_model.dart';
import '../../../accountant_dashboard/presentation/widget/dashboard_stat_card.dart';
import '../../../common/action/report_action_style.dart';
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
  final _amt = NumberFormat('#,##,###.##', 'en_IN');
  final _dateFmt = DateFormat('dd MMM yyyy');
  final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');

  // Draft dates — "Apply" dabane par hi data load hota hai.
  DateTime? _dStart, _dEnd;
  bool _draftInit = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _rs(double v) =>
      '${v < 0 ? '- ' : ''}Rs ${_amt.format(v.abs())}';

  Future<void> _pick(bool isStart) async {
    final init = (isStart ? _dStart : _dEnd) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColor.primary)),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => isStart ? _dStart = picked : _dEnd = picked);
  }

  @override
  Widget build(BuildContext context) {
    final p = customerLedgerReportProvider(widget.branchId);
    final state = ref.watch(p);
    final n = ref.read(p.notifier);
    final wide = MediaQuery.of(context).size.width >= 800;
    final pad = wide ? 24.0 : 16.0;
    final hasFilter = state.startDate != null || state.endDate != null;

    if (!_draftInit) {
      _dStart = state.startDate;
      _dEnd = state.endDate;
      _draftInit = true;
    }
    final dirty = _dStart != state.startDate || _dEnd != state.endDate;

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

    Widget dateField(String label, DateTime? v, bool isStart) => SizedBox(
          width: wide ? 170 : double.infinity,
          child: InkWell(
            onTap: () => _pick(isStart),
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: InputDecoration(
                isDense: true,
                labelText: label,
                prefixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
              child: Text(v == null ? 'Select' : _dateFmt.format(v),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: v == null
                          ? AppColor.textHint
                          : const Color(0xFF1A1D23))),
            ),
          ),
        );

    final applyBtn = ElevatedButton(
      onPressed: dirty ? () => n.applyDateFilter(_dStart, _dEnd) : null,
      style: ReportActionStyle.filled(),
      child: const Text('Apply'),
    );
    final clearBtn = hasFilter || _dStart != null || _dEnd != null
        ? TextButton(
            onPressed: () {
              setState(() => _dStart = _dEnd = null);
              n.applyDateFilter(null, null);
            },
            child: const Text('Clear'),
          )
        : const SizedBox.shrink();

    final searchField = TextField(
      controller: _searchCtrl,
      onSubmitted: n.setSearch,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search customer…',
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
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
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header + filters ──────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer Ledger',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1D23))),
                        SizedBox(height: 2),
                        Text('Customer payments and balance entries',
                            style: TextStyle(
                                fontSize: 12, color: AppColor.textHint)),
                      ],
                    ),
                  ),
                  ReportRefreshButton(onPressed: n.load),
                ]),
                const SizedBox(height: 14),
                if (wide)
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 12),
                    dateField('Start Date', _dStart, true),
                    const SizedBox(width: 10),
                    dateField('End Date', _dEnd, false),
                    const SizedBox(width: 10),
                    applyBtn,
                    clearBtn,
                  ])
                else ...[
                  searchField,
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: dateField('Start Date', _dStart, true)),
                    const SizedBox(width: 10),
                    Expanded(child: dateField('End Date', _dEnd, false)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: applyBtn),
                    clearBtn,
                  ]),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ── Summary cards ─────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 14, pad, 6),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: DashboardStatCard(
                      title: 'Total Entries',
                      value: '${state.totalCount}',
                      iconAsset: 'ic_total_sale',
                      color: AppColor.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DashboardStatCard(
                      title: 'Total Paid',
                      value: _rs(state.totalPaid),
                      iconAsset: 'ic_cash_in',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  if (wide) const Expanded(flex: 1, child: SizedBox()),
                ],
              ),
            ),
          ),

          // ── Table / list ──────────────────────────────────
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
                      : wide
                          ? _LedgerTable(
                              entries: state.entries,
                              rs: _rs,
                              dateFmt: _dateTimeFmt,
                              pad: pad,
                              loadingMore: state.pagination.isLoadingPage,
                            )
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
                              itemCount: state.entries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) => _LedgerCard(
                                e: state.entries[i],
                                rs: _rs,
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

// ── Desktop table ────────────────────────────────────────────────────────────
class _LedgerTable extends StatelessWidget {
  final List<CustomerLedgerModel> entries;
  final String Function(double) rs;
  final DateFormat dateFmt;
  final double pad;
  final bool loadingMore;

  const _LedgerTable({
    required this.entries,
    required this.rs,
    required this.dateFmt,
    required this.pad,
    required this.loadingMore,
  });

  static const _hint = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: Color(0xFF6B7280));

  Widget _cell(int flex, Widget child, {Alignment a = Alignment.centerLeft}) =>
      Expanded(flex: flex, child: Align(alignment: a, child: child));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 8, pad, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              _cell(1, const Text('#', style: _hint)),
              _cell(4, const Text('DATE & TIME', style: _hint)),
              _cell(5, const Text('CUSTOMER', style: _hint)),
              _cell(3, const Text('PREVIOUS', style: _hint),
                  a: Alignment.centerRight),
              _cell(3, const Text('PAID', style: _hint),
                  a: Alignment.centerRight),
              _cell(3, const Text('NEW BALANCE', style: _hint),
                  a: Alignment.centerRight),
              _cell(2, const Text('METHOD', style: _hint),
                  a: Alignment.center),
              _cell(4, const Text('NOTES', style: _hint)),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: ListView.separated(
              itemCount: entries.length + (loadingMore ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF1F2F4)),
              itemBuilder: (_, i) {
                if (i >= entries.length) return const BranchReportLoadMoreStrip();
                final e = entries[i];
                final owes = e.newAmount > 0;
                return Container(
                  color: i.isOdd ? const Color(0xFFFCFCFD) : Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(children: [
                    _cell(
                        1,
                        Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColor.textHint))),
                    _cell(
                        4,
                        Text(dateFmt.format(e.createdAt.toLocal()),
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFF374151)))),
                    _cell(
                        5,
                        Text(e.customerName.isEmpty ? '—' : e.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1D23)))),
                    _cell(
                        3,
                        Text(rs(e.previousAmount),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF374151))),
                        a: Alignment.centerRight),
                    _cell(
                        3,
                        Text(rs(e.payAmount),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981))),
                        a: Alignment.centerRight),
                    _cell(
                        3,
                        Text(rs(e.newAmount),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: owes
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF1A1D23))),
                        a: Alignment.centerRight),
                    _cell(2, _MethodChip(e.paymentMethod), a: Alignment.center),
                    _cell(
                        4,
                        Text(
                            [
                              if ((e.userFullName ?? '').isNotEmpty)
                                e.userFullName!,
                              if ((e.notes ?? '').isNotEmpty) e.notes!,
                            ].join('  •  '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppColor.textHint))),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String method;
  const _MethodChip(this.method);

  @override
  Widget build(BuildContext context) {
    final card = method.toLowerCase() == 'card';
    final c = card ? const Color(0xFF0369A1) : const Color(0xFF8B5CF6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(method.toUpperCase(),
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

// ── Mobile card ──────────────────────────────────────────────────────────────
class _LedgerCard extends StatelessWidget {
  final CustomerLedgerModel e;
  final String Function(double) rs;
  final DateFormat dateFmt;
  const _LedgerCard({required this.e, required this.rs, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value, {Color? color, bool bold = false}) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColor.textHint)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                        color: color ?? const Color(0xFF1A1D23))),
              ),
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
            _MethodChip(e.paymentMethod),
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
            dateFmt.format(e.createdAt.toLocal()) +
                ((e.userFullName ?? '').isNotEmpty ? '  •  ${e.userFullName}' : '') +
                ((e.notes ?? '').isNotEmpty ? '  •  ${e.notes}' : ''),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColor.textHint),
          ),
        ],
      ),
    );
  }
}
