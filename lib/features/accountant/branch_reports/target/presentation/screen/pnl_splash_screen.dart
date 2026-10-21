// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ══════════════════════════════════════════════════════════════
//  CONSTANTS
// ══════════════════════════════════════════════════════════════

const String _kBranchId          = '09ed6ad4-373d-4afb-a7fb-badb1e72e9e3';
const double _kDailyProfitTarget = 20000;

final DateTime _kCampaignStart = DateTime(2026, 7, 7);
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
    if (d.isBefore(_kCampaignStart)) continue; // guard against any stray pre-campaign rows
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
  int? _selectedIdx;

  late final AnimationController _fadeCtrl;
  late final AnimationController _progressCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<double>   _progressAnim;

  // ── Theme palette (aligned with app's LightTheme primary purple) ──
  static const _accent      = Color(0xFF6C63FF); // LightTheme primary
  static const _accentDark  = Color(0xFF3D35CC); // LightTheme primaryDark
  static const _accentSoft  = Color(0xFF9D97FF); // LightTheme primaryLight
  static const _greenText   = Color(0xFF27500A);
  static const _bg          = Color(0xFFF5F5F5);
  static const _card        = Color(0xFFFFFFFF);
  static const _border      = Color(0xFFE0E0E0);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecond  = Color(0xFF6B6B6B);
  static const _textMuted   = Color(0xFF9A9A9A);
  static const _blue        = Color(0xFF185FA5);
  static const _orange      = Color(0xFF854F0B);
  static const _purple      = Color(0xFF534AB7);
  static const _red         = Color(0xFFA32D2D);
  static const _targetLine  = Color(0xFFC0621A);

  final _amtFmt = NumberFormat('#,##,###', 'en_IN');

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

  /// The day currently driving the top sale/profit mini-stats: the tapped
  /// graph point if one is selected, otherwise today.
  DayPoint? get _selectedPoint {
    final points = _data?.chartPoints;
    if (points == null || _selectedIdx == null) return null;
    if (_selectedIdx! < 0 || _selectedIdx! >= points.length) return null;
    return points[_selectedIdx!];
  }

  bool get _hasSelection => _selectedPoint != null;

  double _displaySale()   => _selectedPoint?.sale   ?? _data?.todaySale   ?? 0;
  double _displayProfit() => _selectedPoint?.profit ?? _data?.todayProfit ?? 0;

  String _displayLabel() =>
      _selectedPoint != null
          ? DateFormat('d MMM').format(_selectedPoint!.date)
          : 'Today';

  void _clearSelection() => setState(() => _selectedIdx = null);

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
          const SizedBox(height: 22),
          _daysLeftCard(),
          const SizedBox(height: 14),
          _todayTargetCard(),
          const SizedBox(height: 18),
          _selectedDayHeader(),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _miniStat(icon: Icons.today_rounded,      label: '${_displayLabel()} sale',   value: _loading ? '...' : _fmt(_displaySale()),   color: _orange)),
            const SizedBox(width: 10),
            Expanded(child: _miniStat(icon: Icons.show_chart_rounded, label: '${_displayLabel()} profit', value: _loading ? '...' : _fmt(_displayProfit()), color: _purple)),
          ]),
          const SizedBox(height: 16),
          SizedBox(height: 280, child: _lineChart()),
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
            const SizedBox(height: 22),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _daysLeftCard(),
                const SizedBox(width: 14),
                Expanded(flex: 4, child: _todayTargetCard()),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _selectedDayHeader(),
                  const SizedBox(height: 6),
                  _miniStat(icon: Icons.today_rounded,      label: '${_displayLabel()} sale',   value: _loading ? '...' : _fmt(_displaySale()),   color: _orange),
                  const SizedBox(height: 8),
                  _miniStat(icon: Icons.show_chart_rounded, label: '${_displayLabel()} profit', value: _loading ? '...' : _fmt(_displayProfit()), color: _purple),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            Expanded(child: _lineChart()),
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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_accent, _accentDark],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: _accent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(Icons.analytics_rounded, color: Colors.white, size: compact ? 18 : 22),
          ),
          const SizedBox(width: 10),
          Text('3 Month Target',
              style: TextStyle(color: _textPrimary, fontSize: compact ? 22 : 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ]),
        const SizedBox(height: 4),
        Text(
          '${DateFormat('d MMM yyyy').format(_kCampaignStart)} – '
              '${DateFormat('d MMM yyyy').format(_kCampaignEnd)}  •  '
              'Daily target: ${_fmt(_kDailyProfitTarget)}',
          style: TextStyle(color: _textSecond, fontSize: compact ? 11 : 13),
        ),
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
      width: 158,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accent, _accentDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _accent.withValues(alpha: 0.30), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 12),
        Text('$dLeft', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(height: 2),
        const Text('days left', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (elapsed / total).clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 6),
        Text('Until ${DateFormat('d MMM yyyy').format(_kCampaignEnd)}',
            style: const TextStyle(color: Colors.white60, fontSize: 9)),
      ]),
    );
  }

  Widget _todayTargetCard() {
    if (_loading) return _shimmer(height: 158);
    if (_data == null) return const SizedBox.shrink();

    final todayPct = _data!.todayAchievedPercent;
    final isHit    = todayPct >= 100;
    final barColor = isHit ? _greenText : _accent;

    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (_, __) {
        final animVal    = _progressAnim.value;
        final displayPct = (todayPct * animVal).clamp(0.0, 999.0);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isHit ? _greenText.withValues(alpha: 0.35) : _border, width: isHit ? 1.2 : 0.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("TODAY'S TARGET", style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                const SizedBox(height: 3),
                Text(DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style: TextStyle(color: _textMuted, fontSize: 10)),
              ]),
              _badge(isHit ? 'Hit' : 'In progress', barColor),
            ]),
            const SizedBox(height: 10),
            Text(_fmt(_kDailyProfitTarget), style: TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ((todayPct / 100) * animVal).clamp(0.0, 1.0),
                backgroundColor: _bg,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 11,
              ),
            ),
            const SizedBox(height: 9),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${displayPct.toStringAsFixed(1)}% of today\'s target',
                  style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.w700)),
              Text(_fmt(_data!.todayProfit),
                  style: TextStyle(color: _textSecond, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _miniStat({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: _textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
        ])),
      ]),
    );
  }

  Widget _lineChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.show_chart_rounded, color: _accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Daily sale & profit — '
                  '${DateFormat('d MMM').format(_kCampaignStart)} to '
                  '${DateFormat('d MMM').format(_kCampaignEnd)}',
              style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          _dot('Sale', _blue),
          const SizedBox(width: 10),
          _dot('Profit', _greenText),
          const SizedBox(width: 10),
          _dot('Target', _targetLine),
        ]),
        const SizedBox(height: 4),
        Text('Tap a point to see that day\'s sale & profit above',
            style: TextStyle(color: _textMuted, fontSize: 9)),
        const SizedBox(height: 10),
        if (_loading)
          Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _accent)))
        else if (_data == null || _data!.chartPoints.isEmpty)
          Expanded(child: Center(child: Text('No data found', style: TextStyle(color: _textMuted, fontSize: 13))))
        else
          Expanded(
            child: _FlLineChart(
              points:      _data!.chartPoints,
              dailyTarget: _kDailyProfitTarget,
              selectedIdx: _selectedIdx,
              onSelect:    (i) => setState(() => _selectedIdx = i),
            ),
          ),
      ]),
    );
  }

  /// Small label above the sale/profit mini-stats: shows the selected
  /// day's full date and a clear-selection chip once a graph point has
  /// been tapped; shows nothing while the stats are just "Today".
  Widget _selectedDayHeader() {
    if (!_hasSelection) return const SizedBox.shrink();
    final point = _selectedPoint!;
    final isHit = point.profit >= _kDailyProfitTarget;

    return Row(children: [
      Expanded(
        child: Text(
          DateFormat('EEEE, d MMM yyyy').format(point.date),
          style: TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      _badge(isHit ? 'Target hit' : 'Below target', isHit ? _greenText : _red),
      const SizedBox(width: 6),
      InkWell(
        onTap: _clearSelection,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.close_rounded, size: 14, color: _textMuted),
        ),
      ),
    ]);
  }

  Widget _dot(String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: _textSecond, fontSize: 10)),
    ]);
  }

  // Manual-only navigation. This is the ONLY place widget.onComplete() is
  // called from now that the auto-close timer has been removed.
  Widget _skipBtn() {
    return TextButton(
      onPressed: widget.onComplete,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _border),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Skip', style: TextStyle(color: _textSecond, fontSize: 13)),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward_rounded, color: _textMuted, size: 16),
      ]),
    );
  }

  Widget _shimmer({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border, width: 0.5)),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _accent.withValues(alpha: 0.6))),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LINE CHART (fl_chart) — IMPROVED
