import 'package:jan_ghani_final/core/widget/branch_ui.dart';
import 'package:jan_ghani_final/core/color/branch_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/branch/branch_info/presentation/provider/branch_provider.dart';
import 'package:jan_ghani_final/features/branch/counter/presentation/provider/counter_provider.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/provider/customer_provider.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/widget/add_customer_dialog.dart';
import 'package:jan_ghani_final/features/branch/permissions/presentation/provider/permissions_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/service/print/customer_ledger_print_service.dart';
import '../../../../../core/widget/app_icon.dart';
import '../../data/model/customer_model.dart';
import '../widget/customer_action_button_widget.dart';
import '../widget/customer_detail_drawer.dart';
import '../widget/customer_empty_state.dart';
import '../widget/customer_filter_chip_widget.dart';
import '../widget/customer_status_badge_widget.dart';
import '../widget/customer_type_badge_widget.dart';

// ── Shortcuts ───────────────────────────────────────────────────
//  F1 / Ctrl+F : search      Ctrl+N : new customer     F5 : refresh
//  Ctrl+1..3   : All / Active / Inactive
//  Ctrl+4..8   : All Types / Walk-in / Credit / Wholesale / Petrol
//  PageUp / PageDown : previous / next page
//  ↑↓ row select, phir:  Enter view   Ctrl+E edit   Ctrl+P print
//                        Ctrl+W WhatsApp   Ctrl+Delete delete
//  Esc : selection clear, phir search clear
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
  static const _rowsPerPageChoices = [10, 25, 50, 100, 500];

  // ── Keyboard ─────────────────────────────────────────────
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'Customer_Search');
  final _selectedKey = GlobalKey();
  String? _selectedId; // arrow keys se select hui row

  @override
  void initState() {
    super.initState();
    // Provider mein pehle se search ho to field mein bhi dikhe.
    _searchCtrl.text = ref.read(customerProvider).searchQuery;
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Screen par abhi jo page dikh raha hai uski rows.
  List<CustomerModel> _pageRows() {
    final all = _sortedCustomers(ref.read(customerProvider).filteredCustomers);
    if (all.isEmpty) return const [];
    final pageCount = (all.length + _rowsPerPage - 1) ~/ _rowsPerPage;
    final start = _page.clamp(0, pageCount - 1) * _rowsPerPage;
    return all.skip(start).take(_rowsPerPage).toList();
  }

  void _moveSelection(int step) {
    final rows = _pageRows();
    if (rows.isEmpty) return;
    final current = rows.indexWhere((c) => c.id == _selectedId);
    final next = current < 0 ? 0 : (current + step).clamp(0, rows.length - 1);
    setState(() => _selectedId = rows[next].id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _selectedKey.currentContext;
      if (!mounted || ctx == null) return;
      // Sirf vertical scroll — horizontal position wahi rahe.
      final box = ctx.findRenderObject();
      final scrollable = Scrollable.maybeOf(ctx, axis: Axis.vertical);
      if (box == null || scrollable == null) return;
      scrollable.position.ensureVisible(box,
          alignment: 0.5, duration: const Duration(milliseconds: 120));
    });
  }

  void _goToPage(int step) {
    final total = ref.read(customerProvider).filteredCustomers.length;
    if (total == 0) return;
    final pageCount = (total + _rowsPerPage - 1) ~/ _rowsPerPage;
    final next = (_page + step).clamp(0, pageCount - 1);
    if (next == _page) return;
    setState(() {
      _page = next;
      _selectedId = null;
    });
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    // Dialog / drawer khula ho ya doosri screen top par ho to kuch na karo.
    if (!(ModalRoute.of(context)?.isCurrent ?? true) ||
        Navigator.of(context, rootNavigator: true).canPop()) {
      return false;
    }

    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isAltPressed) return false; // sidebar shortcuts
    final ctrl = keyboard.isControlPressed;
    final key  = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown && !ctrl) {
      _moveSelection(1);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp && !ctrl) {
      _moveSelection(-1);
      return true;
    }
    if (event is! KeyDownEvent) return false;

    final notifier = ref.read(customerProvider.notifier);

    if (key == LogicalKeyboardKey.f1 ||
        (ctrl && key == LogicalKeyboardKey.keyF)) {
      _searchFocus.requestFocus();
      _searchCtrl.selection = TextSelection(
          baseOffset: 0, extentOffset: _searchCtrl.text.length);
      return true;
    }
    if (key == LogicalKeyboardKey.f5) {
      notifier.loadCustomers();
      return true;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      _goToPage(1);
      return true;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _goToPage(-1);
      return true;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_selectedId != null) {
        setState(() => _selectedId = null);
        return true;
      }
      if (_searchCtrl.text.isNotEmpty) {
        _searchCtrl.clear();
        notifier.onSearchChanged('');
        return true;
      }
      return false;
    }

    final selected =
        _pageRows().where((c) => c.id == _selectedId).firstOrNull;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (selected == null) return false;
      showCustomerDetailDrawer(context, selected);
      return true;
    }
    if (!ctrl) return false;

    final auth  = ref.read(authProvider);
    final perms = ref.read(permissionsProvider);
    bool can(String permission) =>
        perms.isGranted(auth.userId, auth.role, permission);

    if (key == LogicalKeyboardKey.keyN) {
      if (can('customer.create')) _openDialog(context);
      return true;
    }

    final statusKeys = {
      LogicalKeyboardKey.digit1: 'all',
      LogicalKeyboardKey.digit2: 'active',
      LogicalKeyboardKey.digit3: 'inactive',
    };
    final status = statusKeys[key];
    if (status != null) {
      notifier.onFilterStatusChanged(status);
      return true;
    }

    final typeKeys = {
      LogicalKeyboardKey.digit4: 'all',
      LogicalKeyboardKey.digit5: 'walkin',
      LogicalKeyboardKey.digit6: 'credit',
      LogicalKeyboardKey.digit7: 'wholesale',
      LogicalKeyboardKey.digit8: 'petrol',
    };
    final type = typeKeys[key];
    if (type != null) {
      notifier.onFilterTypeChanged(type);
      return true;
    }

    // ── Selected row ke actions ──────────────────────────
    if (selected == null) return false;
    if (key == LogicalKeyboardKey.keyE) {
      if (can('customer.edit')) _openDialog(context, customer: selected);
      return true;
    }
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      if (can('customer.delete')) _confirmDelete(context, ref, selected);
      return true;
    }
    if (key == LogicalKeyboardKey.keyP) {
      _printBalance(context, ref, selected);
      return true;
    }
    if (key == LogicalKeyboardKey.keyW) {
      if (selected.phone.isNotEmpty && selected.balance > 0) {
        _sendWhatsAppReminder(context, selected);
      }
      return true;
    }
    return false;
  }

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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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

  // ── Print Balance ────────────────────────────────────────
  Future<void> _printBalance(BuildContext context, WidgetRef ref, CustomerModel c) async {
    try {
      final auth = ref.read(authProvider);
      final branch = await ref.read(branchProvider(auth.storeId).future);
      final counters = ref.read(counterProvider).counters;
      final counterName = auth.counterId != null
          ? counters.where((cnt) => cnt.id == auth.counterId).map((cnt) => cnt.counterName).firstOrNull ?? 'Counter'
          : 'Counter';

      await CustomerLedgerPrintService.printCustomerBalance(
        storeName:     branch?.name ?? '',
        branchAddress: branch?.address ?? '',
        branchPhone:   branch?.phone ?? '',
        counterName:   counterName,
        customerName:  c.name,
        customerPhone: c.phone,
        balance:       c.balance,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: $e'),
            backgroundColor: AppColor.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
    if (_sortColumnIndex == null) {
      // Default sort: jis customer ka record sabse recently update hua ho
      // wo sabse pehle (top) show ho.
      final sorted = List<CustomerModel>.from(customers);
      sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sorted;
    }

    final sorted = List<CustomerModel>.from(customers);

    sorted.sort((a, b) {
      switch (_sortColumnIndex) {
        case 0: // Name
          return _compare(a.name.toLowerCase(), b.name.toLowerCase());
        case 1: // Phone
          return _compare(a.phone, b.phone);
        case 2: // Address
          return _compare((a.address ?? '').toLowerCase(), (b.address ?? '').toLowerCase());
        case 3: // Type
          return _compare(a.customerType.toString(), b.customerType.toString());
        case 4: // Credit Limit
          return _compare(a.creditLimitLabel, b.creditLimitLabel);
        case 5: // Balance
          return _compare(a.balance, b.balance);
        case 6: // Status
          return _compare(a.isActive ? 1 : 0, b.isActive ? 1 : 0);
        case 7: // Updated At
          return _compare(a.updatedAt, b.updatedAt);
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
      _selectedId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(customerProvider);
    final allRows   = _sortedCustomers(state.filteredCustomers);
    final auth      = ref.watch(authProvider);
    final perms     = ref.watch(permissionsProvider);
    final canEdit   = perms.isGranted(auth.userId, auth.role, 'customer.edit');
    final canDelete = perms.isGranted(auth.userId, auth.role, 'customer.delete');
    final canCreate = perms.isGranted(auth.userId, auth.role, 'customer.create');

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
           prev.filterType   != next.filterType)) {
        setState(() {
          _page = 0;
          _selectedId = null;
        });
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
      appBar: BranchAppBar(
        title:    'Customers',
        subtitle: 'Customers aur un ka baqaya',
        actions: [
          BranchRefreshButton(
              tooltip:   'Refresh (F5)',
              onPressed: () =>
                  ref.read(customerProvider.notifier).loadCustomers()),
          if (canCreate)
            BranchActionButton(
              label:     'New Customer  (Ctrl+N)',
              iconAsset: 'ic_plus_new',
              onPressed: () => _openDialog(context),
            ),
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
                BranchStatCard(
                  title: 'Total Customers',
                  value: '${state.totalCount}',
                  iconAsset: 'ic_top_customers',
                  color: BranchColor.navy,
                ),
                const SizedBox(width: 12),
                BranchStatCard(
                  title: 'Active',
                  value: '${state.activeCount}',
                  iconAsset: 'ic_active_check',
                  color: AppColor.success,
                ),
                const SizedBox(width: 12),
                BranchStatCard(
                  title: state.outstandingLabel,
                  value: branchMoney(state.selectedOutstanding),
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
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: ref.read(customerProvider.notifier).onSearchChanged,
                      style: const TextStyle(fontSize: 13),
                      cursorHeight: 14,
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone, code... (F1)',
                        hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
                        prefixIcon: const AppIcon('ic_search', size: 18, color: AppColor.grey400),
                        prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                        filled:    true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

            const SizedBox(height: 6),
            const Text(
              'F1 search  •  Ctrl+1–3 status  •  Ctrl+4–8 type  •  '
              'PgUp/PgDn page  •  ↑↓ select → Enter view, Ctrl+E edit, '
              'Ctrl+P print, Ctrl+W WhatsApp, Ctrl+Del delete  •  Esc clear',
              style: TextStyle(fontSize: 11, color: AppColor.textSecondary),
            ),
            const SizedBox(height: 10),

            // ── Table + pagination ───────────────────
            Expanded(
              child: BranchTableCard(
                child: Column(
                  children: [
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
                        child: IconTheme.merge(
              // Navy header par sort ka teer safed.
              data: const IconThemeData(color: BranchColor.onHeader),
              child: DataTable(
                          dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return BranchColor.navy.withValues(alpha: 0.05);
                            }
                            return null;
                          }),
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 52,
                          columnSpacing: (tableWidth * 0.025).clamp(16.0, 48.0),
                          headingRowHeight: 46,
                          dividerThickness: 0.6,
                          horizontalMargin: 16,
                          showCheckboxColumn: false,
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          columns: [
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
                              numeric: true,
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Balance'),
                              numeric: true,
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Status'),
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Updated At'),
                              onSort: _onSort,
                            ),
                            const DataColumn(label: Text('Actions')),
                          ],
                          rows: List.generate(customers.length, (i) {
                            final c = customers[i];
                            final hasBalance = c.balance > 0;
                            final hasPhone   = c.phone.isNotEmpty;

                            final isSelected = c.id == _selectedId;

                            return DataRow(
                              color: isSelected
                                  ? WidgetStatePropertyAll(
                                      BranchColor.navy.withValues(alpha: 0.12))
                                  : null,
                              onSelectChanged: (_) =>
                                  setState(() => _selectedId = c.id),
                              cells: [

                                // Name
                                DataCell(GestureDetector(
                                  onTap: () {},
                                  child: Text(c.name,
                                      key: isSelected ? _selectedKey : null,
                                      style: const TextStyle(
                                          color: BranchColor.navy,
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
                                DataCell(BranchAmount(c.balance,
                                    isBold: true,
                                    color: c.balance > 0
                                        ? AppColor.error
                                        : AppColor.info)),

                                // Status
                                DataCell(CustomerStatusBadge(isActive: c.isActive)),

                                // Updated At
                                DataCell(Text(
                                    DateFormat('dd MMM yyyy, hh:mm a')
                                        .format(c.updatedAt.toLocal()),
                                    style: const TextStyle(fontSize: 13))),

                                // Actions
                                // Actions
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [

                                    // View — detail panel + connect QR
                                    CustomerActionButton(
                                      icon: Icons.visibility_outlined,
                                      iconAsset: 'ic_view',
                                      color: AppColor.info,
                                      tooltip: 'View (Enter)',
                                      onTap: () =>
                                          showCustomerDetailDrawer(context, c),
                                    ),
                                    const SizedBox(width: 6),

                                    // Edit — sirf 'customer.edit' permission grant hone par
                                    if (canEdit) ...[
                                      CustomerActionButton(
                                        icon: Icons.edit_outlined,
                                        iconAsset: 'ic_edit',
                                        color: BranchColor.navy,
                                        tooltip: 'Edit (Ctrl+E)',
                                        onTap: () => _openDialog(context, customer: c),
                                      ),
                                      const SizedBox(width: 6),
                                    ],

                                    // Delete — sirf 'customer.delete' permission grant hone par
                                    if (canDelete) ...[
                                      CustomerActionButton(
                                        icon: Icons.delete_outline_rounded,
                                        iconAsset: 'ic_delete',
                                        color: AppColor.error,
                                        tooltip: 'Delete (Ctrl+Del)',
                                        onTap: () => _confirmDelete(context, ref, c),
                                      ),
                                      const SizedBox(width: 6),
                                    ],

                                    // Print — sabhi users ke liye, permission required nahi
                                    CustomerActionButton(
                                      icon: Icons.print_outlined,
                                      iconAsset: 'ic_print',
                                      color: AppColor.textSecondary,
                                      tooltip: 'Print Balance (Ctrl+P)',
                                      onTap: () => _printBalance(context, ref, c),
                                    ),
                                    const SizedBox(width: 6),

                                    // WhatsApp — sirf tab jab phone ho aur balance > 0
                                    if (hasPhone && hasBalance)
                                      Tooltip(
                                        message: 'ادائیگی یاد دہانی بھیجیں (Ctrl+W)',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              tooltip: 'Previous (PgUp)',
              onPressed: canPrev ? () => setState(() => _page = page - 1) : null,
            ),
            Text(
              'Page ${page + 1} of $pageCount',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 22),
              tooltip: 'Next (PgDn)',
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