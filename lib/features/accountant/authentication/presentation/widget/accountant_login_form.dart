import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';
import 'package:jan_ghani_final/core/widget/textfield/app_text_field.dart';
import '../providers/accountant_auth_providers.dart';
import '../state/accountant_auth_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(accountantAuthNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

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
            onPressed: isLoading ? null : _submit,
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
}
