// Updated on 2026-10-05 03:37 PM
// =============================================================
// all_supplier_screen.dart
// Stitch "Jan Ghani — Suppliers v2" design:
// TopBar · 4 KPI cards (sub-lines) · toolbar (search, status tabs +
// counts, balance filter, sort, refresh) · table (supplier, phone &
// code, orders, total purchase, balance, status, ⋮ menu) · footer
// (filtered summary + pagination)
// ⋮ menu: Pay (sirf baqaya par) · Detail / Ledger · Edit · Delete
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/provider/supplier_provider/supplier_provider.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/screens/specific_supplier_detail_screen/specific_supplier_detail_screen.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/widgets/add_supplier_dialog.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/widgets/edit_supplier_dialog/edit_supplier_dialog.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/widgets/pay_outstanding_dialog/pay_outstanding_dialog.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/widgets/supplier_widgets.dart';

// Table column flex — header + row dono yahi use karte hain
const int    _kColSupplier = 4;
const int    _kColPhone    = 2;
const int    _kColOrders   = 1;
const int    _kColPurchase = 2;
const int    _kColBalance  = 2;
const int    _kColStatus   = 2;
const double _kColActions  = 64;

class AllSupplierScreen extends ConsumerWidget {
  const AllSupplierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(supplierProvider);
    final notifier = ref.read(supplierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColor.grey100,
      body: state.isLoading && state.allSuppliers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(onAddTap: () => showAddDialog(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                _StatsRow(state: state),
                const SizedBox(height: 16),
                _Toolbar(
                  state:     state,
                  onSearch:  notifier.onSearchChanged,
                  onFilter:  notifier.onFilterChanged,
                  onBalance: notifier.onBalanceFilterChanged,
                  onSort:    notifier.onSortChanged,
                  onRefresh: notifier.loadSuppliers,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _SupplierTable(
                state:      state,
                onOpen:     (s) => _openDetail(context, ref, s),
                onPay:      (s) => PayOutstandingDialog.show(context, s),
                onEdit:     (s) => _showEditDialog(context, s),
                onDelete:   (s) => _showDeleteConfirm(context, ref, s),
                onPage:     notifier.onPageChanged,
                onPageSize: notifier.onPageSizeChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Detail / Ledger screen — wapsi par list refresh ─────────
  void _openDetail(BuildContext context, WidgetRef ref, SupplierModel s) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpecificSupplierDetailScreen(supplier: s),
      ),
    ).then((_) {
      ref.read(supplierProvider.notifier).loadSuppliers();
    });
  }

  // ── Add dialog ──────────────────────────────────────────────
  void showAddDialog(BuildContext context) {
    showDialog(
      context:     context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:     (_) => const AddSupplierDialog(),
    );
  }

  // ── Edit dialog ─────────────────────────────────────────────
  void _showEditDialog(BuildContext context, SupplierModel supplier) {
    EditSupplierDialog.show(context, supplier);
  }

  // ── Delete confirm dialog ───────────────────────────────────
  void _showDeleteConfirm(
      BuildContext context, WidgetRef ref, SupplierModel supplier) {
    showDialog(
      context:     context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding:    const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:        AppColor.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      color: AppColor.error, size: 28),
                ),
                const SizedBox(height: 16),

                // Title
                Text('Supplier Delete Karen?',
                    style: TextStyle(
                        fontSize:   17,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.textPrimary)),
                const SizedBox(height: 8),

                // Supplier name
                Text(
                  '"${supplier.name}"',
                  style: TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.error),
                ),
                const SizedBox(height: 6),

                Text(
                  'Yeh supplier soft-delete ho jaye ga.\nPurchase history mehfooz rahegi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AppColor.textSecondary),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColor.textSecondary,
                          side: BorderSide(color: AppColor.grey300),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Delete confirm
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref
                              .read(supplierProvider.notifier)
                              .deleteSupplier(supplier.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Delete',
                            style: TextStyle(
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onAddTap;
  const _TopBar({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color:  AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.local_shipping_outlined,
                size: 20, color: AppColor.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suppliers',
                    style: TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.textPrimary)),
                Text('Apne suppliers aur unka baqaya manage karein',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, color: AppColor.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onAddTap,
            icon:      const Icon(Icons.add_rounded, size: 18),
            label:     const Text('New Supplier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              minimumSize:   Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATS ROW — values pehle wale getters se, sub-lines list se
// ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final SupplierState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    int newThisMonth = 0, totalOrders = 0, dueCount = 0;
    for (final s in state.allSuppliers) {
      if (s.deletedAt != null) continue;
      final c = s.createdAt.toLocal();
      if (c.year == now.year && c.month == now.month) newThisMonth++;
      totalOrders += s.totalOrders;
      if (s.hasDue) dueCount++;
    }
    final inactive = state.totalCount - state.activeCount;

    return Row(
      children: [
        _StatCard(
            label:    'Total Suppliers',
            value:    '${state.totalCount}',
            subtitle: '$newThisMonth naye is mahine',
            icon:     Icons.groups_outlined,
            color:    AppColor.primary),
        const SizedBox(width: 14),
        _StatCard(
            label:    'Active Suppliers',
            value:    '${state.activeCount}',
            subtitle: '$inactive inactive',
            icon:     Icons.verified_outlined,
            color:    AppColor.success,
            subtitleColor: AppColor.textSecondary),
        const SizedBox(width: 14),
        _StatCard(
            label:    'Total Purchase',
            value:    'Rs ${state.totalPurchased.pkrFormat}',
            subtitle: '$totalOrders purchase orders',
            icon:     Icons.payments_outlined,
            color:    AppColor.info,
            subtitleColor: AppColor.textSecondary),
        const SizedBox(width: 14),
        _StatCard(
            label:    'Total Due (Baqaya)',
            value:    'Rs ${state.totalOutstanding.pkrFormat}',
            subtitle: dueCount == 0
                ? 'Koi baqaya nahi'
                : '$dueCount suppliers ko dena hai',
            icon:     Icons.account_balance_wallet_outlined,
            color:    AppColor.error,
            highlight: dueCount > 0),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final String   subtitle;
  final IconData icon;
  final Color    color;
  final Color?   subtitleColor;
  final bool     highlight; // laal tint (baqaya card)

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.subtitleColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: highlight ? AppColor.errorLight.withOpacity(0.5) : AppColor.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: highlight ? color.withOpacity(0.3) : AppColor.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize:      11,
                          fontWeight:    FontWeight.w600,
                          letterSpacing: 0.6,
                          color: highlight ? color : AppColor.textSecondary)),
                ),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit:       BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize:   22,
                      fontWeight: FontWeight.w700,
                      color: highlight ? color : AppColor.textPrimary)),
            ),
            const SizedBox(height: 2),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w500,
                    color:      subtitleColor ?? color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOOLBAR — search · status tabs · balance · sort · refresh
// ─────────────────────────────────────────────────────────────

class _Toolbar extends StatefulWidget {
  final SupplierState         state;
  final ValueChanged<String>  onSearch;
  final ValueChanged<String>  onFilter;
  final ValueChanged<String>  onBalance;
  final ValueChanged<String>  onSort;
  final Future<void> Function() onRefresh;

  const _Toolbar({
    required this.state,
    required this.onSearch,
    required this.onFilter,
    required this.onBalance,
    required this.onSort,
    required this.onRefresh,
  });

  @override
  State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  late final TextEditingController _controller;

  static const _statuses = [
    ('All',      'all'),
    ('Active',   'active'),
    ('Inactive', 'inactive'),
  ];
  static const _balanceLabels = {
    'all':   'All',
    'due':   'Baqaya hai',
    'clear': 'Clear',
  };
  static const _sortLabels = {
    'due_desc':      'Sabse zyada baqaya',
    'purchase_desc': 'Sabse zyada purchase',
    'name':          'Naam (A–Z)',
    'newest':        'Naye pehle',
  };

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.searchQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st     = widget.state;
    final counts = st.statusCounts;

    final search = SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        onChanged: (q) {
          widget.onSearch(q);
          setState(() {});
        },
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText:  'Name, company, phone, address se search...',
          hintStyle: TextStyle(color: AppColor.textHint, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded,
              color: AppColor.grey400, size: 18),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            onPressed: () {
              _controller.clear();
              widget.onSearch('');
              setState(() {});
            },
          )
              : null,
          filled:         true,
          fillColor:      AppColor.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:   BorderSide(color: AppColor.grey300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:   BorderSide(color: AppColor.grey300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppColor.primary, width: 1.5)),
        ),
      ),
    );

    final tabs = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color:        AppColor.grey100,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, value) in _statuses)
            _StatusTab(
              label:    label,
              count:    counts[value] ?? 0,
              selected: st.filterStatus == value,
              onTap:    () => widget.onFilter(value),
            ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 12),
          tabs,
          const SizedBox(width: 12),
          _MenuField<String>(
            tooltip:  'Balance filter',
            text:     'Balance: ${_balanceLabels[st.filterBalance]}',
            active:   st.filterBalance != 'all',
            selected: st.filterBalance,
            options:  _balanceLabels,
            onSelected: widget.onBalance,
          ),
          const SizedBox(width: 8),
          _MenuField<String>(
            tooltip:  'Sort',
            text:     'Sort: ${_sortLabels[st.sortBy]}',
            icon:     Icons.sort_rounded,
            selected: st.sortBy,
            options:  _sortLabels,
            onSelected: widget.onSort,
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Refresh',
            child: InkWell(
              onTap:        widget.onRefresh,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border:       Border.all(color: AppColor.grey300),
                ),
                child: st.isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(Icons.refresh_rounded,
                    size: 18, color: AppColor.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String       label;
  final int          count;
  final bool         selected;
  final VoidCallback onTap;

  const _StatusTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? AppColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text('$label ($count)',
            style: TextStyle(
              fontSize:   12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColor.white : AppColor.textSecondary,
            )),
      ),
    );
  }
}

