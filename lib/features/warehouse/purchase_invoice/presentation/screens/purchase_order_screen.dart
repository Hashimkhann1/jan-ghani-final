// Updated on 2026-10-05 03:08 PM
// =============================================================
// purchase_order_screen.dart
// Stitch "Jan Ghani — Purchase Orders v2" design:
// TopBar (Return + New PO) · 5 KPI cards (sub-lines) · toolbar
// (search, status tabs + counts, type, date range, supplier) ·
// table (PO, supplier, items, status, total, actions) · footer
// (filtered summary + pagination)
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/purchase_invoice_model.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_invoice_provider/purchase_invoice_provider.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_order_provider.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/screens/purchase_invoice_screen/purchase_invoice_screen.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/widgets/po_detail_dialog_widget.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/widgets/purchase_order_widgets.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/provider/supplier_provider/supplier_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/provider/product_provider.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';

const _kMonths = ['Jan','Feb','Mar','Apr','May','Jun',
  'Jul','Aug','Sep','Oct','Nov','Dec'];

String _fmtDay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_kMonths[d.month - 1]} ${d.year}';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Naya PO / Return / Edit — save hone par refresh ──────
  Future<void> _navigateToInvoice({
    PurchaseOrderModel? existingOrder,
    PoType?             newType,
  }) async {
    // Naye invoice ka type pehle set — Return button seedha return kholta
    // hai, New PO button purchase. Edit mode loadFromExistingOrder khud
    // type set karta hai.
    if (existingOrder == null && newType != null) {
      ref.read(purchaseInvoiceProvider.notifier).setPoType(newType);
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PurchaseInvoiceScreen(
          existingOrder: existingOrder,
        ),
      ),
    );

    // ✅ Sirf tab refresh karo jab actually save hua ho
    if (saved == true) {
      ref.read(purchaseOrderProvider.notifier).loadOrders();
      ref.read(supplierProvider.notifier).loadSuppliers();
      ref.read(productProvider.notifier).loadProducts(); // optional
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(purchaseOrderProvider);
    final notifier = ref.read(purchaseOrderProvider.notifier);

    return Scaffold(
      backgroundColor: AppColor.grey100,
      body: state.isLoading && state.allOrders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
            onNewPO:  () => _navigateToInvoice(newType: PoType.purchase),
            onReturn: () =>
                _navigateToInvoice(newType: PoType.purchaseReturn),
          ),

          // Stats + Toolbar fixed rahenge, sirf table scroll karega
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                _StatsRow(stats: state.stats, orders: state.allOrders),
                const SizedBox(height: 16),
                _Toolbar(
                  controller: _searchController,
                  state:      state,
                  onSearch: (q) {
                    notifier.onSearchChanged(q);
                    setState(() {});
                  },
                  onFilter:    notifier.onFilterChanged,
                  onType:      notifier.onTypeChanged,
                  onSupplier:  notifier.onSupplierChanged,
                  onDateRange: notifier.onDateRangeChanged,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ✅ Table Expanded mein — bounded height milegi
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _OrdersTable(
                state:       state,
                onView: (order) => POdetailDialogWidget.show(context, order),
                onEdit: (order) => _navigateToInvoice(existingOrder: order),
                onPage:      notifier.onPageChanged,
                onPageSize:  notifier.onPageSizeChanged,
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
  final VoidCallback onReturn;
  const _TopBar({required this.onNewPO, required this.onReturn});

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
            child: const Icon(Icons.shopping_cart_outlined,
                size: 20, color: AppColor.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Purchase Orders',
                    style: TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.textPrimary)),
                Text('Supplier se aane wale orders aur returns',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color:    AppColor.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onReturn,
            icon:  const Icon(Icons.keyboard_return_rounded, size: 18),
            label: const Text('Purchase Return'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.error,
              side: BorderSide(color: AppColor.error.withOpacity(0.35)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              minimumSize:   Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onNewPO,
            icon:  const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Purchase Order'),
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
// STATS ROW — values DB stats se (pehle jaise), sub-lines orders
// list se Dart mein (koi naya query nahi)
// ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final PurchaseOrderStats?      stats;
  final List<PurchaseOrderModel> orders;
  const _StatsRow({this.stats, required this.orders});

  @override
  Widget build(BuildContext context) {
    final s = stats; // local variable — null promotion kaam karega
    if (s == null) return const SizedBox();

    final now       = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    int thisMonthCount = 0, draft = 0, ordered = 0, partial = 0;
    double lastMonthTotal = 0;
    final dueSuppliers = <String>{};

    for (final o in orders) {
      final d = o.orderDate.toLocal();
      final m = DateTime(d.year, d.month);
      if (m == thisMonth) thisMonthCount++;
      if (m == lastMonth) lastMonthTotal += o.totalAmount;

      switch (o.status) {
        case 'draft':   draft++;   break;
        case 'ordered': ordered++; break;
        case 'partial': partial++; break;
      }

      // Outstanding card ke DB filter ka mirror (cancelled/received bahar)
      if (o.status != 'cancelled' && o.status != 'received' &&
          o.remainingAmount > 0 && o.supplierId != null) {
        dueSuppliers.add(o.supplierId!);
      }
    }

    final receivedPct = s.totalPOs == 0
        ? 0 : (s.receivedCount * 100 / s.totalPOs).round();

    final String monthSub;
    final Color  monthColor;
    if (lastMonthTotal <= 0) {
      monthSub   = 'Pichle mahine koi PO nahi';
      monthColor = AppColor.textSecondary;
    } else {
      final pct = ((s.thisMonthTotal - lastMonthTotal) * 100 / lastMonthTotal)
          .round();
      monthSub   = '${pct >= 0 ? '↑' : '↓'} ${pct.abs()}% vs last month';
      monthColor = AppColor.info;
    }

    return Row(
      children: [
        PoStatCard(
            label:    'Total POs',
            value:    '${s.totalPOs}',
            subtitle: '$thisMonthCount is mahine',
            icon:     Icons.receipt_long_outlined,
            color:    AppColor.primary),
        const SizedBox(width: 14),
        PoStatCard(
            label:    'Pending',
            value:    '${s.pendingCount}',
            subtitle: 'Draft $draft · Ordered $ordered · Partial $partial',
            icon:     Icons.pending_actions_outlined,
            color:    AppColor.warning,
            subtitleColor: AppColor.warningDark),
        const SizedBox(width: 14),
        PoStatCard(
            label:    'Received',
            value:    '${s.receivedCount}',
            subtitle: '$receivedPct% complete',
            icon:     Icons.check_circle_outline_rounded,
            color:    AppColor.success),
        const SizedBox(width: 14),
        PoStatCard(
            label:    'This month',
            value:    'Rs ${s.thisMonthTotal.pkrFormat}',
            subtitle: monthSub,
            icon:     Icons.calendar_month_outlined,
            color:    AppColor.info,
            subtitleColor: monthColor),
        const SizedBox(width: 14),
        PoStatCard(
            label:    'Outstanding',
            value:    'Rs ${s.totalOutstanding.pkrFormat}',
            subtitle: dueSuppliers.isEmpty
                ? 'Koi baqaya nahi'
                : '${dueSuppliers.length} suppliers ko dena hai',
            icon:     Icons.account_balance_wallet_outlined,
            color:    AppColor.error),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOOLBAR — wide par ek line, narrow par do lines
// ─────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final TextEditingController controller;
  final PurchaseOrderState    state;
  final ValueChanged<String>  onSearch;
  final ValueChanged<String>  onFilter;
  final ValueChanged<String>  onType;
  final ValueChanged<String?> onSupplier;
  final void Function(DateTime? from, DateTime? to) onDateRange;

  const _Toolbar({
    required this.controller,
    required this.state,
    required this.onSearch,
    required this.onFilter,
    required this.onType,
    required this.onSupplier,
    required this.onDateRange,
  });

  static const _statuses = [
    ('All',       'all'),
    ('Draft',     'draft'),
    ('Ordered',   'ordered'),
    ('Partial',   'partial'),
    ('Received',  'received'),
    ('Cancelled', 'cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    final search = SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged:  onSearch,
        style:      const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText:  'PO number, supplier, company se search...',
          hintStyle: TextStyle(color: AppColor.textHint, fontSize: 13),
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
            PoStatusTab(
              label:         label,
              value:         value,
              count:         state.statusCounts[value] ?? 0,
              selectedValue: state.filterStatus,
              onTap:         onFilter,
            ),
        ],
      ),
    );

    final filters = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TypeDropdown(value: state.filterType, onChanged: onType),
        const SizedBox(width: 8),
        _DateRangeField(
          from:      state.fromDate,
          to:        state.toDate,
          onChanged: onDateRange,
        ),
        const SizedBox(width: 8),
        _SupplierDropdown(
          orders:    state.allOrders,
          value:     state.filterSupplierId,
          onChanged: onSupplier,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 1420) {
            return Row(
              children: [
                SizedBox(width: 280, child: search),
                const SizedBox(width: 12),
                tabs,
                const Spacer(),
                filters,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 12),
                  filters,
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: tabs,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOOLBAR FIELD SHELL — dropdown/date field ka common look
// ─────────────────────────────────────────────────────────────

class _FieldShell extends StatelessWidget {
  final IconData? leading;
  final String    text;
  final bool      active;
  final Widget?   trailing;

  const _FieldShell({
    this.leading,
    required this.text,
    this.active = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height:  40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color:        active
            ? AppColor.primary.withOpacity(0.05) : AppColor.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: active
                ? AppColor.primary.withOpacity(0.5) : AppColor.grey300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            Icon(leading, size: 16, color: AppColor.textSecondary),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize:   13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? AppColor.primary : AppColor.textPrimary)),
          ),
          const SizedBox(width: 6),
          trailing ??
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColor.textSecondary),
        ],
      ),
    );
  }
}

// ── Type dropdown (All / Purchase / Return) ──────────────────

class _TypeDropdown extends StatelessWidget {
  final String               value;
  final ValueChanged<String> onChanged;
  const _TypeDropdown({required this.value, required this.onChanged});

  static const _labels = {
    'all':      'All',
    'purchase': 'Purchase',
    'return':   'Return',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip:     'Type filter',
      onSelected:  onChanged,
      offset:      const Offset(0, 44),
      color:       AppColor.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColor.grey200)),
      itemBuilder: (_) => [
        for (final e in _labels.entries)
          CheckedPopupMenuItem<String>(
            value:   e.key,
            checked: e.key == value,
            child:   Text(e.value, style: const TextStyle(fontSize: 13)),
          ),
      ],
      child: _FieldShell(
        text:   'Type: ${_labels[value]}',
        active: value != 'all',
      ),
    );
  }
}

