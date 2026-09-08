import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/provider/customer_provider.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/widget/add_customer_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/widget/app_icon.dart';
import '../../../../../core/widget/figure_card_widget.dart';
import '../../data/model/customer_model.dart';
import '../widget/customer_action_button_widget.dart';
import '../widget/customer_empty_state.dart';
import '../widget/customer_filter_chip_widget.dart';
import '../widget/customer_status_badge_widget.dart';
import '../widget/customer_type_badge_widget.dart';

class AllCustomerScreen extends ConsumerStatefulWidget {
  const AllCustomerScreen({super.key});

  @override
  ConsumerState<AllCustomerScreen> createState() => _AllCustomerScreenState();
}

class _AllCustomerScreenState extends ConsumerState<AllCustomerScreen> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  // ── Pagination ───────────────────────────────────────────
  int _page        = 0;      // 0-based current page
  int _rowsPerPage  = 25;
  static const _rowsPerPageChoices = [10, 25, 50, 100];

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

  // ── Sorting ──────────────────────────────────────
  int _compare<T extends Comparable>(T a, T b) {
    return _sortAscending ? a.compareTo(b) : b.compareTo(a);
  }

  List<CustomerModel> _sortedCustomers(List<CustomerModel> customers) {
    if (_sortColumnIndex == null) return customers;

    final sorted = List<CustomerModel>.from(customers);

    sorted.sort((a, b) {
      switch (_sortColumnIndex) {
        case 0: // Code
          return _compare(a.code, b.code);
        case 1: // Name
          return _compare(a.name.toLowerCase(), b.name.toLowerCase());
        case 2: // Phone
          return _compare(a.phone, b.phone);
        case 3: // Address
          return _compare((a.address ?? '').toLowerCase(), (b.address ?? '').toLowerCase());
        case 4: // Type
          return _compare(a.customerType.toString(), b.customerType.toString());
        case 5: // Credit Limit
          return _compare(a.creditLimitLabel, b.creditLimitLabel);
        case 6: // Balance
          return _compare(a.balance, b.balance);
        case 7: // Status
          return _compare(a.isActive ? 1 : 0, b.isActive ? 1 : 0);
        default:
          return 0;
      }
    });

    return sorted;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(customerProvider);
    final allRows   = _sortedCustomers(state.filteredCustomers);
    final auth      = ref.watch(authProvider);

    // ── Page maths ───────────────────────────────────────────
    final totalRows = allRows.length;
    final pageCount = totalRows == 0
        ? 1
        : ((totalRows + _rowsPerPage - 1) ~/ _rowsPerPage);
    final page      = _page.clamp(0, pageCount - 1);
    final startIdx  = page * _rowsPerPage;
    final endIdx    = (startIdx + _rowsPerPage) > totalRows
        ? totalRows
        : startIdx + _rowsPerPage;
    final customers = totalRows == 0
        ? const <CustomerModel>[]
        : allRows.sublist(startIdx, endIdx);

    ref.listen<CustomerState>(customerProvider, (prev, next) {
      // Search / filter badalne par pehle page par wapas
      if (prev != null &&
          (prev.searchQuery  != next.searchQuery ||
           prev.filterStatus != next.filterStatus ||
           prev.filterType   != next.filterType) &&
          _page != 0) {
        setState(() => _page = 0);
      }

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
            icon: const AppIcon('ic_refresh', size: 20, color: AppColor.textSecondary),
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
                icon: const AppIcon('ic_plus_new', size: 18, color: Colors.white),
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
                  iconAsset: 'ic_top_customers',
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Active',
                  value: '${state.activeCount}',
                  iconAsset: 'ic_active_check',
                  color: AppColor.success,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: state.outstandingLabel,
                  value: 'Rs ${state.selectedOutstanding.toStringAsFixed(0)}',
                  iconAsset: 'ic_credit_sale',
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
                        prefixIcon: const AppIcon('ic_search', size: 18, color: AppColor.grey400),
                        prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
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
              child: allRows.isEmpty
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
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          columns: [
                            DataColumn(
                              label: const Text('#'),
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Customer'),
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Phone'),
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Address'),
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Type'),
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Credit Limit'),
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Balance'),
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Status'),
                              onSort: _onSort,
                            ),
                            const DataColumn(label: Text('Actions')),
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
                                // Actions
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [

                                    // Edit — cashier ko nahi dikhega
                                    if (auth.user?.role != 'cashier') ...[
                                      CustomerActionButton(
                                        icon: Icons.edit_outlined,
                                        iconAsset: 'ic_edit',
                                        color: AppColor.primary,
                                        tooltip: 'Edit',
                                        onTap: () => _openDialog(context, customer: c),
                                      ),
                                      const SizedBox(width: 6),
                                    ],

                                    // Delete — cashier ko nahi dikhega
                                    if (auth.user?.role != 'cashier') ...[
                                      CustomerActionButton(
                                        icon: Icons.delete_outline_rounded,
                                        iconAsset: 'ic_delete',
                                        color: AppColor.error,
                                        tooltip: 'Delete',
                                        onTap: () => _confirmDelete(context, ref, c),
                                      ),
                                      const SizedBox(width: 6),
                                    ],

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
                                            child: const AppIcon(
                                              'ic_message',
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

            // ── Pagination bar ───────────────────────
            if (totalRows > 0)
              _buildPaginationBar(
                startIdx:  startIdx,
                endIdx:    endIdx,
                totalRows: totalRows,
                page:      page,
                pageCount: pageCount,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationBar({
    required int startIdx,
    required int endIdx,
    required int totalRows,
    required int page,
    required int pageCount,
  }) {
    final canPrev = page > 0;
    final canNext = page < pageCount - 1;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          children: [
            const Text('Rows per page:',
                style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _rowsPerPage,
              isDense: true,
              underline: const SizedBox.shrink(),
              style: const TextStyle(fontSize: 13, color: AppColor.textPrimary),
              items: _rowsPerPageChoices
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _rowsPerPage = v;
                  _page = 0;
                });
              },
            ),
            const SizedBox(width: 20),
            Text(
              '${startIdx + 1}–$endIdx of $totalRows',
              style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.first_page_rounded, size: 20),
              tooltip: 'First page',
              onPressed: canPrev ? () => setState(() => _page = 0) : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 22),
              tooltip: 'Previous',
              onPressed: canPrev ? () => setState(() => _page = page - 1) : null,
            ),
            Text(
              'Page ${page + 1} of $pageCount',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 22),
              tooltip: 'Next',
              onPressed: canNext ? () => setState(() => _page = page + 1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.last_page_rounded, size: 20),
              tooltip: 'Last page',
              onPressed:
                  canNext ? () => setState(() => _page = pageCount - 1) : null,
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