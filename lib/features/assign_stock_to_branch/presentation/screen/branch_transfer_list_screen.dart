import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/stock_transfer_model.dart';
import '../provider/stock_transfer_provider.dart';
import '../widget/accept_dialog_widget.dart';
import '../widget/tab_badge_widget.dart';
import '../widget/transfer_table_widget.dart';

class BranchTransferListScreen extends ConsumerStatefulWidget {
  const BranchTransferListScreen({super.key});

  @override
  ConsumerState<BranchTransferListScreen> createState() =>
      _BranchTransferListScreenState();
}

class _BranchTransferListScreenState extends ConsumerState<BranchTransferListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleExpand(String id) =>
      setState(() => _expandedId = _expandedId == id ? null : id);

  @override
  Widget build(BuildContext context) {
    final allTransfers = ref.watch(stockTransferProvider);
    final pending =
    allTransfers.where((t) => t.status == TransferStatus.pending).toList();
    final accepted =
    allTransfers.where((t) => t.status == TransferStatus.accepted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Stock Transfers",
              style: TextStyle(
                  color: Color(0xFF1A1D23),
                  fontWeight: FontWeight.w700,
                  fontSize: 20),
            ),
            Text(
              "Gulberg Branch",
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() => _expandedId = null),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF6C7280),
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 2.5,
          labelStyle:
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Pending"),
                  if (pending.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    TabBadge(count: pending.length, active: true),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Accepted"),
                  if (accepted.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    TabBadge(count: accepted.length, active: false),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TransferTable(
            transfers: pending,
            isPending: true,
            expandedId: _expandedId,
            onToggle: _toggleExpand,
            onAccept: _onAccept,
          ),
          TransferTable(
            transfers: accepted,
            isPending: false,
            expandedId: _expandedId,
            onToggle: _toggleExpand,
            onAccept: (_) {},
          ),
        ],
      ),
    );
  }

  void _onAccept(StockTransfer transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AcceptConfirmDialog(transfer: transfer),
    );
    if (confirmed == true) {
      ref
          .read(stockTransferProvider.notifier)
          .acceptTransfer(transfer.transferId);
      setState(() => _expandedId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  "${transfer.items.length} products added to branch stock",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
