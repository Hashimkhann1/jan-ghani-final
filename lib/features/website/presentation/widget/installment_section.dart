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
          colors: [Color(0xFFF4F3FF), WebsiteColors.page],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -80,
            top: 40,
            child: Floating(
              amplitude: 14,
              child: DecorBlob(size: 260, color: Color(0x1A6C63FF)),
            ),
          ),
          const Positioned(
            left: -60,
            bottom: 120,
            child: Floating(
              amplitude: 10,
              phase: 0.5,
              child: DecorBlob(size: 200, color: Color(0x1422C55E)),
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
          colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
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
            color: hovered ? const Color(0xFFCFCBFF) : WebsiteColors.line,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF)
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
                        colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
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
                        ? const Color(0xFFCFCBFF)
                        : const Color(0xFFE9E8F5),
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
              color: const Color(0xFFB7B2FF),
              fontSize: 12,
              letterSpacing: tracking(context, 1.6),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.instHeadline.fill(WebsiteContent.instMonths),
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
                      color: Color(0xFF22C55E),
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
                    value: t.monthsValue.fill(WebsiteContent.instMonths)),
                _Fact(
                    label: t.charge,
                    value: '${(WebsiteContent.instMarkup * 100).round()}%'),
                _Fact(label: t.advance, value: '30–50%'),
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
  double _price = WebsiteContent.instDefaultPrice.toDouble();
  double _advancePct = WebsiteContent.instAdvances.first;
  int _pulse = 0;

  static const _months = WebsiteContent.instMonths;
  static const _markup = WebsiteContent.instMarkup;

  double get _advance => _price * _advancePct;
  double get _remaining => _price - _advance;
  double get _charge => _remaining * _markup;
  double get _total => _remaining + _charge;
  double get _monthly => _total / _months;

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  void _onPrice(String text) {
    setState(() => _price = double.tryParse(text.replaceAll(',', '')) ?? 0);
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    setState(() => _pulse++);
  }

  String _summary() =>
      'Assalam o Alaikum Jan Ghani, I want a product on installments.\n'
      'Product price: ${formatRs(_price)}\n'
      'Advance (${(_advancePct * 100).round()}%): ${formatRs(_advance)}\n'
      'Monthly: ${formatRs(_monthly)} x $_months months';

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    final mobile = widget.mobile;
    return Container(
      padding: EdgeInsets.all(mobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: WebsiteColors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.10),
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
              const Icon(Icons.calculate_rounded, color: Color(0xFF6C63FF)),
              const SizedBox(width: 8),
              Text(t.calculator,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: WebsiteColors.ink)),
            ],
          ),
          const SizedBox(height: 22),
          _Label(t.productPrice),
          const SizedBox(height: 8),
          TextField(
            controller: _priceCtrl,
            onChanged: _onPrice,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
              _ThousandsFormatter(),
            ],
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: WebsiteColors.ink),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsetsDirectional.only(start: 16, end: 8),
                child: Text('Rs',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6C63FF))),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: const Color(0xFFF7F7FB),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: WebsiteColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF6C63FF), width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _Label(t.chooseAdvance),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final pct in WebsiteContent.instAdvances) ...[
                Expanded(
                  child: _AdvanceChip(
                    pct: pct,
                    selected: pct == _advancePct,
                    onTap: () => setState(() => _advancePct = pct),
                  ),
                ),
                if (pct != WebsiteContent.instAdvances.last)
                  const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.calendar_month_rounded,
                  label: t.instDuration,
                  value: t.monthsValue.fill(_months),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  icon: Icons.percent_rounded,
                  label: t.instCharge,
                  value: '${(_markup * 100).round()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _BreakdownRow(t.productPrice, _price),
          _BreakdownRow(
              t.advancePayment.fill((_advancePct * 100).round()), _advance),
          _BreakdownRow(t.remaining, _remaining),
          _BreakdownRow(t.chargeRow.fill((_markup * 100).round()), _charge),
          _BreakdownRow(t.totalInstallment, _total, bold: true),
          const SizedBox(height: 18),
          _MonthlyCard(monthly: _monthly, months: _months, pulse: _pulse),
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
          const SizedBox(height: 14),
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

class _AdvanceChip extends StatelessWidget {
  final double pct;
  final bool selected;
  final VoidCallback onTap;
  const _AdvanceChip({
    required this.pct,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)])
                : null,
            color: selected ? null : const Color(0xFFF7F7FB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : WebsiteColors.line,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '${(pct * 100).round()}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : WebsiteColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: WebsiteColors.muted)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: WebsiteColors.ink)),
              ],
            ),
          ),
        ],
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
  final int pulse;
  const _MonthlyCard({
    required this.monthly,
    required this.months,
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
            colors: [Color(0xFF6C63FF), Color(0xFF3D35CC)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
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
