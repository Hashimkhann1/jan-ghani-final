import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/provider/customer_provider.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/widget/add_customer_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Customer Delete Karein?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('"${customer.name}" ko permanently delete karna chahte hain?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              ref.read(customerProvider.notifier).deleteCustomer(customer.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── WhatsApp Reminder ──────────────────────────────────────
  Future<void> _sendWhatsAppReminder(BuildContext context, CustomerModel c) async {
    final name    = c.name;
    final balance = c.balance.toStringAsFixed(0);

    final message =
        'السلام علیکم $name صاحب،\n\n'
        'امید ہے آپ بالکل ٹھیک ہوں گے۔\n\n'
        '*جان غنی اسٹور* کی طرف سے گزارش ہے کہ '
        'آپ کے اکاؤنٹ میں ابھی *Rs $balance* کا بقایا جات موجود ہے۔\n\n'
        'مہربانی فرما کر جلد از جلد کچھ رقم جمع کروائیں تاکہ '
        'آپ کا اکاؤنٹ درست رہے اور آپ کو مزید سہولت مل سکے۔\n\n'
        'شکریہ 🙏\n'
        '*جان غنی اسٹور*';

    final phone     = c.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final intlPhone = phone.startsWith('0') ? '92${phone.substring(1)}' : phone;
    final encoded   = Uri.encodeComponent(message);

    // Desktop ke liye WhatsApp Web
    final url = Uri.parse('whatsapp://send?phone=$intlPhone&text=$encoded');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp Web nahi khul raha'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state     = ref.watch(customerProvider);
    final customers = state.filteredCustomers;
    final auth      = ref.watch(authProvider);

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
              onPressed: () => ref.read(customerProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers', style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: () => ref.read(customerProvider.notifier).loadCustomers(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 4),
          IntrinsicWidth(
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
          ),
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
                  title: state.outstandingLabel,
                  value: 'Rs ${state.selectedOutstanding.toStringAsFixed(0)}',
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
                      onChanged: ref.read(customerProvider.notifier).onSearchChanged,
                      style: const TextStyle(fontSize: 13),
                      cursorHeight: 14,
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone, code...',
                        hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppColor.grey400),
                        filled:    true,
                        fillColor: AppColor.grey100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    onTap: ref.read(customerProvider.notifier).onFilterStatusChanged,
                  ),
                  const SizedBox(width: 6),
                  CustomerFilterChip(
                    label: 'Active',
                    value: 'active',
                    selectedValue: state.filterStatus,
                    onTap: ref.read(customerProvider.notifier).onFilterStatusChanged,
                  ),
                  const SizedBox(width: 6),
                  CustomerFilterChip(
                    label: 'Inactive',
                    value: 'inactive',
                    selectedValue: state.filterStatus,
                    onTap: ref.read(customerProvider.notifier).onFilterStatusChanged,
                  ),

                  const SizedBox(width: 16),
                  const _VerticalDivider(),
                  const SizedBox(width: 16),

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
                  const SizedBox(width: 6),
                  CustomerFilterChip(
                    label: 'Petrol',
                    value: 'petrol',
                    selectedValue: state.filterType,
                    onTap: ref.read(customerProvider.notifier).onFilterTypeChanged,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Table ────────────────────────────────
            Expanded(
              child: customers.isEmpty
                  ? CustomerEmptyState(isSearching: state.searchQuery.isNotEmpty)
                  : LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  const double minTableWidth = 1050;
                  final tableWidth = availableWidth > minTableWidth
                      ? availableWidth
                      : minTableWidth;

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
                          columnSpacing: (tableWidth * 0.025).clamp(16.0, 48.0),
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
                            final hasBalance = c.balance > 0;
                            final hasPhone   = c.phone.isNotEmpty;

                            return DataRow(
                              onSelectChanged: (_) {},
                              cells: [

                                // # Code
                                DataCell(Text(c.code,
                                    style: const TextStyle(
                                        color: AppColor.textSecondary, fontSize: 12))),

                                // Name
                                DataCell(GestureDetector(
                                  onTap: () {},
                                  child: Text(c.name,
                                      style: const TextStyle(
                                          color: AppColor.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                )),

                                // Phone
                                DataCell(Text(c.phone,
                                    style: const TextStyle(fontSize: 13))),

                                // Address
                                DataCell(SizedBox(
                                  width: 150,
                                  child: Text(
                                    c.address ?? '—',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                )),

                                // Type
                                DataCell(CustomerTypeBadge(customerType: c.customerType)),

                                // Credit Limit
                                DataCell(Text(c.creditLimitLabel,
                                    style: const TextStyle(fontSize: 13))),

                                // Balance
                                DataCell(Text(c.balance.toString(),
                                    style: const TextStyle(fontSize: 13))),

                                // Status
                                DataCell(CustomerStatusBadge(isActive: c.isActive)),

                                // Actions
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [

                                    // Edit
                                    CustomerActionButton(
                                      icon: Icons.edit_outlined,
                                      color: AppColor.primary,
                                      tooltip: 'Edit',
                                      onTap: () => _openDialog(context, customer: c),
                                    ),
                                    const SizedBox(width: 6),

                                    // Delete
                                    CustomerActionButton(
                                      icon: Icons.delete_outline_rounded,
                                      color: AppColor.error,
                                      tooltip: 'Delete',
                                      onTap: () => _confirmDelete(context, ref, c),
                                    ),
                                    const SizedBox(width: 6),

                                    // WhatsApp — sirf tab jab phone ho aur balance > 0
                                    if (hasPhone && hasBalance)
                                      Tooltip(
                                        message: 'ادائیگی یاد دہانی بھیجیں',
                                        child: InkWell(
                                          onTap: () => _sendWhatsAppReminder(context, c),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF25D366).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFF25D366).withOpacity(0.3),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.chat,
                                              size: 16,
                                              color: Color(0xFF25D366),
                                            ),
                                          ),
                                        ),
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
    return Container(width: 1, height: 28, color: AppColor.grey200);
  }
}