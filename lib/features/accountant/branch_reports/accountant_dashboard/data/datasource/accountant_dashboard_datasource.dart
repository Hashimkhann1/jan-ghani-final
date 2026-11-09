import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../common/special_products.dart';
import '../model/accountant_dashboard_model.dart';

// ═══════════════════════════════════════════════════════════
//  DATASOURCE
// ═══════════════════════════════════════════════════════════

class AccountantBranchDashboardDatasource {
  final _client = Supabase.instance.client;
  final String  branchId;

  AccountantBranchDashboardDatasource({required this.branchId});

  // ── Date helpers — timezone-safe ─────────────────────────
  // fromDate/toDate ab exact time bhi carry karte hain (time filter),
  // is liye yahan din ki shuruaat/aakhir force nahi ki jaati.
  static String _fromStr(DateTime d) => d.toUtc().toIso8601String();

  static String _toStr(DateTime d) => d.toUtc().toIso8601String();

  // ── Special products (Digital + Pull PMG) ────────────────
  // Main cards/graphs sirf normal products dikhate hain. Do group alag hote hain:
  //  • Digital  → product_type != 'physical' (Bank Transfer / Pay Bill / SIM Load…)
  //  • Pull PMG → category ka naam "Pull PMG" ho
  // Invoice us group ki hoti hai jis ka koi item usme ho (digital ko priority).
  ({Set<String> digital, Set<String> pmg})? _special;

  Future<({Set<String> digital, Set<String> pmg})> _specialProductIds() async {
    final cached = _special;
    if (cached != null) return cached;

    final r = await loadSpecialProductIds(_client, branchId);
    return _special = r;
  }

  /// Range ki digital + PMG invoices ka total / payments / profit (deduped).
  Future<List<_SpecialInvoice>> _specialInvoices(
      DateTime from, DateTime to) async {
    final ids = await _specialProductIds();
    final all = {...ids.digital, ...ids.pmg};
    if (all.isEmpty) return const [];
    const chunk = 1000;
    final out = <String, _SpecialInvoice>{};
    var start = 0;
    while (true) {
      final rows = await _client
          .from('sale_invoice_items')
          .select('id, product_id, sale_price, purchase_price, quantity, '
              'discount, sale_invoices!inner(id, invoice_date, grand_total, '
              'sale_invoice_payments(payment_method, amount))')
          .inFilter('product_id', all.toList())
          .eq('sale_invoices.store_id', branchId)
          .eq('sale_invoices.status', 'completed')
          .filter('sale_invoices.deleted_at', 'is', null)
          .gte('sale_invoices.invoice_date', _fromStr(from))
          .lte('sale_invoices.invoice_date', _toStr(to))
          .order('id')
          .range(start, start + chunk - 1) as List;
      for (final r in rows) {
        final inv = r['sale_invoices'] as Map;
        final id  = inv['id'].toString();
        final isDigital = ids.digital.contains(r['product_id'].toString());
        final d = out.putIfAbsent(id, () {
          double pay(String m) =>
              (inv['sale_invoice_payments'] as List? ?? [])
                  .where((p) => p['payment_method'] == m)
                  .fold<double>(0, (a, p) => a + (_dbl(p['amount']) ?? 0));
          return _SpecialInvoice(
            date:      DateTime.parse(inv['invoice_date'].toString()).toLocal(),
            total:     _dbl(inv['grand_total']) ?? 0,
            cash:      pay('cash'),
            card:      pay('card'),
            credit:    pay('credit'),
            isDigital: isDigital,
          );
        });
        // Digital ko priority: mixed invoice digital maani jati hai.
        if (isDigital) d.isDigital = true;
        d.profit += ((_dbl(r['sale_price']) ?? 0) -
                    (_dbl(r['purchase_price']) ?? 0)) *
                (_dbl(r['quantity']) ?? 0) -
            (_dbl(r['discount']) ?? 0);
      }
      if (rows.length < chunk) break;
      start += chunk;
    }
    return out.values.toList();
  }

  // ── RPC call — ek range ka summary row ───────────────────
  Future<Map<String, dynamic>> _summary(DateTime from, DateTime to) async {
    // Sab kuch ek indexed RPC mein (get_branch_dashboard_summary) —
    // 2026_09_25_branch_dashboard_summary.sql.
    final res = await _client.rpc('get_branch_dashboard_summary', params: {
      'p_store_id': branchId,
      'p_from':     _fromStr(from),
      'p_to':       _toStr(to),
    });
    return (res is List ? (res.isEmpty ? <String, dynamic>{} : res.first) : res)
        as Map<String, dynamic>;
  }

