import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/website_content.dart';
import '../../data/website_strings.dart';
import 'website_motion.dart';
import 'website_sections.dart';

/// "Buy Anything on Easy Installments" — steps + static calculator.
/// Hisaab sirf browser mein hota hai, kuch save nahi hota.
class InstallmentSection extends StatelessWidget {
  final bool mobile;
  final ValueChanged<String> onGetInstallment;
  final VoidCallback onContact;

  const InstallmentSection({
    super.key,
    required this.mobile,
    required this.onGetInstallment,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    final info = _InstallmentInfo(mobile: mobile, onContact: onContact);
    final calc = _InstallmentCalculator(
      mobile: mobile,
      onGetInstallment: onGetInstallment,
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WebsiteColors.tint, WebsiteColors.page],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -80,
            top: 40,
            child: Floating(
              amplitude: 14,
              child: DecorBlob(size: 260, color: Color(0x1AED0015)),
            ),
          ),
          const Positioned(
            left: -60,
            bottom: 120,
            child: Floating(
              amplitude: 10,
              phase: 0.5,
              child: DecorBlob(size: 200, color: Color(0x10000000)),
            ),
          ),
          Contained(
            padding: sectionPadding(mobile),
            child: Column(
              children: [
                Reveal(
                  child: SectionHeader(
                    eyebrow: t.instEyebrow,
                    title: t.instTitle,
                    text: t.instText,
                    mobile: mobile,
                  ),
                ),
                const SizedBox(height: 18),
                Reveal(
                  delay: const Duration(milliseconds: 120),
                  child: _MottoPill(mobile: mobile),
                ),
                SizedBox(height: mobile ? 36 : 52),
                _Steps(mobile: mobile),
                SizedBox(height: mobile ? 36 : 56),
                if (mobile)
                  Column(children: [
                    Reveal(child: info),
                    const SizedBox(height: 24),
                    Reveal(child: calc),
                  ])
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: Reveal(child: info)),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 6,
                        child: Reveal(
                          delay: const Duration(milliseconds: 150),
                          child: calc,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MottoPill extends StatelessWidget {
  final bool mobile;
  const _MottoPill({required this.mobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WebsiteColors.red, WebsiteColors.redDark],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: WebsiteColors.red.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        WebsiteText.of(context).instMotto,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: mobile ? 14 : 16,
          fontWeight: FontWeight.w800,
          letterSpacing: tracking(context, 0.2),
        ),
      ),
    );
  }
}

// ── 01 / 02 / 03 steps ───────────────────────────────────────────────────────
class _Steps extends StatelessWidget {
  final bool mobile;
  const _Steps({required this.mobile});

  @override
  Widget build(BuildContext context) {
    final steps = WebsiteText.of(context).instStepItems;
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 720 ? 3 : 1;
      const gap = 20.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (int i = 0; i < steps.length; i++)
            SizedBox(
              width: w,
              child: Reveal(
                delay: Duration(milliseconds: 120 * i),
                child: _StepCard(index: i, item: steps[i]),
              ),
            ),
        ],
      );
    });
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final WebsiteItem item;
  const _StepCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      builder: (context, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hovered ? const Color(0xFFFFB8BD) : WebsiteColors.line,
          ),
          boxShadow: [
            BoxShadow(
              color: WebsiteColors.red
                  .withValues(alpha: hovered ? 0.14 : 0.04),
              blurRadius: hovered ? 30 : 14,
              offset: Offset(0, hovered ? 16 : 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedScale(
                  scale: hovered ? 1.08 : 1,
                  duration: const Duration(milliseconds: 240),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [WebsiteColors.red, WebsiteColors.redDark],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 26),
                  ),
                ),
                const Spacer(),
                Text(
                  '0${index + 1}',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: hovered
                        ? const Color(0xFFFFB8BD)
                        : const Color(0xFFEDEDED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(item.title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: WebsiteColors.ink)),
            const SizedBox(height: 8),
            Text(item.text,
                style: const TextStyle(
                    fontSize: 14.5, height: 1.55, color: WebsiteColors.muted)),
          ],
        ),
      ),
    );
  }
}

