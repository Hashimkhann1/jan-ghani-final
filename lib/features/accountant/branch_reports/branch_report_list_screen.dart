import 'package:flutter/material.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/account_branch_stock_inventory_report/presentation/screen/accountant_branch_stock_inventory_report_screen.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/accountant_customer_ledger/presentation/screen/accountant_customer_ledger_screen.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/accountant_dashboard/presentation/screen/accountant_dashboard_screen.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/accountant_discount_wise_sale_report/presentation/screen/accountant_discount_wise_sale_report_screen.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/pareto_report/presentation/screen/pareto_report_screen.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';
import '../../../../../../core/color/app_color.dart';
import 'accountant_branch_transaction/presentation/screen/accountant_branch_transaction_report_screen.dart';
import 'accountant_category_wise_sale_report/presentaion/screen/category_sale_report_screen.dart';
import 'accountant_customer/presentation/screen/accountant_customer_report_screen.dart';
import 'accountant_profit_loss_report/presentation/screen/accountant_profit_loss_report_screen.dart';
import 'accountant_sale_report/presentation/screen/accountant_sale_report_screen.dart';
import 'accountant_sale_return_report/presentation/screen/sale_return_report_screen.dart';
import 'ai_chatbot_screen.dart';
import 'branch_cash_counter_report/presentation/screen/branch_cash_counter_screen.dart';
import 'branch_cash_difference/presentation/screen/branch_cash_difference_screen.dart';
import 'branch_stock_damage_report/presentation/screen/accountant_branch_stock_damage_report_screen.dart';
import 'branch_stock_inventory_logs/presentation/screen/branch_stock_inventory_logs_screen.dart';
import 'customer_logs/presentation/screen/customer_logs_screen.dart';
import 'inventory_counting/presentation/screen/inventory_counting_report_screen.dart';

/// Web/desktop par sidebar dikhane ke liye minimum width.
const double _kSidebarBreakpoint = 900;

class BranchReportListScreen extends StatefulWidget {
  const BranchReportListScreen({super.key, required this.branchId});
  final String branchId;

  @override
  State<BranchReportListScreen> createState() => _BranchReportListScreenState();
}

class _BranchReportListScreenState extends State<BranchReportListScreen> {
  /// Desktop sidebar par abhi kaunsi report khuli hai.
  int _selected = 0;

  static const List<_ReportItem> _reports = [
    _ReportItem(
      iconAsset: 'sidebar_icons/dashboard',
      label:    'Dashboard',
      subtitle: 'Overview of branch activities',
      color:    AppColor.primary,
    ),
    _ReportItem(
      iconAsset: 'sidebar_icons/sale_invoice_report',
      label:    'Sale Invoice Report',
      subtitle: 'All sale invoices record',
      color:    Color(0xFF10B981),
    ),
    _ReportItem(
      iconAsset: 'sidebar_icons/sale_return_report',
      label:    'Sale Return Report',
      subtitle: 'Details of returned items',
      color:    Color(0xFFF59E0B),
    ),
    _ReportItem(
      iconAsset: 'sidebar_icons/branch_stock',
      label:    'Inventory Report',
      subtitle: 'Stock and items list',
      color:    Color(0xFF8B5CF6),
    ),
    _ReportItem(
      iconAsset: 'sidebar_icons/cash_counter',
      label:    'Cash Counter Report',
      subtitle: 'Cash transactions record',
      color:    Color(0xFF06B6D4),
    ),
    _ReportItem(
      iconAsset: 'ic_total_products',
      label:    'Branch Inventory Counting Report',
      subtitle: 'Complete Branch Inventory Counting Report',
      color:    Color(0xFFEC4899),
    ),
    _ReportItem(
      iconAsset: 'sidebar_icons/branch_transactions',
      label:    'Branch Transaction Report',
      subtitle: 'Details of all transactions',
      color:    Color(0xFFF97316),
    ),
    _ReportItem(
      iconAsset: 'sidebar_icons/customer',
      label:    'Customer Report',
      subtitle: 'Complete customers list',
      color:    Color(0xFF14B8A6),
    ),
    _ReportItem(
      iconAsset: 'sidebar_icons/customer_ledger',
      label:    'Customer Ledger Report',
      subtitle: 'Customer account details',
      color:    Color(0xFF6366F1),
    ),
    _ReportItem(
      iconAsset: 'ic_sale_price_trend',
      label:    'Profit and Loss Report',
      subtitle: 'Sale profit and loss report',
      color:    Color(0xFF059669),
    ),
    _ReportItem(
      iconAsset: 'ic_top_products',
      label:    'Category Wise Sale Report',
      subtitle: 'Track sales by category',
      color:    Color(0xFFD97706),
    ),
    _ReportItem(
      iconAsset: 'ic_net_amount',
      label:    'Discount Wise Sale Report',
      subtitle: 'Details of Discount Wise items',
      color:    Color(0xFFF59E0B),
    ),
    _ReportItem(
      iconAsset: 'sidebar_icons/stock_damage',
      label:    'Inventory Stock Damage Report',
      subtitle: 'Show All damage Stock',
      color:    Color(0xFF8B5CF6),
    ),
    _ReportItem(
      iconAsset: 'ic_top_customers',
      label:    'Pareto Principle Report',
      subtitle: 'Top 20% products, customers & balance',
      color:    Color(0xFF8B5CF6),
    ),
    _ReportItem(
      iconAsset: 'sidebar_icons/difference',
      label:    'Cash Difference Report',
      subtitle: 'Cash in/out transaction record',
      color:    Color(0xFF0EA5E9),
    ),
    _ReportItem(
      iconAsset: 'sidebar_icons/customer_account',
      label:    'Customer Logs',
      subtitle: 'Customer balance change history',
      color:    Color(0xFF7C3AED),
    ),
    _ReportItem(
      iconAsset: 'sidebar_icons/branch_stock',
      label:    'Stock Inventory Logs',
      subtitle: 'Product stock and price change history',
      color:    Color(0xFF0891B2),
    ),
  ];

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _kSidebarBreakpoint;

