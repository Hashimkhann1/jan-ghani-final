import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/accountant_dashboard_model.dart';
import '../model/insights_model.dart';

/// Insights graphs — dono RPC database mein aggregate karte hain.
/// 2026_11_10_branch_dashboard_insights.sql run karna zaroori hai.
class InsightsDatasource {
  final _client = Supabase.instance.client;
  final String branchId;
  InsightsDatasource({required this.branchId});

  Future<InsightsResult> load(DateTime end, DashboardTrendPeriod period) async {
    // Trend buckets: weekly = 7 din, monthly = 6 mahine (dashboard jaisa).
    // Range: weekly = pichle 7 din, monthly = pichle 30 din.
    final labels = <String>[];
    final starts = <DateTime>[], ends = <DateTime>[];
    if (period == DashboardTrendPeriod.weekly) {
      final f = DateFormat('EEE');
      for (var i = 6; i >= 0; i--) {
        final d = DateTime(end.year, end.month, end.day - i);
        labels.add(f.format(d));
        starts.add(d);
        ends.add(DateTime(d.year, d.month, d.day, 23, 59, 59));
      }
    } else {
      final f = DateFormat('MMM');
      for (var i = 5; i >= 0; i--) {
        final m = DateTime(end.year, end.month - i);
        labels.add(f.format(m));
        starts.add(m);
        ends.add(DateTime(m.year, m.month + 1, 1).subtract(const Duration(seconds: 1)));
      }
    }
    final days = period == DashboardTrendPeriod.weekly ? 6 : 29;
    final from = DateTime(end.year, end.month, end.day - days);
    String iso(DateTime d) => d.toUtc().toIso8601String();

    final rangeFut = _client.rpc('get_branch_insights_range', params: {
      'p_store_id': branchId,
      'p_from': iso(from),
      'p_to': iso(end),
      'p_limit': 8,
    });
    final trendFut = _client.rpc('get_branch_insights_trend', params: {
      'p_store_id': branchId,
      'p_starts': starts.map(iso).toList(),
      'p_ends': ends.map(iso).toList(),
    });
    final r = Map<String, dynamic>.from(await rangeFut as Map);
    final t = await trendFut as List;

    List<InsightItem> items(String key, String v, [String? x, String n = 'name']) => [
          for (final e in (r[key] as List? ?? const []))
            InsightItem('${e[n]}', _d(e[v]), x == null ? 0 : _d(e[x])),
        ];

    final byIdx = {
      for (final e in t) (e['idx'] as num).toInt(): Map<String, dynamic>.from(e as Map)
    };
    return InsightsResult(
      InsightsRange(
        hourly: items('hourly', 'sale', 'count', 'hour'),
        category: items('category', 'sale', 'profit'),
        staff: items('staff', 'sale', 'count'),
        lossProducts: items('loss_products', 'loss', 'qty'),
        topCustomers: items('top_customers', 'total', 'count'),
        topUdhaar: items('top_udhaar', 'balance'),
        deadStock: items('dead_stock', 'value', 'stock'),
      ),
      [
        for (var i = 0; i < labels.length; i++)
          InsightsBucket(
            label: labels[i],
            revenue: _d(byIdx[i + 1]?['revenue']),
            profit: _d(byIdx[i + 1]?['profit']),
            discount: _d(byIdx[i + 1]?['discount']),
            credit: _d(byIdx[i + 1]?['credit']),
            recovered: _d(byIdx[i + 1]?['recovered']),
            damage: _d(byIdx[i + 1]?['damage']),
            cashIn: _d(byIdx[i + 1]?['cash_in']),
            cashOut: _d(byIdx[i + 1]?['cash_out']),
          ),
      ],
    );
  }

  static double _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
}
