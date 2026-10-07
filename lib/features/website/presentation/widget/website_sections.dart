import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/website_content.dart';
import '../../data/website_strings.dart';
import 'map_embed.dart';
import 'website_motion.dart';

// Website ke sections — content: data/website_content.dart
// Installment section alag file mein: installment_section.dart

enum WebsiteSection { home, about, products, installments, branches, contact }

String _sectionLabel(WebsiteText t, WebsiteSection s) => switch (s) {
      WebsiteSection.home => t.navHome,
      WebsiteSection.about => t.navAbout,
      WebsiteSection.products => t.navProducts,
      WebsiteSection.installments => t.navInstallments,
      WebsiteSection.branches => t.navBranches,
      WebsiteSection.contact => t.navContact,
    };

class WebsiteColors {
  WebsiteColors._();
  // Jan Ghani brand colors.
  static const red = Color(0xFFED0015);
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  static const redDark = Color(0xFFC00012);
  static const redDeep = Color(0xFF8E000D);
  static const page = Color(0xFFF7F7F7);
  static const ink = black;
  static const muted = Color(0xFF5E5E5E);
  static const line = Color(0xFFE6E6E6);
  static const tint = Color(0xFFFFEEEF);
  static const darkBg = black;
}

/// Website ka brand logo (`assets/images/web_logo.png`) — naam bhi isi mein
/// hai, isliye saath alag text ki zarurat nahi.
class WebsiteLogo extends StatelessWidget {
  final double height;
  const WebsiteLogo({super.key, this.height = 44});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/web_logo.png',
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
}

const double _maxContent = 1180;

/// Content ko beech mein max width par rakhta hai.
class Contained extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  const Contained({
    super.key,
    required this.child,
    required this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: padding,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContent),
        child: child,
      ),
    );
  }
}

EdgeInsets sectionPadding(bool mobile) => mobile
    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 64)
    : const EdgeInsets.symmetric(horizontal: 32, vertical: 104);

