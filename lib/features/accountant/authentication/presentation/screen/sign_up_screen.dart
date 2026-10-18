import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/routes/accountant_paths.dart';
import '../providers/accountant_auth_providers.dart';
import '../widget/auth_widgets.dart';

class AccountantSignUpScreen extends ConsumerStatefulWidget {
  const AccountantSignUpScreen({super.key});

  @override
  ConsumerState<AccountantSignUpScreen> createState() =>
      _AccountantSignUpScreenState();
}

class _AccountantSignUpScreenState
    extends ConsumerState<AccountantSignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (name.isEmpty) return 'Enter your name';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address';
    }
    if (pass.length < 6) return 'Password must be at least 6 characters';
    if (pass != _confirmCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(accountantAuthRepositoryProvider).signUp(
            fullName: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
      if (mounted) setState(() => _done = true);
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return AuthShell(child: _success(context));

    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuthTitle('Create account'),
          const SizedBox(height: 28),
          AuthField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            hint: 'Full name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
          AuthField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            hint: 'Email address',
            icon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 14),
          AuthField(
            controller: _passCtrl,
            obscure: _obscure,
            textInputAction: TextInputAction.next,
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
          const SizedBox(height: 14),
          AuthField(
            controller: _confirmCtrl,
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            hint: 'Confirm password',
            icon: Icons.lock_outline_rounded,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            AuthError(_error!),
          ],
          const SizedBox(height: 20),
          AuthPrimaryButton(
              label: 'Sign Up', loading: _loading, onPressed: _submit),
          const SizedBox(height: 20),
          const AuthDivider(),
          const SizedBox(height: 20),
          AuthGoogleButton(
              onPressed: () => ref.read(accountantAuthNotifierProvider.notifier).loginWithGoogle()),
          const SizedBox(height: 16),
          AuthSwitchLine(
            text: 'Already have an account?',
            action: 'Sign in',
            onTap: () => context.go(AccPaths.login),
          ),
        ],
      ),
    );
  }

  Widget _success(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 56, color: AppColor.success),
          const SizedBox(height: 16),
          const AuthTitle('Account created'),
          const SizedBox(height: 8),
          const Text(
            'Please visit your nearest branch to connect your account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColor.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 28),
          AuthPrimaryButton(
              label: 'Back to Sign In',
              onPressed: () => context.go(AccPaths.login)),
        ],
      );
}
