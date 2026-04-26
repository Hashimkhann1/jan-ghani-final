// =============================================================
// all_supplier_screen.dart
// Delete confirm dialog + Edit dialog connected
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/provider/supplier_provider/supplier_provider.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/screens/specific_supplier_detail_screen/specific_supplier_detail_screen.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/widgets/add_supplier_dialog.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/widgets/edit_supplier_dialog/edit_supplier_dialog.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/widgets/supplier_widgets.dart';

class AllSupplierScreen extends ConsumerWidget {
  const AllSupplierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(supplierProvider);
    final notifier = ref.read(supplierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _TopBar(onAddTap: () => showAddDialog(context)),
          _StatsRow(state: state),
          _SearchFilterBar(
            searchQuery:    state.searchQuery,
            selectedFilter: state.filterStatus,
            onSearch:       notifier.onSearchChanged,
            onFilter:       notifier.onFilterChanged,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.filteredSuppliers.isEmpty
                ? SupplierEmptyState(
              isSearching: state.searchQuery.isNotEmpty ||
                  state.filterStatus != 'all',
            )
                : _SupplierTable(
              suppliers: state.filteredSuppliers,
              onDelete:  (s) => _showDeleteConfirm(context, ref, s),
              onEdit:    (s) => _showEditDialog(context, s),
              ref:       ref,
            ),
          ),
        ],
      ),
    );
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
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color:   AppColor.surface,
      child: Row(
        children: [
          Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suppliers',
                  style: TextStyle(
                      fontSize:   22,
                      fontWeight: FontWeight.w700,
                      color:      AppColor.textPrimary)),
              Text('Apne suppliers manage karein',
                  style: TextStyle(
                      fontSize: 13, color: AppColor.textSecondary)),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onAddTap,
            icon:      const Icon(Icons.add_rounded, size: 18),
            label:     const Text('New Supplier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 17),
              minimumSize:   Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final SupplierState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   AppColor.surface,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          SupplierStatCard(
              label: 'Total Suppliers',
              value: '${state.totalCount}',
              icon:  Icons.people_outline_rounded,
              color: AppColor.primary),
          const SizedBox(width: 12),
          SupplierStatCard(
              label: 'Active',
              value: '${state.activeCount}',
              icon:  Icons.check_circle_outline_rounded,
              color: AppColor.success),
          const SizedBox(width: 12),
          SupplierStatCard(
              label: 'Total Purchase',
              value: _fmt(state.totalPurchased),
              icon:  Icons.shopping_cart_outlined,
              color: AppColor.info),
          const SizedBox(width: 12),
          SupplierStatCard(
              label: 'Total Due',
              value: _fmt(state.totalOutstanding),
              icon:  Icons.account_balance_wallet_outlined,
              color: AppColor.warning),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────
// SEARCH + FILTER BAR
// ─────────────────────────────────────────────────────────────

class _SearchFilterBar extends StatefulWidget {
  final String               searchQuery;
  final String               selectedFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onFilter;

  const _SearchFilterBar({
    required this.searchQuery,
    required this.selectedFilter,
    required this.onSearch,
    required this.onFilter,
  });

  @override
  State<_SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<_SearchFilterBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 440,
            height: 42,
            child: TextField(
              controller: _controller,
              onChanged:  widget.onSearch,
              decoration: InputDecoration(
                hintText:  'Name, phone, address se search karein...',
                hintStyle: TextStyle(
                    color: AppColor.textHint, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColor.grey400, size: 20),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearch('');
                    setState(() {});
                  },
                )
                    : null,
                filled:         true,
                fillColor:      AppColor.surface,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColor.grey200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColor.grey200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppColor.primary, width: 1.5)),
              ),
            ),
          ),
          const Spacer(),
          SupplierFilterChip(
              label:         'All',
              value:         'all',
              selectedValue: widget.selectedFilter,
              onTap:         widget.onFilter),
          const SizedBox(width: 6),
          SupplierFilterChip(
              label:         'Active',
              value:         'active',
              selectedValue: widget.selectedFilter,
              onTap:         widget.onFilter),
          const SizedBox(width: 6),
          SupplierFilterChip(
              label:         'Inactive',
              value:         'inactive',
              selectedValue: widget.selectedFilter,
              onTap:         widget.onFilter),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUPPLIER TABLE
// ─────────────────────────────────────────────────────────────

class _SupplierTable extends StatefulWidget {
  final List<SupplierModel>         suppliers;
  final ValueChanged<SupplierModel> onDelete;
  final ValueChanged<SupplierModel> onEdit;
  final WidgetRef                   ref;

  static const double minWidth = 1320;

  const _SupplierTable({
    required this.suppliers,
    required this.onDelete,
    required this.onEdit,
    required this.ref,
  });

  @override
  State<_SupplierTable> createState() => _SupplierTableState();
}

