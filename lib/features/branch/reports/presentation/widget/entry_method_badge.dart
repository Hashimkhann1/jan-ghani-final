import 'package:flutter/material.dart';

import '../../../../../core/color/app_color.dart';

/// Invoice item cart mein kis tareeqe se aaya. Purani sales (null) par kuch nahi.
class EntryMethodBadge extends StatelessWidget {
  final String? method;
  const EntryMethodBadge(this.method, {super.key});

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (method) {
      'barcode' => ('Scan', AppColor.success),
      'manual'  => ('Manual', AppColor.error),
      'mixed'   => ('Mixed', AppColor.warning),
      _         => ('', Colors.transparent),
    };
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
