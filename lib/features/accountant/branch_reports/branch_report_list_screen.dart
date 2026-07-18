import 'package:flutter/material.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/account_branch_stock_inventory_report/presentation/screen/accountant_branch_stock_inventory_report_screen.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/accountant_customer_ledger/presentation/screen/accountant_customer_ledger_screen.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/accountant_dashboard/presentation/screen/accountant_dashboard_screen.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/accountant_discount_wise_sale_report/presentation/screen/accountant_discount_wise_sale_report_screen.dart';
import '../../../../../../core/color/app_color.dart';
import 'accountant_branch_transaction/presentation/screen/accountant_branch_transaction_report_screen.dart';
import 'accountant_category_wise_sale_report/presentaion/screen/category_sale_report_screen.dart';
import 'accountant_customer/presentation/screen/accountant_customer_report_screen.dart';
import 'accountant_profit_loss_report/presentation/screen/accountant_profit_loss_report_screen.dart';
import 'accountant_sale_report/presentation/screen/accountant_sale_report_screen.dart';
import 'accountant_sale_return_report/presentation/screen/sale_return_report_screen.dart';
import 'ai_chatbot_screen.dart';
import 'branch_cash_counter_report/presentation/screen/branch_cash_counter_screen.dart';
import 'branch_stock_damage_report/presentation/screen/accountant_branch_stock_damage_report_screen.dart';
import 'inventory_counting/presentation/screen/inventory_counting_report_screen.dart';

class BranchReportListScreen extends StatelessWidget {
  const BranchReportListScreen({super.key, required this.branchId});
  final String branchId;

  static const List<_ReportItem> _reports = [
    _ReportItem(
      icon:     Icons.dashboard_rounded,
      label:    'Dashboard',
      subtitle: 'Overview of branch activities',
      color:    AppColor.primary,
    ),
    _ReportItem(
      icon:     Icons.receipt_long_rounded,
      label:    'Sale Invoice Report',
      subtitle: 'All sale invoices record',
      color:    Color(0xFF10B981),
    ),
    _ReportItem(
      icon:     Icons.assignment_return_rounded,
      label:    'Sale Return Report',
      subtitle: 'Details of returned items',
      color:    Color(0xFFF59E0B),
    ),
    _ReportItem(
      icon:     Icons.inventory_2_rounded,
      label:    'Inventory Report',
      subtitle: 'Stock and items list',
      color:    Color(0xFF8B5CF6),
    ),
    _ReportItem(
      icon:     Icons.point_of_sale_rounded,
      label:    'Cash Counter Report',
      subtitle: 'Cash transactions record',
      color:    Color(0xFF06B6D4),
    ),
    _ReportItem(
      icon:     Icons.summarize_rounded,
      label:    'Branch Inventory Counting Report',
      subtitle: 'Complete Branch Inventory Counting Report',
      color:    Color(0xFFEC4899),
    ),
    _ReportItem(
      icon:     Icons.swap_horiz_rounded,
      label:    'Branch Transaction Report',
      subtitle: 'Details of all transactions',
      color:    Color(0xFFF97316),
    ),
    _ReportItem(
      icon:     Icons.people_alt_rounded,
      label:    'Customer Report',
      subtitle: 'Complete customers list',
      color:    Color(0xFF14B8A6),
    ),
    _ReportItem(
      icon:     Icons.menu_book_rounded,
      label:    'Customer Ledger Report',
      subtitle: 'Customer account details',
      color:    Color(0xFF6366F1),
    ),
    _ReportItem(
      icon:     Icons.trending_up_rounded,
      label:    'Profit and Loss Report',
      subtitle: 'Sale profit and loss report',
      color:    Color(0xFF059669),
    ),
    _ReportItem(
      icon:     Icons.category_rounded,
      label:    'Category Wise Sale Report',
      subtitle: 'Track sales by category',
      color:    Color(0xFFD97706),
    ),
    _ReportItem(
      icon:     Icons.assignment_return_rounded,
      label:    'Discount Wise Sale Report',
      subtitle: 'Details of Discount Wise items',
      color:    Color(0xFFF59E0B),
    ),
    _ReportItem(
      icon:     Icons.inventory_2_rounded,
      label:    'Inventory Stock Damage Report',
      subtitle: 'Show All damage Stock',
      color:    Color(0xFF8B5CF6),
    ),
  ];

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

  @override
  Widget build(BuildContext context) {
    final desktop = _isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: desktop ? _DesktopLayout(
        reports:  _reports,
        branchId: branchId,
        onTap:    (i) => _onTap(context, i),
      ) :
      _MobileLayout(
        reports:  _reports,
        branchId: branchId,
        onTap:    (i) => _onTap(context, i),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AIBusinessChatbotScreen()),),
        backgroundColor: AppColor.primary,
        child: const Icon(Icons.support_agent, color: Colors.white),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AccountantBranchDashboardScreen(branchId: branchId),
        ));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AccountantSaleReportScreen(branchId: branchId),
        ));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AccountantSaleReturnReportScreen(branchId: branchId),
        ));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AccountantBranchInventoryReportScreen(branchId: branchId),
        ));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => BranchCashCounterReportScreen(branchId: branchId),
        ));
        break;
      case 5:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => InventoryCountingReportScreen(
            storeId: branchId,
          ),
        ));
        break;
      case 6:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AccountantBranchTransactionScreen(branchId: branchId),
        ));
        break;
      case 7:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AccountantCustomerReportScreen(branchId: branchId),
        ));
        break;
      case 8:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AccountantCustomerLedgerScreen(branchId: branchId),
        ));
        break;
      case 9:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PnlReportScreen(branchId: branchId),
        ));
        break;
      case 10:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CategorySaleReportScreen(branchId: branchId),
        ));
        break;
      case 11:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DiscountWiseSaleReportScreen(branchId: branchId),
        ));
        break;
      case 12:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AccountantBranchStockDamageReportScreen(branchId: branchId),
        ));
        break;
    }
  }
}

// ── Desktop Layout ────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final List<_ReportItem> reports;
  final String branchId;
  final ValueChanged<int> onTap;

  const _DesktopLayout({
    required this.reports,
    required this.branchId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top bar ──────────────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF1A1D23)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F6FA),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Branch Reports',
                    style: TextStyle(
                      fontSize:   22,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF1A1D23),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Click on any report to view details',
                    style: TextStyle(
                        fontSize: 13, color: AppColor.textHint),
                  ),
                ],
              ),
              const Spacer(),
              // Reports count badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bar_chart_rounded,
                        size: 16, color: AppColor.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${reports.length} Reports',
                      style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // ── Grid ────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisExtent:     110,
                crossAxisSpacing:   16,
                mainAxisSpacing:    16,
              ),
              itemCount: reports.length,
              itemBuilder: (_, i) => _ReportGridCard(
                item:  reports[i],
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Mobile Layout ─────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final List<_ReportItem> reports;
  final String branchId;
  final ValueChanged<int> onTap;

  const _MobileLayout({
    required this.reports,
    required this.branchId,
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

// ── Report Grid Card (Desktop) ────────────────────────────────────────────────
class _ReportGridCard extends StatelessWidget {
  final _ReportItem  item;
  final VoidCallback onTap;

  const _ReportGridCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width:  48,
              height: 48,
              decoration: BoxDecoration(
                color:        item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:  MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF1A1D23),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColor.textHint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded,
                size: 16, color: item.color),
          ],
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
                child: Icon(item.icon, color: item.color, size: 22),
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
  final IconData icon;
  final String   label;
  final String   subtitle;
  final Color    color;

  const _ReportItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });
}