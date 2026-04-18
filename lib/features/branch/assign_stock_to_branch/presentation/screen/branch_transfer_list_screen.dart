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
            onPressed: () => ref.read(stockTransferProvider.notifier).refresh(),
          ),
        ],
        bottom: asyncTransfers.when(
          data: (transfers) {
            final pending =
            transfers.where((t) => t.isPending).toList();
            final accepted =
            transfers.where((t) => t.isAccepted).toList();
            final rejected =
            transfers.where((t) => t.isRejected).toList();

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
                _buildTab("Accepted", accepted.length, const Color(0xFF10B981)),
                _buildTab("Rejected", rejected.length, const Color(0xFFEF4444)),
              ],
            );
          },
          loading: () => null,
          error: (_, __) => null,
        ),
      ),
      body: asyncTransfers.when(
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (transfers) {
          final pending = transfers.where((t) => t.isPending).toList();
          final accepted = transfers.where((t) => t.isAccepted).toList();
          final rejected = transfers.where((t) => t.isRejected).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _TransferList(transfers: pending),
              _TransferList(transfers: accepted),
              _TransferList(transfers: rejected),
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
              child: Text(
                "$count",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransferList extends StatelessWidget {
  final List<StockTransfer> transfers;
  const _TransferList({required this.transfers});

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
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transfers.length,
      itemBuilder: (context, i) => _TransferCard(transfer: transfers[i]),
    );
  }
}

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