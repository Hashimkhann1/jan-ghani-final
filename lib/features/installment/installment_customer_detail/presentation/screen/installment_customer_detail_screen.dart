import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/installment/installment_customer_detail/domain/customer_detail_helpers.dart';
import 'package:jan_ghani_final/features/installment/installment_customer_detail/presentation/widget/installment_plan_card.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';
import 'package:jan_ghani_final/features/installment/installment_plan_detail/presentation/screen/installment_plan_detail_screen.dart';

/// Ek customer ki detail — uske saare installment plans (multi-plan).
/// Sirf UI — data mock se aata hai.
class InstallmentCustomerDetailScreen extends StatelessWidget {
  final InstallmentCustomer customer;

  const InstallmentCustomerDetailScreen({super.key, required this.customer});

  static const Color _canvas = Color(0xFFF7F7F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildHeader(),
            16.hBox,
            _buildSummaryCard(),
            20.hBox,
            _buildPlansHeader(),
            12.hBox,
            ...customer.plans.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InstallmentPlanCard(
                  plan: p,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InstallmentPlanDetailScreen(
                        plan: p,
                        customerName: customer.name,
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
        'Customer Detail',
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

  // ── Customer header ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColor.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            customer.initials,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColor.primary,
            ),
          ),
        ),
        12.hBox,
        Text(
          customer.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
          ),
        ),
        4.hBox,
        if (customer.phone.isNotEmpty || customer.cnic.isNotEmpty)
          Text(
            [
              if (customer.phone.isNotEmpty) customer.phone,
              if (customer.cnic.isNotEmpty) customer.cnic,
            ].join('  •  '),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColor.textSecondary),
          ),
        16.hBox,
        Row(
          children: [
            Expanded(
              child: _OutlineAction(
                icon: Icons.call,
                label: 'Call',
                onTap: () {},
              ),
            ),
            12.wBox,
            Expanded(
              child: _OutlineAction(
                icon: Icons.chat,
                label: 'WhatsApp',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Summary card (outstanding / paid / plans / next due) ─────────────────────
  Widget _buildSummaryCard() {
    final nextDue = customer.nextDueDate;
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
          const Text(
            'TOTAL OUTSTANDING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColor.textSecondary,
            ),
          ),
          4.hBox,
          Text(
            'Rs ${customer.totalRemaining.pkrFormat}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
          14.hBox,
          Container(height: 1, color: AppColor.grey100),
          14.hBox,
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Total Paid',
                  value: 'Rs ${customer.totalPaid.pkrFormat}',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Active Plans',
                  value: '${customer.activePlanCount}',
                ),
              ),
            ],
          ),
          if (nextDue != null) ...[
            14.hBox,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppColor.primary),
                  10.wBox,
                  const Text(
                    'Next Due',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${formatDmy(nextDue)}  •  Rs ${customer.nextDueAmount.pkrFormat}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColor.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── "Installment Plans" header + count badge ─────────────────────────────────
  Widget _buildPlansHeader() {
    return Row(
      children: [
        const Text(
          'Installment Plans',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
          ),
        ),
        8.wBox,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColor.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${customer.planCount}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColor.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
        ),
        4.hBox,
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _OutlineAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColor.primary,
        side: const BorderSide(color: AppColor.grey300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
