import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'website_sections.dart';

// Website ke halke animations — koi extra package nahi.

final _rs = NumberFormat('#,##0', 'en_US');
String formatRs(num v) => 'Rs ${_rs.format(v.round())}';

/// Pehle scroll par fade-up tha — website slow hoti thi, ab seedha child.
class Reveal extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final double offset;

  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 28,
  });

  @override
  Widget build(BuildContext context) => child;
}

/// Hover state builder ko deta hai (lift animation hata di — performance).
class HoverLift extends StatefulWidget {
  final Widget Function(BuildContext context, bool hovered) builder;
  final double lift;
  final VoidCallback? onTap;

  const HoverLift({
    super.key,
    required this.builder,
    this.lift = 6,
    this.onTap,
  });

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: widget.builder(context, _hovered),
      ),
    );
  }
}

/// Pehle lagataar upar neeche tairta tha (har frame repaint) — ab static.
class Floating extends StatelessWidget {
  final Widget child;
  final double amplitude;
  final Duration period;
  final double phase;

  const Floating({
    super.key,
    required this.child,
    this.amplitude = 10,
    this.period = const Duration(seconds: 6),
    this.phase = 0,
  });

  @override
  Widget build(BuildContext context) => child;
}

/// Raqam (calculator) — bina counting animation ke.
class AnimatedMoney extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String suffix;

  const AnimatedMoney({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) =>
      Text('${formatRs(value)}$suffix', style: style);
}

/// Website buttons — hover par halka scale + shadow.
enum WebButtonStyle { primary, outline, light, whatsapp }

class WebButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final WebButtonStyle style;
  final bool large;
  final bool expand;

  const WebButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.style = WebButtonStyle.primary,
    this.large = false,
    this.expand = false,
  });

  @override
  State<WebButton> createState() => _WebButtonState();
}

class _WebButtonState extends State<WebButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const primary = WebsiteColors.red;
    final (Color bg, Color fg, Color? border, Color glow) =
        switch (widget.style) {
      WebButtonStyle.primary => (primary, Colors.white, null, primary),
      WebButtonStyle.outline => (
          Colors.white,
          WebsiteColors.ink,
          const Color(0xFFE2E2E2),
          Colors.black
        ),
      WebButtonStyle.light => (
          Colors.white.withValues(alpha: 0.12),
          Colors.white,
          Colors.white.withValues(alpha: 0.28),
          Colors.black
        ),
      WebButtonStyle.whatsapp => (
          const Color(0xFF1FAF5A),
          Colors.white,
          null,
          const Color(0xFF1FAF5A)
        ),
    };

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(widget.icon, size: widget.large ? 19 : 17, color: fg),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: widget.large ? 15 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: border == null ? null : Border.all(color: border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: _hovered ? 0.28 : 0.10),
              blurRadius: _hovered ? 24 : 12,
              offset: Offset(0, _hovered ? 10 : 4),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.large ? 26 : 18,
                vertical: widget.large ? 18 : 12,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
