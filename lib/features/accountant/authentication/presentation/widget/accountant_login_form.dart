import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/routes/accountant_paths.dart';
import '../providers/accountant_auth_providers.dart';
import '../state/accountant_auth_state.dart';
import 'auth_widgets.dart';

/// Email + password form — login screen aur website ka login popup dono
/// yahi use karte hain. Success par session set hota hai, aage ka kaam
/// router (accountant_router.dart) karta hai.
class AccountantLoginForm extends ConsumerStatefulWidget {
  const AccountantLoginForm({super.key});

  @override
  ConsumerState<AccountantLoginForm> createState() =>
      _AccountantLoginFormState();
}

class _AccountantLoginFormState extends ConsumerState<AccountantLoginForm> {
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(accountantAuthNotifierProvider.notifier).login(
          username: _usernameCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
  }

  void _go(String path) {
    ref.read(accountantAuthNotifierProvider.notifier).resetState();
    final router = GoRouter.of(context);
    // Website ke login popup mein ho to pehle popup band karo, warna Sign up /
    // Forgot password screen ke neeche popup khula reh jata hai.
    if (ModalRoute.of(context) is PopupRoute) Navigator.of(context).pop();
    router.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(accountantAuthNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AuthTitle('Welcome back'),
        const SizedBox(height: 28),
        AuthField(
          controller: _usernameCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          hint: 'Email address',
          icon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: 14),
        AuthField(
          controller: _passCtrl,
          obscure: _obscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          hint: 'Password',
          icon: Icons.lock_outline_rounded,
          suffix: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: _obscure ? AppColor.textMuted : AppColor.primary,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        if (authState.status == AuthStatus.error &&
            authState.errorMessage != null) ...[
          const SizedBox(height: 12),
          AuthError(authState.errorMessage!),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _go(AccPaths.forgotPassword),
            child: const Text('Forgot password?',
                style: TextStyle(color: AppColor.primary)),
          ),
        ),
        const SizedBox(height: 4),
        AuthPrimaryButton(
            label: 'Sign In', loading: isLoading, onPressed: _submit),
        const SizedBox(height: 20),
        const AuthDivider(),
        const SizedBox(height: 20),
        AuthGoogleButton(
            onPressed: () => ref
                .read(accountantAuthNotifierProvider.notifier)
                .loginWithGoogle()),
        const SizedBox(height: 16),
        AuthSwitchLine(
          text: "Don't have an account?",
          action: 'Sign up',
          onTap: () => _go(AccPaths.signUp),
        ),
      ],
    );
  }
}
