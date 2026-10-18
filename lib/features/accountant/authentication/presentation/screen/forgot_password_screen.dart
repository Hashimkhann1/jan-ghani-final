import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/routes/accountant_paths.dart';
import '../providers/accountant_auth_providers.dart';
import '../widget/auth_widgets.dart';

class AccountantForgotPasswordScreen extends ConsumerStatefulWidget {
  const AccountantForgotPasswordScreen({super.key});

  @override
  ConsumerState<AccountantForgotPasswordScreen> createState() =>
      _AccountantForgotPasswordScreenState();
}

class _AccountantForgotPasswordScreenState
    extends ConsumerState<AccountantForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(accountantAuthRepositoryProvider).sendPasswordReset(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is Exception
            ? e.toString().replaceAll('Exception: ', '')
            : 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuthTitle('Forgot password'),
          const SizedBox(height: 28),
          AuthField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            hint: 'Email address',
            icon: Icons.mail_outline_rounded,
          ),
          if (_sent) ...[
            const SizedBox(height: 12),
            const Text(
              'If this email has an account, a reset link has been sent.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColor.success, fontSize: 13),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            AuthError(_error!),
          ],
          const SizedBox(height: 20),
          AuthPrimaryButton(
              label: 'Send reset link', loading: _loading, onPressed: _submit),
          const SizedBox(height: 16),
          AuthSwitchLine(
            text: 'Remember your password?',
            action: 'Sign in',
            onTap: () => context.go(AccPaths.login),
          ),
        ],
      ),
    );
  }
}
