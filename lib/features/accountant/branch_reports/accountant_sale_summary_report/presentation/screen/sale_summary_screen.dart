import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/app_icon.dart';
import '../../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../../common/filter/report_filter_dialog.dart';
import '../../../common/pagination/branch_report_pagination_controls.dart';
import '../../data/model/sale_summary_model.dart';
import '../provider/sale_summary_provider.dart';

class SaleSummaryScreen extends ConsumerStatefulWidget {
  const SaleSummaryScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<SaleSummaryScreen> createState() => _SaleSummaryScreenState();
}

class _SaleSummaryScreenState extends ConsumerState<SaleSummaryScreen> {
  final _dateFmt = DateFormat('dd MMM yyyy');
  final _timeFmt = DateFormat('hh:mm a');
  final _amtFmt  = NumberFormat('#,##,###', 'en_IN');

  String _fmtAmt(double v) =>
      '${v < 0 ? '- ' : ''}Rs ${_amtFmt.format(v.abs().round())}';

  ThemeData _pickerTheme(BuildContext ctx) => Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: AppColor.primary),
      );

  Future<void> _pickDate(bool isFrom) async {
    final provider = saleSummaryProvider(widget.branchId);
    final state    = ref.read(provider);
    final init     = isFrom ? state.fromDate : state.toDate;
    final picked   = await showDatePicker(
      context:     context,
      initialDate: init,
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
    );
    if (picked == null) return;
    final combined = DateTime(
        picked.year, picked.month, picked.day, init.hour, init.minute, init.second);
    final notifier = ref.read(provider.notifier);
    isFrom ? notifier.setFromDate(combined) : notifier.setToDate(combined);
  }

  Future<void> _pickTime(bool isFrom) async {
    final provider = saleSummaryProvider(widget.branchId);
    final state    = ref.read(provider);
    final init     = isFrom ? state.fromDate : state.toDate;
    final picked   = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(init),
      builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
    );
    if (picked == null) return;
    final combined = DateTime(
        init.year, init.month, init.day, picked.hour, picked.minute);
    final notifier = ref.read(provider.notifier);
    isFrom ? notifier.setFromDate(combined) : notifier.setToDate(combined);
  }

  void _openFilters() {
    final provider = saleSummaryProvider(widget.branchId);
    showReportFilterDialog(
      context: context,
      onReset: () {
        final n = ref.read(provider.notifier);
        n.setToday();
        n.setCustomer(null);
      },
      content: Consumer(builder: (ctx, ref, _) {
        final state    = ref.watch(provider);
        final notifier = ref.read(provider.notifier);
        final customerItems = [
          DropdownItem<String?>(
            value: null,
            label: 'All Customers',
            icon:  Icons.people_outline_rounded,
          ),
          ...state.customers.map((c) => DropdownItem<String?>(
                value: c.id,
                label: c.label,
                icon:  Icons.person_outline_rounded,
              )),
        ];
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: _PickerField(
                  label: 'Start Date',
                  value: _dateFmt.format(state.fromDate),
                  onTap: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerField(
                  label: 'Start Time',
                  value: _timeFmt.format(state.fromDate),
                  onTap: () => _pickTime(true),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _PickerField(
                  label: 'End Date',
                  value: _dateFmt.format(state.toDate),
                  onTap: () => _pickDate(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerField(
                  label: 'End Time',
                  value: _timeFmt.format(state.toDate),
                  onTap: () => _pickTime(false),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            AppSearchableDropdown<String?>(
              items:      customerItems,
              value:      state.selectedCustomerId,
              hint:       'All Customers',
              fullWidth:  true,
              prefixIcon: Icons.person_outline_rounded,
              onChanged:  notifier.setCustomer,
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = saleSummaryProvider(widget.branchId);
    final state    = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final summary  = state.summary;

    ref.listen<SaleSummaryState>(provider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.errorMessage!),
          backgroundColor: AppColor.error,
          behavior:        SnackBarBehavior.floating,
          action: SnackBarAction(
            label:     'OK',
            textColor: Colors.white,
            onPressed: notifier.clearError,
          ),
        ));
      }
    });

    final cards = [
      _StatCard(
        label: 'Total Sale',
        value: _fmtAmt(summary.totalSale),
        icon:  'ic_cash_sale',
        color: AppColor.success,
      ),
      _StatCard(
        label: 'Total Return',
        value: _fmtAmt(summary.totalReturn),
        icon:  'sidebar_icons/sale_return_report',
        color: AppColor.error,
      ),
      _StatCard(
        label: 'Net Sale',
        value: _fmtAmt(summary.netSale),
        icon:  'ic_net_amount',
        color: AppColor.primary,
      ),
      _StatCard(
        label: 'Total Collected (Customers)',
        value: _fmtAmt(summary.totalCollected),
        icon:  'ic_cash_in',
        color: AppColor.warning,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Sale Summary',
          style: TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.w700,
            color:      Color(0xFF1A1D23),
          ),
        ),
        actions: [
          ReportFilterButton(
            onPressed:   _openFilters,
            activeCount: state.selectedCustomerId != null ? 1 : 0,
          ),
          IconButton(
            onPressed: notifier.load,
            icon:    const AppIcon('ic_refresh',
                size: 22, color: AppColor.textSecondary),
            tooltip: 'Refresh',
          ),
          TextButton(
            onPressed: notifier.setToday,
            child: const Text('Today'),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final pad    = isWide ? 28.0 : 16.0;

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(pad),
                  child: state.isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColor.primary),
                          ),
                        )
                      : isWide
                          ? Row(children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                if (i > 0) const SizedBox(width: 14),
                                Expanded(child: cards[i]),
                              ],
                            ])
                          : Column(children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                if (i > 0) const SizedBox(height: 12),
                                cards[i],
                              ],
                            ]),
                ),
                if (!state.isLoading) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sale Invoices',
                        style: const TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w700,
                          color:      Color(0xFF1A1D23),
                        ),
                      ),
                    ),
                  ),
                  if (state.invoices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('No invoices found for the selected filters',
                          style: TextStyle(color: AppColor.textHint)),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                      child: Column(
                        children: [
                          for (final inv in state.invoices)
                            _InvoiceTile(
                              invoice: inv,
                              dateFmt: _dateFmt,
                              timeFmt: _timeFmt,
                              fmtAmt:  _fmtAmt,
                            ),
                        ],
                      ),
                    ),
                  if (state.invoices.isNotEmpty)
                    BranchReportPaginationControls(
                      page:        state.pagination.page,
                      hasNextPage: state.pagination.hasNextPage,
                      isLoading:   state.pagination.isLoadingPage,
                      onNext:      notifier.nextPage,
                      onPrevious:  notifier.previousPage,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String       label;
  final String       value;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      AppColor.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap:        onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color:        AppColor.grey100,
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(color: AppColor.grey200),
              ),
              child: Row(
                children: [
                  const AppIcon('ic_calendar',
                      size: 16, color: AppColor.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
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
          ),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color  color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppIcon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit:       BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.w800,
                        color:      color,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color:    AppColor.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}


class _InvoiceTile extends StatelessWidget {
  final SummaryInvoice          invoice;
  final DateFormat              dateFmt;
  final DateFormat              timeFmt;
  final String Function(double) fmtAmt;

  const _InvoiceTile({
    required this.invoice,
    required this.dateFmt,
    required this.timeFmt,
    required this.fmtAmt,
  });

  @override
  Widget build(BuildContext context) {
    final inv = invoice;
    const hint = TextStyle(fontSize: 11, color: AppColor.textHint);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFEEEEEE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.invoiceNo,
                        style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.primary)),
                    const SizedBox(height: 2),
                    Text(inv.customerLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColor.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmtAmt(inv.grandTotal),
                      style: const TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w800,
                          color:      Color(0xFF1A1D23))),
                  const SizedBox(height: 2),
                  Text(
                    '${dateFmt.format(inv.invoiceDate)}, ${timeFmt.format(inv.invoiceDate)}  •  ${inv.paymentLabel}',
                    style: hint,
                  ),
                ],
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color:        const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Expanded(flex: 4, child: Text('Product', style: hint)),
                Expanded(flex: 2, child: Text('Qty', style: hint, textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Price', style: hint, textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Total', style: hint, textAlign: TextAlign.right)),
              ]),
            ),
            for (final item in inv.items)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(children: [
                  Expanded(
                    flex: 4,
                    child: Text(item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.quantity % 1 == 0
                          ? item.quantity.toInt().toString()
                          : item.quantity.toStringAsFixed(2),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(fmtAmt(item.salePrice),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(fmtAmt(item.totalAmount),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            const Divider(height: 16, color: Color(0xFFEEEEEE)),
            Row(children: [
              _amt('Previous', fmtAmt(inv.previousAmount)),
              _amt('Paid', fmtAmt(inv.payAmount)),
              _amt('New', fmtAmt(inv.newAmount)),
              if (inv.totalDiscount > 0)
                _amt('Discount', fmtAmt(inv.totalDiscount)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _amt(String label, String value) => Expanded(
        child: Column(children: [
          Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
        ]),
      );
}
