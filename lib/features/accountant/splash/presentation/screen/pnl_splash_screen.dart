// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ══════════════════════════════════════════════════════════════
//  CONSTANTS
// ══════════════════════════════════════════════════════════════

const String _kBranchId          = '09ed6ad4-373d-4afb-a7fb-badb1e72e9e3';
const double _kDailyProfitTarget = 20000;

final DateTime _kCampaignStart = DateTime(2025, 7, 7);
final DateTime _kCampaignEnd   = DateTime(2026, 10, 7);

// ══════════════════════════════════════════════════════════════
//  MODEL
// ══════════════════════════════════════════════════════════════

class DayPoint {
  final DateTime date;
  final double   sale;
  final double   profit;
  const DayPoint({required this.date, required this.sale, required this.profit});
}

class SplashData {
  final double         totalSale;
  final double         totalProfit;
  final double         todaySale;
  final double         todayProfit;
  final int            daysElapsed;
  final List<DayPoint> chartPoints;
  final int            daysLeft;

  const SplashData({
    required this.totalSale,
    required this.totalProfit,
    required this.todaySale,
    required this.todayProfit,
    required this.daysElapsed,
    required this.chartPoints,
    required this.daysLeft,
  });

  double get cumulativeTarget   => _kDailyProfitTarget * daysElapsed;
  double get achievedPercent    => cumulativeTarget == 0 ? 0 : (totalProfit / cumulativeTarget * 100).clamp(0, 999);
  double get todayTarget        => _kDailyProfitTarget;
  double get todayAchievedPercent => (todayProfit / todayTarget * 100).clamp(0, 999);
}

// ══════════════════════════════════════════════════════════════
//  HELPERS
// ══════════════════════════════════════════════════════════════

double _dbl(dynamic v) {
  if (v == null) return 0;
  if (v is num)  return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

// ══════════════════════════════════════════════════════════════
//  DATA FETCHER
// ══════════════════════════════════════════════════════════════

Future<SplashData> _fetchSplashData() async {
  final client   = Supabase.instance.client;
  final now      = DateTime.now();
  final today    = DateTime(now.year, now.month, now.day);
  final todayStr = today.toIso8601String().substring(0, 10);

  final daysLeft    = _kCampaignEnd.difference(today).inDays.clamp(0, 9999);
  final daysElapsed = (today.difference(_kCampaignStart).inDays + 1).clamp(1, 9999);

  // Paginated invoices
  Future<List<Map<String, dynamic>>> fetchInvoices() async {
    const pageSize = 1000;
    int offset = 0;
    final List<Map<String, dynamic>> all = [];
    while (true) {
      final batch = await client
          .from('sale_invoices')
          .select('invoice_date, sale_invoice_items(sale_price, purchase_price, quantity, discount)')
          .eq('store_id', _kBranchId)
          .eq('status', 'completed')
          .isFilter('deleted_at', null)
          .gte('invoice_date', _kCampaignStart.toIso8601String())
          .lte('invoice_date', DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String())
          .range(offset, offset + pageSize - 1);
      final rows = (batch as List).cast<Map<String, dynamic>>();
      all.addAll(rows);
      if (rows.length < pageSize) break;
      offset += pageSize;
    }
    return all;
  }

  // Cash counter
  Future<List<Map<String, dynamic>>> fetchCounter() async {
    final raw = await client
        .from('branch_cash_counter')
        .select('counter_date, total_sale')
        .eq('store_id', _kBranchId)
        .isFilter('deleted_at', null)
        .gte('counter_date', _kCampaignStart.toIso8601String().substring(0, 10))
        .lte('counter_date', todayStr)
        .order('counter_date', ascending: true);
    return (raw as List).cast<Map<String, dynamic>>();
  }

  final results     = await Future.wait([fetchInvoices(), fetchCounter()]);
  final invoicesRaw = results[0];
  final counterRaw  = results[1];

  // Daily profit
  final Map<String, double> dailyProfit = {};
  for (final r in invoicesRaw) {
    final dateStr = r['invoice_date']?.toString() ?? '';
    if (dateStr.isEmpty) continue;
    final key   = dateStr.substring(0, 10);
    final items = (r['sale_invoice_items'] as List? ?? []).cast<Map<String, dynamic>>();
    double dayP = 0;
    for (final item in items) {
      dayP += (_dbl(item['sale_price']) - _dbl(item['purchase_price'])) * _dbl(item['quantity']) - _dbl(item['discount']);
    }
    dailyProfit[key] = (dailyProfit[key] ?? 0) + dayP;
  }

  // Daily sale
  final Map<String, double> dailySale = {};
  for (final r in counterRaw) {
    final key = r['counter_date'].toString().substring(0, 10);
    dailySale[key] = (dailySale[key] ?? 0) + _dbl(r['total_sale']);
  }

  final allKeys = <String>{...dailyProfit.keys, ...dailySale.keys}.toList()..sort();
  final List<DayPoint> points = [];
  double totSale = 0, totProfit = 0;

  for (final key in allKeys) {
    final d = DateTime.parse(key);
    final s = dailySale[key]   ?? 0;
    final p = dailyProfit[key] ?? 0;
    totSale   += s;
    totProfit += p;
    points.add(DayPoint(date: d, sale: s, profit: p));
  }

  return SplashData(
    totalSale:   totSale,
    totalProfit: totProfit,
    todaySale:   dailySale[todayStr]   ?? 0,
    todayProfit: dailyProfit[todayStr] ?? 0,
    daysElapsed: daysElapsed,
    chartPoints: points,
    daysLeft:    daysLeft,
  );
}

// ══════════════════════════════════════════════════════════════
//  SPLASH SCREEN WIDGET
// ══════════════════════════════════════════════════════════════

class PnlSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const PnlSplashScreen({super.key, required this.onComplete});

  @override
  State<PnlSplashScreen> createState() => _PnlSplashScreenState();
}