// ── Date range (order date) — khaali = sab dates ─────────────

class _DateRangeField extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to) onChanged;

  const _DateRangeField({
    required this.from,
    required this.to,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context:          context,
      initialDateRange: (from != null && to != null)
          ? DateTimeRange(start: from!, end: to!)
          : DateTimeRange(
          start: today.subtract(const Duration(days: 29)), end: today),
      firstDate: DateTime(2020),
      lastDate:  today, // aaj tak
      helpText:  'Order date range',
      saveText:  'Apply',
    );
    if (picked != null) onChanged(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    final hasRange = from != null && to != null;
    return InkWell(
      onTap:        () => _pick(context),
      borderRadius: BorderRadius.circular(8),
      child: _FieldShell(
        leading: Icons.calendar_today_outlined,
        text:    hasRange
            ? '${_fmtDay(from!)} – ${_fmtDay(to!)}'
            : 'Sab dates',
        active:  hasRange,
        trailing: hasRange
            ? InkWell(
          onTap:        () => onChanged(null, null),
          borderRadius: BorderRadius.circular(10),
          child: Icon(Icons.close_rounded,
              size: 16, color: AppColor.primary),
        )
            : null,
      ),
    );
  }
}

// ── Supplier dropdown — sirf wo suppliers jin ke PO hain ─────

