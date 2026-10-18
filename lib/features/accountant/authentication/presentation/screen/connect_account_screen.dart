import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../providers/accoutant_session_provider.dart';
import '../providers/accountant_auth_providers.dart';
import '../state/accountant_auth_state.dart';
import 'connect_scan_screen.dart';
import '../widget/auth_widgets.dart';

/// Role NULL wale user (sign up ke baad) ko login par yehi screen milti hai.
/// Branch par ja kar account connect hone ke baad role set hota hai.
class AccountantConnectAccountScreen extends ConsumerWidget {
  const AccountantConnectAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final auth = ref.watch(accountantAuthNotifierProvider);
    final notifier = ref.read(accountantAuthNotifierProvider.notifier);
    final loading = auth.status == AuthStatus.loading;

    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded,
                  size: 40, color: AppColor.primary),
            ),
          ),
          const SizedBox(height: 20),
          const AuthTitle('Visit your nearest branch'),
          const SizedBox(height: 10),
          const Text(
            'Please visit your nearest branch to connect your account. '
            'Scan the QR shown there.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColor.textMuted, fontSize: 15, height: 1.4),
          ),
          if (user != null) ...[
            const SizedBox(height: 14),
            Text(user.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColor.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
          if (auth.status == AuthStatus.error &&
              auth.errorMessage != null) ...[
            const SizedBox(height: 12),
            AuthError(auth.errorMessage!),
          ],
          const SizedBox(height: 28),
          AuthPrimaryButton(
              label: 'Scan QR',
              onPressed: loading
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AccountantConnectScanScreen()))),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: loading ? null : notifier.refreshProfile,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              foregroundColor: AppColor.textDark,
              side: const BorderSide(color: AppColor.grey200),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Check again',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: loading ? null : notifier.logout,
            child: const Text('Sign out',
                style: TextStyle(color: AppColor.textMuted)),
          ),
        ],
      ),
    );
  }
}
