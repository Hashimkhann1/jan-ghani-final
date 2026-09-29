// lib/features/accountant/branch_reports/accountant_branch_dashboard/data/model/accountant_branch_dashboard_model.dart

// ═══════════════════════════════════════════════════════════
//  MODEL
// ═══════════════════════════════════════════════════════════

class AccountantBranchDashboardModel {
  // ── Sales ──────────────────────────────────────────────
  final double totalSale;             // sale_invoices → sum(grand_total)
  final double cashSale;              // sale_invoice_payments → payment_method='cash'
  final double cardSale;              // sale_invoice_payments → payment_method='card'
  final double creditSale;            // sale_invoice_payments → payment_method='credit'
  final double installmentSale;       // customer_ledger → sum(pay_amount)
  final double totalAmountReceived;   // cashSale + cardSale + installmentSale

  // ── Returns ────────────────────────────────────────────
  final double totalSaleReturn;       // sale_returns → grand_total

  // ── Net & Profit ───────────────────────────────────────
  final double netSale;               // totalSale - totalSaleReturn
  final double grossProfit;           // (salePrice - purchasePrice) × qty - discount

  // ── Inventory ──────────────────────────────────────────
  final double inventoryValue;        // stock × purchase_price (Stock Purchase Value)
  final double stockSaleValue;        // stock × sale_price     (Stock Sale Value)

  // ── Cash ─────────────────────────────────────────────────
  final double cashIn;                // branch_cash_transaction → transaction_type='cash_in'
  final double cashOut;               // branch_cash_transaction → transaction_type!='cash_in'

  // ── Damage ───────────────────────────────────────────────
  final double totalDamage;           // branch_stock_damage → stock_damage × purchase_price

  // ── Outstanding ────────────────────────────────────────
  final double outstandingReceivable; // customer → balance (sum)

  const AccountantBranchDashboardModel({
    required this.totalSale,
    required this.cashSale,
    required this.cardSale,
    required this.creditSale,
    required this.installmentSale,
    required this.totalAmountReceived,
    required this.totalSaleReturn,
    required this.netSale,
    required this.grossProfit,
    required this.inventoryValue,
    required this.stockSaleValue,
    required this.cashIn,
    required this.cashOut,
    required this.totalDamage,
    required this.outstandingReceivable,
  });

  factory AccountantBranchDashboardModel.empty() =>
      const AccountantBranchDashboardModel(
        totalSale:             0,
        cashSale:              0,
        cardSale:              0,
        creditSale:            0,
        installmentSale:       0,
        totalAmountReceived:   0,
        totalSaleReturn:       0,
        netSale:               0,
        grossProfit:           0,
        inventoryValue:        0,
        stockSaleValue:        0,
        cashIn:                0,
        cashOut:               0,
        totalDamage:           0,
        outstandingReceivable: 0,
      );
}

// ═══════════════════════════════════════════════════════════
//  TREND (charts) — ek bucket (din ya mahina) ka sale/profit
// ═══════════════════════════════════════════════════════════

enum DashboardTrendPeriod { weekly, monthly }

/// Dashboard ke graphs — har ek ka apna Weekly/Monthly period.
enum DashboardChart { sales, profit, credit, installment }

class DashboardTrendPoint {
  final String label;       // 'Mon' / 'Jan'
  final double sale;        // sale_invoices grand_total
  final double saleReturn;  // sale_returns grand_total
  final double profit;      // gross profit (returns minus)
  final double creditSale;  // sale_invoice_payments → payment_method='credit'
  final double installment; // customer_ledger → sum(pay_amount)

  const DashboardTrendPoint({
    required this.label,
    required this.sale,
    required this.saleReturn,
    required this.profit,
    required this.creditSale,
    required this.installment,
  });

  double get netSale => sale - saleReturn;
}
