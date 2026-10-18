import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QR mein `inst:<installment customer id>` hota hai. Customer app mein (naya
/// sign up, role khali) is QR ko scan kare to uska account is customer se
/// connect ho jata hai (RPC connect_installment_account).
String installmentConnectQrData(String customerId) => 'inst:$customerId';

Future<void> showInstallmentConnectQrDialog(
    BuildContext context, InstallmentCustomer customer) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(customer.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary)),
            const SizedBox(height: 4),
            const Text('Connect account',
                style: TextStyle(fontSize: 13, color: AppColor.textSecondary)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.grey200),
              ),
              child: QrImageView(
                data: installmentConnectQrData(customer.id),
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Ask the customer to sign up in the Jan Ghani app and scan this QR to connect the account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, height: 1.4, color: AppColor.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ),
  );
}
