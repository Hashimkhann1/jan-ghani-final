// =============================================================
// purchase_order_screen.dart
// Purchase Order list screen
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/provider/purchase_order_provider.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/screens/purchase_invoice_screen/purchase_invoice_screen.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/widgets/po_detail_dialog_widget.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/widgets/purchase_order_widgets.dart';
import 'package:jan_ghani_final/features/supplier/presentation/provider/supplier_provider/supplier_provider.dart';
import 'package:jan_ghani_final/features/warehouse_stock_inventory/presentation/provider/product_provider.dart';

class PurchaseOrderScreen extends ConsumerStatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  ConsumerState<PurchaseOrderScreen> createState() =>
      _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState
    extends ConsumerState<PurchaseOrderScreen> {

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(purchaseOrderProvider.notifier).loadOrders());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(purchaseOrderProvider);
    final notifier = ref.read(purchaseOrderProvider.notifier);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _TopBar(
            onNewPO: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PurchaseInvoiceScreen(),
              ),
            ).then((_) {
              // Purchase orders refresh karo
              ref.read(purchaseOrderProvider.notifier).loadOrders();
              // Supplier balances bhi refresh karo
              ref.read(supplierProvider.notifier).loadSuppliers();
              // Products cost_price + inventory refresh karo
              ref.read(productProvider.notifier).loadProducts();
            }),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _StatsRow(stats: state.stats),
                  const SizedBox(height: 14),
                  _Toolbar(
                    controller:     _searchController,
                    selectedFilter: state.filterStatus,
                    onSearch: (q) {
                      notifier.onSearchChanged(q);
                      setState(() {});
                    },
                    onFilter: notifier.onFilterChanged,
                  ),
                  const SizedBox(height: 14),
                  _OrdersTable(
                    orders:      state.filteredOrders,
                    isSearching: state.searchQuery.isNotEmpty ||
                        state.filterStatus != 'all',
                    onView: (order) {
                      POdetailDialogWidget.show(context, order);
                    },
                    onEdit: (order) {
                      // TODO: navigate to UpdatePurchaseOrderScreen
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onNewPO;
  const _TopBar({required this.onNewPO});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color:  AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Purchase Orders',
                  style: TextStyle(fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary)),
              Text('Supplier se aane wale orders manage karo',
                  style: TextStyle(fontSize: 13,
                      color: AppColor.textSecondary)),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed:  onNewPO,
            icon:       const Icon(Icons.add_rounded, size: 18),
            label:      const Text('New PO'),
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
// STATS ROW
// ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final stats;
  const _StatsRow({this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox();
    return Row(
      children: [
        PoStatCard(label: 'Total POs',
            value: '${stats.totalPOs}',
            icon: Icons.receipt_long_outlined,
            color: AppColor.primary),
        const SizedBox(width: 12),
        PoStatCard(label: 'Pending',
            value: '${stats.pendingCount}',
            icon: Icons.pending_outlined,
            color: AppColor.warning),
        const SizedBox(width: 12),
        PoStatCard(label: 'Received',
            value: '${stats.receivedCount}',
            icon: Icons.check_circle_outline_rounded,
            color: AppColor.success),
        const SizedBox(width: 12),
        PoStatCard(label: 'This month',
            value: stats.thisMonthTotal.toString(),
            icon: Icons.calendar_month_outlined,
            color: AppColor.info),
        const SizedBox(width: 12),
        PoStatCard(label: 'Outstanding',
            value: _fmt(stats.totalOutstanding),
            icon: Icons.account_balance_wallet_outlined,
            color: AppColor.error),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────
// TOOLBAR
// ─────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final TextEditingController controller;
  final String                selectedFilter;
  final ValueChanged<String>  onSearch;
  final ValueChanged<String>  onFilter;

  const _Toolbar({
    required this.controller,
    required this.selectedFilter,
    required this.onSearch,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 340, height: 42,
          child: TextField(
            controller: controller,
            onChanged:  onSearch,
            decoration: InputDecoration(
              hintText:   'PO number, supplier se search karein...',
              hintStyle:  TextStyle(
                  color: AppColor.textHint, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppColor.grey400, size: 18),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: () {
                  controller.clear();
                  onSearch('');
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
        Row(
          children: [
            PoFilterChip(label: 'All',       value: 'all',
                selectedValue: selectedFilter, onTap: onFilter),
            const SizedBox(width: 6),
            PoFilterChip(label: 'Draft',     value: 'draft',
                selectedValue: selectedFilter, onTap: onFilter),
            const SizedBox(width: 6),
            PoFilterChip(label: 'Ordered',   value: 'ordered',
                selectedValue: selectedFilter, onTap: onFilter),
            const SizedBox(width: 6),
            PoFilterChip(label: 'Partial',   value: 'partial',
                selectedValue: selectedFilter, onTap: onFilter),
            const SizedBox(width: 6),
            PoFilterChip(label: 'Received',  value: 'received',
                selectedValue: selectedFilter, onTap: onFilter),
            const SizedBox(width: 6),
            PoFilterChip(label: 'Cancelled', value: 'cancelled',
                selectedValue: selectedFilter, onTap: onFilter),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ORDERS TABLE
// ─────────────────────────────────────────────────────────────

class _OrdersTable extends StatelessWidget {
  final List            orders;
  final bool            isSearching;
  final Function(dynamic) onView;
  final Function(dynamic) onEdit;

  // Table minimum width — isse choti window pe horizontal scroll
  static const double _minWidth = 1350;

  const _OrdersTable({
    required this.orders,
    required this.isSearching,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _ScrollableTable(
          minWidth:    _minWidth,
          orders:      orders,
          isSearching: isSearching,
          onView:      onView,
          onEdit:      onEdit,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SCROLLABLE TABLE — shared ScrollController
// ─────────────────────────────────────────────────────────────

class _ScrollableTable extends StatefulWidget {
  final double            minWidth;
  final List              orders;
  final bool              isSearching;
  final Function(dynamic) onView;
  final Function(dynamic) onEdit;

  const _ScrollableTable({
    required this.minWidth,
    required this.orders,
    required this.isSearching,
    required this.onView,
    required this.onEdit,
  });

  @override
  State<_ScrollableTable> createState() => _ScrollableTableState();
}

class _ScrollableTableState extends State<_ScrollableTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth >= widget.minWidth
            ? constraints.maxWidth
            : widget.minWidth;

        return Column(
          children: [
            // ── Header ──────────────────────────────────
            SingleChildScrollView(
              controller:      _scrollController,
              scrollDirection: Axis.horizontal,
              physics:         const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: tableWidth,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    color:  AppColor.grey100,
                    border: Border(
                        bottom: BorderSide(color: AppColor.grey200)),
                  ),
                  child: Row(
                    children: const [
                      _TH(label: 'PO Number',    flex: 2),
                      _TH(label: 'Supplier',     flex: 3),
                      _TH(label: 'Destination',  flex: 2),
                      _TH(label: 'Status',       flex: 2),
                      _TH(label: 'Total / Paid', flex: 2),
                      _TH(label: 'Remaining',    flex: 2),
                      _TH(label: 'Actions',
                          flex: 1, center: true),
                    ],
                  ),
                ),
              ),
            ),

            // ── Rows ────────────────────────────────────
            if (widget.orders.isEmpty)
              SizedBox(
                height: 220,
                child: PoEmptyState(
                    isSearching: widget.isSearching),
              )
            else
              SingleChildScrollView(
                controller:      _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics:    const NeverScrollableScrollPhysics(),
                    itemCount:  widget.orders.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppColor.grey100),
                    itemBuilder: (_, i) => PoTableRow(
                      key:    ValueKey(widget.orders[i].id),
                      order:  widget.orders[i],
                      onView: () => widget.onView(widget.orders[i]),
                      onEdit: widget.orders[i].canEdit
                          ? () => widget.onEdit(widget.orders[i])
                          : null,
                    ),
                  ),
                ),
              ),

            // ── Footer ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppColor.grey100))),
              child: Row(
                children: [
                  Text(
                    '${widget.orders.length} purchase orders',
                    style: TextStyle(fontSize: 12,
                        color: AppColor.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TABLE HEADER CELL
// ─────────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String label;
  final int    flex;
  final bool   center;

  const _TH({
    required this.label,
    required this.flex,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label,
          textAlign: center ? TextAlign.center : TextAlign.left,
          style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColor.textSecondary,
              letterSpacing: 0.4)),
    );
  }
}