// =============================================================
// purchase_report_source.dart
//
// MAQSAD:
//   Purchase Report ke data source ka ek common CONTRACT (interface).
//   Do implementations isi ko follow karte hain:
//     • PurchaseReportLocalDatasource  → local postgres (Windows/Mac/mobile)
//     • PurchaseReportRemoteDatasource → Supabase RPC      (website)
//
//   Faida: provider sirf is interface (PurchaseReportSource) par depend
//   karta hai. Platform ke hisaab se woh local ya remote impl bana ke
//   notifier ko deta hai — baaki code (notifier/screen) ko farq nahi padta,
//   kyunki dono ke methods aur return-models bilkul same hain.
//
//   Saare methods optional date filter lete hain:
//     from → start date (null = no lower bound)
//     to   → end date   (null = no upper bound)
//   Kuch list methods `limit` bhi lete hain (kitne rows chahiye).
// =============================================================

import 'purchase_report_models.dart';

abstract interface class PurchaseReportSource {
  // Summary cards: total POs, received value, pending count, this-month value.
  Future<PurchaseSummaryData> getSummary({DateTime? from, DateTime? to});

  // Pie chart: har PO status (received/ordered/partial/draft/cancelled) ka count.
  Future<List<PoStatusCount>> getStatusDistribution({DateTime? from, DateTime? to});

  // Bar chart: sabse zyada PO value wale top `limit` suppliers.
  Future<List<SupplierPoValue>> getTopSuppliersByValue({
    int limit,
    DateTime? from,
    DateTime? to,
  });

  // Line chart: month-wise received PO value (filter na ho to last 6 months).
  Future<List<MonthlyPoData>> getMonthlyTrend({DateTime? from, DateTime? to});

  // Progress bars: har supplier ka ordered vs received (completion rate).
  Future<List<SupplierCompletionData>> getSupplierCompletion({
    int limit,
    DateTime? from,
    DateTime? to,
  });

  // Latest `limit` POs (newest first).
  Future<List<RecentPoEntry>> getRecentPos({
    int limit,
    DateTime? from,
    DateTime? to,
  });

  // Sirf pending POs (draft / ordered / partial).
  Future<List<RecentPoEntry>> getPendingPos({DateTime? from, DateTime? to});
}
