// =============================================================
// specific_supplier_detail_screen.dart
// Supplier detail screen — sidebar nahi hai
// Layout: TopBar → 3 Stat Cards → Tabs → Table (full width)
// Supplier name click → SupplierInfoDialog
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/supplier/domian/supplier_detail_models.dart';
import 'package:jan_ghani_final/features/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/supplier/presentation/provider/supplier_detail_provider/supplier_detail_provider.dart';
import 'package:jan_ghani_final/features/supplier/presentation/widgets/pay_outstanding_dialog/pay_outstanding_dialog.dart';
import 'package:jan_ghani_final/features/supplier/presentation/widgets/supplier_detail_widgets/supplier_detail_widgets.dart';
import 'package:jan_ghani_final/features/supplier/presentation/widgets/supplier_info_dialog/supplier_info_dialog.dart';


class SpecificSupplierDetailScreen extends ConsumerStatefulWidget {
  final SupplierModel supplier;

  const SpecificSupplierDetailScreen({
    super.key,
    required this.supplier,
  });

  @override
  ConsumerState<SpecificSupplierDetailScreen> createState() =>
      _SpecificSupplierDetailScreenState();
}

class _SpecificSupplierDetailScreenState
    extends ConsumerState<SpecificSupplierDetailScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(supplierDetailProvider.notifier).loadData(widget.supplier.id));
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(supplierDetailProvider);
    final notifier = ref.read(supplierDetailProvider.notifier);
    final s        = widget.supplier;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // ── 1. Top bar ─────────────────────────────
          _TopBar(
            supplier: s,
            // Supplier name click → info dialog
            onNameTap: () => SupplierInfoDialog.show(context, s),
          ),

          // ── 2. Financial summary cards ──────────────
          if (state.financialSummary != null)
            _FinancialSummaryRow(summary: state.financialSummary!),

          // ── 3. Tab bar ─────────────────────────────
          _TabBar(
            activeTab:    state.activeTab,
            ledgerCount:  state.ledgerEntries.length,
            ordersCount:  state.purchaseOrders.length,
            onTabChanged: notifier.switchTab,
          ),

          // ── 4. Table — full width ───────────────────
          Expanded(
            child: state.activeTab == 'ledger'
                ? _LedgerTable(entries: state.ledgerEntries)
                : _OrdersTable(
              orders:        state.purchaseOrders,
              supplierName:  s.name,
              supplierModel: s, // ← ADD (s = widget.supplier)
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
  final SupplierModel supplier;
  final VoidCallback  onNameTap; // supplier name click → dialog

  const _TopBar({required this.supplier, required this.onNameTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color:  AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // ── Back button ────────────────────────────────
          InkWell(
            onTap:        () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border:       Border.all(color: AppColor.grey200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded,
                      size: 13, color: AppColor.textSecondary),
                  const SizedBox(width: 6),
                  Text('Suppliers',
                      style: TextStyle(fontSize: 13,
                          color: AppColor.textSecondary)),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: AppColor.grey200),
          const SizedBox(width: 16),

          // ── Avatar ─────────────────────────────────────
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color:        AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              supplier.name.isNotEmpty
                  ? supplier.name[0].toUpperCase() : '?',
              style: TextStyle(fontWeight: FontWeight.w700,
                  color: AppColor.primary, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),

          // ── Supplier name (clickable) + code ───────────
          Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name — click karo to dialog open ho
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onNameTap,
                  child: Text(
                    supplier.name,
                    style: TextStyle(
                      fontSize:      16,
                      fontWeight:    FontWeight.w700,
                      color:         AppColor.textPrimary,
                      // Subtle underline hint ke liye
                      decoration:    TextDecoration.underline,
                      decorationColor: AppColor.grey300,
                      decorationStyle: TextDecorationStyle.dotted,
                    ),
                  ),
                ),
              ),
              if (supplier.code != null)
                Text(supplier.code!,
                    style: TextStyle(fontSize: 11,
                        color: AppColor.textSecondary)),
            ],
          ),

          const SizedBox(width: 10),

          // ── Active badge ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: supplier.isActive
                  ? AppColor.successLight : AppColor.grey200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: supplier.isActive
                        ? AppColor.success : AppColor.grey400,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  supplier.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color: supplier.isActive
                        ? AppColor.success : AppColor.grey600,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          InkWell(
            onTap:        () => PayOutstandingDialog.show(context, supplier),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:        AppColor.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(color: AppColor.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments_outlined, size: 15, color: AppColor.success),
                  const SizedBox(width: 6),
                  Text('Pay Amount',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColor.success)),
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
// FINANCIAL SUMMARY ROW — 3 stat cards
// ─────────────────────────────────────────────────────────────

