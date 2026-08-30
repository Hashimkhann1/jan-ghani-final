// Branch Transfer List Screen — updated with inventory-style summary header
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/color/app_color.dart';
import '../../data/model/stock_transfer_model.dart';
import '../provider/stock_transfer_provider.dart';
import 'stock_transfer_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            icon: const Icon(Icons.refresh_rounded, color: AppColor.textSecondary),
            tooltip: 'Refresh',
            onPressed: () => ref.read(stockTransferProvider.notifier).refresh(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: asyncTransfers.when(
          data: (transfers) {
            final pending  = transfers.where((t) => t.isPending).toList();
            final accepted = transfers.where((t) => t.isAccepted).toList();
            final rejected = transfers.where((t) => t.isRejected).toList();
            return _TransferTabBar(
              controller: _tabController,
              tabs: [
                _TransferTabSpec(
                    icon: Icons.schedule_rounded,
                    label: 'Pending',
                    color: AppColor.warning,
                    count: pending.length),
                _TransferTabSpec(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Accepted',
                    color: AppColor.success,
                    count: accepted.length),
                _TransferTabSpec(
                    icon: Icons.cancel_outlined,
                    label: 'Rejected',
                    color: AppColor.error,
                    count: rejected.length),
              ],
            );
          },
          loading: () => null,
          error: (_, __) => null,
        ),
      ),
      body: asyncTransfers.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColor.primary)),
        error: (e, _) => _ErrorState(
          message: '$e',
          onRetry: () => ref.read(stockTransferProvider.notifier).refresh(),
        ),
        data: (transfers) {
          final pending  = transfers.where((t) => t.isPending).toList();
          final accepted = transfers.where((t) => t.isAccepted).toList();
          final rejected = transfers.where((t) => t.isRejected).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _TransferList(
                transfers:   pending,
                accentColor: AppColor.warning,
                emptyIcon:   Icons.schedule_rounded,
                emptyTitle:  'No pending transfers',
                emptySubtitle:
                'New stock assignments from the warehouse will show up here',
              ),
              _TransferList(
                transfers:   accepted,
                accentColor: AppColor.success,
                emptyIcon:   Icons.check_circle_outline_rounded,
                emptyTitle:  'No accepted transfers yet',
                emptySubtitle:
                'Transfers you accept get added to your branch stock',
              ),
              _TransferList(
                transfers:   rejected,
                accentColor: AppColor.error,
                emptyIcon:   Icons.cancel_outlined,
                emptyTitle:  'No rejected transfers',
                emptySubtitle: 'Transfers you decline will be listed here',
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
  final IconData icon;
  final String   label;
  final Color    color;
  final int      count;
  const _TransferTabSpec({
    required this.icon,
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
                      Icon(spec.icon,
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
  final List<StockTransfer> transfers;
  final Color accentColor;

  const _SummaryBar({
    required this.transfers,
    required this.accentColor,
  });

  int get _totalTransfers => transfers.length;

  int get _totalUnits =>
      transfers.fold(0, (sum, t) => sum + t.totalItems);

  double get _totalPurchase =>
      transfers.fold(0.0, (sum, t) => sum + t.totalCost);

  double get _totalSale =>
      transfers.fold(0.0, (sum, t) => sum + t.totalSalePrice);

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) return const SizedBox.shrink();

    final items = [
      _SummaryItem(
        icon: Icons.swap_horiz_rounded,
        iconBg: accentColor.withOpacity(0.1),
        iconColor: accentColor,
        value: "$_totalTransfers",
        label: "Total Transfers",
        valueColor: accentColor,
      ),
      _SummaryItem(
        icon: Icons.inventory_2_rounded,
        iconBg: AppColor.primary.withOpacity(0.1),
        iconColor: AppColor.primary,
        value: "$_totalUnits",
        label: "Total Quantity",
      ),
      _SummaryItem(
        icon: Icons.shopping_cart_outlined,
        iconBg: AppColor.warning.withOpacity(0.1),
        iconColor: AppColor.warning,
        value: "Rs ${_fmt(_totalPurchase)}",
        label: "Total Purchase Price",
      ),
      _SummaryItem(
        icon: Icons.trending_up_rounded,
        iconBg: AppColor.success.withOpacity(0.1),
        iconColor: AppColor.success,
        value: "Rs ${_fmt(_totalSale)}",
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
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final Color? valueColor;
  const _SummaryItem({
    required this.icon,
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
            child: Icon(item.icon, color: item.iconColor, size: 21),
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
  final List<StockTransfer> transfers;
  final Color accentColor;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _TransferList({
    required this.transfers,
    required this.accentColor,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          _SummaryBar(transfers: transfers, accentColor: accentColor),

          // Transfer cards list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: transfers.length,
              itemBuilder: (context, i) =>
                  _TransferCard(transfer: transfers[i]),
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Transfer Card
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _TransferCard extends StatelessWidget {
  final StockTransfer transfer;
  const _TransferCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (transfer.isPending) {
      statusColor = AppColor.warning;
      statusLabel = "Pending";
      statusIcon = Icons.schedule_rounded;
    } else if (transfer.isAccepted) {
      statusColor = AppColor.success;
      statusLabel = "Accepted";
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = AppColor.error;
      statusLabel = "Rejected";
      statusIcon = Icons.cancel_rounded;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              StockTransferDetailScreen(transferId: transfer.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    transfer.transferNumber,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.warehouse_rounded,
                    size: 13, color: AppColor.textHint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    transfer.assignedByName ?? 'Warehouse',
                    style: const TextStyle(
                        fontSize: 12, color: AppColor.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.inventory_2_rounded,
                    size: 13, color: AppColor.textHint),
                const SizedBox(width: 6),
                Text(
                  "${transfer.items.length} products • ${transfer.totalItems} units",
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:        const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Purchase",
                            style: TextStyle(
                                fontSize: 10, color: AppColor.textHint)),
                        const SizedBox(height: 2),
                        Text(
                          "Rs ${transfer.totalCost.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1D23)),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 28, color: const Color(0xFFE5E7EB)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Sale Price",
                            style: TextStyle(
                                fontSize: 10, color: AppColor.textHint)),
                        const SizedBox(height: 2),
                        Text(
                          "Rs ${transfer.totalSalePrice.toStringAsFixed(0)}",
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColor.success),
                        ),
                      ],
                    ),
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