class _PnlSplashScreenState extends State<PnlSplashScreen> with TickerProviderStateMixin {

  SplashData? _data;
  bool _loading = true;

  late final AnimationController _fadeCtrl;
  late final AnimationController _progressCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<double>   _progressAnim;

  static const _green      = Color(0xFF2E7D32);
  static const _greenLight = Color(0xFF4CAF50);
  static const _greenDark  = Color(0xFF1B5E20);
  static const _bg         = Color(0xFF0C1210);
  static const _card       = Color(0xFF17211D);
  static const _border     = Color(0xFF26332D);
  static const _blue       = Color(0xFF42A5F5);
  static const _orange     = Color(0xFFFFA726);
  static const _purple     = Color(0xFFE040FB);
  static const _red        = Color(0xFFEF5350);
  static const _targetLine = Color(0xFFFF7043);

  final _amtFmt  = NumberFormat('#,##,###', 'en_IN');
  final _dateFmt = DateFormat('dd MMM');

  @override
  void initState() {
    super.initState();
    _fadeCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeAnim      = CurvedAnimation(parent: _fadeCtrl,     curve: Curves.easeOut);
    _progressAnim  = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
    // NOTE: auto-navigation timer removed. Screen now stays until the user
    // taps the Skip button — onComplete() is only called from _skipBtn().
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _fetchSplashData();
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });
      _progressCtrl.forward();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: LayoutBuilder(builder: (ctx, cons) {
          return cons.maxWidth >= 700 ? _buildWide() : _buildMobile();
        }),
      ),
    );
  }

  // ── MOBILE ───────────────────────────────────────────────────
  Widget _buildMobile() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _header(compact: true),
          const SizedBox(height: 20),
          _daysLeftCard(),
          const SizedBox(height: 14),
          _targetCard(),
          const SizedBox(height: 14),
          _todayTargetCard(),
          const SizedBox(height: 14),
          _miniStat(icon: Icons.point_of_sale_rounded, label: 'Total Sale (7 Jul – Today)',  value: _loading ? '...' : _fmt(_data?.totalSale  ?? 0), color: _blue),
          const SizedBox(height: 10),
          _miniStat(icon: Icons.trending_up_rounded,   label: 'Total Profit (7 Jul – Today)', value: _loading ? '...' : _fmt(_data?.totalProfit ?? 0), color: _greenLight),
          const SizedBox(height: 10),
          _miniStat(icon: Icons.today_rounded,         label: 'Today Sale',   value: _loading ? '...' : _fmt(_data?.todaySale   ?? 0), color: _orange),
          const SizedBox(height: 10),
          _miniStat(icon: Icons.show_chart_rounded,    label: 'Today Profit', value: _loading ? '...' : _fmt(_data?.todayProfit ?? 0), color: _purple),
          const SizedBox(height: 16),
          SizedBox(height: 300, child: _chart()),
          const SizedBox(height: 20),
          Center(child: _skipBtn()),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ── WIDE / WEB ───────────────────────────────────────────────
  Widget _buildWide() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 34),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _header(compact: false),
            const SizedBox(height: 20),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _daysLeftCard(),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: _targetCard()),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: _todayTargetCard()),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _miniStat(icon: Icons.point_of_sale_rounded, label: 'Total Sale',   value: _loading ? '...' : _fmt(_data?.totalSale  ?? 0), color: _blue),
                  const SizedBox(height: 8),
                  _miniStat(icon: Icons.trending_up_rounded,   label: 'Total Profit', value: _loading ? '...' : _fmt(_data?.totalProfit ?? 0), color: _greenLight),
                ])),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _miniStat(icon: Icons.today_rounded,      label: 'Today Sale',   value: _loading ? '...' : _fmt(_data?.todaySale   ?? 0), color: _orange),
                  const SizedBox(height: 8),
                  _miniStat(icon: Icons.show_chart_rounded, label: 'Today Profit', value: _loading ? '...' : _fmt(_data?.todayProfit ?? 0), color: _purple),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            Expanded(child: _chart()),
            const SizedBox(height: 16),
            Center(child: _skipBtn()),
          ]),
        ),
      ),
    );
  }

  // ── SHARED WIDGETS ───────────────────────────────────────────

  Widget _header({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: compact ? 36 : 44, height: compact ? 36 : 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_green, _greenDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.analytics_rounded, color: Colors.white, size: compact ? 18 : 22),
          ),
          const SizedBox(width: 10),
          Text('PnL Dashboard',
              style: TextStyle(color: Colors.white, fontSize: compact ? 22 : 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ]),
        const SizedBox(height: 4),
        Text('7 Jul 2025 – 7 Oct 2026  •  Daily Target: ${_fmt(_kDailyProfitTarget)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: compact ? 11 : 13)),
      ],
    );
  }

  Widget _daysLeftCard() {
    final now     = DateTime.now();
    final today   = DateTime(now.year, now.month, now.day);
    final dLeft   = _kCampaignEnd.difference(today).inDays.clamp(0, 9999);
    final total   = _kCampaignEnd.difference(_kCampaignStart).inDays.clamp(1, 9999);
    final elapsed = today.difference(_kCampaignStart).inDays.clamp(0, total);

    return Container(
      width: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_green.withValues(alpha: 0.85), _greenDark.withValues(alpha: 0.95)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _greenLight.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.30), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.hourglass_bottom_rounded, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text('$dLeft', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(height: 2),
        Text('days left', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (elapsed / total).clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 6),
        Text('Until 7 Oct 2026', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 9)),
      ]),
    );
  }

  Widget _targetCard() {
    if (_loading) return _shimmer(height: 130);
    if (_data == null) return const SizedBox.shrink();

    final achieved  = _data!.achievedPercent;
    final isHit     = achieved >= 100;
    final barColor  = isHit ? _greenLight : _red;
    final cumTarget = _data!.cumulativeTarget;

    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (_, __) {
        final animVal    = _progressAnim.value;
        final displayPct = (achieved * animVal).clamp(0.0, 999.0);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('OVERALL TARGET', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text('${_data!.daysElapsed} days × ${_fmt(_kDailyProfitTarget)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
              ]),
              _badge(isHit ? (achieved > 100 ? 'Exceeded' : 'On Track') : 'Behind', isHit ? _greenLight : _red),
            ]),
            const SizedBox(height: 8),
            Text(_fmt(cumTarget), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ((achieved / 100) * animVal).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 7),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${displayPct.toStringAsFixed(1)}% achieved',
                  style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.w700)),
              Text(_fmt(_data!.totalProfit),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _todayTargetCard() {
    if (_loading) return _shimmer(height: 130);
    if (_data == null) return const SizedBox.shrink();

    final todayPct = _data!.todayAchievedPercent;
    final isHit    = todayPct >= 100;
    final barColor = isHit ? _greenLight : _orange;

    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (_, __) {
        final animVal    = _progressAnim.value;
        final displayPct = (todayPct * animVal).clamp(0.0, 999.0);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isHit ? _greenLight.withValues(alpha: 0.3) : _border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("TODAY'S TARGET", style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
              ]),
              _badge(isHit ? 'Hit!' : 'In Progress', barColor),
            ]),
            const SizedBox(height: 8),
            Text(_fmt(_kDailyProfitTarget), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ((todayPct / 100) * animVal).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 7),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${displayPct.toStringAsFixed(1)}% of today target',
                  style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.w700)),
              Text(_fmt(_data!.todayProfit),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _miniStat({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
        ])),
      ]),
    );
  }

  Widget _chart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bar_chart_rounded, color: _greenLight, size: 16),
          const SizedBox(width: 8),
          const Expanded(child: Text('Daily Sale & Profit  —  7 Jul to 7 Oct',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
          _dot('Sale',   _blue),
          const SizedBox(width: 10),
          _dot('Profit', _greenLight),
          const SizedBox(width: 10),
          _dot('Target', _targetLine),
        ]),
        const SizedBox(height: 4),
        Text('Tap a bar • Orange line = Rs 20,000/day target',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9)),
        const SizedBox(height: 10),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _greenLight)))
        else if (_data == null || _data!.chartPoints.isEmpty)
          const Expanded(child: Center(child: Text('Data nahi mila', style: TextStyle(color: Colors.white38, fontSize: 13))))
        else
          Expanded(
            child: _InteractiveChart(
              points:      _data!.chartPoints,
              dailyTarget: _kDailyProfitTarget,
              dateFmt:     _dateFmt,
              fmtAmt:      _fmt,
            ),
          ),
      ]),
    );
  }

  Widget _dot(String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
    ]);
  }

  // Manual-only navigation. This is the ONLY place widget.onComplete() is
  // called from now that the auto-close timer has been removed.
  Widget _skipBtn() {
    return TextButton(
      onPressed: widget.onComplete,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('Skip', style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_forward_rounded, color: Colors.white38, size: 16),
      ]),
    );
  }

  Widget _shimmer({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _greenLight.withValues(alpha: 0.5))),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  INTERACTIVE CHART WIDGET
