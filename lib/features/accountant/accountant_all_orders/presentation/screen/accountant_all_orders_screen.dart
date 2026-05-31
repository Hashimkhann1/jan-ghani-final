import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/accountant_order_model.dart';
import '../provider/accountant_orders_provider.dart';

// =============================================================
// Accountant → All Orders (read-only)
// Sare purchase orders. Order tap → expand → poora data + items
// =============================================================
class AccountantAllOrdersScreen extends ConsumerStatefulWidget {
  final String warehouseId;
  const AccountantAllOrdersScreen({super.key, required this.warehouseId});

  @override
  ConsumerState<AccountantAllOrdersScreen> createState() =>
      _AccountantAllOrdersScreenState();
}

class _AccountantAllOrdersScreenState
    extends ConsumerState<AccountantAllOrdersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(accAllOrdersProvider(widget.warehouseId));

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text(
          'All Orders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColor.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textDark),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'PO number ya supplier dhoondein...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColor.textMuted),
                  filled: true,
                  fillColor: AppColor.grey100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── List ──────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColor.primary,
                onRefresh: () async =>
                    ref.invalidate(accAllOrdersProvider(widget.warehouseId)),
                child: ordersAsync.when(
                  data: (all) {
                    final list = _query.isEmpty
                        ? all
                        : all
                            .where((o) =>
                                o.poNumber.toLowerCase().contains(_query) ||
                                o.supplierName
                                    .toLowerCase()
                                    .contains(_query))
                            .toList();

                    if (list.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'Koi order nahi mila',
                              style: TextStyle(color: AppColor.textMuted),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _OrderCard(order: list[i]),
                    );
                  },
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 7,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _ShimmerBox(height: 86),
                    ),
                  ),
                  error: (e, _) => ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Orders load nahi hue — pull to refresh',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order Card (expandable) ───────────────────────────────────────────────────
class _OrderCard extends ConsumerWidget {
  final AccOrderModel order;
  const _OrderCard({required this.order});

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'Rs. $s';
  }

  String _date(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'received':  return AppColor.cashIn;
      case 'cancelled': return AppColor.cashOut;
      case 'partial':   return const Color(0xFFF59E0B);
      case 'ordered':   return AppColor.primary;
      default:          return AppColor.textMuted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColor.primary, size: 22),
          ),
          title: Text(
            order.poNumber,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColor.textDark,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${order.supplierName}  •  ${_date(order.orderDate)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColor.textMuted),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(order.totalAmount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          children: [
            // ── Full order info ───────────────────────────────
            const Divider(height: 1),
            const SizedBox(height: 10),
            _infoRow('Supplier', order.supplierName),
            if (order.supplierCompany?.isNotEmpty == true)
              _infoRow('Company', order.supplierCompany!),
            _infoRow('Order Date', _date(order.orderDate)),
            _infoRow('Expected Date', _date(order.expectedDate)),
            _infoRow('Received Date', _date(order.receivedDate)),
            _infoRow('Status', order.statusLabel),
            if (order.createdByName?.isNotEmpty == true)
              _infoRow('Created By', order.createdByName!),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Amount breakdown ──────────────────────────────
            _amountRow('Subtotal', order.subtotal),
            if (order.discountAmount > 0)
              _amountRow('Discount', -order.discountAmount),
            if (order.taxAmount > 0) _amountRow('Tax', order.taxAmount),
            _amountRow('Total', order.totalAmount, bold: true),
            _amountRow('Paid', order.paidAmount),
            _amountRow(
              order.isFullyPaid ? 'Remaining' : 'Baqi',
              order.remainingAmount,
              valueColor:
                  order.isFullyPaid ? AppColor.cashIn : AppColor.cashOut,
            ),

            const SizedBox(height: 12),

            // ── Items ─────────────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Items',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColor.textDark,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _OrderItemsList(poId: order.id),

            if (order.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Note: ${order.notes}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColor.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColor.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: bold ? AppColor.textDark : AppColor.textMuted,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            _money(value),
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? AppColor.textDark,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order Items (lazy load) ───────────────────────────────────────────────────
class _OrderItemsList extends ConsumerWidget {
  final String poId;
  const _OrderItemsList({required this.poId});

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'Rs. $s';
  }

  String _qty(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(accOrderItemsProvider(poId));

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Koi item nahi',
              style: TextStyle(fontSize: 12, color: AppColor.textMuted),
            ),
          );
        }
        return Column(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 6, color: AppColor.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textDark,
                          ),
                        ),
                        Text(
                          '${_qty(item.quantityOrdered)} × ${_money(item.unitCost)}'
                          '${item.sku?.isNotEmpty == true ? '  •  ${item.sku}' : ''}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColor.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _money(item.totalCost),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textDark,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColor.primary),
        ),
      ),
      error: (e, _) => const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Items load nahi hue',
          style: TextStyle(fontSize: 12, color: Colors.red),
        ),
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
      );
}
