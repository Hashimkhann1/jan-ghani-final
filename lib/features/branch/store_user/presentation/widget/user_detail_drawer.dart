import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../customer/presentation/widget/customer_status_badge_widget.dart';
import '../../data/model/user_model.dart';
import 'user_role_badge_widget.dart';

/// Right side se khulne wala user detail panel.
Future<void> showUserDetailDrawer(
    BuildContext context, UserModel user, {String? counterName}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => Align(
      alignment: Alignment.centerRight,
      child: _UserDetailDrawer(user: user, counterName: counterName),
    ),
    transitionBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class _UserDetailDrawer extends StatelessWidget {
  final UserModel user;
  final String? counterName;
  const _UserDetailDrawer({required this.user, this.counterName});

  @override
  Widget build(BuildContext context) {
    final u = user;
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
                      child: Text('User Details',
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
                    Text(u.fullName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(children: [
                      UserRoleBadge(role: u.role),
                      const SizedBox(width: 8),
                      CustomerStatusBadge(isActive: u.isActive),
                    ]),
                    const SizedBox(height: 20),
                    _row('Username', '@${u.username}'),
                    _row('Phone', (u.phone ?? '').isEmpty ? '—' : u.phone!),
                    _row('Role', u.roleLabel),
                    _row('Counter', counterName ?? 'No Counter'),
                    _row('Last Login', u.lastLogin == null
                        ? 'Never'
                        : fmt.format(u.lastLogin!.toLocal())),
                    _row('Created', fmt.format(u.createdAt.toLocal())),
                    _row('Updated', fmt.format(u.updatedAt.toLocal())),
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
                          data: 'user:${u.id}',
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
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