// ── Left: info + benefits ────────────────────────────────────────────────────
class _InstallmentInfo extends StatelessWidget {
  final bool mobile;
  final VoidCallback onContact;
  const _InstallmentInfo({required this.mobile, required this.onContact});

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    return Container(
      padding: EdgeInsets.all(mobile ? 24 : 36),
      decoration: BoxDecoration(
        color: WebsiteColors.darkBg,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.howItWorks,
            style: TextStyle(
              color: const Color(0xFFFF8A93),
              fontSize: 12,
              letterSpacing: tracking(context, 1.6),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.instHeadline.fill(WebsiteContent.instPlans.last),
            style: TextStyle(
              color: Colors.white,
              fontSize: mobile ? 24 : 30,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: tracking(context, -0.6),
            ),
          ),
          const SizedBox(height: 24),
          for (final b in t.instBenefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: WebsiteColors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(b,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, height: 1.45)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                _Fact(
                    label: t.duration,
                    value: t.monthsValue.fill(
                        '${WebsiteContent.instPlans.first}–${WebsiteContent.instPlans.last}')),
                _Fact(
                    label: t.charge,
                    value: t.chargePerMonth.fill(InstallmentPlan.pctNum(
                        WebsiteContent.instRatePerMonth))),
                _Fact(
                    label: t.advance,
                    value: t.fromPct
                        .fill((WebsiteContent.instMinAdvance * 100).round())),
              ],
            ),
          ),
          const SizedBox(height: 24),
          WebButton(
            label: t.contactBrand,
            icon: Icons.support_agent_rounded,
            style: WebButtonStyle.light,
            onTap: onContact,
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Right: calculator ────────────────────────────────────────────────────────
// Formula: baqi raqam x (1 + 2.5% x mahine), kam az kam 15% advance.
class _InstallmentCalculator extends StatefulWidget {
  final bool mobile;
  final ValueChanged<String> onGetInstallment;
  const _InstallmentCalculator({
    required this.mobile,
    required this.onGetInstallment,
  });

  @override
  State<_InstallmentCalculator> createState() => _InstallmentCalculatorState();
}

class _InstallmentCalculatorState extends State<_InstallmentCalculator> {
  final _priceCtrl = TextEditingController(
      text: _ThousandsFormatter.format(WebsiteContent.instDefaultPrice));
  final _advanceCtrl = TextEditingController();
  double _price = WebsiteContent.instDefaultPrice.toDouble();
  double _advanceInput = 0;

  /// User ne advance khud likha? Nahi to hamesha 15% auto bharta hai.
  bool _advanceTouched = false;
  int _months = WebsiteContent.instPopularPlan;
  int _pulse = 0;

  static const _minPct = WebsiteContent.instMinAdvance;

  double get _minAdvance => (_price * _minPct).ceilToDouble();
  bool get _fullAdvance => _price > 0 && _advanceInput >= _price;
  bool get _tooLow =>
      _price > 0 && !_fullAdvance && _advanceInput < _minAdvance;

  /// Kam advance par qistein 15% ke hisaab se.
  double get _advance => _tooLow ? _minAdvance : _advanceInput;
  double get _remaining => _fullAdvance ? 0 : _price - _advance;
  bool get _hasPlans => _price > 0 && !_fullAdvance;
  InstallmentPlan get _plan => InstallmentPlan.of(_remaining, _months);

  @override
  void initState() {
    super.initState();
    _autoAdvance();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _advanceCtrl.dispose();
    super.dispose();
  }

  static double _parse(String text) =>
      double.tryParse(text.replaceAll(',', '')) ?? 0;

  void _autoAdvance() {
    if (_advanceTouched) return;
    _advanceInput = _minAdvance;
    _advanceCtrl.text =
        _price > 0 ? _ThousandsFormatter.format(_advanceInput) : '';
  }

  void _onPrice(String text) {
    setState(() {
      _price = _parse(text);
      _autoAdvance();
    });
  }

  void _onAdvance(String text) {
    setState(() {
      _advanceTouched = text.trim().isNotEmpty;
      _advanceInput = _parse(text);
      _autoAdvance();
    });
  }

  void _reset() {
    setState(() {
      _priceCtrl.clear();
      _price = 0;
      _advanceTouched = false;
      _months = WebsiteContent.instPopularPlan;
      _autoAdvance();
    });
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    setState(() => _pulse++);
  }

  String _summary() {
    final p = _plan;
    return 'Assalam o Alaikum Jan Ghani, I want a product on installments.\n'
        'Product price: ${formatRs(_price)}\n'
        'Advance (${_pctText(_advance)}%): ${formatRs(_advance)}\n'
        'Plan: ${p.months} months\n'
        'Monthly: ${formatRs(p.monthly)} x ${p.months} months'
        '${p.lastDiffers ? ' (last ${formatRs(p.last)})' : ''}\n'
        'Total (incl. advance): ${formatRs(_advance + p.total)}';
  }

  String _pctText(double amount) {
    if (_price <= 0) return '0';
    final pct = amount / _price * 100;
    return pct > 0 && pct < 1 ? pct.toStringAsFixed(1) : '${pct.round()}';
  }

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    final mobile = widget.mobile;
    final plan = _plan;
    final minPctText = '${(_minPct * 100).round()}';
    final enteredPct = _price > 0 ? _advanceInput / _price : 0.0;

    return Container(
      padding: EdgeInsets.all(mobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: WebsiteColors.line),
        boxShadow: [
          BoxShadow(
            color: WebsiteColors.red.withValues(alpha: 0.10),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_rounded, color: WebsiteColors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.calculator,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: WebsiteColors.ink)),
              ),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(t.newCalculation),
                style: TextButton.styleFrom(
                  foregroundColor: WebsiteColors.red,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _Label(t.productPrice),
          const SizedBox(height: 8),
          _MoneyField(
            controller: _priceCtrl,
            onChanged: _onPrice,
            fontSize: 20,
          ),
          const SizedBox(height: 20),
          _Label(t.advanceLabel),
          const SizedBox(height: 8),
          _MoneyField(
            controller: _advanceCtrl,
            onChanged: _onAdvance,
            fontSize: 18,
            error: _tooLow,
          ),
          const SizedBox(height: 10),
          _PctBar(
            label: t.ofPrice.fill(_pctText(_advanceInput)),
            value: enteredPct.clamp(0.0, 1.0),
          ),
          if (_tooLow || _fullAdvance) ...[
            const SizedBox(height: 12),
            _Warn(
              _fullAdvance
                  ? t.fullAdvance
                  : t.minAdvanceWarn
                      .fill(minPctText)
                      .fillA(formatRs(_minAdvance)),
            ),
          ],
          if (_hasPlans) ...[
            const SizedBox(height: 22),
            _Label(t.choosePlan),
            const SizedBox(height: 10),
            for (final m in WebsiteContent.instPlans)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlanTile(
                  plan: InstallmentPlan.of(_remaining, m),
                  advance: _advance,
                  selected: m == _months,
                  tag: m == WebsiteContent.instPopularPlan
                      ? t.tagPopular
                      : m == WebsiteContent.instLowestPlan
                          ? t.tagLowest
                          : null,
                  onTap: () => setState(() => _months = m),
                ),
              ),
            const SizedBox(height: 12),
            _BreakdownRow(t.productPrice, _price),
            _BreakdownRow(t.advancePayment.fill(_pctText(_advance)), _advance),
            _BreakdownRow(t.remaining, _remaining),
            _BreakdownRow(
                '${t.chargeRow.fill(plan.chargePct)} '
                '(${t.chargePerMonth.fill(InstallmentPlan.pctNum(WebsiteContent.instRatePerMonth))} '
                '× ${plan.months})',
                plan.charge),
            _BreakdownRow(t.totalInstallment, plan.total, bold: true),
            const SizedBox(height: 18),
            _MonthlyCard(
              monthly: plan.monthly,
              months: plan.months,
              last: plan.lastDiffers ? plan.last : null,
              pulse: _pulse,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                WebButton(
                  label: t.calculate,
                  icon: Icons.calculate_rounded,
                  onTap: _calculate,
                ),
                WebButton(
                  label: t.getOnInstallments,
                  icon: Icons.shopping_bag_rounded,
                  style: WebButtonStyle.whatsapp,
                  onTap: () => widget.onGetInstallment(_summary()),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.lock_clock_rounded,
                  size: 16, color: WebsiteColors.red),
              const SizedBox(width: 6),
              Expanded(
                child: Text(t.priceFixed,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: WebsiteColors.ink)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t.instNote,
            style: const TextStyle(fontSize: 12, color: WebsiteColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: WebsiteColors.muted));
}

class _MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final double fontSize;
  final bool error;
  const _MoneyField({
    required this.controller,
    required this.onChanged,
    required this.fontSize,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final idle = error ? const Color(0xFFEF4444) : WebsiteColors.line;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
        _ThousandsFormatter(),
      ],
      style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: WebsiteColors.ink),
      decoration: InputDecoration(
        hintText: '0',
        prefixIcon: const Padding(
          padding: EdgeInsetsDirectional.only(start: 16, end: 8),
          child: Text('Rs',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: WebsiteColors.red)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: WebsiteColors.page,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: idle, width: error ? 1.8 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: error ? idle : WebsiteColors.red, width: 1.8),
        ),
      ),
    );
  }
}