class _SupplierTableState extends State<_SupplierTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────
            LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth > _SupplierTable.minWidth
                  ? constraints.maxWidth
                  : _SupplierTable.minWidth;
              return SingleChildScrollView(
                controller:      _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: w,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color:  AppColor.grey100,
                      border: Border(
                          bottom: BorderSide(color: AppColor.grey200)),
                    ),
                    child: const Row(
                      children: [
                        _HeaderCell(label: 'Supplier',       flex: 3),
                        _HeaderCell(label: 'Phone',          flex: 2),
                        _HeaderCell(label: 'Payment Terms',  flex: 1),
                        _HeaderCell(label: 'Total Purchase', flex: 2),
                        _HeaderCell(label: 'Balance',        flex: 1),
                        _HeaderCell(label: 'Orders',         flex: 1),
                        _HeaderCell(label: 'Status',         flex: 1),
                        _HeaderCell(label: 'Actions',        flex: 1,
                            align: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // ── Rows ──────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final w = constraints.maxWidth > _SupplierTable.minWidth
                    ? constraints.maxWidth
                    : _SupplierTable.minWidth;
                return SingleChildScrollView(
                  controller:      _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: w,
                    child: ListView.separated(
                      itemCount: widget.suppliers.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: AppColor.grey100),
                      itemBuilder: (context, i) {
                        final s = widget.suppliers[i];
                        return GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  SpecificSupplierDetailScreen(
                                      supplier: s),
                            ),
                          ).then((_) {
                            // Detail screen se wapas aane pe reload karo
                            widget.ref.read(supplierProvider.notifier).loadSuppliers();
                          }),
                          child: _SupplierRow(
                            key:      ValueKey(s.id),
                            supplier: s,
                            onDelete: () => widget.onDelete(s),
                            onEdit:   () => widget.onEdit(s),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),

            // ── Footer ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppColor.grey100))),
              child: Row(
                children: [
                  Text(
                    '${widget.suppliers.length} supplier'
                        '${widget.suppliers.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 12,
                        color:    AppColor.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER CELL
// ─────────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final String    label;
  final int       flex;
  final TextAlign align;

  const _HeaderCell({
    required this.label,
    required this.flex,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label,
          textAlign: align,
          style: TextStyle(
              fontSize:      12,
              fontWeight:    FontWeight.w600,
              color:         AppColor.textSecondary,
              letterSpacing: 0.4)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TABLE ROW
// ─────────────────────────────────────────────────────────────

class _SupplierRow extends StatefulWidget {
  final SupplierModel supplier;
  final VoidCallback  onDelete;
  final VoidCallback  onEdit;

  const _SupplierRow({
    required super.key,
    required this.supplier,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_SupplierRow> createState() => _SupplierRowState();
}

class _SupplierRowState extends State<_SupplierRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;

    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (_) { if (mounted) setState(() => _isHovered = true);  },
      onExit:  (_) { if (mounted) setState(() => _isHovered = false); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _isHovered
            ? AppColor.primary.withOpacity(0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Supplier name + company + address
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  SupplierAvatar(name: s.name),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize:   14,
                                color:      AppColor.textPrimary),
                            overflow: TextOverflow.ellipsis),
                        if (s.companyName != null)
                          Text(s.companyName!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color:    AppColor.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        if (s.address != null)
                          Row(children: [
                            Icon(Icons.location_on_outlined,
                                size: 12, color: AppColor.grey400),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(s.address!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color:    AppColor.grey400),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Phone
            Expanded(
              flex: 2,
              child: Text(s.phone,
                  style: TextStyle(
                      fontSize: 13,
                      color:    AppColor.textSecondary)),
            ),

            // Payment Terms
            Expanded(
                flex: 1,
                child: PaymentTermsBadge(days: s.paymentTerms)),
            const SizedBox(width: 20),

            // Total Purchase
            Expanded(
              flex: 2,
              child: Text(s.totalPurchaseAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w500,
                      color:      AppColor.textPrimary)),
            ),

            // Balance
            SizedBox(child: SupplierBalanceBadge(supplier: s)),
            const SizedBox(width: 20),

            // Orders
            Expanded(
              flex: 1,
              child: Text('${s.totalOrders}',
                  style: TextStyle(
                      fontSize: 13,
                      color:    AppColor.textSecondary)),
            ),

            // Status
            Expanded(
                flex: 1,
                child: SupplierStatusBadge(isActive: s.isActive)),

            // Actions — hover pe dikhte hain
            Expanded(
              flex: 1,
              child: _isHovered
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SupplierActionButton(
                      icon:    Icons.edit_outlined,
                      color:   AppColor.info,
                      tooltip: 'Edit',
                      onTap:   widget.onEdit),
                  const SizedBox(width: 6),
                  SupplierActionButton(
                      icon:    Icons.delete_outline,
                      color:   AppColor.error,
                      tooltip: 'Delete',
                      onTap:   widget.onDelete),
                ],
              )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}