import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';
import 'package:jan_ghani_final/core/widget/app_logo_widget.dart';
import 'package:jan_ghani_final/core/widget/textfield/app_text_field.dart';
import 'package:jan_ghani_final/features/accountant/dashboard/presentation/screen/dashboard_screen.dart';
import '../providers/accountant_auth_providers.dart';
import '../state/accountant_auth_state.dart';

class AccountantLoginScreen extends ConsumerStatefulWidget {
  const AccountantLoginScreen({super.key});

  @override
  ConsumerState<AccountantLoginScreen> createState() =>
      _AccountantLoginScreenState();
}

class _AccountantLoginScreenState extends ConsumerState<AccountantLoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

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
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _listenAuth(AccountantAuthState? prev, AccountantAuthState next) {
    if (next.status == AuthStatus.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountantDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(accountantAuthNotifierProvider, _listenAuth);
    final authState = ref.watch(accountantAuthNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    // Screen width se mobile/web decide karo
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColor.grey100,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: isWide
            ? _buildWebLayout(authState, isLoading)
            : _buildMobileLayout(authState, isLoading),
      ),
    );
  }

  // ── WEB LAYOUT ──────────────────────────────────────────────────────────
  Widget _buildWebLayout(AccountantAuthState authState, bool isLoading) {
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
                    child: _buildFormContent(authState, isLoading),
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
  Widget _buildMobileLayout(AccountantAuthState authState, bool isLoading) {
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
                  child: _buildFormContent(authState, isLoading),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SHARED FORM CONTENT ───────────────────────────────────────────────────
  Widget _buildFormContent(AccountantAuthState authState, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColor.textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sign in to continue',
          style: TextStyle(fontSize: 14, color: AppColor.textMuted),
        ),
        const SizedBox(height: 28),

        AppTextField(
          controller: _usernameCtrl,
          keyboardType: TextInputType.emailAddress,
          hint: 'Email address',
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: AppIcon('ic_role_manager', size: 18, color: AppColor.textMuted),
          ),
        ),
        const SizedBox(height: 16),

        AppTextField(
          controller: _passCtrl,
          obscureText: _obscure,
          hint: 'Password',
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: AppIcon('ic_custom_access', size: 18, color: AppColor.textMuted),
          ),
          suffixIcon: IconButton(
            icon: AppIcon(
              'ic_view',
              size: 20,
              color: _obscure ? AppColor.textMuted : AppColor.primary,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),

        // Error banner
        if (authState.status == AuthStatus.error &&
            authState.errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const AppIcon('ic_rejected', size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text(
              'Forgot password?',
              style: TextStyle(color: AppColor.primary),
            ),
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
              ref
                  .read(accountantAuthNotifierProvider.notifier)
                  .login(
                username: _usernameCtrl.text.trim(),
                password: _passCtrl.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : const Text(
              'Sign In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
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