class _SupplierDropdown extends StatelessWidget {
  final List<PurchaseOrderModel> orders;
  final String?                  value;
  final ValueChanged<String?>    onChanged;

  const _SupplierDropdown({
    required this.orders,
    required this.value,
    required this.onChanged,
  });

  static const _allKey = '__all__';

  static String _label(PurchaseOrderModel o) =>
      (o.supplierCompany?.isNotEmpty ?? false)
          ? o.supplierCompany!
          : (o.supplierName ?? '—');

  @override
  Widget build(BuildContext context) {
    final suppliers = <String, String>{};
    for (final o in orders) {
      final id = o.supplierId;
      if (id != null) suppliers.putIfAbsent(id, () => _label(o));
    }
    final sorted = suppliers.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    return PopupMenuButton<String>(
      tooltip:     'Supplier filter',
      onSelected:  (v) => onChanged(v == _allKey ? null : v),
      offset:      const Offset(0, 44),
      color:       AppColor.surface,
      constraints: const BoxConstraints(maxHeight: 420, minWidth: 220),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColor.grey200)),
      itemBuilder: (_) => [
        CheckedPopupMenuItem<String>(
          value:   _allKey,
          checked: value == null,
          child:   const Text('All suppliers', style: TextStyle(fontSize: 13)),
        ),
        for (final e in sorted)
          CheckedPopupMenuItem<String>(
            value:   e.key,
            checked: e.key == value,
            child:   Text(e.value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
          ),
      ],
      child: _FieldShell(
        text:   'Supplier: ${value == null ? 'All' : (suppliers[value] ?? '—')}',
        active: value != null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ORDERS TABLE
// ─────────────────────────────────────────────────────────────

class _OrdersTable extends StatefulWidget {
  final PurchaseOrderState                state;
  final void Function(PurchaseOrderModel) onView;
  final void Function(PurchaseOrderModel) onEdit;
  final ValueChanged<int>                 onPage;
  final ValueChanged<int>                 onPageSize;

  const _OrdersTable({
    required this.state,
    required this.onView,
    required this.onEdit,
    required this.onPage,
    required this.onPageSize,
  });

  @override
  State<_OrdersTable> createState() => _OrdersTableState();
}

class _OrdersTableState extends State<_OrdersTable> {
  static const double _minWidth = 900;
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s    = widget.state;
    final rows = s.pagedOrders;

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
                            if (rows.isEmpty)
                              Expanded(
                                child: PoEmptyState(
                                    isSearching: s.hasActiveFilters),
                              )
                            else
                              Expanded(
                                child: ListView.builder(
                                  itemCount:  rows.length,
                                  itemExtent: 65, // ✅ fixed height — scroll fast
                                  itemBuilder: (_, i) => Column(
                                    children: [
                                      SizedBox(
                                        height: 64,
                                        child: RepaintBoundary(
                                          child: PoTableRow(
                                            key:    ValueKey(rows[i].id),
                                            order:  rows[i],
                                            onView: () => widget.onView(rows[i]),
                                            onEdit: rows[i].canEdit
                                                ? () => widget.onEdit(rows[i])
                                                : null,
                                          ),
                                        ),
                                      ),
                                      Divider(height: 1, color: AppColor.grey100),
                                    ],
                                  ),
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
              state:      s,
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
          _TH(label: 'PO NUMBER', flex: kPoColPo),
          _TH(label: 'SUPPLIER',  flex: kPoColSupplier),
          _TH(label: 'ITEMS',     flex: kPoColItems),
          _TH(label: 'STATUS',    flex: kPoColStatus),
          _TH(label: 'TOTAL',     flex: kPoColTotal, align: TextAlign.right),
          SizedBox(
            width: kPoColActions,
            child: Text('ACTIONS',
                textAlign: TextAlign.right,
                style: _TH.style),
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
// TABLE FOOTER — count · filtered summary · pagination
// ─────────────────────────────────────────────────────────────

class _TableFooter extends StatelessWidget {
  final PurchaseOrderState state;
  final ValueChanged<int>  onPage;
  final ValueChanged<int>  onPageSize;

  const _TableFooter({
    required this.state,
    required this.onPage,
    required this.onPageSize,
  });

  @override
  Widget build(BuildContext context) {
    final list  = state.filteredOrders;
    final total = list.length;
    final first = total == 0 ? 0 : state.page * state.pageSize + 1;
    final last  = (state.page * state.pageSize + state.pagedOrders.length);

    // Summary — sirf purchase POs (return/cancelled nahi)
    double sumTotal = 0, sumPaid = 0, sumDue = 0;
    for (final o in list) {
      if (o.isReturn || o.status == 'cancelled') continue;
      sumTotal += o.totalAmount;
      sumPaid  += o.paidAmount;
      sumDue   += o.remainingAmount;
    }

    final muted = TextStyle(fontSize: 12.5, color: AppColor.textSecondary);
    final bold  = TextStyle(fontSize: 12.5,
        fontWeight: FontWeight.w700, color: AppColor.textPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColor.grey200))),
      child: LayoutBuilder(
        builder: (context, c) {
          final countText = Text.rich(TextSpan(style: muted, children: [
            const TextSpan(text: 'Showing '),
            TextSpan(text: '$first–$last', style: bold),
            const TextSpan(text: ' of '),
            TextSpan(text: '$total', style: bold),
            const TextSpan(text: ' purchase orders'),
          ]));

          final summary = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color:        AppColor.grey100,
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: AppColor.grey200),
            ),
            child: Text.rich(TextSpan(style: muted, children: [
              const TextSpan(text: 'Total '),
              TextSpan(text: 'Rs ${sumTotal.pkrFormat}', style: bold),
              const TextSpan(text: '   ·   Paid '),
              TextSpan(text: 'Rs ${sumPaid.pkrFormat}',
                  style: bold.copyWith(color: AppColor.success)),
              const TextSpan(text: '   ·   Baaki '),
              TextSpan(text: 'Rs ${sumDue.pkrFormat}',
                  style: bold.copyWith(color: AppColor.error)),
            ])),
          );

          final pager = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Show:', style: muted),
              const SizedBox(width: 8),
              _PageSizeMenu(value: state.pageSize, onChanged: onPageSize),
              const SizedBox(width: 14),
              _Pager(
                page:      state.page,
                pageCount: state.pageCount,
                onPage:    onPage,
              ),
            ],
          );

          // Wide: ek line (left · center · right) — narrow: wrap
          if (c.maxWidth >= 1100) {
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
}

class _PageSizeMenu extends StatelessWidget {
  final int               value;
  final ValueChanged<int> onChanged;
  const _PageSizeMenu({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip:    'Rows per page',
      onSelected: onChanged,
      color:      AppColor.surface,
      itemBuilder: (_) => [
        for (final n in const [25, 50, 100])
          CheckedPopupMenuItem<int>(
            value:   n,
            checked: n == value,
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
            Text('$value', style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColor.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  final int               page;      // 0-based
  final int               pageCount;
  final ValueChanged<int> onPage;

  const _Pager({
    required this.page,
    required this.pageCount,
    required this.onPage,
  });

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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PageBtn(
          icon:  Icons.chevron_left_rounded,
          onTap: page > 0 ? () => onPage(page - 1) : null,
        ),
        for (final p in _pages())
          p == -1
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('…',
                style: TextStyle(color: AppColor.textSecondary)),
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