class _FinancialSummaryRow extends StatelessWidget {
  final SupplierFinancialSummary summary;

  const _FinancialSummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   AppColor.surface,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        children: [
          DetailStatCard(
            label:    'Outstanding Balance',
            value:    'Rs ${_fmt(summary.outstandingBalance)}',
            subtitle: summary.outstandingBalance > 0
                ? 'Dena baaki hai' : 'Clear',
            icon:     Icons.account_balance_wallet_outlined,
            color:    summary.outstandingBalance > 0
                ? AppColor.error : AppColor.success,
          ),
          const SizedBox(width: 12),
          DetailStatCard(
            label:    'Total Purchased',
            value:    'Rs ${_fmt(summary.totalPurchased)}',
            subtitle: '${summary.totalOrders} orders total',
            icon:     Icons.shopping_cart_outlined,
            color:    AppColor.info,
          ),
          const SizedBox(width: 12),
          DetailStatCard(
            label:    'Total Paid',
            value:    'Rs ${_fmt(summary.totalPaid)}',
            subtitle: '${summary.pendingOrders} orders pending',
            icon:     Icons.payments_outlined,
            color:    AppColor.success,
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final String               activeTab;
  final int                  ledgerCount;
  final int                  ordersCount;
  final ValueChanged<String> onTabChanged;

  const _TabBar({
    required this.activeTab,
    required this.ledgerCount,
    required this.ordersCount,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color:   AppColor.surface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color:        AppColor.grey100,
              borderRadius: BorderRadius.circular(10),
              border:       Border.all(color: AppColor.grey200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DetailTabButton(
                  label:     'Ledger History',
                  value:     'ledger',
                  activeTab: activeTab,
                  count:     ledgerCount,
                  onTap:     () => onTabChanged('ledger'),
                ),
                const SizedBox(width: 3),
                DetailTabButton(
                  label:     'Purchase Orders',
                  value:     'orders',
                  activeTab: activeTab,
                  count:     ordersCount,
                  onTap:     () => onTabChanged('orders'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LEDGER TABLE — full width
// ─────────────────────────────────────────────────────────────

class _LedgerTable extends StatelessWidget {
  final List<SupplierLedgerEntry> entries;

  const _LedgerTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Icon column ke liye extra SizedBox header
            _buildHeader(),

            Expanded(
              child: entries.isEmpty
                  ? _emptyState('Koi ledger entry nahi')
                  : ListView.separated(
                itemCount:        entries.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColor.grey100),
                itemBuilder: (_, i) => LedgerEntryRow(
                  key:   ValueKey(entries[i].id),
                  entry: entries[i],
                ),
              ),
            ),

            _footer('${entries.length} entries'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        color:  AppColor.grey100,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          // Icon column — no label
          const SizedBox(width: 44),
          ..._headerCells(kLedgerHeaders),
        ],
      ),
    );
  }

  List<Widget> _headerCells(List<TableHeaderCell> cols) => cols
      .where((c) => c.label.isNotEmpty)
      .map((c) => Expanded(
    flex: c.flex,
    child: Text(c.label,
        style: const TextStyle(fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF757575),
            letterSpacing: 0.4)),
  ))
      .toList();
}

// ─────────────────────────────────────────────────────────────
// ORDERS TABLE — full width
// ─────────────────────────────────────────────────────────────

class _OrdersTable extends StatelessWidget {
  final List<SupplierPurchaseOrder> orders;
  final String supplierName;
  final SupplierModel supplierModel; // ← ADD

  const _OrdersTable({
    required this.orders,
    required this.supplierName,
    required this.supplierModel, // ← ADD
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            TableHeaderRow(columns: kOrderHeaders),

            Expanded(
              child: orders.isEmpty
                  ? _emptyState('Koi purchase order nahi')
                  : ListView.separated(
                itemCount:        orders.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColor.grey100),
                itemBuilder: (_, i) => PurchaseOrderRow(
                  key:   ValueKey(orders[i].id),
                  order: orders[i],
                  // Row click → PO detail dialog open karo
                  onTap: () => PurchaseOrderDetailDialog.show(
                    context,
                    orders[i],
                    supplierName,
                    supplierModel: supplierModel, // ← ADD
                  ),
                ),
              ),
            ),

            _footer('${orders.length} orders'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────

Widget _emptyState(String message) {
  return Center(
    child: Text(message,
        style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E))),
  );
}

Widget _footer(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF5F5F5)))),
    child: Row(children: [
      Text(label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
    ]),
  );
}