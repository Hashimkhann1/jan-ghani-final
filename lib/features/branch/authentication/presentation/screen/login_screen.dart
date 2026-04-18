import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../provider/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _showPass  = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      _username.text.trim(),
      _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    // Error snackbar
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label:     'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(authProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColor.grey100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // ── Logo / Brand ──────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:        AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size:  56,
                  color: AppColor.primary,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Jan Ghani',
                style: TextStyle(
                  fontSize:   28,
                  fontWeight: FontWeight.w800,
                  color:      AppColor.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Store Management System',
                style: TextStyle(
                  fontSize: 13,
                  color:    AppColor.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              // ── Login Card ────────────────────────────
              Container(
                width:   420,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:      Colors.black.withValues(alpha: 0.07),
                      blurRadius: 24,
                      offset:     const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Header
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize:   22,
                          fontWeight: FontWeight.w700,
                          color:      AppColor.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Apna username aur password dalein',
                        style: TextStyle(
                          fontSize: 13,
                          color:    AppColor.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Username Field ────────────────
                      const _FieldLabel('Username'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller:      _username,
                        cursorHeight:    14,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                            fontSize: 14,
                            color:    AppColor.textPrimary),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Username required hai';
                          return null;
                        },
                        decoration: _inputDec(
                          hint:   'manager',
                          prefix: Icons.person_outline_rounded,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Password Field ────────────────
                      const _FieldLabel('Password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller:      _password,
                        obscureText:     !_showPass,
                        cursorHeight:    14,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        style: const TextStyle(
                            fontSize: 14,
                            color:    AppColor.textPrimary),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Password required hai';
                          return null;
                        },
                        decoration: _inputDec(
                          hint:   '••••••••',
                          prefix: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            icon: Icon(
                              _showPass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size:  18,
                              color: AppColor.grey400,
                            ),
                            onPressed: () =>
                                setState(() => _showPass = !_showPass),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Login Button ──────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:         AppColor.primary,
                            foregroundColor:         Colors.white,
                            disabledBackgroundColor:
                            AppColor.primary.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                            width:  20,
                            height: 20,
                            child:  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:       Colors.white),
                          )
                              : const Text(
                            'Login',
                            style: TextStyle(
                                fontSize:   15,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Footer ───────────────────────────────
              Text(
                '© ${DateTime.now().year} Jan Ghani. All rights reserved.',
                style: const TextStyle(
                    fontSize: 12, color: AppColor.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec({
    required String  hint,
    required IconData prefix,
    Widget?          suffix,
  }) {
    return InputDecoration(
      hintText:  hint,
      hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
      prefixIcon: Icon(prefix, size: 18, color: AppColor.grey400),
      suffixIcon: suffix,
      filled:    true,
      fillColor: AppColor.grey100,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   const BorderSide(color: AppColor.grey200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   const BorderSide(color: AppColor.grey200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppColor.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   const BorderSide(color: AppColor.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppColor.error, width: 1.5)),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize:   13,
        fontWeight: FontWeight.w500,
        color:      AppColor.textPrimary),
  );
}