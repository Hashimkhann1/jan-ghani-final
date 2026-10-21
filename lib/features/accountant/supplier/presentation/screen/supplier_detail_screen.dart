import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/accountant_supplier_detail_models.dart';
import '../provider/accountant_supplier_provider.dart';

// =============================================================
// Accountant → Supplier Detail (read-only)
// Header: supplier info + outstanding + summary
// Body: 2 swipeable tabs
//   • Transactions (default)  → supplier_ledger
//   • Orders (swipe right)    → purchase_orders (expandable items)
// =============================================================
class AccountantSupplierDetailScreen extends ConsumerWidget {
  final String  supplierId;
  final String  supplierName;
  final String? companyName;
  final String  phone;
  final double  outstandingBalance;

  const AccountantSupplierDetailScreen({
    super.key,
    required this.supplierId,
    required this.supplierName,
    this.companyName,
    required this.phone,
    required this.outstandingBalance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColor.textDark),
          title: const Text(
            'Supplier Detail',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColor.textDark,
            ),
          ),
        ),
        body: Column(
          children: [
            // ── Header card ───────────────────────────────────
            _HeaderCard(
              name: supplierName,
              companyName: companyName,
              phone: phone,
              outstanding: outstandingBalance,
            ),

            // ── Tabs ──────────────────────────────────────────
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AppColor.primary,
                unselectedLabelColor: AppColor.textMuted,
                indicatorColor: AppColor.primary,
                indicatorWeight: 2.5,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: [
                  Tab(text: 'Transactions'),
                  Tab(text: 'Orders'),
                ],
              ),
            ),

            // ── Swipeable content ─────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  _TransactionsTab(supplierId: supplierId),
                  _OrdersTab(supplierId: supplierId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header Card ───────────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final String  name;
  final String? companyName;
  final String  phone;
  final double  outstanding;

  const _HeaderCard({
    required this.name,
    required this.companyName,
    required this.phone,
    required this.outstanding,
  });

  String _money(double v) {
    final neg = v < 0;
    final s = v.abs().toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '${neg ? '- ' : ''}Rs. $s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  name.isNotEmpty ? name.trim()[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (companyName?.isNotEmpty == true)
                      Text(
                        companyName!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    if (phone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.phone_rounded,
                                color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              phone,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Text(
            'Outstanding Balance',
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _money(outstanding),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TAB 1 — Transactions (supplier_ledger)
// =============================================================
class _TransactionsTab extends ConsumerWidget {
  final String supplierId;
  const _TransactionsTab({required this.supplierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(accSupplierLedgerProvider(supplierId));

    return RefreshIndicator(
      color: AppColor.primary,
      onRefresh: () async =>
          ref.invalidate(accSupplierLedgerProvider(supplierId)),
      child: ledgerAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return _emptyList('Koi transaction nahi mili');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length,
            itemBuilder: (_, i) => _LedgerTile(entry: list[i]),
          );
        },
        loading: () => _loadingList(),
        error: (e, _) => _emptyList('Transactions load nahi hui'),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  final AccSupplierLedgerEntry entry;
  const _LedgerTile({required this.entry});

  String _money(double v) {
    final s = v.abs().toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'Rs. $s';
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.isCredit; // payment/return — paisa kam
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCredit
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isCredit ? AppColor.cashIn : AppColor.cashOut,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.entryTypeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColor.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _date(entry.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textMuted),
                ),
                if (entry.notes?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      entry.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColor.textMuted),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '- ' : '+ '}${_money(entry.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCredit ? AppColor.cashIn : AppColor.cashOut,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Bal: ${_money(entry.balanceAfter)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColor.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TAB 2 — Orders (purchase_orders) + expandable items
// =============================================================
class _OrdersTab extends ConsumerWidget {
  final String supplierId;
  const _OrdersTab({required this.supplierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(accSupplierOrdersProvider(supplierId));

    return RefreshIndicator(
      color: AppColor.primary,
      onRefresh: () async =>
          ref.invalidate(accSupplierOrdersProvider(supplierId)),
      child: ordersAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return _emptyList('Koi order nahi mila');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length,
            itemBuilder: (_, i) => _OrderCard(order: list[i]),
          );
        },
        loading: () => _loadingList(),
        error: (e, _) => _emptyList('Orders load nahi hue'),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final AccSupplierOrder order;
  const _OrderCard({required this.order});

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'Rs. $s';
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.poNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColor.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _date(order.orderDate),
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${_money(order.totalAmount)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textDark,
                  ),
                ),
                Text(
                  order.isFullyPaid
                      ? 'Paid'
                      : 'Baqi: ${_money(order.remainingAmount)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: order.isFullyPaid
                        ? AppColor.cashIn
                        : AppColor.cashOut,
                  ),
                ),
              ],
            ),
          ),
          children: [
            // ── Amount breakdown ──────────────────────────────
            _amountRow('Subtotal', order.subtotal),
            if (order.discountAmount > 0)
              _amountRow('Discount', -order.discountAmount),
            if (order.taxAmount > 0) _amountRow('Tax', order.taxAmount),
            _amountRow('Total', order.totalAmount, bold: true),
            _amountRow('Paid', order.paidAmount),
            const Divider(height: 18),

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
              const SizedBox(height: 8),
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

  Widget _amountRow(String label, double value, {bool bold = false}) {
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
              color: AppColor.textDark,
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
    final itemsAsync = ref.watch(accSupplierOrderItemsProvider(poId));

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

// ── Shared helpers ────────────────────────────────────────────────────────────
Widget _loadingList() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        height: 68,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );

Widget _emptyList(String msg) => ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Text(msg, style: const TextStyle(color: AppColor.textMuted)),
        ),
      ],
    );