/// "Qeemat ka 15%" + progress bar.
class _PctBar extends StatelessWidget {
  final String label;
  final double value;
  const _PctBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: WebsiteColors.muted)),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: const Color(0xFFEEEEEE),
              color: WebsiteColors.red,
            ),
          ),
        ),
      ],
    );
  }
}

class _Warn extends StatelessWidget {
  final String text;
  const _Warn(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB3202C))),
    );
  }
}

/// Ek plan: mahine + mahana qist + kul qeemat (advance samet).
class _PlanTile extends StatelessWidget {
  final InstallmentPlan plan;
  final double advance;
  final bool selected;
  final String? tag;
  final VoidCallback onTap;
  const _PlanTile({
    required this.plan,
    required this.advance,
    required this.selected,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? WebsiteColors.tint : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? WebsiteColors.red : WebsiteColors.line,
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [WebsiteColors.red, WebsiteColors.redDark]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${plan.months}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1,
                            fontWeight: FontWeight.w900)),
                    Text(t.monthsShort,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(t.perMonth.fill(formatRs(plan.monthly)),
                          style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: WebsiteColors.ink)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                        t.totalWithAdvance.fill(formatRs(advance + plan.total)),
                        style: const TextStyle(
                            fontSize: 12, color: WebsiteColors.muted)),
                    if (plan.lastDiffers)
                      Text(t.lastInstallment.fill(formatRs(plan.last)),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: WebsiteColors.red)),
                  ],
                ),
              ),
              if (tag != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: WebsiteColors.red,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(tag!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _BreakdownRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: WebsiteColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  color: bold ? WebsiteColors.ink : WebsiteColors.muted,
                )),
          ),
          AnimatedMoney(
            value: value,
            style: TextStyle(
              fontSize: bold ? 16 : 15,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: WebsiteColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyCard extends StatelessWidget {
  final double monthly;
  final int months;

  /// Aakhri qist alag ho to.
  final double? last;
  final int pulse;
  const _MonthlyCard({
    required this.monthly,
    required this.months,
    required this.last,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    // "Calculate" dabane par halka sa pulse.
    return TweenAnimationBuilder<double>(
      key: ValueKey(pulse),
      tween: Tween(begin: pulse == 0 ? 1 : 0.96, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [WebsiteColors.red, WebsiteColors.redDeep],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: WebsiteColors.red.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.monthlyPayment,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedMoney(
                value: monthly,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(t.perMonthFor.fill(months),
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (last != null) ...[
              const SizedBox(height: 4),
              Text(t.lastInstallment.fill(formatRs(last!)),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 100000 → 100,000 (type karte hue).
class _ThousandsFormatter extends TextInputFormatter {
  static String format(num v) {
    final s = v.toInt().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final text = format(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
