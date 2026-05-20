// Branch Transfer List Screen — updated with inventory-style summary header
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Stock Transfers",
                style: TextStyle(
                    color: Color(0xFF1A1D23),
                    fontWeight: FontWeight.w700,
                    fontSize: 20)),
            Text("Branch Transfers",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6366F1)),
            onPressed: () =>
                ref.read(stockTransferProvider.notifier).refresh(),
          ),
        ],
        bottom: asyncTransfers.when(
          data: (transfers) {
            final pending = transfers.where((t) => t.isPending).toList();
            final accepted = transfers.where((t) => t.isAccepted).toList();
            final rejected = transfers.where((t) => t.isRejected).toList();
            return TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: const Color(0xFF6C7280),
              indicatorColor: const Color(0xFF6366F1),
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12),
              tabs: [
                _buildTab("Pending", pending.length, const Color(0xFFF59E0B)),
                _buildTab(
                    "Accepted", accepted.length, const Color(0xFF10B981)),
                _buildTab(
                    "Rejected", rejected.length, const Color(0xFFEF4444)),
              ],
            );
          },
          loading: () => null,
          error: (_, __) => null,
        ),
      ),
      body: asyncTransfers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (transfers) {
          final pending = transfers.where((t) => t.isPending).toList();
          final accepted = transfers.where((t) => t.isAccepted).toList();
          final rejected = transfers.where((t) => t.isRejected).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _TransferList(
                  transfers: pending,
                  accentColor: const Color(0xFFF59E0B)),
              _TransferList(
                  transfers: accepted,
                  accentColor: const Color(0xFF10B981)),
              _TransferList(
                  transfers: rejected,
                  accentColor: const Color(0xFFEF4444)),
            ],
          );
        },
      ),
    );
  }

  Tab _buildTab(String label, int count, Color color) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("$count",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ],
        ],
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
        iconBg: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF6366F1),
        value: "$_totalTransfers",
        label: "Total Transfers",
      ),
      _SummaryItem(
        icon: Icons.inventory_2_rounded,
        iconBg: const Color(0xFFF0FDF4),
        iconColor: const Color(0xFF10B981),
        value: "$_totalUnits",
        label: "Total Quantity",
      ),
      _SummaryItem(
        icon: Icons.shopping_cart_outlined,
        iconBg: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFF59E0B),
        value: "Rs ${_fmt(_totalPurchase)}",
        label: "Total Purchase Price",
      ),
      _SummaryItem(
        icon: Icons.trending_up_rounded,
        iconBg: const Color(0xFFF0FDF4),
        iconColor: const Color(0xFF10B981),
        value: "Rs ${_fmt(_totalSale)}",
        label: "Total Sale Price",
      ),
    ];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Horizontal scrollable stat cards — exactly like inventory screen
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFE5E7EB),
                indent: 8,
                endIndent: 8,
              ),
              itemBuilder: (_, i) => _StatCard(item: items[i]),
            ),
          ),
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
  const _SummaryItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });
}

class _StatCard extends StatelessWidget {
  final _SummaryItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Row(
        children: [
          // Icon box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Value + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D23),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
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
// Transfer List — summary bar + transfer cards
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _TransferList extends StatelessWidget {
  final List<StockTransfer> transfers;
  final Color accentColor;

  const _TransferList({
    required this.transfers,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text("No transfers found",
                style:
                TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ← Inventory-style summary bar at top
        _SummaryBar(transfers: transfers, accentColor: accentColor),

        // Transfer cards list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transfers.length,
            itemBuilder: (context, i) =>
                _TransferCard(transfer: transfers[i]),
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Transfer Card (unchanged)
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
      statusColor = const Color(0xFFF59E0B);
      statusLabel = "Pending";
      statusIcon = Icons.schedule_rounded;
    } else if (transfer.isAccepted) {
      statusColor = const Color(0xFF10B981);
      statusLabel = "Accepted";
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = const Color(0xFFEF4444);
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
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                        color: Color(0xFF6366F1)),
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
                    size: 13, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Text(
                  transfer.assignedByName ?? 'Warehouse',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6C7280)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.inventory_2_rounded,
                    size: 13, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Text(
                  "${transfer.items.length} products • ${transfer.totalItems} units",
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6C7280)),
                ),
                const Spacer(),
                Text(
                  "Rs. ${transfer.totalCost.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D23)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}