/// Halka gol rang ka dhabba (background decoration).
class DecorBlob extends StatelessWidget {
  final double size;
  final Color color;
  const DecorBlob({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? text;
  final bool mobile;
  final bool light;
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.mobile,
    this.text,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: light
                ? Colors.white.withValues(alpha: 0.10)
                : WebsiteColors.tint,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: tracking(context, 1.6),
              color: light ? const Color(0xFFFF8A93) : WebsiteColors.red,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: mobile ? 28 : 40,
            fontWeight: FontWeight.w800,
            letterSpacing: tracking(context, mobile ? -0.6 : -1.2),
            height: 1.15,
            color: light ? Colors.white : WebsiteColors.ink,
          ),
        ),
        if (text != null) ...[
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: Text(
              text!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: mobile ? 15 : 17,
                height: 1.6,
                color: light ? Colors.white70 : WebsiteColors.muted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Nav bar ──────────────────────────────────────────────────────────────────
class WebsiteNavBar extends StatelessWidget {
  final bool mobile;
  final bool scrolled;
  final String accountLabel;
  final VoidCallback onAccount;
  final ValueChanged<WebsiteSection> onSection;

  const WebsiteNavBar({
    super.key,
    required this.mobile,
    required this.scrolled,
    required this.accountLabel,
    required this.onAccount,
    required this.onSection,
  });

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    return Reveal(
      offset: -18,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: scrolled ? Colors.transparent : WebsiteColors.line,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: scrolled ? 0.07 : 0),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Contained(
          padding: EdgeInsets.symmetric(
              horizontal: mobile ? 16 : 32, vertical: scrolled ? 10 : 14),
          child: Row(
            children: [
              InkWell(
                onTap: () => onSection(WebsiteSection.home),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WebsiteLogo(height: mobile ? 44 : 52),
                  ],
                ),
              ),
              if (!mobile) ...[
                // Urdu / Pashto labels lambe hain — jagah kam ho to chhote.
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final s in WebsiteSection.values)
                            _NavLink(
                                label: _sectionLabel(t, s),
                                onTap: () => onSection(s)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const WebsiteLanguageButton(),
                const SizedBox(width: 10),
                WebButton(
                  label: accountLabel,
                  icon: Icons.login_rounded,
                  onTap: onAccount,
                ),
              ] else ...[
                const Spacer(),
                const WebsiteLanguageButton(compact: true),
                const SizedBox(width: 8),
                Builder(
                  builder: (ctx) => IconButton(
                    tooltip: t.menu,
                    onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                    style: IconButton.styleFrom(
                      backgroundColor: WebsiteColors.tint,
                    ),
                    icon: const Icon(Icons.menu_rounded,
                        color: WebsiteColors.ink),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// English / اردو / پښتو — navbar ka language menu.
class WebsiteLanguageButton extends StatelessWidget {
  final bool compact;
  const WebsiteLanguageButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final locale = WebsiteLocale.of(context);
    return PopupMenuButton<WebsiteLang>(
      tooltip: locale.lang.text.language,
      initialValue: locale.lang,
      onSelected: locale.onChanged,
      position: PopupMenuPosition.under,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        for (final l in WebsiteLang.values)
          PopupMenuItem(
            value: l,
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: l == locale.lang
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: WebsiteColors.red)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(l.label,
                    style: TextStyle(
                        fontWeight: l == locale.lang
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: WebsiteColors.ink)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14, vertical: compact ? 8 : 11),
        decoration: BoxDecoration(
          color: WebsiteColors.tint,
          borderRadius: BorderRadius.circular(compact ? 10 : 14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate_rounded,
                size: 18, color: WebsiteColors.red),
            const SizedBox(width: 6),
            Text(locale.lang.label,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: WebsiteColors.ink)),
            const Icon(Icons.arrow_drop_down_rounded,
                size: 20, color: WebsiteColors.muted),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? WebsiteColors.red : WebsiteColors.muted,
                ),
                child: Text(widget.label),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: _hovered ? 18 : 0,
                decoration: BoxDecoration(
                  color: WebsiteColors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WebsiteDrawer extends StatelessWidget {
  final String accountLabel;
  final VoidCallback onAccount;
  final ValueChanged<WebsiteSection> onSection;

  const WebsiteDrawer({
    super.key,
    required this.accountLabel,
    required this.onAccount,
    required this.onSection,
  });

  static const _icons = {
    WebsiteSection.home: Icons.home_rounded,
    WebsiteSection.about: Icons.info_rounded,
    WebsiteSection.products: Icons.category_rounded,
    WebsiteSection.installments: Icons.event_repeat_rounded,
    WebsiteSection.branches: Icons.storefront_rounded,
    WebsiteSection.contact: Icons.support_agent_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    void close(VoidCallback then) {
      Navigator.of(context).pop();
      then();
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const WebsiteLogo(height: 56),
              ],
            ),
            const SizedBox(height: 20),
            for (final s in WebsiteSection.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: Icon(_icons[s], color: WebsiteColors.red),
                  title: Text(_sectionLabel(t, s),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: WebsiteColors.ink)),
                  onTap: () => close(() => onSection(s)),
                ),
              ),
            const SizedBox(height: 16),
            WebButton(
              label: accountLabel,
              icon: Icons.login_rounded,
              expand: true,
              onTap: () => close(onAccount),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────
class HeroSection extends StatelessWidget {
  final bool mobile;
  final VoidCallback onInstallments;
  final VoidCallback onContact;

  const HeroSection({
    super.key,
    required this.mobile,
    required this.onInstallments,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final align = mobile ? TextAlign.center : TextAlign.start;
    final titleStyle = TextStyle(
      fontSize: mobile ? 36 : 60,
      fontWeight: FontWeight.w900,
      letterSpacing: tracking(context, mobile ? -1.2 : -2.2),
      height: rtl ? 1.45 : 1.04,
      color: WebsiteColors.ink,
    );

    final text = Column(
      crossAxisAlignment:
          mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Reveal(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: WebsiteColors.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag_rounded,
                    size: 15, color: WebsiteColors.red),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    t.heroChip,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: WebsiteColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Reveal(
          delay: const Duration(milliseconds: 100),
          child: Text(t.heroTitle1, textAlign: align, style: titleStyle),
        ),
        Reveal(
          delay: const Duration(milliseconds: 200),
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (r) => const LinearGradient(
              colors: [WebsiteColors.red, WebsiteColors.redDark, WebsiteColors.black],
            ).createShader(r),
            child: Text(t.heroTitle2, textAlign: align, style: titleStyle),
          ),
        ),
        const SizedBox(height: 22),
        Reveal(
          delay: const Duration(milliseconds: 300),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              t.heroText,
              textAlign: align,
              style: TextStyle(
                fontSize: mobile ? 16 : 18,
                height: 1.6,
                color: WebsiteColors.muted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 34),
        Reveal(
          delay: const Duration(milliseconds: 400),
          child: Wrap(
            alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
            spacing: 12,
            runSpacing: 12,
            children: [
              WebButton(
                label: t.exploreInstallments,
                icon: Icons.event_repeat_rounded,
                large: true,
                onTap: onInstallments,
              ),
              WebButton(
                label: t.contactUs,
                icon: Icons.support_agent_rounded,
                style: WebButtonStyle.outline,
                large: true,
                onTap: onContact,
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        Reveal(
          delay: const Duration(milliseconds: 500),
          child: Wrap(
            alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
            spacing: 22,
            runSpacing: 10,
            children: [
              _TrustPoint(Icons.verified_rounded, t.trustQuality),
              _TrustPoint(Icons.local_shipping_rounded, t.trustDelivery),
              _TrustPoint(Icons.event_repeat_rounded, t.trustPlans),
            ],
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WebsiteColors.tint, Color(0xFFF8F8F8), Color(0xFFF4F4F4)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -60,
            left: -80,
            child: Floating(
              amplitude: 16,
              period: Duration(seconds: 8),
              child: DecorBlob(size: 280, color: Color(0x14ED0015)),
            ),
          ),
          const Positioned(
            bottom: -40,
            right: 120,
            child: Floating(
              amplitude: 12,
              phase: 0.4,
              child: DecorBlob(size: 180, color: Color(0x12000000)),
            ),
          ),
          Contained(
            padding: mobile
                ? const EdgeInsets.fromLTRB(16, 52, 16, 64)
                : const EdgeInsets.fromLTRB(32, 100, 32, 112),
            child: mobile
                ? Column(children: [
                    text,
                    const SizedBox(height: 48),
                    const Reveal(
                      delay: Duration(milliseconds: 300),
                      child: _HeroVisual(compact: true),
                    ),
                  ])
                : Row(
                    children: [
                      Expanded(flex: 6, child: text),
                      const SizedBox(width: 56),
                      const Expanded(
                        flex: 5,
                        child: Reveal(
                          delay: Duration(milliseconds: 250),
                          offset: 40,
                          child: _HeroVisual(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrustPoint extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustPoint(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: WebsiteColors.red),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: WebsiteColors.muted)),
        ],
      );
}

class _HeroVisual extends StatelessWidget {
  final bool compact;
  const _HeroVisual({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 22 : 30),
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: Image.asset('assets/images/home.jpg', fit: BoxFit.cover),
        ),
      ),
    );
  }
}

// ── Cards grid (About highlights / Products / Why us) ────────────────────────
class _CardGrid extends StatelessWidget {
  final List<WebsiteItem> items;
  final int columns;
  final bool centered;
  const _CardGrid({
    required this.items,
    required this.columns,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 900
          ? columns
          : c.maxWidth >= 520
              ? 2
              : 1;
      const gap = 20.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (int i = 0; i < items.length; i++)
            SizedBox(
              width: w,
              child: Reveal(
                delay: Duration(milliseconds: 80 * (i % cols)),
                child: _InfoCard(item: items[i], centered: centered),
              ),
            ),
        ],
      );
    });
  }
}

class _InfoCard extends StatelessWidget {
  final WebsiteItem item;
  final bool centered;
  const _InfoCard({required this.item, this.centered = false});

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      builder: (_, hovered) => AnimatedContainer(
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
              color: WebsiteColors.red.withValues(alpha: hovered ? 0.13 : 0.03),
              blurRadius: hovered ? 30 : 12,
              offset: Offset(0, hovered ? 16 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: hovered
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [WebsiteColors.red, WebsiteColors.redDark])
                    : null,
                color: hovered ? null : WebsiteColors.tint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedScale(
                scale: hovered ? 1.12 : 1,
                duration: const Duration(milliseconds: 240),
                child: Icon(item.icon,
                    color: hovered ? Colors.white : WebsiteColors.red, size: 27),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              item.title,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: WebsiteColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.text,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: WebsiteColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── About ────────────────────────────────────────────────────────────────────
class AboutSection extends StatelessWidget {
  final bool mobile;
  const AboutSection({super.key, required this.mobile});

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    return Contained(
      color: Colors.white,
      padding: sectionPadding(mobile),
      child: Column(
        children: [
          Reveal(
            child: SectionHeader(
              eyebrow: t.aboutEyebrow,
              title: t.aboutTitle,
              text: t.aboutText,
              mobile: mobile,
            ),
          ),
          SizedBox(height: mobile ? 36 : 56),
          _CardGrid(
            items: t.highlightItems,
            columns: 4,
            centered: true,
          ),
        ],
      ),
    );
  }
}

// ── Products (categories) ────────────────────────────────────────────────────
class ProductsSection extends StatelessWidget {
  final bool mobile;
  const ProductsSection({super.key, required this.mobile});

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    return Contained(
      padding: sectionPadding(mobile),
      child: Column(
        children: [
          Reveal(
            child: SectionHeader(
              eyebrow: t.productsEyebrow,
              title: t.productsTitle,
              text: t.productsText,
              mobile: mobile,
            ),
          ),
          SizedBox(height: mobile ? 36 : 56),
          _CardGrid(items: t.categoryItems, columns: 3),
        ],
      ),
    );
  }
}

// ── Why us ───────────────────────────────────────────────────────────────────
class WhyUsSection extends StatelessWidget {
  final bool mobile;
  const WhyUsSection({super.key, required this.mobile});

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    return Contained(
      color: Colors.white,
      padding: sectionPadding(mobile),
      child: Column(
        children: [
          Reveal(
            child: SectionHeader(
              eyebrow: t.whyEyebrow,
              title: t.whyTitle,
              mobile: mobile,
            ),
          ),
          SizedBox(height: mobile ? 36 : 56),
          _CardGrid(items: t.whyUsItems, columns: 4),
        ],
      ),
    );
  }
}

// ── Branches ─────────────────────────────────────────────────────────────────
class BranchesSection extends StatelessWidget {
  final bool mobile;
  final VoidCallback onContact;
  const BranchesSection({
    super.key,
    required this.mobile,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    const branches = WebsiteContent.branches;
    return Contained(
      padding: sectionPadding(mobile),
      child: Column(
        children: [
          Reveal(
            child: SectionHeader(
              eyebrow: t.branchesEyebrow,
              title: t.branchesTitle,
              text: t.branchesText,
              mobile: mobile,
            ),
          ),
          SizedBox(height: mobile ? 36 : 56),
          if (branches.isEmpty)
            Reveal(
                child: _NearestBranchCard(mobile: mobile, onContact: onContact))
          else
            LayoutBuilder(builder: (context, c) {
              final fit = c.maxWidth >= 900
                  ? 3
                  : c.maxWidth >= 640
                      ? 2
                      : 1;
              final cols = fit < branches.length ? fit : branches.length;
              const gap = 20.0;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (int i = 0; i < branches.length; i++)
                    SizedBox(
                      width: w,
                      child: Reveal(
                        delay: Duration(milliseconds: 80 * (i % cols)),
                        child: _BranchCard(branch: branches[i], mobile: mobile),
                      ),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final WebsiteBranch branch;
  final bool mobile;
  const _BranchCard({required this.branch, required this.mobile});

  void _openMap() =>
      launchUrl(Uri.parse(branch.mapUrl), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final hasMap = branch.mapUrl.isNotEmpty;
    final lat = branch.lat, lng = branch.lng;
    return HoverLift(
      lift: 4,
      builder: (_, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hovered ? const Color(0xFFFFB8BD) : WebsiteColors.line,
          ),
          boxShadow: [
            BoxShadow(
              color: WebsiteColors.red.withValues(alpha: hovered ? 0.12 : 0.03),
              blurRadius: hovered ? 28 : 12,
              offset: Offset(0, hovered ? 14 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lat != null && lng != null)
              SizedBox(
                height: mobile ? 220 : 280,
                child: MapEmbed(lat: lat, lng: lng),
              ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  const WebsiteLogo(height: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(branch.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: WebsiteColors.ink)),
                        _IconLine(Icons.location_on_rounded, branch.address),
                        if (branch.phone.isNotEmpty)
                          _IconLine(Icons.phone_rounded, branch.phone),
                      ],
                    ),
                  ),
                  if (hasMap) ...[
                    const SizedBox(width: 12),
                    WebButton(
                      label: WebsiteText.of(context).directions,
                      icon: Icons.directions_rounded,
                      style: WebButtonStyle.outline,
                      onTap: _openMap,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconLine(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: WebsiteColors.red),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13.5, height: 1.4, color: WebsiteColors.muted)),
            ),
          ],
        ),
      );
}

class _NearestBranchCard extends StatelessWidget {
  final bool mobile;
  final VoidCallback onContact;
  const _NearestBranchCard({required this.mobile, required this.onContact});

  @override
  Widget build(BuildContext context) {
    final icon = Floating(
      amplitude: 6,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [WebsiteColors.red, WebsiteColors.redDark],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child:
            const Icon(Icons.storefront_rounded, color: Colors.white, size: 40),
      ),
    );
    final t = WebsiteText.of(context);
    final text = Column(
      crossAxisAlignment:
          mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(t.nearestTitle,
            textAlign: mobile ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: WebsiteColors.ink)),
        const SizedBox(height: 8),
        Text(t.nearestText,
            textAlign: mobile ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
                fontSize: 14.5, height: 1.55, color: WebsiteColors.muted)),
      ],
    );
    final button = WebButton(
      label: t.contactBrand,
      icon: Icons.support_agent_rounded,
      onTap: onContact,
    );

    return Container(
      padding: EdgeInsets.all(mobile ? 24 : 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: WebsiteColors.line),
      ),
      child: mobile
          ? Column(children: [
              icon,
              const SizedBox(height: 20),
              text,
              const SizedBox(height: 20),
              button,
            ])
          : Row(children: [
              icon,
              const SizedBox(width: 28),
              Expanded(child: text),
              const SizedBox(width: 28),
              button,
            ]),
    );
  }
}

// ── Contact + account ────────────────────────────────────────────────────────
class ContactSection extends StatelessWidget {
  final bool mobile;
  final String accountLabel;
  final VoidCallback onAccount;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;

  const ContactSection({
    super.key,
    required this.mobile,
    required this.accountLabel,
    required this.onAccount,
    this.onWhatsApp,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    final contacts = <(IconData, String, String)>[
      if (WebsiteContent.whatsapp.isNotEmpty)
        (
          Icons.chat_rounded,
          t.whatsapp,
          WebsiteContent.phone.isNotEmpty
              ? WebsiteContent.phone
              : '+${WebsiteContent.whatsapp}'
        ),
      if (WebsiteContent.phone.isNotEmpty)
        (Icons.phone_rounded, t.phone, WebsiteContent.phone),
      if (WebsiteContent.email.isNotEmpty)
        (Icons.mail_rounded, t.email, WebsiteContent.email),
      if (WebsiteContent.address.isNotEmpty)
        (Icons.location_on_rounded, t.address, WebsiteContent.address),
    ];

    final contactCard = Container(
      padding: EdgeInsets.all(mobile ? 24 : 36),
      decoration: BoxDecoration(
        color: WebsiteColors.darkBg,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.getInTouch,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(t.getInTouchText,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 15, height: 1.5)),
          const SizedBox(height: 24),
          if (contacts.isEmpty)
            Text(t.visitNearest,
                style: const TextStyle(color: Colors.white, fontSize: 15))
          else
            for (final (icon, label, value) in contacts)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(icon, color: const Color(0xFFFF8A93), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                          Text(value,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          if (onWhatsApp != null || onCall != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (onWhatsApp != null)
                  WebButton(
                    label: t.chatWhatsApp,
                    icon: Icons.chat_rounded,
                    style: WebButtonStyle.whatsapp,
                    onTap: onWhatsApp!,
                  ),
                if (onCall != null)
                  WebButton(
                    label: t.callUs,
                    icon: Icons.phone_rounded,
                    style: WebButtonStyle.light,
                    onTap: onCall!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    final accountCard = Container(
      padding: EdgeInsets.all(mobile ? 24 : 36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WebsiteColors.red, WebsiteColors.redDeep],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_circle_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 18),
          Text(t.accountTitle,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(t.accountText,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14.5, height: 1.55)),
          const SizedBox(height: 24),
          WebButton(
            label: accountLabel,
            icon: Icons.login_rounded,
            style: WebButtonStyle.outline,
            onTap: onAccount,
          ),
        ],
      ),
    );

    return Contained(
      color: Colors.white,
      padding: sectionPadding(mobile),
      child: Column(
        children: [
          Reveal(
            child: SectionHeader(
              eyebrow: t.contactEyebrow,
              title: t.contactTitle,
              mobile: mobile,
            ),
          ),
          SizedBox(height: mobile ? 36 : 56),
          if (mobile)
            Column(children: [
              Reveal(child: contactCard),
              const SizedBox(height: 20),
              Reveal(child: accountCard),
            ])
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: Reveal(child: contactCard)),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Reveal(
                      delay: const Duration(milliseconds: 120),
                      child: accountCard,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Footer ───────────────────────────────────────────────────────────────────
class WebsiteFooter extends StatelessWidget {
  final bool mobile;
  final ValueChanged<WebsiteSection> onSection;
  const WebsiteFooter({
    super.key,
    required this.mobile,
    required this.onSection,
  });

  @override
  Widget build(BuildContext context) {
    final t = WebsiteText.of(context);
    final brand = Column(
      crossAxisAlignment:
          mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: WebsiteColors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const WebsiteLogo(height: 56),
        ),
        const SizedBox(height: 12),
        Text(
          '${t.tagline}\n${t.instMotto}',
          textAlign: mobile ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
              color: Colors.white60, fontSize: 13.5, height: 1.6),
        ),
      ],
    );
    final links = Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (final s in WebsiteSection.values)
          TextButton(
            onPressed: () => onSection(s),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: Text(_sectionLabel(t, s)),
          ),
      ],
    );

    return Contained(
      color: WebsiteColors.darkBg,
      padding: EdgeInsets.fromLTRB(
          mobile ? 16 : 32, mobile ? 40 : 56, mobile ? 16 : 32, 28),
      child: Column(
        children: [
          mobile
              ? Column(children: [brand, const SizedBox(height: 20), links])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [brand, const Spacer(), links],
                ),
          const SizedBox(height: 28),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            t.copyright.fill(DateTime.now().year),
            style: const TextStyle(color: Colors.white38, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
