// lib/features/accountant/branch_reports/accountant_branch_dashboard/data/model/accountant_branch_dashboard_model.dart

// ═══════════════════════════════════════════════════════════
//  MODEL
// ═══════════════════════════════════════════════════════════

class AccountantBranchDashboardModel {
  // ── Sales ──────────────────────────────────────────────
  final double totalSale;             // branch_cash_counter → total_sale
  final double cashSale;              // branch_cash_counter → cash_sale
  final double cardSale;              // branch_cash_counter → card_sale
  final double creditSale;            // branch_cash_counter → credit_sale
  final double totalAmountReceived;   // branch_cash_counter → total_amount

  // ── Returns ────────────────────────────────────────────
  final double totalSaleReturn;       // sale_returns → grand_total

  // ── Net & Profit ───────────────────────────────────────
  final double netSale;               // totalSale - totalSaleReturn
  final double grossProfit;           // (salePrice - purchasePrice) × qty - discount

  // ── Inventory ──────────────────────────────────────────
  final double inventoryValue;        // stock × purchase_price

  // ── Outstanding ────────────────────────────────────────
  final double outstandingReceivable; // customer → balance (sum)

  const AccountantBranchDashboardModel({
    required this.totalSale,
    required this.cashSale,
    required this.cardSale,
    required this.creditSale,
    required this.totalAmountReceived,
    required this.totalSaleReturn,
    required this.netSale,
    required this.grossProfit,
    required this.inventoryValue,
    required this.outstandingReceivable,
  });

  factory AccountantBranchDashboardModel.empty() =>
      const AccountantBranchDashboardModel(
        totalSale:             0,
        cashSale:              0,
        cardSale:              0,
        creditSale:            0,
        totalAmountReceived:   0,
        totalSaleReturn:       0,
        netSale:               0,
        grossProfit:           0,
        inventoryValue:        0,
        outstandingReceivable: 0,
      );
}