import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';
import 'package:jan_ghani_final/core/widget/app_logo_widget.dart';
import '../widget/accountant_login_form.dart';

class AccountantLoginScreen extends ConsumerStatefulWidget {
  const AccountantLoginScreen({super.key});

  @override
  ConsumerState<AccountantLoginScreen> createState() =>
      _AccountantLoginScreenState();
}

class _AccountantLoginScreenState extends ConsumerState<AccountantLoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Login success par session set hota hai → router (accountant_router.dart)
    // khud dashboard / pichle URL par le jata hai.
    // Screen width se mobile/web decide karo
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColor.grey100,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: isWide
            ? _buildWebLayout()
            : _buildMobileLayout(),
      ),
    );
  }

  // ── WEB LAYOUT ──────────────────────────────────────────────────────────
  Widget _buildWebLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left side - branding
            Flexible(
              flex: 1,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppLogo(size: 76, radius: 20),
                      const SizedBox(height: 24),
                      const Text(
                        'Our mission:\n10,000 shops\nacross Pakistan',
                        style: TextStyle(
                          color: AppColor.textDark,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'We deliver household goods to every '
                        'family, right to their doorstep.',
                        style: TextStyle(
                          color: AppColor.textMuted,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Mission highlights
                      _featureBadge('ic_cash_registration',
                          '10,000 shops across Pakistan'),
                      const SizedBox(height: 10),
                      _featureBadge('ic_transfer',
                          'Household goods delivered to your door'),
                      const SizedBox(height: 10),
                      _featureBadge('ic_top_customers',
                          'Serving every home, every family'),
                    ],
                  ),
                ),
              ),
            ),

            // Right side - login card
            Flexible(
              flex: 1,
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColor.grey200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(40),
                    child: const AccountantLoginForm(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MOBILE LAYOUT ────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 84, radius: 22),
                  const SizedBox(height: 16),
                  const Text(
                    'Our mission: 10,000 shops across Pakistan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColor.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We deliver household goods to every family, '
                    'right to their doorstep.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColor.textMuted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 440),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColor.grey200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  child: const AccountantLoginForm(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper: feature badge (web only) ─────────────────────────────────────
  Widget _featureBadge(String icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColor.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppIcon(icon, size: 16, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColor.textDark,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
