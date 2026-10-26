import 'package:flutter/material.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../../core/widget/app_icon.dart';
import 'report_action_style.dart';

/// Refresh control shared by every branch report.
class ReportRefreshButton extends StatelessWidget {
  final VoidCallback? onPressed;
  /// null = screen width se tay hota hai; true = hamesha labelled button.
  final bool? labeled;
  const ReportRefreshButton(
      {super.key, required this.onPressed, this.labeled});

  @override
  Widget build(BuildContext context) {
    if (!(labeled ?? ReportActionStyle.isWide(context))) {
      return IconButton(
        onPressed: onPressed,
        icon: const AppIcon('ic_refresh',
            size: 22, color: AppColor.textSecondary),
        tooltip: 'Refresh',
      );
    }
    return Padding(
      padding: ReportActionStyle.wideGap,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const AppIcon('ic_refresh', size: 18, color: AppColor.primary),
        label: const Text('Refresh'),
        style: ReportActionStyle.outlined(),
      ),
    );
  }
}
