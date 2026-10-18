import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/app_logo_widget.dart';

/// Login / Sign up / Forgot password — teeno screens ka common frame.
/// Mobile par seedha page, wide screen par center mein card.
class AuthShell extends StatelessWidget {
  final Widget child;
  const AuthShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 600;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: AppLogo(size: 84, radius: 22)),
        const SizedBox(height: 28),
        child,
      ],
    );

    return Scaffold(
      backgroundColor: isWide ? AppColor.grey100 : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: isWide
                  ? Container(
                      padding: const EdgeInsets.fromLTRB(36, 36, 36, 32),
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
                      child: content,
                    )
                  : content,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthTitle extends StatelessWidget {
  final String title;
  const AuthTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColor.textDark,
        ),
      );
}

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c),
        );
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 15, color: AppColor.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColor.textMuted),
        prefixIcon: Icon(icon, size: 20, color: AppColor.textMuted),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColor.grey100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(AppColor.primary),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
}

class AuthGoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AuthGoogleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 54,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColor.textDark,
            side: const BorderSide(color: AppColor.grey200),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('G',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4285F4))),
              SizedBox(width: 12),
              Text('Continue with Google',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Expanded(child: Divider(color: AppColor.grey200)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('or',
                style: TextStyle(color: AppColor.textMuted, fontSize: 13)),
          ),
          Expanded(child: Divider(color: AppColor.grey200)),
        ],
      );
}

class AuthError extends StatelessWidget {
  final String message;
  const AuthError(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColor.errorLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 16, color: AppColor.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style:
                      const TextStyle(color: AppColor.error, fontSize: 13)),
            ),
          ],
        ),
      );
}

/// "Don't have an account? Sign up" jaisi bottom line.
class AuthSwitchLine extends StatelessWidget {
  final String text;
  final String action;
  final VoidCallback onTap;
  const AuthSwitchLine(
      {super.key, required this.text, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text,
              style: const TextStyle(color: AppColor.textMuted, fontSize: 14)),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 36)),
            child: Text(action,
                style: const TextStyle(
                    color: AppColor.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      );
}

void showComingSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what is coming soon.')));
}