//  • Built-in load animation
//  • Gradient + glow strokes, rounded caps
//  • Combined sale+profit tooltip
//  • Selection highlight (vertical marker + bold axis label)
//  • Subtle horizontal grid + pill-style target label
// ══════════════════════════════════════════════════════════════

class _FlLineChart extends StatelessWidget {
  final List<DayPoint>    points;
  final double            dailyTarget;
  final int?              selectedIdx;
  final ValueChanged<int> onSelect;

  const _FlLineChart({
    required this.points,
    required this.dailyTarget,
    required this.selectedIdx,
    required this.onSelect,
  });

  static const _saleColor     = Color(0xFF378ADD);
  static const _saleColorLt   = Color(0xFF7CB4EE);
  static const _profitColor   = Color(0xFF3B6D11);
  static const _profitColorLt = Color(0xFF7BB84C);
  static const _targetColor   = Color(0xFFC0621A);
  static const _axisColor     = Color(0xFF9A9A9A);

  static final _amtFmt = NumberFormat('#,##,###', 'en_IN');

  @override
  Widget build(BuildContext context) {
    final n = points.length;
    final saleSpots   = [for (int i = 0; i < n; i++) FlSpot(i.toDouble(), points[i].sale)];
    final profitSpots = [for (int i = 0; i < n; i++) FlSpot(i.toDouble(), points[i].profit)];

    final maxSale   = points.map((p) => p.sale).fold(0.0, math.max);
    final maxProfit = points.map((p) => p.profit).fold(0.0, math.max);
    final rawMax    = [maxSale, maxProfit, dailyTarget].reduce(math.max);
    final maxY      = (rawMax <= 0 ? 1.0 : rawMax) * 1.2;
    final step      = math.max(1, (n / 6).ceil());

    return LineChart(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFFEDEDED),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= n || i % step != 0) return const SizedBox.shrink();
                final p = points[i];
                final isSelected = i == selectedIdx;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${p.date.day}/${p.date.month}',
                    style: TextStyle(
                      color: isSelected ? _saleColor : _axisColor,
                      fontSize: 8,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          verticalLines: [
            if (selectedIdx != null)
              VerticalLine(
                x: selectedIdx!.toDouble(),
                color: _saleColor.withValues(alpha: 0.25),
                strokeWidth: 1.5,
                dashArray: const [4, 4],
              ),
          ],
          horizontalLines: [
            HorizontalLine(
              y: dailyTarget,
              color: _targetColor,
              strokeWidth: 2,
              dashArray: const [8, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  backgroundColor: _targetColor,
                ),
                labelResolver: (_) => '  Target: Rs ${dailyTarget ~/ 1000}k  ',
              ),
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A1A1A),
            tooltipBorderRadius: BorderRadius.circular(12),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (spots) {
              final idx = spots.first.x.round();
              if (idx < 0 || idx >= points.length) {
                return spots.map((_) => null).toList();
              }
              final p = points[idx];
              final dateStr = DateFormat('d MMM').format(p.date);
              return spots.map((s) {
                final isSaleLine = s.barIndex == 0;
                if (!isSaleLine) return null; // suppress duplicate tooltip on 2nd line
                return LineTooltipItem(
                  '$dateStr\n',
                  const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(
                      text: 'Sale: Rs ${_amtFmt.format(p.sale.toInt())}\n',
                      style: const TextStyle(color: _saleColorLt, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: 'Profit: Rs ${_amtFmt.format(p.profit.toInt())}',
                      style: const TextStyle(color: _profitColorLt, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          touchCallback: (event, response) {
            if (event is FlTapUpEvent || event is FlPanEndEvent || event is FlLongPressEnd) {
              final spots = response?.lineBarSpots;
              if (spots != null && spots.isNotEmpty) onSelect(spots.first.x.round());
            }
          },
        ),
        lineBarsData: [
          _buildLine(saleSpots, _saleColor, _saleColorLt, isSale: true),
          _buildLine(profitSpots, _profitColor, _profitColorLt, isSale: false),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color, Color colorLt, {required bool isSale}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      preventCurveOverShooting: true,
      gradient: LinearGradient(colors: [color, colorLt]),
      barWidth: isSale ? 3 : 2.4,
      isStrokeCapRound: true,
      isStrokeJoinRound: true,
      shadow: Shadow(color: color.withValues(alpha: 0.35), blurRadius: 6),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          final isSelected = index == selectedIdx;
          if (!isSelected) {
            return FlDotCirclePainter(radius: 0, color: Colors.transparent, strokeWidth: 0);
          }
          return FlDotCirclePainter(
            radius: 6,
            color: color,
            strokeWidth: 3,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}