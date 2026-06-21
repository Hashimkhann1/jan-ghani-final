import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_summary.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/presentation/provider/installment_dashboard_provider.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/presentation/widget/installment_customer_card.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/presentation/widget/installment_stat_card.dart';
import 'package:jan_ghani_final/features/installment/installment_customer_detail/presentation/screen/installment_customer_detail_screen.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';
import 'package:jan_ghani_final/features/installment/register_installment_customer/presentation/screen/register_installment_customer_screen.dart';

/// Installment module ka mobile dashboard (sirf UI — data abhi mock).
class InstallmentDashboardScreen extends ConsumerStatefulWidget {
  const InstallmentDashboardScreen({super.key});

  @override
  ConsumerState<InstallmentDashboardScreen> createState() =>
      _InstallmentDashboardScreenState();
}

class _InstallmentDashboardScreenState
    extends ConsumerState<InstallmentDashboardScreen> {
  static const Color _canvas = Color(0xFFF7F7F9);

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// + tap par Register New Customer screen kholo.
  void _openRegisterCustomer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegisterInstallmentCustomerScreen(),
      ),
    );
  }

  /// Customer card tap par uski detail (multi-plan) screen kholo.
  void _openCustomerDetail(InstallmentCustomer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            InstallmentCustomerDetailScreen(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(installmentSummaryProvider);
    final customers = ref.watch(installmentCustomersProvider);
    final filter = ref.watch(installmentFilterProvider);

    return Scaffold(
      backgroundColor: _canvas,
      appBar: _buildAppBar(),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _openRegisterCustomer,
      //   backgroundColor: AppColor.primary,
      //   elevation: 2,
      //   child: const Icon(Icons.add, color: AppColor.white, size: 28),
      // ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            16.hBox,
            _buildStatsRow(summary),
            16.hBox,
            _buildSearchBar(),
            16.hBox,
            _buildFilterChips(filter),
            16.hBox,
            if (customers.isEmpty)
              _buildEmpty()
            else
              ...customers.map(
                (c) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: InstallmentCustomerCard(
                    customer: c,
                    onTap: () => _openCustomerDetail(c),
                  ),
                ),
              ),
            90.hBox,
          ],
        ),
      ),
    );
  }

  // ── Top app bar ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColor.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: AppColor.surface,
      centerTitle: false,
      titleSpacing: 16,
      title: const Text(
        'Installments',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColor.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _openRegisterCustomer,
          icon: const Icon(Icons.add, color: AppColor.primary),
        ),
        8.wBox,
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColor.grey200),
      ),
    );
  }

  // ── Stats row (horizontal) ──────────────────────────────────────────────────
  Widget _buildStatsRow(InstallmentSummary s) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          InstallmentStatCard(
            label: 'Total Customers',
            value: s.totalCustomers.toDouble().pkrFormat,
            badge: '${s.customersGrowthPct.toStringAsFixed(0)}%',
            badgeIcon: Icons.arrow_upward,
            badgeColor: AppColor.success,
          ),
          // InstallmentStatCard(
          //   label: 'Active',
          //   value: s.activeCount.toDouble().pkrFormat,
          //   badge: 'Ongoing',
          //   badgeIcon: Icons.payments_outlined,
          //   badgeColor: AppColor.primary,
          // ),
          InstallmentStatCard(
            label: 'Remaining',
            value: 'Rs ${s.remainingTotal.toInt().compact}',
            badge: 'Pending',
            badgeIcon: Icons.pending_actions_outlined,
            badgeColor: AppColor.warningDark,
          ),
          InstallmentStatCard(
            label: 'Collected (Mo)',
            value: 'Rs ${s.collectedThisMonth.toInt().compact}',
            badge: 'Target Met',
            badgeIcon: Icons.verified_outlined,
            badgeColor: AppColor.success,
          ),
        ],
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    final query = ref.watch(installmentSearchProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (v) =>
            ref.read(installmentSearchProvider.notifier).state = v,
        decoration: InputDecoration(
          hintText: 'Search customer or product...',
          hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColor.grey500),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: AppColor.grey500),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(installmentSearchProvider.notifier).state = '';
                  },
                ),
          filled: true,
          fillColor: AppColor.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: AppColor.grey300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Filter chips ────────────────────────────────────────────────────────────
  Widget _buildFilterChips(InstallmentFilter selected) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: InstallmentFilter.values.map((f) {
          final isSelected = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  ref.read(installmentFilterProvider.notifier).state = f,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: isSelected ? AppColor.primary : AppColor.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? AppColor.primary : AppColor.grey300,
                  ),
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColor.white : AppColor.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: AppColor.grey400),
          12.hBox,
          const Text(
            'No customers found',
            style: TextStyle(color: AppColor.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
