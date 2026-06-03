import 'package:flutter/material.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/account_branch_stock_inventory_report/presentation/screen/accountant_branch_stock_inventory_report_screen.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/accountant_branch_summary/presentation/screen/accountant_branch_summary_report_screen.dart';
import 'package:jan_ghani_final/features/accountant/branch_reports/accountant_customer_ledger/presentation/screen/accountant_customer_ledger_screen.dart';
import '../../../../../../core/color/app_color.dart';
import 'accountant_customer/presentation/screen/accountant_customer_report_screen.dart';
import 'accountant_profit_loss_report/presentation/screen/accountant_profit_loss_report_screen.dart';
import 'accountant_sale_report/presentation/screen/accountant_sale_report_screen.dart';
import 'accountant_sale_return_report/presentation/screen/sale_return_report_screen.dart';
import 'ai_chatbot_screen.dart';
import 'branch_cash_counter_report/presentation/screen/branch_cash_counter_screen.dart';

class BranchReportListScreen extends StatelessWidget {
  const BranchReportListScreen({super.key, required this.branchId});
  final String branchId;

  static const List<_ReportItem> _reports = [
    _ReportItem(
      icon:     Icons.dashboard_rounded,
      label:    'Dashboard',
      subtitle: 'Branch ka overview dekhein',
      color:    AppColor.primary,
    ),
    _ReportItem(
      icon:     Icons.receipt_long_rounded,
      label:    'Sale Invoice Report',
      subtitle: 'Saari sale invoices ka record',
      color:    Color(0xFF10B981),
    ),
    _ReportItem(
      icon:     Icons.assignment_return_rounded,
      label:    'Sale Return Report',
      subtitle: 'Returned items ki detail',
      color:    Color(0xFFF59E0B),
    ),
    _ReportItem(
      icon:     Icons.inventory_2_rounded,
      label:    'Inventory Report',
      subtitle: 'Stock aur items ki list',
      color:    Color(0xFF8B5CF6),
    ),
    _ReportItem(
      icon:     Icons.point_of_sale_rounded,
      label:    'Cash Counter Report',
      subtitle: 'Cash transactions ka hisaab',
      color:    Color(0xFF06B6D4),
    ),
    _ReportItem(
      icon:     Icons.summarize_rounded,
      label:    'Branch Summary Report',
      subtitle: 'Branch ki mukammal summary',
      color:    Color(0xFFEC4899),
    ),
    _ReportItem(
      icon:     Icons.swap_horiz_rounded,
      label:    'Branch Transaction Report',
      subtitle: 'Saare transactions ki detail',
      color:    Color(0xFFF97316),
    ),
    _ReportItem(
      icon:     Icons.people_alt_rounded,
      label:    'Customer Report',
      subtitle: 'Customers ki mukammal list',
      color:    Color(0xFF14B8A6),
    ),
    _ReportItem(
      icon:     Icons.menu_book_rounded,
      label:    'Customer Ledger Report',
      subtitle: 'Customer ka hisaab kitaab',
      color:    Color(0xFF6366F1),
    ),
    _ReportItem(
      icon:     Icons.menu_book_rounded,
      label:    'Profit and Loss Report',
      subtitle: 'sale profit and loss report',
      color:    Color(0xFF6366F1),
    ),
  ];

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
        itemCount:        _reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ReportCard(
          item:     _reports[i],
          index:    i,
          onTap:    () => _onTap(context, i),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => AIBusinessChatbotScreen()));
        },
        child: Icon(Icons.support_agent),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 1: // Sale Invoice Report
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountantSaleReportScreen(branchId: branchId),
          ),
        );
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BranchCashCounterReportScreen(branchId: branchId),
          ),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BranchSummaryReportScreen(branchId: branchId),
          ),
        );
        break;
      case 7:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountantCustomerReportScreen(branchId: branchId),
          ),
        );
        break;
      case 8:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountantCustomerLedgerScreen(branchId: branchId),
          ),
        );
        break;
      case 9:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PnlReportScreen(branchId: branchId),  // ← ADD
          ),
        );
        break;
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  Report Card
// ═══════════════════════════════════════════════════════════

class _ReportCard extends StatelessWidget {
  final _ReportItem  item;
  final int          index;
  final VoidCallback onTap;

  const _ReportCard({
    required this.item,
    required this.index,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [

              // Icon Box
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

              // Label + Subtitle
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
                        fontSize: 12,
                        color:    AppColor.textHint,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                width:  30,
                height: 30,
                decoration: BoxDecoration(
                  color:        item.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size:  14,
                  color: item.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Data Class
// ═══════════════════════════════════════════════════════════

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