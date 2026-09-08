// Branch Transfer List Screen — updated with inventory-style summary header
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/color/app_color.dart';
import '../../../../../core/widget/app_icon.dart';
import '../../../../../core/widget/pagination_bar.dart';
import '../../../reports/presentation/widget/report_table.dart';
import '../../data/datasource/stock_transfer_remote_datasource.dart';
import '../../data/model/stock_transfer_model.dart';
import '../provider/stock_transfer_provider.dart';
import 'stock_transfer_detail_screen.dart';

final _transferDateFmt = DateFormat('dd MMM yyyy');

const _kTabStatus = ['pending', 'accepted', 'rejected'];

class BranchTransferListScreen extends ConsumerStatefulWidget {
  const BranchTransferListScreen({super.key});

  @override
  ConsumerState<BranchTransferListScreen> createState() =>
      _BranchTransferListScreenState();
}

class _BranchTransferListScreenState
    extends ConsumerState<BranchTransferListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Slide-over transfer panel ─────────────────────────────
  String?        _selectedId;
  StockTransfer? _selectedTransfer;   // cache — page badalne par bhi rahe
  bool           _panelOpen = false;

  void _openTransfer(StockTransfer t) => setState(() {
        _selectedId       = t.id;
        _selectedTransfer = t;
        _panelOpen        = true;
      });

  void _closePanel() {
    setState(() => _panelOpen = false);
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted && !_panelOpen) {
        setState(() { _selectedId = null; _selectedTransfer = null; });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final status = _kTabStatus[_tabController.index];
      if (ref.read(stockTransferProvider).value?.status != status) {
        ref.read(stockTransferProvider.notifier).setStatus(status);
        _closePanel();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncTransfers = ref.watch(stockTransferProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Stock Transfers",
                style: TextStyle(
                    color: Color(0xFF1A1D23),
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            Text("Assign Stock to My Branch",
                style: TextStyle(color: AppColor.textHint, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const AppIcon('ic_refresh', size: 20, color: AppColor.textSecondary),
            tooltip: 'Refresh',
            onPressed: () => ref.read(stockTransferProvider.notifier).refresh(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: asyncTransfers.when(
          skipLoadingOnReload: true,
          data: (data) {
            return _TransferTabBar(
              controller: _tabController,
              tabs: [
                _TransferTabSpec(
                    iconAsset: 'ic_pending',
                    label: 'Pending',
                    color: AppColor.warning,
                    count: data.aggFor('pending').count),
                _TransferTabSpec(
                    iconAsset: 'ic_accepted',
                    label: 'Accepted',
                    color: AppColor.success,
                    count: data.aggFor('accepted').count),
                _TransferTabSpec(
                    iconAsset: 'ic_rejected',
                    label: 'Rejected',
                    color: AppColor.error,
                    count: data.aggFor('rejected').count),
              ],
            );
          },
          loading: () => null,
          error: (_, __) => null,
        ),
      ),
      body: asyncTransfers.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColor.primary)),
        error: (e, _) => _ErrorState(
          message: '$e',
          onRetry: () => ref.read(stockTransferProvider.notifier).refresh(),
        ),
        data: (data) {
          final status = data.status;
          final accent = status == 'pending'
              ? AppColor.warning
              : status == 'accepted'
                  ? AppColor.success
                  : AppColor.error;

          final fresh = _selectedId == null
              ? null
              : data.rows.firstWhereOrNull((t) => t.id == _selectedId);
          final selected = fresh ?? _selectedTransfer;

          return Stack(
            fit: StackFit.expand,
            children: [
              _TransferList(
                data:        data,
                accentColor: accent,
                emptyIcon:   status == 'pending'
                    ? Icons.schedule_rounded
                    : status == 'accepted'
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                emptyTitle: status == 'pending'
                    ? 'No pending transfers'
                    : status == 'accepted'
                        ? 'No accepted transfers yet'
                        : 'No rejected transfers',
                emptySubtitle: status == 'pending'
                    ? 'New stock assignments from the warehouse will show up here'
                    : status == 'accepted'
                        ? 'Transfers you accept get added to your branch stock'
                        : 'Transfers you decline will be listed here',
                onView:  _openTransfer,
                onPage:  (p) =>
                    ref.read(stockTransferProvider.notifier).setPage(p),
              ),
              ReportSlideOver(
                open:       _panelOpen && selected != null,
                onClose:    _closePanel,
                title:      selected?.transferNumber ?? 'Transfer',
                width:      520,
                scrollable: false,
                child: selected == null
                    ? const SizedBox.shrink()
                    : StockTransferDetailBody(
                        transfer: selected,
                        onActionDone: _closePanel,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Tab Bar — pill segmented control, each tab keeps its own status
// color (matches the badges/cards below) instead of a flat underline.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _TransferTabSpec {
  final String   iconAsset;
  final String   label;
  final Color    color;
  final int      count;
  const _TransferTabSpec({
    required this.iconAsset,
    required this.label,
    required this.color,
    required this.count,
  });
}

class _TransferTabBar extends StatefulWidget implements PreferredSizeWidget {
  final TabController          controller;
  final List<_TransferTabSpec> tabs;

  const _TransferTabBar({required this.controller, required this.tabs});

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  State<_TransferTabBar> createState() => _TransferTabBarState();
}

class _TransferTabBarState extends State<_TransferTabBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   Colors.white,
      height:  62,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color:        AppColor.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(widget.tabs.length, (i) {
            final spec     = widget.tabs[i];
            final selected = widget.controller.index == i;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap:    () => widget.controller.animateTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve:    Curves.easeOut,
                  margin:   const EdgeInsets.symmetric(horizontal: 2),
                  padding:  const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:        selected ? spec.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: selected
                        ? [
                      BoxShadow(
                        color:      spec.color.withOpacity(0.35),
                        blurRadius: 8,
                        offset:     const Offset(0, 3),
                      ),
                    ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(spec.iconAsset,
                          size:  15,
                          color: selected ? Colors.white : AppColor.textSecondary),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          spec.label,
                          maxLines:  1,
                          overflow:  TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize:   12,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                            color:      selected ? Colors.white : AppColor.textSecondary,
                          ),
                        ),
                      ),
                      if (spec.count > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withOpacity(0.25)
                                : spec.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${spec.count}',
                            style: TextStyle(
                              fontSize:   10,
                              fontWeight: FontWeight.w700,
                              color:      selected ? Colors.white : spec.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Inventory-style horizontal summary stat cards
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SummaryBar extends StatelessWidget {
  final TransferStatusAgg agg;
  final Color accentColor;

  const _SummaryBar({
    required this.agg,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (agg.count == 0) return const SizedBox.shrink();

    final items = [
      _SummaryItem(
        iconAsset: 'ic_transfer',
        iconBg: accentColor.withOpacity(0.1),
        iconColor: accentColor,
        value: "${agg.count}",
        label: "Total Transfers",
        valueColor: accentColor,
      ),
      _SummaryItem(
        iconAsset: 'ic_total_quantity',
        iconBg: AppColor.primary.withOpacity(0.1),
        iconColor: AppColor.primary,
        value: "${agg.totalUnits}",
        label: "Total Quantity",
      ),
      _SummaryItem(
        iconAsset: 'ic_purchase_price',
        iconBg: AppColor.warning.withOpacity(0.1),
        iconColor: AppColor.warning,
        value: "Rs ${_fmt(agg.totalCost)}",
        label: "Total Purchase Price",
      ),
      _SummaryItem(
        iconAsset: 'ic_sale_price_trend',
        iconBg: AppColor.success.withOpacity(0.1),
        iconColor: AppColor.success,
        value: "Rs ${_fmt(agg.totalSale)}",
        label: "Total Sale Price",
      ),
    ];

    return Container(
      color:   Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          // Full-width stat cards — each card grows to fit its full value
          Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: _StatCard(item: items[i])),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
        ],
      ),
    );
  }

  String _fmt(double v) {
    // Decimal nahi hai to integer show karo
    if (v % 1 == 0) {
      return v.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},');
    }
    return v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},');
  }
}

class _SummaryItem {
  final String iconAsset;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final Color? valueColor;
  const _SummaryItem({
    required this.iconAsset,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    this.valueColor,
  });
}

class _StatCard extends StatelessWidget {
  final _SummaryItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color:        item.iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: item.iconColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: AppIcon(item.iconAsset, color: item.iconColor, size: 21),
          ),
          const SizedBox(width: 12),
          // Value + label — FittedBox shrinks the number instead of
          // ellipsis-cutting it, so the full amount is always readable.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit:       BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize:      19,
                      fontWeight:    FontWeight.w800,
                      color:         item.valueColor ?? const Color(0xFF1A1D23),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColor.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Transfer List — summary bar + transfer cards (pull-to-refresh)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _TransferList extends ConsumerWidget {
  final TransferPageData data;
  final Color accentColor;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(StockTransfer) onView;
  final void Function(int) onPage;

  const _TransferList({
    required this.data,
    required this.accentColor,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onView,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfers = data.rows;
    final agg       = data.aggFor(data.status);

    if (transfers.isEmpty) {
      return RefreshIndicator(
        color: accentColor,
        onRefresh: () => ref.read(stockTransferProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: _EmptyState(
              icon:     emptyIcon,
              color:    accentColor,
              title:    emptyTitle,
              subtitle: emptySubtitle,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () => ref.read(stockTransferProvider.notifier).refresh(),
      child: Column(
        children: [
          // ← Inventory-style summary bar at top
          _SummaryBar(agg: agg, accentColor: accentColor),

          // Transfer table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: ReportTable(
                rowsPerPage: 100000, // server-paged — table khud paginate na kare
                columns: const [
                  ReportColumn('Transfer #', flex: 3),
                  ReportColumn('Date', flex: 2),
                  ReportColumn('From', flex: 3),
                  ReportColumn('Products', flex: 2,
                      align: Alignment.center),
                  ReportColumn('Units', flex: 2,
                      align: Alignment.center),
                  ReportColumn('Purchase', flex: 2,
                      align: Alignment.centerRight),
                  ReportColumn('Sale', flex: 2,
                      align: Alignment.centerRight),
                  ReportColumn('Status', flex: 2,
                      align: Alignment.centerRight),
                ],
                rowCount: transfers.length,
                onView: (i) => onView(transfers[i]),
                cellsBuilder: (i) {
                  final t = transfers[i];
                  return [
                    Text(t.transferNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColor.primary)),
                    Text(_transferDateFmt.format(t.assignedAt),
                        style: const TextStyle(fontSize: 11.5)),
                    Text(t.assignedByName ?? 'Warehouse',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('${t.items.length}'),
                    Text('${t.totalItems}'),
                    Text('Rs ${t.totalCost.toStringAsFixed(0)}'),
                    Text('Rs ${t.totalSalePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColor.success)),
                    Text(
                      t.isPending
                          ? 'Pending'
                          : t.isAccepted
                              ? 'Accepted'
                              : 'Rejected',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: t.isPending
                              ? AppColor.warning
                              : t.isAccepted
                                  ? AppColor.success
                                  : AppColor.error),
                    ),
                  ];
                },
              ),
            ),
          ),

          // ── Server-side pagination bar ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: PaginationBar(
              total:   agg.count,
              page:    data.page,
              perPage: kTransferPageSize,
              onPageChanged: onPage,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Empty State
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   subtitle;

  const _EmptyState({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.w700,
                  color:      Color(0xFF1A1D23))),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColor.textHint, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Error State
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColor.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 32, color: AppColor.error),
            ),
            const SizedBox(height: 16),
            const Text('Something went wrong',
                style: TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.w700,
                    color:      Color(0xFF1A1D23))),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColor.textHint)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
