// =============================================================
// supplier_report_source.dart
//
// Supplier Report ke data source ka common CONTRACT (interface).
// Do implementations isko follow karte hain:
//   • SupplierReportLocalDatasource  → local postgres (Windows/Mac/mobile)
//   • SupplierReportRemoteDatasource → Supabase raw fetch + Dart compute (web)
//
// (Supplier data chhota hai — 45+, future ~600 — isliye web par koi RPC/
//  view NAHI banayi; remote bas raw rows fetch karke aggregates app mein
//  compute karta hai.)
//
// Faida: provider sirf is interface par depend karta hai aur platform ke
// hisaab se sahi impl pick karta hai — baaki code (notifier/screen) ko
// farq nahi padta.
//
// Date filter (from/to) — null = no bound. Kuch list methods `limit` lete.
// =============================================================

import 'supplier_report_models.dart';

abstract interface class SupplierReportSource {
  // Summary cards (supplier counts/outstanding LIVE hain; total purchased
  // date range follow karta hai).
  Future<SupplierSummaryData> getSummary({DateTime? from, DateTime? to});

  // Outstanding balance pie — top `limit` suppliers jin pe baqaya hai.
  Future<List<SupplierBalanceItem>> getTopByBalance({int limit});

  // Purchase volume bar chart — top `limit` suppliers (date-filtered).
  Future<List<SupplierPurchaseItem>> getTopByPurchase({
    int limit,
    DateTime? from,
    DateTime? to,
  });

  // Monthly purchase trend (filter na ho to last 6 months).
  Future<List<MonthlyPurchaseData>> getMonthlyTrend({DateTime? from, DateTime? to});

  // Supplier balance table — saare active suppliers + PO aggregation,
  // balanceStatus ke hisaab se filter (all / outstanding / clear).
  Future<List<SupplierBalanceItem>> getAllSuppliers({
    DateTime? from,
    DateTime? to,
    BalanceStatusFilter balanceStatus,
  });

  // Recent ledger entries (latest `limit`, date-filtered).
  Future<List<RecentLedgerEntry>> getRecentLedger({
    int limit,
    DateTime? from,
    DateTime? to,
  });
}