  /// Index -> uski report screen (mobile push aur desktop pane dono use karte hain).
  Widget _screenForIndex(int index, String branchId) {
    switch (index) {
      case 0:  return AccountantBranchDashboardScreen(branchId: branchId);
      case 1:  return AccountantSaleReportScreen(branchId: branchId);
      case 2:  return AccountantSaleReturnReportScreen(branchId: branchId);
      case 3:  return AccountantBranchInventoryReportScreen(branchId: branchId);
      case 4:  return BranchCashCounterReportScreen(branchId: branchId);
      case 5:  return InventoryCountingReportScreen(storeId: branchId);
      case 6:  return AccountantBranchTransactionScreen(branchId: branchId);
      case 7:  return AccountantCustomerReportScreen(branchId: branchId);
      case 8:  return AccountantCustomerLedgerScreen(branchId: branchId);
      case 9:  return PnlReportScreen(branchId: branchId);
      case 10: return CategorySaleReportScreen(branchId: branchId);
      case 11: return DiscountWiseSaleReportScreen(branchId: branchId);
      case 12: return AccountantBranchStockDamageReportScreen(branchId: branchId);
      case 13: return ParetoReportScreen(branchId: branchId);
      case 14: return BranchCashDifferenceScreen(branchId: branchId);
      case 15: return CustomerLogsScreen(branchId: branchId);
      case 16: return BranchStockInventoryLogsScreen(branchId: branchId);
      default: return const SizedBox.shrink();
    }
  }

  void _openMobile(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _screenForIndex(index, widget.branchId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = _isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: desktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReportSidebar(
                  reports:  _reports,
                  selected: _selected,
                  onSelect: (i) => setState(() => _selected = i),
                  onBack:   () => Navigator.pop(context),
                ),
                const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final mq = MediaQuery.of(ctx);
                      // Report screen ko pane ki width "screen width" ki tarah
                      // dikhao taake wo apna (desktop/mobile) layout theek chune.
                      return MediaQuery(
                        data: mq.copyWith(
                          size: Size(constraints.maxWidth, mq.size.height),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey<int>(_selected),
                          child: _screenForIndex(_selected, widget.branchId),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : _MobileLayout(
              reports: _reports,
              onTap:   _openMobile,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AIBusinessChatbotScreen()),
        ),
        backgroundColor: AppColor.primary,
        child: const Icon(Icons.support_agent, color: Colors.white),
      ),
    );
  }
}

// ── Desktop Sidebar ───────────────────────────────────────────────────────────
class _ReportSidebar extends StatelessWidget {
  final List<_ReportItem> reports;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onBack;

  const _ReportSidebar({
    required this.reports,
    required this.selected,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Color(0xFF1A1D23), size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F6FA),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Branch Reports',
                        style: TextStyle(
                          fontSize:   17,
                          fontWeight: FontWeight.w800,
                          color:      Color(0xFF1A1D23),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select a report',
                        style: TextStyle(
                            fontSize: 12, color: AppColor.textHint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ── Report list ──────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: reports.length,
              itemBuilder: (_, i) => _SidebarItem(
                item:     reports[i],
                selected: i == selected,
                onTap:    () => onSelect(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _ReportItem  item;
  final bool         selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? item.color.withOpacity(0.10) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected ? item.color : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width:  36,
              height: 36,
              decoration: BoxDecoration(
                color:        item.color.withOpacity(selected ? 0.16 : 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(item.iconAsset, color: item.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? item.color : const Color(0xFF1A1D23),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColor.textHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile Layout ─────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final List<_ReportItem> reports;
  final ValueChanged<int> onTap;

  const _MobileLayout({
    required this.reports,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Branch Reports',
          style: TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.w700,
            color:      Color(0xFF1A1D23),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: ListView.separated(
        padding:          const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount:        reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ReportListCard(
          item:  reports[i],
          onTap: () => onTap(i),
        ),
      ),
    );
  }
}

// ── Report List Card (Mobile) ─────────────────────────────────────────────────
class _ReportListCard extends StatelessWidget {
  final _ReportItem  item;
  final VoidCallback onTap;

  const _ReportListCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width:  46,
                height: 46,
                decoration: BoxDecoration(
                  color:        item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcon(item.iconAsset, color: item.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w700,
                        color:      Color(0xFF1A1D23),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textHint),
                    ),
                  ],
                ),
              ),
              Container(
                width:  30,
                height: 30,
                decoration: BoxDecoration(
                  color:        item.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: item.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data Class ────────────────────────────────────────────────────────────────
class _ReportItem {
  final String iconAsset;
  final String label;
  final String subtitle;
  final Color  color;

  const _ReportItem({
    required this.iconAsset,
    required this.label,
    required this.subtitle,
    required this.color,
  });
}