/// Dropdown jaisa field — PopupMenu se options
class _MenuField<T> extends StatelessWidget {
  final String           tooltip;
  final String           text;
  final IconData?        icon;
  final bool             active;
  final T                selected;
  final Map<T, String>   options;
  final ValueChanged<T>  onSelected;

  const _MenuField({
    required this.tooltip,
    required this.text,
    this.icon,
    this.active = false,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip:    tooltip,
      onSelected: onSelected,
      offset:     const Offset(0, 44),
      color:      AppColor.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColor.grey200)),
      itemBuilder: (_) => [
        for (final e in options.entries)
          CheckedPopupMenuItem<T>(
            value:   e.key,
            checked: e.key == selected,
            child:   Text(e.value, style: const TextStyle(fontSize: 13)),
          ),
      ],
      child: Container(
        height:  40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active
              ? AppColor.primary.withOpacity(0.05) : AppColor.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active
                  ? AppColor.primary.withOpacity(0.5) : AppColor.grey300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                style: TextStyle(
                    fontSize:   13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? AppColor.primary : AppColor.textPrimary)),
            const SizedBox(width: 6),
            Icon(icon ?? Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColor.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUPPLIER TABLE
// ─────────────────────────────────────────────────────────────

class _SupplierTable extends StatefulWidget {
  final SupplierState               state;
  final ValueChanged<SupplierModel> onOpen;
  final ValueChanged<SupplierModel> onPay;
  final ValueChanged<SupplierModel> onEdit;
  final ValueChanged<SupplierModel> onDelete;
  final ValueChanged<int>           onPage;
  final ValueChanged<int>           onPageSize;

  const _SupplierTable({
    required this.state,
    required this.onOpen,
    required this.onPay,
    required this.onEdit,
    required this.onDelete,
    required this.onPage,
    required this.onPageSize,
  });

  @override
  State<_SupplierTable> createState() => _SupplierTableState();
}

class _SupplierTableState extends State<_SupplierTable> {
  static const double _minWidth = 960;
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st       = widget.state;
    final filtered = st.filteredSuppliers;

    // Pagination — page list se bahar na jaye (delete/filter ke baad)
    final pageCount = filtered.isEmpty
        ? 1 : ((filtered.length - 1) ~/ st.pageSize) + 1;
    final page  = st.page.clamp(0, pageCount - 1);
    final start = page * st.pageSize;
    final end   = (start + st.pageSize).clamp(0, filtered.length);
    final rows  = filtered.isEmpty
        ? const <SupplierModel>[] : filtered.sublist(start, end);

    return Container(
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = constraints.maxWidth >= _minWidth
                      ? constraints.maxWidth
                      : _minWidth;

                  return Scrollbar(
                    controller:      _hScroll,
                    thumbVisibility: constraints.maxWidth < _minWidth,
                    child: SingleChildScrollView(
                      controller:      _hScroll,
                      scrollDirection: Axis.horizontal,
                      physics:         const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          children: [
                            const _TableHeader(),
                            Expanded(
                              child: rows.isEmpty
                                  ? SupplierEmptyState(
                                isSearching: st.searchQuery.isNotEmpty ||
                                    st.filterStatus != 'all' ||
                                    st.filterBalance != 'all',
                              )
                                  : ListView.builder(
                                itemCount:  rows.length,
                                itemExtent: 65,
                                itemBuilder: (_, i) {
                                  final s = rows[i];
                                  return Column(
                                    children: [
                                      SizedBox(
                                        height: 64,
                                        child: _SupplierRow(
                                          key:      ValueKey(s.id),
                                          supplier: s,
                                          onOpen:   () => widget.onOpen(s),
                                          onPay:    () => widget.onPay(s),
                                          onEdit:   () => widget.onEdit(s),
                                          onDelete: () => widget.onDelete(s),
                                        ),
                                      ),
                                      Divider(height: 1, color: AppColor.grey100),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _TableFooter(
              filtered:   filtered,
              shown:      rows.length,
              start:      start,
              page:       page,
              pageCount:  pageCount,
              pageSize:   st.pageSize,
              onPage:     widget.onPage,
              onPageSize: widget.onPageSize,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TABLE HEADER
// ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height:  46,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color:  const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: const Row(
        children: [
          _TH(label: 'SUPPLIER',       flex: _kColSupplier),
          _TH(label: 'PHONE & CODE',   flex: _kColPhone),
          _TH(label: 'ORDERS',         flex: _kColOrders,   align: TextAlign.right),
          _TH(label: 'TOTAL PURCHASE', flex: _kColPurchase, align: TextAlign.right),
          _TH(label: 'BALANCE',        flex: _kColBalance,  align: TextAlign.right),
          SizedBox(width: 28),
          _TH(label: 'STATUS',         flex: _kColStatus),
          SizedBox(
            width: _kColActions,
            child: Text('ACTIONS', textAlign: TextAlign.right, style: _TH.style),
          ),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String    label;
  final int       flex;
  final TextAlign align;

  const _TH({
    required this.label,
    required this.flex,
    this.align = TextAlign.left,
  });

  static const style = TextStyle(
      fontSize:      11,
      fontWeight:    FontWeight.w600,
      color:         AppColor.textSecondary,
      letterSpacing: 0.6);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex:  flex,
      child: Text(label, textAlign: align, style: style),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TABLE ROW
// ─────────────────────────────────────────────────────────────

class _SupplierRow extends StatefulWidget {
  final SupplierModel supplier;
  final VoidCallback  onOpen;
  final VoidCallback  onPay;
  final VoidCallback  onEdit;
  final VoidCallback  onDelete;

  const _SupplierRow({
    required super.key,
    required this.supplier,
    required this.onOpen,
    required this.onPay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SupplierRow> createState() => _SupplierRowState();
}

class _SupplierRowState extends State<_SupplierRow> {
  bool _isHovered = false;

  @override
  void deactivate() {
    _isHovered = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final s        = widget.supplier;
    final hasComp  = s.companyName?.isNotEmpty ?? false;
    final title    = hasComp ? s.companyName! : s.name;
    final person   = hasComp
        ? s.name
        : ((s.contactPerson?.isNotEmpty ?? false) ? s.contactPerson! : null);
    final address  = (s.address?.trim().isNotEmpty ?? false)
        ? s.address!.trim() : null;
    final subtitle = [person, address].whereType<String>().join('  •  ');

    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      cursor:          SystemMouseCursors.click,
      onEnter: (_) { if (mounted) setState(() => _isHovered = true);  },
      onExit:  (_) { if (mounted) setState(() => _isHovered = false); },
      child: GestureDetector(
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _isHovered
              ? AppColor.primary.withOpacity(0.03)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Opacity(
            opacity: s.isActive ? 1.0 : 0.6,
            child: Row(
              children: [
                // ── Supplier ──────────────────────────────
                Expanded(
                  flex: _kColSupplier,
                  child: Row(
                    children: [
                      _Avatar(text: title),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          mainAxisAlignment:  MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize:   14,
                                    fontWeight: FontWeight.w600,
                                    color:      AppColor.textPrimary)),
                            if (subtitle.isNotEmpty)
                              Text(subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:    AppColor.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Phone & code ──────────────────────────
                Expanded(
                  flex: _kColPhone,
                  child: Column(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.phone.isEmpty ? '—' : s.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color:    AppColor.textPrimary)),
                      if (s.code?.isNotEmpty ?? false)
                        Text(s.code!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11,
                                color:    AppColor.textHint)),
                    ],
                  ),
                ),

                // ── Orders ────────────────────────────────
                Expanded(
                  flex: _kColOrders,
                  child: Text('${s.totalOrders}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 13,
                          color:    AppColor.textPrimary)),
                ),

                // ── Total purchase ────────────────────────
                Expanded(
                  flex: _kColPurchase,
                  child: Text('Rs ${s.totalPurchaseAmount.pkrFormat}',
                      textAlign: TextAlign.right,
                      maxLines:  1,
                      overflow:  TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize:   13.5,
                          fontWeight: FontWeight.w600,
                          color:      AppColor.textPrimary)),
                ),

                // ── Balance ───────────────────────────────
                Expanded(
                  flex: _kColBalance,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _BalanceCell(supplier: s),
                  ),
                ),
                const SizedBox(width: 28),

                // ── Status ────────────────────────────────
                Expanded(
                  flex: _kColStatus,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusPill(isActive: s.isActive),
                  ),
                ),

                // ── ⋮ menu ────────────────────────────────
                SizedBox(
                  width: _kColActions,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _RowMenu(
                      supplier: s,
                      onPay:    widget.onPay,
                      onOpen:   widget.onOpen,
                      onEdit:   widget.onEdit,
                      onDelete: widget.onDelete,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String text;
  const _Avatar({required this.text});

  static String _initials(String t) {
    final parts = t.trim().split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static const _bg = [
    Color(0xFFEEEDFE), Color(0xFFE6F1FB),
    Color(0xFFEAF3DE), Color(0xFFFAEEDA),
    Color(0xFFFCEBEB),
  ];
  static const _fg = [
    Color(0xFF534AB7), Color(0xFF185FA5),
    Color(0xFF3B6D11), Color(0xFF633806),
    Color(0xFFA32D2D),
  ];

  @override
  Widget build(BuildContext context) {
    final ini = _initials(text);
    final i   = ini.codeUnitAt(0) % _bg.length;
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color:        _bg[i],
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(ini,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: _fg[i])),
    );
  }
}

class _BalanceCell extends StatelessWidget {
  final SupplierModel supplier;
  const _BalanceCell({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final b = supplier.outstandingBalance;

    if (b > 0) {
      return Column(
        mainAxisAlignment:  MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Rs ${b.pkrFormat}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                  color:      AppColor.error)),
          Text('BAQAYA DUE',
              style: TextStyle(
                  fontSize:      9.5,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.5,
                  color:         AppColor.error)),
        ],
      );
    }

    if (b < 0) {
      // Supplier ko zyada de diya — advance
      return Column(
        mainAxisAlignment:  MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Rs ${b.abs().pkrFormat}',
              style: TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                  color:      AppColor.info)),
          Text('ADVANCE',
              style: TextStyle(
                  fontSize:      9.5,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.5,
                  color:         AppColor.info)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color:        AppColor.successLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Clear',
              style: TextStyle(
                  fontSize:   11.5,
                  fontWeight: FontWeight.w600,
                  color:      AppColor.success)),
          const SizedBox(width: 3),
          Icon(Icons.check_rounded, size: 13, color: AppColor.success),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final fg = isActive ? AppColor.success : AppColor.grey600;
    final bg = isActive ? AppColor.successLight : AppColor.grey100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: fg)),
          const SizedBox(width: 5),
          Text(isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

// ── ⋮ menu: Pay · Detail / Ledger · Edit · Delete ────────────

class _RowMenu extends StatelessWidget {
  final SupplierModel supplier;
  final VoidCallback  onPay;
  final VoidCallback  onOpen;
  final VoidCallback  onEdit;
  final VoidCallback  onDelete;

  const _RowMenu({
    required this.supplier,
    required this.onPay,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip:     'Actions',
      offset:      const Offset(0, 38),
      color:       AppColor.surface,
      constraints: const BoxConstraints(minWidth: 220),
      icon: Icon(Icons.more_vert_rounded, size: 20, color: AppColor.grey600),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColor.grey200)),
      onSelected: (v) {
        switch (v) {
          case 'pay':    onPay();    break;
          case 'open':   onOpen();   break;
          case 'edit':   onEdit();   break;
          case 'delete': onDelete(); break;
        }
      },
      itemBuilder: (_) => [
        if (supplier.hasDue)
          _item('pay', Icons.account_balance_wallet_outlined,
              'Pay karein', AppColor.success),
        _item('open', Icons.visibility_outlined,
            'Detail / Ledger dekhein', AppColor.textPrimary),
        _item('edit', Icons.edit_outlined,
            'Edit karein', AppColor.textPrimary),
        const PopupMenuDivider(height: 8),
        _item('delete', Icons.delete_outline_rounded,
            'Delete', AppColor.error),
      ],
    );
  }

  PopupMenuItem<String> _item(
      String v, IconData icon, String label, Color color) =>
      PopupMenuItem<String>(
        value:  v,
        height: 40,
        child: Row(
          children: [
            Icon(icon, size: 17,
                color: color == AppColor.textPrimary
                    ? AppColor.textSecondary : color),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize:   13.5,
                    fontWeight: FontWeight.w500,
                    color:      color)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// TABLE FOOTER — count · filtered summary · pagination
// ─────────────────────────────────────────────────────────────

class _TableFooter extends StatelessWidget {
  final List<SupplierModel> filtered;
  final int                 shown;
  final int                 start;
  final int                 page;
  final int                 pageCount;
  final int                 pageSize;
  final ValueChanged<int>   onPage;
  final ValueChanged<int>   onPageSize;

  const _TableFooter({
    required this.filtered,
    required this.shown,
    required this.start,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.onPage,
    required this.onPageSize,
  });

  @override
  Widget build(BuildContext context) {
    final total = filtered.length;
    double sumPurchase = 0, sumDue = 0;
    for (final s in filtered) {
      sumPurchase += s.totalPurchaseAmount;
      if (s.hasDue) sumDue += s.outstandingBalance;
    }

    final muted = TextStyle(fontSize: 12.5, color: AppColor.textSecondary);
    final bold  = TextStyle(fontSize: 12.5,
        fontWeight: FontWeight.w700, color: AppColor.textPrimary);

    final countText = Text.rich(TextSpan(style: muted, children: [
      const TextSpan(text: 'Showing '),
      TextSpan(text: total == 0 ? '0' : '${start + 1}–${start + shown}',
          style: bold),
      const TextSpan(text: ' of '),
      TextSpan(text: '$total', style: bold),
      const TextSpan(text: ' suppliers'),
    ]));

    final summary = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color:        AppColor.grey100,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Text.rich(TextSpan(style: muted, children: [
        const TextSpan(text: 'Total Purchase: '),
        TextSpan(text: 'Rs ${sumPurchase.pkrFormat}', style: bold),
        const TextSpan(text: '   ·   Baqaya: '),
        TextSpan(text: 'Rs ${sumDue.pkrFormat}',
            style: bold.copyWith(color: AppColor.error)),
      ])),
    );

    final pager = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Show:', style: muted),
        const SizedBox(width: 8),
        PopupMenuButton<int>(
          tooltip:    'Rows per page',
          onSelected: onPageSize,
          color:      AppColor.surface,
          itemBuilder: (_) => [
            for (final n in const [25, 50, 100])
              CheckedPopupMenuItem<int>(
                value:   n,
                checked: n == pageSize,
                child:   Text('$n', style: const TextStyle(fontSize: 13)),
              ),
          ],
          child: Container(
            height:  32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border:       Border.all(color: AppColor.grey300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$pageSize', style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: AppColor.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        _PageBtn(
          icon:  Icons.chevron_left_rounded,
          onTap: page > 0 ? () => onPage(page - 1) : null,
        ),
        for (final p in _pages())
          p == -1
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('…', style: muted),
          )
              : _PageBtn(
            label:    '${p + 1}',
            selected: p == page,
            onTap:    () => onPage(p),
          ),
        _PageBtn(
          icon:  Icons.chevron_right_rounded,
          onTap: page < pageCount - 1 ? () => onPage(page + 1) : null,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColor.grey200))),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 1000) {
            return Row(
              children: [
                countText,
                const Spacer(),
                summary,
                const Spacer(),
                pager,
              ],
            );
          }
          return SizedBox(
            width: double.infinity,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing:            16,
              runSpacing:         8,
              children: [countText, summary, pager],
            ),
          );
        },
      ),
    );
  }

  /// 1 … (page-1) page (page+1) … last — -1 = ellipsis
  List<int> _pages() {
    if (pageCount <= 7) return List.generate(pageCount, (i) => i);
    final set = <int>{0, pageCount - 1, page - 1, page, page + 1}
      ..removeWhere((p) => p < 0 || p >= pageCount);
    final sorted = set.toList()..sort();
    final out = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) out.add(-1);
      out.add(sorted[i]);
    }
    return out;
  }
}

class _PageBtn extends StatelessWidget {
  final String?       label;
  final IconData?     icon;
  final bool          selected;
  final VoidCallback? onTap;

  const _PageBtn({
    this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          constraints: const BoxConstraints(minWidth: 32),
          height:      32,
          padding:     const EdgeInsets.symmetric(horizontal: 8),
          alignment:   Alignment.center,
          decoration: BoxDecoration(
            color:        selected ? AppColor.primary : AppColor.surface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
                color: selected ? AppColor.primary : AppColor.grey300),
          ),
          child: icon != null
              ? Icon(icon, size: 18,
              color: disabled ? AppColor.grey400 : AppColor.textPrimary)
              : Text(label!,
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColor.white : AppColor.textPrimary)),
        ),
      ),
    );
  }
}