// ══════════════════════════════════════════════════════════════

class _InteractiveChart extends StatefulWidget {
  final List<DayPoint>          points;
  final double                  dailyTarget;
  final DateFormat              dateFmt;
  final String Function(double) fmtAmt;

  const _InteractiveChart({
    required this.points,
    required this.dailyTarget,
    required this.dateFmt,
    required this.fmtAmt,
  });

  @override
  State<_InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<_InteractiveChart> with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double>   _anim;
  int? _hoveredIdx;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int? _indexAt(Offset local, Size size) {
    const pl = 10.0, pt = 8.0, pb = 24.0;
    final chartW = size.width - pl;
    final chartH = size.height - pb - pt;
    final n      = widget.points.length;
    if (n == 0) return null;
    final groupW = chartW / n;
    final idx    = ((local.dx - pl) / groupW).floor();
    if (idx < 0 || idx >= n) return null;
    if (local.dy < pt || local.dy > pt + chartH) return null;
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, cons) {
      final size = Size(cons.maxWidth, cons.maxHeight);
      return GestureDetector(
        onTapDown: (d) {
          final idx = _indexAt(d.localPosition, size);
          setState(() => _hoveredIdx = (_hoveredIdx == idx) ? null : idx);
        },
        child: MouseRegion(
          onHover: (d) {
            final idx = _indexAt(d.localPosition, size);
            if (idx != _hoveredIdx) setState(() => _hoveredIdx = idx);
          },
          onExit: (_) => setState(() => _hoveredIdx = null),
          child: Stack(children: [
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => CustomPaint(
                painter: _BarPainter(
                  points:      widget.points,
                  dailyTarget: widget.dailyTarget,
                  progress:    _anim.value,
                  hoveredIdx:  _hoveredIdx,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            if (_hoveredIdx != null)
              _Tooltip(
                point:       widget.points[_hoveredIdx!],
                dailyTarget: widget.dailyTarget,
                idx:         _hoveredIdx!,
                total:       widget.points.length,
                dateFmt:     widget.dateFmt,
                fmtAmt:      widget.fmtAmt,
                chartSize:   size,
              ),
          ]),
        ),
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════
//  TOOLTIP
// ══════════════════════════════════════════════════════════════

class _Tooltip extends StatelessWidget {
  final DayPoint                point;
  final double                  dailyTarget;
  final int                     idx;
  final int                     total;
  final DateFormat              dateFmt;
  final String Function(double) fmtAmt;
  final Size                    chartSize;

  const _Tooltip({
    required this.point,
    required this.dailyTarget,
    required this.idx,
    required this.total,
    required this.dateFmt,
    required this.fmtAmt,
    required this.chartSize,
  });

  @override
  Widget build(BuildContext context) {
    const pl = 10.0, pt = 8.0;
    final groupW  = (chartSize.width - pl) / total;
    final centerX = pl + groupW * idx + groupW / 2;

    final achieved = dailyTarget == 0 ? 0.0 : (point.profit / dailyTarget * 100).clamp(0.0, 999.0);
    final isHit    = achieved >= 100;
    final pctColor = isHit ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);

    const tipW = 170.0;
    double left = (centerX - tipW / 2).clamp(4.0, chartSize.width - tipW - 4);

    return Positioned(
      left: left,
      top:  pt + 4,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: tipW,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2D28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3A4F45)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(dateFmt.format(point.date),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: pctColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: pctColor.withValues(alpha: 0.4)),
                ),
                child: Text('${achieved.toStringAsFixed(0)}%',
                    style: TextStyle(color: pctColor, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 8),
            _tRow(Icons.point_of_sale_rounded, 'Sale',   fmtAmt(point.sale),   const Color(0xFF42A5F5)),
            const SizedBox(height: 4),
            _tRow(Icons.trending_up_rounded,   'Profit', fmtAmt(point.profit), const Color(0xFF4CAF50)),
            const Divider(height: 10, color: Color(0xFF3A4F45)),
            _tRow(Icons.track_changes_rounded, 'Target', fmtAmt(dailyTarget),  const Color(0xFFFFA726)),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (achieved / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                minHeight: 4,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tRow(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 11),
      const SizedBox(width: 5),
      Text('$label  ', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
      Expanded(child: Text(value, textAlign: TextAlign.right,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
//  CUSTOM PAINTER
// ══════════════════════════════════════════════════════════════

class _BarPainter extends CustomPainter {
  final List<DayPoint> points;
  final double         dailyTarget;
  final double         progress;
  final int?           hoveredIdx;

  _BarPainter({
    required this.points,
    required this.dailyTarget,
    required this.progress,
    required this.hoveredIdx,
  });

  static const _saleColor   = Color(0xFF42A5F5);
  static const _profitGreen = Color(0xFF4CAF50);
  static const _profitRed   = Color(0xFFEF5350);
  static const _targetColor = Color(0xFFFF7043);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxSale = points.map((p) => p.sale).reduce(math.max);
    final maxVal  = math.max(maxSale, dailyTarget) == 0 ? 1.0 : math.max(maxSale, dailyTarget);

    const pl = 10.0, pb = 24.0, pt = 8.0;
    final chartW = size.width  - pl;
    final chartH = size.height - pb - pt;
    final n      = points.length;
    final groupW = chartW / n;
    final barW   = (groupW * 0.35).clamp(3.0, 18.0);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      final y = pt + chartH * (1 - i / 4);
      canvas.drawLine(Offset(pl, y), Offset(size.width, y), gridPaint);
    }

    // Target dashed line
    final targetY = pt + chartH * (1 - (dailyTarget / maxVal).clamp(0.0, 1.0));
    _dashedLine(canvas, Offset(pl, targetY), Offset(size.width, targetY), _targetColor, 1.5);

    // Target label
    final labelTp = TextPainter(
      textDirection: ui.TextDirection.ltr,
      text: TextSpan(
        text: 'Target: Rs ${NumberFormat('#,##,###', 'en_IN').format(dailyTarget.toInt())}',
        style: const TextStyle(color: _targetColor, fontSize: 7, fontWeight: FontWeight.w700),
      ),
    )..layout();
    labelTp.paint(canvas, Offset(pl + 4, targetY - 10));

    // Bars
    final xAxisStyle = TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 8);

    for (int i = 0; i < n; i++) {
      final p          = points[i];
      final x          = pl + groupW * i + groupW / 2;
      final isHovered  = hoveredIdx == i;
      final baseOpacity = hoveredIdx == null ? 0.75 : (isHovered ? 1.0 : 0.3);

      // Hover highlight
      if (isHovered) {
        canvas.drawRect(
          Rect.fromLTWH(x - barW - 4, pt, barW * 2 + 8, chartH),
          Paint()..color = Colors.white.withValues(alpha: 0.04),
        );
      }

      // Sale bar
      final saleH    = (p.sale / maxVal) * chartH * progress;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x - barW - 2, pt + chartH - saleH, barW, saleH),
          topLeft: const Radius.circular(3), topRight: const Radius.circular(3),
        ),
        Paint()..color = _saleColor.withValues(alpha: baseOpacity),
      );

      // Profit bar — green if target hit, red if not
      final profitColor = p.profit >= dailyTarget ? _profitGreen : _profitRed;
      final profitH     = (p.profit.clamp(0.0, maxVal) / maxVal) * chartH * progress;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x + 2, pt + chartH - profitH, barW, profitH),
          topLeft: const Radius.circular(3), topRight: const Radius.circular(3),
        ),
        Paint()..color = profitColor.withValues(alpha: isHovered ? 1.0 : (hoveredIdx == null ? 0.85 : 0.3)),
      );
    }

    // X-axis date labels
    final step = math.max(1, (n / 10).ceil());
    for (int i = 0; i < n; i += step) {
      final p     = points[i];
      final x     = pl + groupW * i + groupW / 2;
      final label = '${p.date.day}/${p.date.month}';
      final tp    = TextPainter(
        textDirection: ui.TextDirection.ltr,
        text: TextSpan(text: label, style: xAxisStyle),
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, pt + chartH + 6));
    }
  }

  void _dashedLine(Canvas canvas, Offset start, Offset end, Color color, double strokeWidth) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    const dashLen = 6.0;
    const gapLen  = 4.0;
    final dx  = end.dx - start.dx;
    final dy  = end.dy - start.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final ux = dx / len;
    final uy = dy / len;
    double dist   = 0;
    bool drawing  = true;
    while (dist < len) {
      final seg = drawing ? math.min(dashLen, len - dist) : math.min(gapLen, len - dist);
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + ux * dist,       start.dy + uy * dist),
          Offset(start.dx + ux * (dist + seg), start.dy + uy * (dist + seg)),
          paint,
        );
      }
      dist    += seg;
      drawing  = !drawing;
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) {
    return old.progress != progress || old.hoveredIdx != hoveredIdx;
  }
}