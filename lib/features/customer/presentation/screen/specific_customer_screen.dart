import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../../../core/widget/figure_card_widget.dart';
import '../../data/model/customer_model.dart';
import '../provider/customer_detail_provider.dart';
import '../widget/tab/customer_ledger_lab_widget.dart';
import '../widget/tab/sale_invoice_tab_widget.dart';
import '../widget/tab/sale_return_tab_widget.dart';

class SpecificCustomerDetailScreen extends ConsumerStatefulWidget {
  final CustomerModel customer;
  const SpecificCustomerDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<SpecificCustomerDetailScreen> createState() =>
      _SpecificCustomerDetailScreenState();
}

class _SpecificCustomerDetailScreenState
    extends ConsumerState<SpecificCustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final notifier = ref.read(customerDetailProvider(widget.customer.id).notifier);
    final state    = ref.read(customerDetailProvider(widget.customer.id));
    final picked   = await showDatePicker(
      context:       context,
      initialDate:   isStart ? (state.startDate ?? DateTime.now()) : (state.endDate ?? DateTime.now()),
      firstDate:     DateTime(2020),
      lastDate:      DateTime(2030),
    );
    if (picked != null) {
      isStart ? notifier.setStartDate(picked) : notifier.setEndDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c        = widget.customer;
    final state    = ref.watch(customerDetailProvider(c.id));
    final notifier = ref.read(customerDetailProvider(c.id).notifier);
    final fmt      = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('${c.code} · ${c.typeLabel}',
                style: const TextStyle(fontSize: 12, color: AppColor.textSecondary)),
          ],
        ),
        toolbarHeight: 64,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Summary Cards ──────────────────────
            Row(
              children: [
                SummaryCard(title: 'Total Sale',   value: 'Rs ${notifier.totalSale.toStringAsFixed(0)}',   color: AppColor.primary, icon: Icons.receipt_long_outlined),
                const SizedBox(width: 10),
                SummaryCard(title: 'Total Return', value: 'Rs ${notifier.totalReturn.toStringAsFixed(0)}', color: AppColor.error,   icon: Icons.assignment_return_outlined),
                const SizedBox(width: 10),
                SummaryCard(title: 'Total Paid',   value: 'Rs ${notifier.totalPaid.toStringAsFixed(0)}',   color: AppColor.success, icon: Icons.check_circle_outline_rounded),
                const SizedBox(width: 10),
                SummaryCard(title: 'Total Due',    value: 'Rs ${notifier.totalDue.toStringAsFixed(0)}',    color: AppColor.warning, icon: Icons.warning_amber_outlined),
              ],
            ),

            const SizedBox(height: 14),

            // ── Date Range ─────────────────────────
            Row(
              children: [
                _DatePickerField(
                  label:    state.startDate != null ? fmt.format(state.startDate!) : 'Start Date',
                  hasValue: state.startDate != null,
                  onTap:    () => _pickDate(context, true),
                  onClear:  () => notifier.setStartDate(null),
                ),
                const SizedBox(width: 10),
                _DatePickerField(
                  label:    state.endDate != null ? fmt.format(state.endDate!) : 'End Date',
                  hasValue: state.endDate != null,
                  onTap:    () => _pickDate(context, false),
                  onClear:  () => notifier.setEndDate(null),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Tab Bar ────────────────────────────
            Container(
              padding:    const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color:        AppColor.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller:           _tabController,
                indicatorSize:        TabBarIndicatorSize.tab,
                dividerColor:         Colors.transparent,
                indicator: BoxDecoration(
                  color:        AppColor.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                labelColor:           Colors.white,
                unselectedLabelColor: AppColor.textSecondary,
                labelStyle:           const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Sale Invoice'),
                  Tab(text: 'Sale Return'),
                  Tab(text: 'Customer Ledger'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Tab Content ────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [

                  SaleInvoiceTab(customerId: c.id, customerName: c.name,),
                  SaleReturnTab(customerId: c.id, customerName: c.name,),
                  CustomerLedgerTab(customerId: c.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Date Picker Field ──────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final String   label;
  final bool     hasValue;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DatePickerField({
    required this.label,
    required this.hasValue,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height:     42,
          padding:    const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color:        AppColor.grey100,
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(
                color: hasValue ? AppColor.primary : AppColor.grey300),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size:  16,
                  color: hasValue ? AppColor.primary : AppColor.grey400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        color: hasValue
                            ? AppColor.textPrimary
                            : AppColor.textHint)),
              ),
              if (hasValue)
                InkWell(
                  onTap:        onClear,
                  borderRadius: BorderRadius.circular(20),
                  child: const Icon(Icons.close,
                      size: 16, color: AppColor.grey400),
                ),
            ],
          ),
        ),
      ),
    );
  }
}