  // ── Main method ──────────────────────────────────────────
  Future<AccountantBranchDashboardModel> getDashboard({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final results = await Future.wait([
      _summary(fromDate, toDate),
      _specialInvoices(fromDate, toDate),
    ]);
    final row     = results[0] as Map<String, dynamic>;
    final special = results[1] as List<_SpecialInvoice>;
    double ssum(Iterable<_SpecialInvoice> l, double Function(_SpecialInvoice) f) =>
        l.fold<double>(0, (a, d) => a + f(d));
    final digital = special.where((d) => d.isDigital).toList();
    final pmg     = special.where((d) => !d.isDigital).toList();
    final dTotal  = ssum(special, (d) => d.total);
    final dCash   = ssum(special, (d) => d.cash);
    final dCard   = ssum(special, (d) => d.card);
    final dCredit = ssum(special, (d) => d.credit);
    final dReceived = dCash + dCard;
    double v(String k) => _dbl(row[k]) ?? 0;

    return AccountantBranchDashboardModel(
      totalSale:             v('total_sale') - dTotal,
      cashSale:              v('cash_sale') - dCash,
      cardSale:              v('card_sale') - dCard,
      creditSale:            v('credit_sale') - dCredit,
      installmentSale:       v('installment'),
      totalAmountReceived:   v('cash_sale') + v('card_sale') + v('installment') - dReceived,
      totalSaleReturn:       v('total_return'),
      netSale:               v('total_sale') - dTotal - v('total_return'),
      // Total profit (physical + Pull PMG + digital).
      grossProfit:           v('gross_profit'),
      pmgSale:               ssum(pmg, (d) => d.total),
      pmgProfit:             ssum(pmg, (d) => d.profit),
      digitalSale:           ssum(digital, (d) => d.total),
      digitalProfit:         ssum(digital, (d) => d.profit),
      inventoryValue:        v('stock_purchase'),
      stockSaleValue:        v('stock_sale'),
      cashIn:                v('cash_in'),
      cashOut:               v('cash_out'),
      totalDamage:           v('damage'),
      outstandingReceivable: v('outstanding'),
    );
  }

  // ── Trend (charts) ───────────────────────────────────────
  // weekly  → [endDate] tak pichle 7 din, har din ek bucket
  // monthly → [endDate] tak pichle 6 mahine, har mahina ek bucket
  // Saare buckets ek RPC call mein.
  Future<List<DashboardTrendPoint>> getTrend({
    required DateTime            endDate,
    required DashboardTrendPeriod period,
  }) async {
    final buckets = <(String, DateTime, DateTime)>[];
    if (period == DashboardTrendPeriod.weekly) {
      final dayFmt = DateFormat('EEE');
      for (var i = 6; i >= 0; i--) {
        final d = DateTime(endDate.year, endDate.month, endDate.day - i);
        buckets.add((
          dayFmt.format(d),
          d,
          DateTime(d.year, d.month, d.day, 23, 59, 59),
        ));
      }
    } else {
      final monFmt = DateFormat('MMM');
      for (var i = 5; i >= 0; i--) {
        final m = DateTime(endDate.year, endDate.month - i);
        buckets.add((
          monFmt.format(m),
          m,
          DateTime(m.year, m.month + 1, 1).subtract(const Duration(seconds: 1)),
        ));
      }
    }

    // Ek hi RPC saare buckets ke liye (get_branch_dashboard_trend) —
    // 2026_10_18_branch_dashboard_trend.sql.
    final trendFut = _client.rpc('get_branch_dashboard_trend', params: {
      'p_store_id': branchId,
      'p_starts':   [for (final b in buckets) _fromStr(b.$2)],
      'p_ends':     [for (final b in buckets) _toStr(b.$3)],
    });
    final digitalFut =
        _specialInvoices(buckets.first.$2, buckets.last.$3);
    final res     = await trendFut;
    final digital = await digitalFut;

    // Har digital/PMG invoice ko uske bucket ki sale/credit se minus karo
    // (profit total rehta hai).
    final dSale   = List<double>.filled(buckets.length, 0);
    final dCredit = List<double>.filled(buckets.length, 0);
    final pSale = List<double>.filled(buckets.length, 0);
    final pProfit = List<double>.filled(buckets.length, 0);
    final gSale = List<double>.filled(buckets.length, 0);
    final gProfit = List<double>.filled(buckets.length, 0);
    for (final d in digital) {
      for (var i = 0; i < buckets.length; i++) {
        if (!d.date.isBefore(buckets[i].$2) && !d.date.isAfter(buckets[i].$3)) {
          dSale[i]   += d.total;
          dCredit[i] += d.credit;
          if (d.isDigital) {
            gSale[i]   += d.total;
            gProfit[i] += d.profit;
          } else {
            pSale[i]   += d.total;
            pProfit[i] += d.profit;
          }
          break;
        }
      }
    }
    final byIdx = <int, Map<String, dynamic>>{
      for (final r in (res as List))
        (r['idx'] as num).toInt(): Map<String, dynamic>.from(r as Map),
    };

    return [
      for (var i = 0; i < buckets.length; i++)
        DashboardTrendPoint(
          label:      buckets[i].$1,
          sale:       (_dbl(byIdx[i + 1]?['total_sale'])   ?? 0) - dSale[i],
          saleReturn: _dbl(byIdx[i + 1]?['total_return']) ?? 0,
          profit:     _dbl(byIdx[i + 1]?['gross_profit']) ?? 0,
          creditSale: (_dbl(byIdx[i + 1]?['credit_sale'])  ?? 0) - dCredit[i],
          installment: _dbl(byIdx[i + 1]?['installment']) ?? 0,
          pmgSale:       pSale[i],
          pmgProfit:     pProfit[i],
          digitalSale:   gSale[i],
          digitalProfit: gProfit[i],
        ),
    ];
  }

  // ── Helper ───────────────────────────────────────────────
  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}


class _SpecialInvoice {
  final DateTime date;
  final double total, cash, card, credit;
  bool isDigital;
  double profit = 0;
  _SpecialInvoice({
    required this.date,
    required this.total,
    required this.cash,
    required this.card,
    required this.credit,
    required this.isDigital,
  });
}
