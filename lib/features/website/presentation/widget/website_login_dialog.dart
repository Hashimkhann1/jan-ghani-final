import 'package:flutter/material.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/widget/accountant_login_form.dart';

import 'website_sections.dart';

/// Website ka login popup — accountant / owner / customer sab isi se login
/// karte hain. Login hone par WebsiteScreen popup band karke account
/// (dashboard ya customer portal) par le jati hai.
Future<void> showWebsiteLoginDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _WebsiteLoginDialog(),
  );
}

class _WebsiteLoginDialog extends StatelessWidget {
  const _WebsiteLoginDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const WebsiteLogo(height: 56),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: WebsiteColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const AccountantLoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}
