import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Website ke halke animations (3D bhi) — koi extra package nahi.

/// Matrix4 perspective — 3D gehrai (zyada = zyada dramatic).
const double _perspective = 0.0012;

final _rs = NumberFormat('#,##0', 'en_US');
String formatRs(num v) => 'Rs ${_rs.format(v.round())}';

/// Scroll karte hue screen mein aate hi 3D flip-up (sirf ek baar).
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offset;

  /// Shuru ka 3D jhukao (radians, X-axis par).
  final double flip;

  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 28,
    this.flip = 0.35,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  ScrollPosition? _position;
  bool _triggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_check);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_triggered || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.of(context).size.height * 0.92) {
      _triggered = true;
      _position?.removeListener(_check);
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (_, child) {
        final rest = 1 - _curve.value;
        return Opacity(
          opacity: _curve.value,
          child: Transform(
            alignment: Alignment.bottomCenter,
            // 3D: neeche se perspective ke saath seedha khara hota hai.
            transform: Matrix4.identity()
              ..setEntry(3, 2, _perspective)
              ..translateByDouble(0.0, widget.offset * rest, 0.0, 1.0)
              ..rotateX(widget.flip * rest),
            child: child,
          ),
        );
      },
    );
  }
}

/// Hover par upar uthna + mouse ki taraf 3D jhukna (tilt).
/// Builder ko `hovered` milta hai (shadow / photo zoom waghera card khud kare).
class HoverLift extends StatefulWidget {
  final Widget Function(BuildContext context, bool hovered) builder;
  final double lift;

  /// Zyada se zyada 3D jhukao (radians). 0 = sirf lift.
  final double tilt;
  final VoidCallback? onTap;

  const HoverLift({
    super.key,
    required this.builder,
    this.lift = 6,
    this.tilt = 0.14,
    this.onTap,
  });

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  /// Mouse ki jagah card ke beech se, -1..1 (x, y).
  Offset _pointer = Offset.zero;

  void _track(Offset local) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    setState(() => _pointer = Offset(
          (local.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
          (local.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final target = _hovered ? _pointer : Offset.zero;
    return MouseRegion(
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (e) {
        _hovered = true;
        _track(e.localPosition);
      },
      onHover: (e) => _track(e.localPosition),
      onExit: (_) => setState(() {
        _hovered = false;
        _pointer = Offset.zero;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          transform:
              Matrix4.translationValues(0, _hovered ? -widget.lift : 0, 0),
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(end: target),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: widget.builder(context, _hovered),
            builder: (_, p, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, _perspective)
                ..rotateX(-p.dy * widget.tilt)
                ..rotateY(p.dx * widget.tilt),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lagataar dheere 3D mein jhoolna (hero card) — Y aur X axis par.
class Sway3D extends StatefulWidget {
  final Widget child;
  final double angle;
  final Duration period;

  const Sway3D({
    super.key,
    required this.child,
    this.angle = 0.10,
    this.period = const Duration(seconds: 9),
  });

  @override
  State<Sway3D> createState() => _Sway3DState();
}

class _Sway3DState extends State<Sway3D> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (_, child) {
        final t = _ctrl.value * 2 * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateY(math.sin(t) * widget.angle)
            ..rotateX(math.cos(t) * widget.angle * 0.45),
          child: child,
        );
      },
    );
  }
}

/// Upar neeche dheere tairti hui cheez (decorative blobs / chips).
class Floating extends StatefulWidget {
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
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (_, child) => Transform.translate(
        offset: Offset(
          0,
          math.sin((_ctrl.value + widget.phase) * 2 * math.pi) *
              widget.amplitude,
        ),
        child: child,
      ),
    );
  }
}

/// Raqam badalne par purani se nayi tak ginti (calculator).
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
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${formatRs(v)}$suffix', style: style),
    );
  }
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
    const primary = Color(0xFF6C63FF);
    final (Color bg, Color fg, Color? border, Color glow) =
        switch (widget.style) {
      WebButtonStyle.primary => (primary, Colors.white, null, primary),
      WebButtonStyle.outline => (
          Colors.white,
          const Color(0xFF12112B),
          const Color(0xFFE2E2EC),
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
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border:
                border == null ? null : Border.all(color: border, width: 1.5),
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
      ),
    );
  }
}
