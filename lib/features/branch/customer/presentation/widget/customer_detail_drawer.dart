import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/model/customer_model.dart';
import 'customer_status_badge_widget.dart';
import 'customer_type_badge_widget.dart';

/// Right side se khulne wala customer detail panel. Neeche customer id ka QR —
/// app mein scan karne se user ka account is customer se connect hota hai
/// (RPC connect_customer_account).
Future<void> showCustomerDetailDrawer(
    BuildContext context, CustomerModel customer) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => Align(
      alignment: Alignment.centerRight,
      child: _CustomerDetailDrawer(customer: customer),
    ),
    transitionBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class _CustomerDetailDrawer extends StatelessWidget {
  final CustomerModel customer;
  const _CustomerDetailDrawer({required this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final width = MediaQuery.sizeOf(context).width;
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Material(
      color: Colors.white,
      elevation: 16,
      child: SizedBox(
        width: width < 440 ? width : 420,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Customer Details',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(c.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(children: [
                      CustomerTypeBadge(customerType: c.customerType),
                      const SizedBox(width: 8),
                      CustomerStatusBadge(isActive: c.isActive),
                    ]),
                    const SizedBox(height: 20),
                    _row('Code', c.code),
                    _row('Phone', c.phone.isEmpty ? '—' : c.phone),
                    _row('Address',
                        (c.address ?? '').isEmpty ? '—' : c.address!),
                    _row('Credit Limit', c.creditLimitLabel),
                    _row('Balance', c.balanceLabel),
                    if ((c.notes ?? '').isNotEmpty) _row('Notes', c.notes!),
                    _row('Created', fmt.format(c.createdAt.toLocal())),
                    _row('Updated', fmt.format(c.updatedAt.toLocal())),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColor.grey200),
                        ),
                        child: QrImageView(
                          data: c.id,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Scan this QR in the Jan Ghani app to connect the account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColor.textMuted, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColor.textMuted, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}
