

import 'package:flutter/material.dart';

import '../../../../../core/color/app_color.dart';

class EmptyState extends StatelessWidget {
  final bool isSearching;
  const EmptyState({this.isSearching = false});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isSearching ? Icons.search_off_rounded : Icons.account_balance_wallet_outlined, size: 64, color: AppColor.grey300),
        const SizedBox(height: 16),
        Text(isSearching ? 'Koi record nahi mila' : 'Koi payment record nahi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.textSecondary)),
        const SizedBox(height: 6),
        Text(isSearching ? 'Search query change karein' : 'New Payment button se record add karein', style: const TextStyle(fontSize: 13, color: AppColor.textHint)),
      ],
    ),
  );
}
