import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';
import 'package:jan_ghani_final/features/installment/installment_plan_detail/domain/installment_schedule_item.dart';
import 'package:jan_ghani_final/features/installment/installment_plan_detail/presentation/widget/installment_schedule_row.dart';

/// Ek product plan ki tafseel — schedule + record payment + contract.
/// Sirf UI — schedule plan se mock generate hota hai.
class InstallmentPlanDetailScreen extends StatelessWidget {
  final InstallmentPlan plan;
  final String customerName;

  const InstallmentPlanDetailScreen({
    super.key,
    required this.plan,
    required this.customerName,
  });

  static const Color _canvas = Color(0xFFF7F7F9);

  @override
  Widget build(BuildContext context) {
    final schedule = buildScheduleFromPlan(plan);
    final monthly =
        plan.totalCount == 0 ? 0.0 : plan.totalPayable / plan.totalCount;
    final endDate =
        schedule.isEmpty ? plan.startDate : schedule.last.dueDate;

    return Scaffold(
      backgroundColor: _canvas,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildHeaderCard(),
            16.hBox,
            _buildRecordPaymentButton(),
            16.hBox,
            _buildScheduleCard(schedule),
            16.hBox,
            _buildContractCard(endDate, monthly),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: AppColor.surface,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColor.textPrimary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'Plan Details',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColor.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColor.textPrimary),
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColor.grey200),
      ),
    );
  }

  // ── Header card (product + summary 2x2) ──────────────────────────────────────
  Widget _buildHeaderCard() {
    final status = plan.status;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.product,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    2.hBox,
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              8.wBox,
              _StatusBadge(label: status.label, color: status.color, bg: status.bgColor),
            ],
          ),
          8.hBox,
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 14, color: AppColor.textSecondary),
              6.wBox,
              Text(
                'Started ${planDetailDmy(plan.startDate)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColor.textSecondary,
                ),
              ),
            ],
          ),
          14.hBox,
          Container(height: 1, color: AppColor.grey100),
          14.hBox,
          Row(
            children: [
              Expanded(
                child: _SummaryCell(
                  label: 'Total Price',
                  value: 'Rs ${plan.totalPayable.pkrFormat}',
                ),
              ),
              Expanded(
                child: _SummaryCell(
                  label: 'Advance Paid',
                  value: 'Rs 0',
                ),
              ),
            ],
          ),
          14.hBox,
          Row(
            children: [
              Expanded(
                child: _SummaryCell(
                  label: 'Paid Amount',
                  value: 'Rs ${plan.paidAmount.pkrFormat}',
                ),
              ),
              Expanded(
                child: _SummaryCell(
                  label: 'Remaining',
                  value: 'Rs ${plan.remaining.pkrFormat}',
                  highlight: true,
                ),
              ),
            ],
          ),
          14.hBox,
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: plan.progress,
              minHeight: 6,
              backgroundColor: AppColor.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(status.color),
            ),
          ),
          8.hBox,
          Text(
            '${plan.paidCount} of ${plan.totalCount} installments paid',
            style: const TextStyle(
              fontSize: 12,
              color: AppColor.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Record Payment ───────────────────────────────────────────────────────────
  Widget _buildRecordPaymentButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: AppColor.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.payments_outlined, size: 20),
        label: const Text(
          'Record Payment',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Schedule card ────────────────────────────────────────────────────────────
  Widget _buildScheduleCard(List<InstallmentScheduleItem> schedule) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey200),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Installment Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
            ),
          ),
          Container(height: 1, color: AppColor.grey100),
          ...List.generate(schedule.length, (i) {
            return InstallmentScheduleRow(
              item: schedule[i],
              isLast: i == schedule.length - 1,
            );
          }),
        ],
      ),
    );
  }

  // ── Contract details card ────────────────────────────────────────────────────
  Widget _buildContractCard(DateTime endDate, double monthly) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 18, color: AppColor.primary),
              8.wBox,
              const Text(
                'Contract Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
          14.hBox,
          _ContractRow(label: 'Start Date', value: planDetailDmy(plan.startDate)),
          12.hBox,
          _ContractRow(label: 'End Date', value: planDetailDmy(endDate)),
          12.hBox,
          // NOTE: markup abhi mock — baad mein plan data se aayega.
          const _ContractRow(
            label: 'Markup Rate',
            value: '20%',
            valueColor: AppColor.warningDark,
          ),
          12.hBox,
          _ContractRow(
            label: 'Monthly Installment',
            value: 'Rs ${monthly.pkrFormat}',
            valueColor: AppColor.primary,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _SummaryCell({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: AppColor.textSecondary,
          ),
        ),
        4.hBox,
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: highlight ? AppColor.primary : AppColor.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ContractRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _ContractRow({
    required this.label,
    required this.value,
    this.valueColor = AppColor.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColor.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
