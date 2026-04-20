import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/provider/customer_provider.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/widget/add_customer_dialog.dart';
import '../../../../../core/widget/figure_card_widget.dart';
import '../../data/model/customer_model.dart';
import '../widget/customer_action_button_widget.dart';
import '../widget/customer_empty_state.dart';
import '../widget/customer_filter_chip_widget.dart';
import '../widget/customer_status_badge_widget.dart';
import '../widget/customer_type_badge_widget.dart';

class AllCustomerScreen extends ConsumerWidget {
  const AllCustomerScreen({super.key});

  void _openDialog(BuildContext context, {CustomerModel? customer}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddCustomerDialog(customer: customer),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Customer Delete Karein?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content:
        Text('"${customer.name}" ko permanently delete karna chahte hain?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              ref
                  .read(customerProvider.notifier)
                  .deleteCustomer(customer.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerProvider);
    final customers = state.filteredCustomers;
    final size = MediaQuery.sizeOf(context);
    final auth = ref.watch(authProvider);

    // ── Error Snackbar ───────────────────────────────────────
    ref.listen<CustomerState>(customerProvider, (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(customerProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          // Refresh button
          IconButton(
            onPressed: () =>
                ref.read(customerProvider.notifier).loadCustomers(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 4),
          // New Customer button
          auth.role == "store_manager" ? IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                onPressed: () => _openDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Customer', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ) : SizedBox(),
          const SizedBox(width: 16),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Stat Cards ───────────────────────────
            Row(
              children: [
                SummaryCard(
                  title: 'Total Customers',
                  value: '${state.totalCount}',
                  icon:  Icons.people_outline_rounded,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Active',
                  value: '${state.activeCount}',
                  icon:  Icons.check_circle_outline_rounded,
                  color: AppColor.success,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Outstanding',
                  value:
                  'Rs ${state.totalOutstanding.toStringAsFixed(0)}',
                  icon:  Icons.account_balance_wallet_outlined,
                  color: AppColor.error,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Search + Filters ─────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      onChanged: ref
                          .read(customerProvider.notifier)
                          .onSearchChanged,
                      style: const TextStyle(fontSize: 13),
                      cursorHeight: 14,
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone, code...',
                        hintStyle: const TextStyle(
                            color: AppColor.textHint, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: AppColor.grey400),
                        filled:    true,
                        fillColor: AppColor.grey100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  CustomerFilterChip(
                    label: 'All',
                    value: 'all',
                    selectedValue: state.filterStatus,
                    onTap: ref
                        .read(customerProvider.notifier)
                        .onFilterStatusChanged,
                  ),
                  const SizedBox(width: 6),
                  CustomerFilterChip(
                    label: 'Active',
                    value: 'active',
                    selectedValue: state.filterStatus,
                    onTap: ref
                        .read(customerProvider.notifier)
                        .onFilterStatusChanged,
                  ),
                  const SizedBox(width: 6),
                  CustomerFilterChip(
                    label: 'Inactive',
                    value: 'inactive',
                    selectedValue: state.filterStatus,
                    onTap: ref
                        .read(customerProvider.notifier)
                        .onFilterStatusChanged,
                  ),

                  const SizedBox(width: 16),
                  const _VerticalDivider(),
                  const SizedBox(width: 16),

                  // Type filters
                  CustomerFilterChip(
                    label: 'All Types',
                    value: 'all',
                    selectedValue: state.filterType,
                    onTap: ref.read(customerProvider.notifier).onFilterTypeChanged,
                  ),
                  const SizedBox(width: 6),
                  CustomerFilterChip(
                    label: 'Walk-in',
                    value: 'walkin',
                    selectedValue: state.filterType,
                    onTap: ref.read(customerProvider.notifier).onFilterTypeChanged,
                  ),
                  const SizedBox(width: 6),
                  CustomerFilterChip(
                    label: 'Credit',
                    value: 'credit',
                    selectedValue: state.filterType,
                    onTap: ref.read(customerProvider.notifier).onFilterTypeChanged,
                  ),
                  const SizedBox(width: 6),
                  CustomerFilterChip(
                    label: 'Wholesale',
                    value: 'wholesale',
                    selectedValue: state.filterType,
                    onTap: ref.read(customerProvider.notifier).onFilterTypeChanged,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Table ────────────────────────────────
            Expanded(
              child: customers.isEmpty ?
              CustomerEmptyState(isSearching: state.searchQuery.isNotEmpty) :
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  const double minTableWidth = 950;
                  final tableWidth =
                  availableWidth > minTableWidth ? availableWidth : minTableWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: tableWidth),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColor.grey100),
                          dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return AppColor.primary.withValues(alpha: 0.05);
                            }
                            return null;
                          }),
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 52,
                          columnSpacing: (tableWidth * 0.03).clamp(16.0, 48.0),
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('#')),
                            DataColumn(label: Text('Customer')),
                            DataColumn(label: Text('Phone')),
                            DataColumn(label: Text('Address')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Credit Limit')),
                            DataColumn(label: Text('Balance')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: List.generate(customers.length, (i) {
                            final c = customers[i];
                            return DataRow(
                              onSelectChanged: (_) {},
                              cells: [
                                DataCell(Text(c.code,
                                    style: const TextStyle(
                                        color: AppColor.textSecondary, fontSize: 12))),

                                DataCell(GestureDetector(
                                  onTap: () {},
                                  child: Text(c.name,
                                      style: const TextStyle(
                                          color: AppColor.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                )),

                                DataCell(Text(c.phone,
                                    style: const TextStyle(fontSize: 13))),

                                DataCell(SizedBox(
                                  width: 150,
                                  child: Text(
                                    c.address ?? '—',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                )),

                                DataCell(CustomerTypeBadge(customerType: c.customerType)),

                                DataCell(Text(c.creditLimitLabel,
                                    style: const TextStyle(fontSize: 13))),

                                DataCell(Text(c.balance.toString(),
                                    style: const TextStyle(fontSize: 13))),

                                DataCell(CustomerStatusBadge(isActive: c.isActive)),

                                DataCell(Row(
                                  children: [
                                    CustomerActionButton(
                                      icon: Icons.edit_outlined,
                                      color: AppColor.primary,
                                      tooltip: 'Edit',
                                      onTap: () {
                                        if (auth.isManager) {
                                          _openDialog(context, customer: c);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                  "Only manager can edit customers"),
                                              backgroundColor: AppColor.error,
                                              behavior: SnackBarBehavior.floating,
                                              action: SnackBarAction(
                                                label: 'OK',
                                                textColor: Colors.white,
                                                onPressed: () => ref
                                                    .read(customerProvider.notifier)
                                                    .clearError(),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    CustomerActionButton(
                                      icon: Icons.delete_outline_rounded,
                                      color: AppColor.error,
                                      tooltip: 'Delete',
                                      onTap: () {
                                        if (auth.isManager) {
                                          _confirmDelete(context, ref, c);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                  "Only manager can delete customers"),
                                              backgroundColor: AppColor.error,
                                              behavior: SnackBarBehavior.floating,
                                              action: SnackBarAction(
                                                label: 'OK',
                                                textColor: Colors.white,
                                                onPressed: () => ref
                                                    .read(customerProvider.notifier)
                                                    .clearError(),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 28,
      color: AppColor.grey200,
    );
  }
}